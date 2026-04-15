# Canonical Submission Snapshot (April 2026)

Last updated: 2026-04-15

This file is the canonical execution/status snapshot for submission.
Historical checklists and legacy phase reports are archived under `archive/status_docs/`.

## Canonical Anchors
- MELD stacked peak weighted F1: 71.56%
- Distilled single-model weighted F1: 68.29%
- MELD -> IEMOCAP zero-shot weighted F1: 49.04%
- Calibrated MELD -> IEMOCAP weighted F1: 49.91% (+0.87pp, one-sided p=0.0102)

Canonical source files:
- `PROJECT_GOVERNANCE.md`
- `METRIC_PROVENANCE_LEDGER.md`
- `RESULTS_TRACEABILITY.md`
- `MODEL_RISK_GATES.md`
- `seif_paper_revised.tex`

## Canonical Experiment Registry (Exp01-Exp53 Families)

Legend:
- `Status=Canonical`: submission-facing, artifact-backed claims and supporting evidence.
- `Status=Appendix`: exploratory or diagnostic evidence kept for narrative completeness.

| Family | Scope | Primary Metric Type | Best Value (Current) | Primary Artifact | Status | Manuscript Mapping |
|---|---|---|---|---|---|---|
| Exp01-04 | MELD core baselines and first LLM-RAG jump | Test weighted F1 | 68.42% | `experiments/INDEX.md` | Appendix | Intro/Method historical ladder |
| Exp05-18 | MELD multimodal RAG, transfer, stacking, calibration | Test weighted F1 | 71.56% | `outputs/exp13_temporal_ensemble_results.json` | Canonical | Results (text-transfer/cross-corpus) |
| Exp10 calibration | Cross-corpus prior-shift correction | Test weighted F1 delta | +0.87pp (49.04 -> 49.91) | `outputs/exp10_calibrated_best_v2/final_summary.json` | Canonical | Cross-corpus table and discussion |
| Exp19-20 | Text-bias mitigation and inference-time controls | Test and stress weighted F1 | 65.05% (Exp19d MELD) / no SOTA gain in Exp20 | `outputs/exp19d_test_results.json` | Appendix | Robustness failure analysis |
| Exp21-29 | TCAP/OGM warmup branch (direct acoustic integration) | Dev/Test weighted F1 | Dev 63.38%, Test 57.93% (IEMOCAP) | `outputs/exp28_warmup_ogm_ge/training_log.json` | Appendix | Direct acoustic integration section |
| Exp30-36 | KD/perceiver/gated recovery line | Test weighted F1 | 68.29% (distilled avg) | `outputs/exp32_v3_avg_results.log` | Canonical (M07) + Appendix | Direct acoustic + compression/ablation |
| Exp37-45 | Qwen2 native audio-LLM branch | Dev weighted F1 | 69.95% (best snapshot) | `outputs/exp37_qwen2_audio/best_per_class_f1.json` | Appendix | Architecture falsification appendix |
| Exp46-53 | Late fusion, instruction recovery, reasoning stack | Test weighted F1 | 71.35% recovered baseline stack | `outputs/exp53_reasoning_recovery/results_exp53.json` | Appendix | Recovery/diagnostic appendix |
| Recovery branch R9b | Risk-gate audit checkpoint | Dev weighted/macro/minority/neutral/tail | 57.87 / 38.73 / 11.74 / 61.1 | `outputs/recovery_R9b_kd_k4_fullDev/metrics_best.json` | Canonical (M09-M10) | Tail-risk audit table |
| Recovery branch R9c | Tail-risk corrective stress test | Dev weighted/macro/minority/neutral/tail | 8.93 / 10.01 / 7.57 / 0.27 | `outputs/recovery_R9c_kd_tailrisk_fix/metrics_best.json` | Appendix | Corrective diagnostic (non-promoted) |

## Open Items (Submission-Critical)
1. If time permits, run a milder R9d corrective variant (reduced minority forcing) as optional appendix evidence; keep R9b as canonical unless a candidate improves without broad regression.
2. Keep abstract and conclusion strictly within M01-M11 ledger claims.
3. Refresh build-readiness proof (local LaTeX tools or successful `Build Manuscript PDF` CI artifact).

## Freeze Decisions Applied
- Reverse-direction cross-corpus evidence (`IEMOCAP->MELD`) remains explicitly deferred in canonical reporting for this submission freeze.
- Calibration inferential support is retained and reproducible via `outputs/significance/exp10_calibration_paired_bootstrap.json`.
- R9c corrective run (`outputs/recovery_R9c_kd_tailrisk_fix/metrics_best.json`) remains appendix-only because it heavily regresses overall dev quality versus R9b despite passing minimal gate booleans.

## Validation Commands
```powershell
.\verify_submission_bundle.ps1
.\stage_submission_bundle.ps1 -DryRun
.\trigger_manuscript_ci.ps1
```
