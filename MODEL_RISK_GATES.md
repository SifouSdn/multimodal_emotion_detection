# Model Risk Gates (Canonical)

Last updated: 2026-04-12

## Purpose
Define minimum release-screening gates so weighted F1 is not used alone for promotion.

## Required Metrics
For a candidate checkpoint, report at minimum:
- `dev_weighted_f1`
- `dev_macro_f1`
- `neutral_prediction_ratio`
- `per_class_f1.fear`
- `per_class_f1.disgust`

## Promotion Gates
Canonical thresholds (from `outputs/recovery_R9b_kd_k4_fullDev/config.json`):
- Macro gate: `dev_macro_f1 >= 0.10`
- Minority gate: `minority_mean_f1 >= 0.02`
- Neutral-collapse gate: `neutral_prediction_ratio <= 0.85`

A checkpoint should only be considered promotion-eligible when all three pass.

## Current Reference Checkpoint (Audit)
Source: `outputs/recovery_R9b_kd_k4_fullDev/metrics_best.json`
- `dev_weighted_f1 = 0.5787149114846841`
- `dev_macro_f1 = 0.3873003261198753`
- `minority_mean_f1 = 0.11737089201877933`
- `neutral_prediction_ratio = 0.6113615870153292`
- `per_class_f1.fear = 0.0`
- `per_class_f1.disgust = 0.0`
- `checkpoint_promotion_gates = {macro_pass=true, minority_pass=true, neutral_pass=true}`

Interpretation:
- Promotion gates pass.
- Tail-class brittleness remains and must be reported explicitly in manuscript conclusions.

## Verification Commands
```powershell
$metrics = Get-Content .\outputs\recovery_R9b_kd_k4_fullDev\metrics_best.json | ConvertFrom-Json
$metrics.dev_macro_f1
$metrics.minority_mean_f1
$metrics.neutral_prediction_ratio
$metrics.per_class_f1.fear
$metrics.per_class_f1.disgust
$metrics.checkpoint_promotion_gates
```

## Policy Note
Passing promotion gates does not imply tail-class parity; it is a minimum screening layer.
