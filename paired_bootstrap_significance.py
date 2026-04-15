"""
paired_bootstrap_significance.py
===============================

Generic paired-bootstrap significance test for classification predictions.

Given gold labels and two prediction vectors on the same samples, this script
reports:
- point metrics for model A and model B,
- delta metrics (B - A),
- 95% percentile confidence intervals from paired bootstrap,
- one-sided p-values for improvement (delta <= 0).
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Dict, Tuple

import numpy as np
import pandas as pd
from sklearn.metrics import accuracy_score, f1_score


def load_vector(csv_path: Path, column: str) -> np.ndarray:
    if not csv_path.exists():
        raise FileNotFoundError(f"CSV not found: {csv_path}")

    df = pd.read_csv(csv_path)
    if column:
        if column not in df.columns:
            raise ValueError(
                f"Column '{column}' not found in {csv_path}. Available: {list(df.columns)}"
            )
        values = df[column]
    else:
        if df.shape[1] != 1:
            raise ValueError(
                f"CSV {csv_path} has {df.shape[1]} columns; set --labels-column/--pred-a-column/--pred-b-column"
            )
        values = df.iloc[:, 0]

    values = values.astype(str).str.strip()
    values = values[values != ""]
    if values.empty:
        raise ValueError(f"No usable labels found in {csv_path}")
    return values.to_numpy()


def encode_labels(y_true: np.ndarray, y_a: np.ndarray, y_b: np.ndarray) -> Tuple[np.ndarray, np.ndarray, np.ndarray, Dict[str, int]]:
    labels = sorted(set(y_true.tolist()) | set(y_a.tolist()) | set(y_b.tolist()))
    label_to_id = {label: idx for idx, label in enumerate(labels)}

    y_true_idx = np.array([label_to_id[x] for x in y_true], dtype=np.int64)
    y_a_idx = np.array([label_to_id[x] for x in y_a], dtype=np.int64)
    y_b_idx = np.array([label_to_id[x] for x in y_b], dtype=np.int64)
    return y_true_idx, y_a_idx, y_b_idx, label_to_id


def compute_metrics(y_true: np.ndarray, y_pred: np.ndarray) -> Dict[str, float]:
    return {
        "weighted_f1": float(f1_score(y_true, y_pred, average="weighted", zero_division=0)),
        "macro_f1": float(f1_score(y_true, y_pred, average="macro", zero_division=0)),
        "accuracy": float(accuracy_score(y_true, y_pred)),
    }


def percentile_ci(samples: np.ndarray, alpha: float = 0.05) -> Tuple[float, float]:
    lo = float(np.quantile(samples, alpha / 2.0))
    hi = float(np.quantile(samples, 1.0 - alpha / 2.0))
    return lo, hi


def paired_bootstrap(
    y_true: np.ndarray,
    y_a: np.ndarray,
    y_b: np.ndarray,
    n_boot: int,
    seed: int,
) -> Dict[str, Dict[str, float | Tuple[float, float]]]:
    rng = np.random.default_rng(seed)
    n = y_true.shape[0]

    delta_wf1 = np.empty(n_boot, dtype=np.float64)
    delta_mf1 = np.empty(n_boot, dtype=np.float64)
    delta_acc = np.empty(n_boot, dtype=np.float64)

    for i in range(n_boot):
        idx = rng.integers(0, n, size=n)
        yt = y_true[idx]
        ya = y_a[idx]
        yb = y_b[idx]

        ma = compute_metrics(yt, ya)
        mb = compute_metrics(yt, yb)
        delta_wf1[i] = mb["weighted_f1"] - ma["weighted_f1"]
        delta_mf1[i] = mb["macro_f1"] - ma["macro_f1"]
        delta_acc[i] = mb["accuracy"] - ma["accuracy"]

    p_wf1 = float((np.sum(delta_wf1 <= 0.0) + 1) / (n_boot + 1))
    p_mf1 = float((np.sum(delta_mf1 <= 0.0) + 1) / (n_boot + 1))
    p_acc = float((np.sum(delta_acc <= 0.0) + 1) / (n_boot + 1))

    return {
        "delta_weighted_f1": {
            "mean": float(np.mean(delta_wf1)),
            "std": float(np.std(delta_wf1, ddof=1)),
            "ci95": percentile_ci(delta_wf1, alpha=0.05),
            "p_one_sided_improvement": p_wf1,
        },
        "delta_macro_f1": {
            "mean": float(np.mean(delta_mf1)),
            "std": float(np.std(delta_mf1, ddof=1)),
            "ci95": percentile_ci(delta_mf1, alpha=0.05),
            "p_one_sided_improvement": p_mf1,
        },
        "delta_accuracy": {
            "mean": float(np.mean(delta_acc)),
            "std": float(np.std(delta_acc, ddof=1)),
            "ci95": percentile_ci(delta_acc, alpha=0.05),
            "p_one_sided_improvement": p_acc,
        },
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Generic paired-bootstrap significance")
    parser.add_argument("--labels", type=Path, required=True, help="CSV containing gold labels")
    parser.add_argument("--pred-a", type=Path, required=True, help="CSV containing baseline predictions")
    parser.add_argument("--pred-b", type=Path, required=True, help="CSV containing candidate predictions")

    parser.add_argument("--labels-column", type=str, default="")
    parser.add_argument("--pred-a-column", type=str, default="")
    parser.add_argument("--pred-b-column", type=str, default="")

    parser.add_argument("--n-boot", type=int, default=5000)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument(
        "--out-json",
        type=Path,
        default=Path("outputs/significance/paired_bootstrap_significance.json"),
    )
    parser.add_argument(
        "--out-tex",
        type=Path,
        default=Path("outputs/significance/paired_bootstrap_significance.tex"),
    )

    args = parser.parse_args()

    y_true = load_vector(args.labels, args.labels_column)
    y_a = load_vector(args.pred_a, args.pred_a_column)
    y_b = load_vector(args.pred_b, args.pred_b_column)

    if not (len(y_true) == len(y_a) == len(y_b)):
        raise ValueError(
            f"Input lengths differ: labels={len(y_true)}, pred_a={len(y_a)}, pred_b={len(y_b)}"
        )

    y_true_idx, y_a_idx, y_b_idx, label_to_id = encode_labels(y_true, y_a, y_b)

    m_a = compute_metrics(y_true_idx, y_a_idx)
    m_b = compute_metrics(y_true_idx, y_b_idx)
    boot = paired_bootstrap(
        y_true_idx,
        y_a_idx,
        y_b_idx,
        n_boot=int(args.n_boot),
        seed=int(args.seed),
    )

    out = {
        "n_samples": int(len(y_true_idx)),
        "n_boot": int(args.n_boot),
        "seed": int(args.seed),
        "label_to_id": label_to_id,
        "model_a": m_a,
        "model_b": m_b,
        "bootstrap": boot,
    }

    args.out_json.parent.mkdir(parents=True, exist_ok=True)
    args.out_json.write_text(json.dumps(out, indent=2), encoding="utf-8")

    wf = boot["delta_weighted_f1"]
    mf = boot["delta_macro_f1"]
    ac = boot["delta_accuracy"]
    tex = f"""
