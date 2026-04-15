# START HERE: Canonical Submission Entry (April 2026)

Last updated: 2026-04-14

Use this file as the canonical top-level entrypoint for submission-facing status and reproducibility.

## Canonical Baseline (Current)
- MELD stacked peak weighted F1: 71.56% (artifact-backed)
- MELD 3-model stack weighted F1: 71.53% (artifact-backed)
- Distilled single-model weighted F1: 68.29% (artifact-backed log)
- MELD to IEMOCAP zero-shot weighted F1: 49.04% (artifact-backed)
- Calibrated MELD to IEMOCAP weighted F1: 49.91% (+0.87pp, one-sided p=0.0102)
- Additive fusion stress run (dev): 49.55% (artifact-backed log)

## Single-Source Navigation
- Canonical experiment storyline registry: `STATUS_CHECKLIST.md`
- Canonical metric claim ledger (M01-M11): `METRIC_PROVENANCE_LEDGER.md`
- Canonical traceability map: `RESULTS_TRACEABILITY.md`
- Canonical risk-gate policy: `MODEL_RISK_GATES.md`
- Canonical manuscript source: `seif_paper_revised.tex`
- Canonical governance policy: `PROJECT_GOVERNANCE.md`

## Recommended Command Flow
```powershell
.\verify_submission_bundle.ps1
.\stage_submission_bundle.ps1 -DryRun
.\trigger_manuscript_ci.ps1
```

## Historical Content Policy
- Legacy status snapshots and phase-specific historical summaries are archived under `archive/status_docs/`.
- Do not use archived legacy values for abstract/conclusion headline claims.
- Promote new headline metrics only after they are added to `METRIC_PROVENANCE_LEDGER.md` and `RESULTS_TRACEABILITY.md`.
