# Reproducibility Bundle Skeleton

Last updated: 2026-04-12

## Scope
This file defines a minimal, submission-oriented reproducibility bundle for this repository.

## One-Command Verification
```powershell
.\verify_submission_bundle.ps1
```

Expected behavior:
- Writes `artifacts/submission_bundle_check.json`
- Returns exit code `0` when all checks pass
- Returns exit code `1` when one or more checks fail
- If local LaTeX tools are unavailable, requires proof that the latest `Build Manuscript PDF` CI run completed successfully and published `seif_paper_revised-pdf`.

## CI Compile Trigger (No Local LaTeX)
```powershell
.\trigger_manuscript_ci.ps1
```

If remote is not configured yet:
```powershell
.\trigger_manuscript_ci.ps1 -RemoteUrl https://github.com/<owner>/<repo>.git
```

Expected behavior:
- If GitHub CLI is available and authenticated, dispatches `Build Manuscript PDF` workflow.
- Can auto-add missing remote when `-RemoteUrl` is supplied.
- If CLI auth/tooling is missing, prints exact manual Actions URL for the workflow.

## Canonical Staging Helper
```powershell
.\stage_submission_bundle.ps1
```

Preview only:
```powershell
.\stage_submission_bundle.ps1 -DryRun
```

Expected behavior:
- Stages only canonical submission files (not the full untracked workspace).
- Prints staged diff summary and next commit/push commands.

## Canonical Inputs
- Manuscript source: `seif_paper_revised.tex`
- Architecture figure source: `figures/final_publishable_architecture_tikz.tex`
- Governance policy: `PROJECT_GOVERNANCE.md`
- Metric provenance ledger: `METRIC_PROVENANCE_LEDGER.md`
- Active status snapshot: `STATUS_CHECKLIST.md`

## Headline Metric Verification (PowerShell)
Run from repository root.

1) MELD stacked peak weighted F1 (71.56%)
```powershell
$exp13 = Get-Content .\outputs\exp13_temporal_ensemble_results.json | ConvertFrom-Json
"overall_best_f1={0}" -f $exp13.overall_best_f1
```
Expected: `overall_best_f1=0.7156010684240085`

2) MELD 3-model stack weighted F1 (71.53%)
```powershell
$exp12 = Get-Content .\outputs\exp12_sota_final\final_results.json | ConvertFrom-Json
"ablation[3].wf1={0}" -f $exp12.ablation[3].wf1
```
Expected: `ablation[3].wf1=0.7153`

3) MELD -> IEMOCAP zero-shot weighted F1 (49.04%)
```powershell
$exp10 = Get-Content .\outputs\exp10_cross_corpus\results.json | ConvertFrom-Json
"zero_shot_wf1={0}" -f $exp10.option_a_cross_corpus.lr_stacking_C6.weighted_f1
```
Expected: `zero_shot_wf1=49.04`

4) Distilled checkpoint-average weighted F1 (68.29%)
```powershell
Select-String -Path .\outputs\exp32_v3_avg_results.log -Pattern "Test WF1: 0.6829" -Encoding Unicode
```
Expected: one matching line

5) Naive additive fusion stress metric (49.55%, dev)
```powershell
Select-String -Path .\outputs\exp31_deep_v11\train_log.txt -Pattern "Best dev WF1: 0.4955"
```
Expected: one matching line

## Manuscript Build Skeleton
Reference runbook: `BUILD.md`

0) If local LaTeX tools are unavailable, use CI workflow:
	- `.github/workflows/build-manuscript.yml` (workflow name: `Build Manuscript PDF`)

1) Preferred (if `latexmk` is available):
```powershell
latexmk -pdf -interaction=nonstopmode -halt-on-error .\seif_paper_revised.tex
```

2) Fallback (`pdflatex` + `bibtex` pipeline):
```powershell
pdflatex -interaction=nonstopmode -halt-on-error .\seif_paper_revised.tex
bibtex seif_paper_revised
pdflatex -interaction=nonstopmode -halt-on-error .\seif_paper_revised.tex
pdflatex -interaction=nonstopmode -halt-on-error .\seif_paper_revised.tex
```

Expected output: `seif_paper_revised.pdf`

## Bundle Checklist
- [ ] `PROJECT_GOVERNANCE.md` reflects current canonical files.
- [ ] `METRIC_PROVENANCE_LEDGER.md` has no doc-backed headline metrics.
- [ ] Headline metric checks above match expected values.
- [ ] Manuscript compiles with no unresolved references.
- [ ] Archived snapshots remain under `archive/status_docs/` only.
