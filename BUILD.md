# Manuscript Build Guide

Last updated: 2026-04-12

## Scope
This guide defines deterministic build paths for `seif_paper_revised.tex`.

## Local Build (if LaTeX tools are installed)
From repository root:

```powershell
latexmk -pdf -interaction=nonstopmode -halt-on-error .\seif_paper_revised.tex
```

Fallback pipeline:

```powershell
pdflatex -interaction=nonstopmode -halt-on-error .\seif_paper_revised.tex
bibtex seif_paper_revised
pdflatex -interaction=nonstopmode -halt-on-error .\seif_paper_revised.tex
pdflatex -interaction=nonstopmode -halt-on-error .\seif_paper_revised.tex
```

Expected output: `seif_paper_revised.pdf`

## CI Build (no local LaTeX required)
A GitHub Actions workflow is provided at `.github/workflows/build-manuscript.yml`.

### Stage canonical files only
```powershell
.\stage_submission_bundle.ps1
```

Preview only (no index changes):
```powershell
.\stage_submission_bundle.ps1 -DryRun
```

Optional (include latest verification JSON in staging set):
```powershell
.\stage_submission_bundle.ps1 -IncludeVerificationReport
```

### Preferred terminal trigger
```powershell
.\trigger_manuscript_ci.ps1
```

If `origin` is missing, bootstrap it in one call:
```powershell
.\trigger_manuscript_ci.ps1 -RemoteUrl https://github.com/<owner>/<repo>.git
```

Behavior:
- Dispatches workflow `Build Manuscript PDF` on the current branch (or `-Ref` override).
- Can auto-add missing remote when `-RemoteUrl` is provided.
- Falls back with exact manual Actions URL when `gh` is unavailable or unauthenticated.

### Trigger manually
1. Open repository on GitHub.
2. Go to Actions.
3. Select workflow `Build Manuscript PDF`.
4. Click `Run workflow` on the default branch.

### Trigger automatically
The workflow also runs on pushes that touch:
- `seif_paper_revised.tex`
- `*.bib`
- `figures/**`
- `.github/workflows/build-manuscript.yml`

### Retrieve output
Download artifact `seif_paper_revised-pdf` from the workflow run.

## Build Validation
A build is considered valid when:
- job exits successfully,
- artifact contains `seif_paper_revised.pdf`,
- no unresolved-reference warnings remain in logs after final pass.

## Notes
- If local build tools are absent, use the CI path above.
- Keep all manuscript edits in canonical sources only (`seif_paper_revised.tex`, `figures/final_publishable_architecture_tikz.tex`).
