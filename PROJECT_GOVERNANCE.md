# Project Governance (Canonical State)

Last updated: 2026-04-12

## Purpose
This file defines the canonical project entry points and status sources to prevent conflicting top-level summaries.

## Canonical Files
- Primary project entry point: `00_START_HERE.md`
- Primary execution/status snapshot: `STATUS_CHECKLIST.md`
- Primary manuscript source: `seif_paper_revised.tex`
- Primary architecture figure source: `figures/final_publishable_architecture_tikz.tex`
- Primary metric provenance ledger: `METRIC_PROVENANCE_LEDGER.md`
- Primary metric traceability map: `RESULTS_TRACEABILITY.md`
- Primary reproducibility bundle skeleton: `REPRODUCIBILITY_BUNDLE.md`
- Primary manuscript build runbook: `BUILD.md`
- Primary one-command verification script: `verify_submission_bundle.ps1`
- Primary CI trigger helper script: `trigger_manuscript_ci.ps1`
- Primary canonical staging helper script: `stage_submission_bundle.ps1`

## Governance Rules
1. Do not create new top-level `*_STATUS*.md`, `*_SUMMARY*.md`, or duplicate `START_HERE` files unless they replace a canonical file.
2. Historical reports must be moved under `archive/status_docs/`.
3. Any manuscript headline metric must be traceable in `METRIC_PROVENANCE_LEDGER.md` before being promoted to abstract/conclusion claims.
4. If multiple values exist for the same metric family (e.g., 71.50/71.53/71.56), the ledger must explicitly record provenance and the selected canonical reporting rule.

## Current Canonical Reporting Rule
- For MELD stacked peak weighted F1, use the strongest artifact-backed value from `outputs/exp13_temporal_ensemble_results.json`:
  - `overall_best_f1 = 0.7156010684240085` (reported as 71.56%).
- If historical sections remain inside canonical docs for audit context, top-of-file canonical headers must clearly separate active submission values from legacy snapshots.

## Change Control
When updating canonical files:
- Update this governance file date.
- Update `METRIC_PROVENANCE_LEDGER.md` if any metric claims change.
- Keep archived snapshots untouched for auditability.
