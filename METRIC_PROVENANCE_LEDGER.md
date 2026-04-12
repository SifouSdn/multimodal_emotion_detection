# Metric Provenance Ledger

Last updated: 2026-04-12

## Policy
- Only artifact-backed values should be used for manuscript headline claims.
- If a value is currently doc-backed only, keep it as provisional until a machine-readable artifact path is located.
- For script-level reproduction entry points and commands, use `RESULTS_TRACEABILITY.md`.

## Canonical Headline Selection
- Selected MELD stacked peak weighted F1: **71.56%**
- Canonical source: `outputs/exp13_temporal_ensemble_results.json` -> `overall_best_f1`
- Raw value: `0.7156010684240085`

## Ledger

| Claim ID | Metric | Value | Source File | Source Field | Status | Notes |
|---|---|---:|---|---|---|---|
| M01 | MELD stacked peak weighted F1 | 71.56% | `outputs/exp13_temporal_ensemble_results.json` | `overall_best_f1` | artifact-backed | Raw value `0.7156010684240085` |
| M02 | MELD 3-model stack weighted F1 | 71.53% | `outputs/exp12_sota_final/final_results.json` | `ablation[3].wf1` | artifact-backed | Combo `exp05+exp07v1+exp12_ep1`; raw value `0.7153` |
| M03 | MELD LR stack weighted F1 | 70.86% | `outputs/exp12_sota_final/final_results.json` | `lr.weighted_f1` | artifact-backed | Raw value `0.7086005662053201` |
| M04 | MELD->IEMOCAP zero-shot weighted F1 | 49.04% | `outputs/exp10_cross_corpus/results.json` | `option_a_cross_corpus.lr_stacking_C6.weighted_f1` | artifact-backed | Domain shift result; raw value `49.04`; reverse direction (IEMOCAP->MELD) not in current canonical artifact set |
| M05 | Parser fallback ratio before parser fix (MELD 10% eval) | 79.28% | `outputs/recovery_fast_val/eval_metrics_10pct.json` | `meld_metrics.parser_fallback_ratio` | artifact-backed | Raw value `0.7927927927927928` |
| M06 | Parser fallback ratio after parser fix (MELD 10% eval) | 0.00% | `outputs/recovery_fast_val/eval_metrics_10pct_after_parser_fix.json` | `meld_metrics.parser_fallback_ratio` | artifact-backed | Raw value `0.0` |
| M07 | Distilled single-model weighted F1 (checkpoint average) | 68.29% | `outputs/exp32_v3_avg_results.log` | `Test WF1: 0.6829` and weighted-average report line | artifact-backed (log) | Averaged checkpoints [800, 1100], aligned with Exp 32 v3 averaging note |
| M08 | Naive additive fusion weighted F1 (fixed alpha=0.1, dev stress test) | 49.55% | `outputs/exp31_deep_v11/train_log.txt` | `Eval @ step 1700: WF1=0.4955` and `Best dev WF1: 0.4955` | artifact-backed (log) | Additive fusion degradation in fixed-alpha stress run |
| M09 | Recovery branch dev weighted F1 | 57.87% | `outputs/recovery_R9b_kd_k4_fullDev/metrics_best.json` | `dev_weighted_f1` | artifact-backed | Raw value `0.5787149114846841` |

## Open Provenance Tasks
1. Confirm manuscript wording keeps split context explicit where needed (for example, mark additive stress metric as dev-derived).
2. Verify no manuscript/table metric remains outside this ledger before final submission freeze.