\\begin{{table}}[h]
\\centering
\\caption{{Paired bootstrap significance (N={len(y_true_idx)}, B={args.n_boot}) for model B minus model A.}}
\\begin{{tabular}}{{lccc}}
\\toprule
Metric & Mean Delta & 95\\% CI & One-sided p \\\\
\\midrule
Weighted F1 & {wf['mean']:+.4f} & [{wf['ci95'][0]:+.4f}, {wf['ci95'][1]:+.4f}] & {wf['p_one_sided_improvement']:.4f} \\\\
Macro F1 & {mf['mean']:+.4f} & [{mf['ci95'][0]:+.4f}, {mf['ci95'][1]:+.4f}] & {mf['p_one_sided_improvement']:.4f} \\\\
Accuracy & {ac['mean']:+.4f} & [{ac['ci95'][0]:+.4f}, {ac['ci95'][1]:+.4f}] & {ac['p_one_sided_improvement']:.4f} \\\\
\\bottomrule
\\end{{tabular}}
\\label{{tab:paired-bootstrap-significance}}
\\end{{table}}
""".strip() + "\n"
    args.out_tex.parent.mkdir(parents=True, exist_ok=True)
    args.out_tex.write_text(tex, encoding="utf-8")

    print("Paired bootstrap significance complete")
    print(args.out_json)
    print(args.out_tex)
    print(
        f"WF1 delta mean={wf['mean']:+.4f}, CI95=[{wf['ci95'][0]:+.4f}, {wf['ci95'][1]:+.4f}], "
        f"p={wf['p_one_sided_improvement']:.4f}"
    )


if __name__ == "__main__":
    main()
