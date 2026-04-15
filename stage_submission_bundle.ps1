[CmdletBinding()]
param(
    [switch]$IncludeVerificationReport,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}

function Write-Info {
    param([string]$Message)
    Write-Output ("[INFO] {0}" -f $Message)
}

function Write-WarnLine {
    param([string]$Message)
    Write-Output ("[WARN] {0}" -f $Message)
}

function Fail {
    param([string]$Message)
    Write-Output ("[ERROR] {0}" -f $Message)
    exit 1
}

$canonicalPaths = @(
    '00_START_HERE.md',
    'STATUS_CHECKLIST.md',
    'PROJECT_GOVERNANCE.md',
    'METRIC_PROVENANCE_LEDGER.md',
    'RESULTS_TRACEABILITY.md',
    'MODEL_RISK_GATES.md',
    'REPRODUCIBILITY_BUNDLE.md',
    'BUILD.md',
    'stage_submission_bundle.ps1',
    'verify_submission_bundle.ps1',
    'paired_bootstrap_significance.py',
    'trigger_manuscript_ci.ps1',
    '.github/workflows/build-manuscript.yml',
    'seif_paper_revised.tex',
    'figures/final_publishable_architecture_tikz.tex'
)

if ($IncludeVerificationReport) {
    $canonicalPaths += 'artifacts/submission_bundle_check.json'
}

Write-Output '=== Stage Submission Bundle Files ==='

$inside = (& git rev-parse --is-inside-work-tree 2>$null)
if (($LASTEXITCODE -ne 0) -or ($inside.Trim() -ne 'true')) {
    Fail 'Current directory is not inside a git repository.'
}

$staged = @()
$missing = @()
foreach ($path in $canonicalPaths) {
    if (-not (Test-Path $path)) {
        $missing += $path
        continue
    }

    if ($DryRun) {
        Write-Output ("[DRYRUN] would stage: {0}" -f $path)
        $staged += $path
        continue
    }

    & git add -- $path
    if ($LASTEXITCODE -ne 0) {
        Fail ("Failed to stage: {0}" -f $path)
    }
    $staged += $path
}

if ($missing.Count -gt 0) {
    Write-WarnLine ("Skipped missing paths: {0}" -f ($missing -join ', '))
}

if ($staged.Count -eq 0) {
    Write-WarnLine 'No files were staged.'
    exit 1
}

Write-Info ("Staged {0} file(s)." -f $staged.Count)
Write-Output 'Staged paths:'
$staged | ForEach-Object { Write-Output (" - {0}" -f $_) }

Write-Output ''
if ($DryRun) {
    Write-Output 'Dry run mode: no files were added to the git index.'
} else {
    Write-Output 'Staged diff summary:'
    & git diff --cached --name-status -- $staged
}

$currentBranch = (& git branch --show-current 2>$null).Trim()
if ([string]::IsNullOrWhiteSpace($currentBranch)) {
    $currentBranch = 'main'
}

Write-Output ''
Write-Output 'Next commands:'
if ($DryRun) {
    Write-Output '  .\stage_submission_bundle.ps1'
}
Write-Output '  git commit -m "submission bundle: canonical docs + CI helpers"'
Write-Output ("  git push -u origin {0}" -f $currentBranch)

exit 0
