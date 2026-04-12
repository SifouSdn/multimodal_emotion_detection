$ErrorActionPreference = 'Stop'

$results = @()
$failures = 0

function Add-CheckResult {
    param(
        [string]$Name,
        [bool]$Passed,
        [string]$Actual,
        [string]$Expected
    )

    if (-not $Passed) {
        $script:failures += 1
    }

    $status = if ($Passed) { 'PASS' } else { 'FAIL' }
    Write-Output ("[{0}] {1}" -f $status, $Name)
    if ($Expected) {
        Write-Output ("  expected: {0}" -f $Expected)
    }
    if ($Actual) {
        Write-Output ("  actual:   {0}" -f $Actual)
    }

    $script:results += [PSCustomObject]@{
        name = $Name
        passed = $Passed
        expected = $Expected
        actual = $Actual
    }
}

Write-Output '=== Submission Bundle Verification ==='

$requiredFiles = @(
    '00_START_HERE.md',
    'STATUS_CHECKLIST.md',
    'PROJECT_GOVERNANCE.md',
    'METRIC_PROVENANCE_LEDGER.md',
    'REPRODUCIBILITY_BUNDLE.md',
    'BUILD.md',
    'stage_submission_bundle.ps1',
    'trigger_manuscript_ci.ps1',
    'seif_paper_revised.tex',
    'figures/final_publishable_architecture_tikz.tex',
    '.github/workflows/build-manuscript.yml'
)

foreach ($f in $requiredFiles) {
    $exists = Test-Path $f
    Add-CheckResult -Name ("Required file exists: {0}" -f $f) -Passed $exists -Actual $exists -Expected 'True'
}

try {
    $exp13 = Get-Content .\outputs\exp13_temporal_ensemble_results.json | ConvertFrom-Json
    $val = [double]$exp13.overall_best_f1
    $pass = [math]::Abs($val - 0.7156010684240085) -lt 1e-12
    Add-CheckResult -Name 'MELD stacked peak overall_best_f1' -Passed $pass -Actual $val -Expected '0.7156010684240085'
} catch {
    Add-CheckResult -Name 'MELD stacked peak overall_best_f1' -Passed $false -Actual $_.Exception.Message -Expected 'Readable JSON with overall_best_f1'
}

try {
    $exp12 = Get-Content .\outputs\exp12_sota_final\final_results.json | ConvertFrom-Json
    $val = [double]$exp12.ablation[3].wf1
    $pass = [math]::Abs($val - 0.7153) -lt 1e-12
    Add-CheckResult -Name 'MELD 3-model stack ablation[3].wf1' -Passed $pass -Actual $val -Expected '0.7153'
} catch {
    Add-CheckResult -Name 'MELD 3-model stack ablation[3].wf1' -Passed $false -Actual $_.Exception.Message -Expected 'Readable JSON with ablation[3].wf1'
}

try {
    $exp10 = Get-Content .\outputs\exp10_cross_corpus\results.json | ConvertFrom-Json
    $val = [double]$exp10.option_a_cross_corpus.lr_stacking_C6.weighted_f1
    $pass = [math]::Abs($val - 49.04) -lt 1e-12
    Add-CheckResult -Name 'MELD->IEMOCAP zero_shot weighted_f1' -Passed $pass -Actual $val -Expected '49.04'
} catch {
    Add-CheckResult -Name 'MELD->IEMOCAP zero_shot weighted_f1' -Passed $false -Actual $_.Exception.Message -Expected 'Readable JSON with option_a_cross_corpus.lr_stacking_C6.weighted_f1'
}

try {
    $m = Select-String -Path .\outputs\exp32_v3_avg_results.log -Pattern 'Test WF1: 0.6829' -Encoding Unicode
    $pass = $m.Count -ge 1
    $actual = if ($pass) { "matches=" + $m.Count } else { 'matches=0' }
    Add-CheckResult -Name 'Distilled checkpoint-average evidence line present' -Passed $pass -Actual $actual -Expected '>=1 match for "Test WF1: 0.6829"'
} catch {
    Add-CheckResult -Name 'Distilled checkpoint-average evidence line present' -Passed $false -Actual $_.Exception.Message -Expected 'Readable log file'
}

try {
    $m = Select-String -Path .\outputs\exp31_deep_v11\train_log.txt -Pattern 'Best dev WF1: 0.4955'
    $pass = $m.Count -ge 1
    $actual = if ($pass) { "matches=" + $m.Count } else { 'matches=0' }
    Add-CheckResult -Name 'Additive fusion stress evidence line present' -Passed $pass -Actual $actual -Expected '>=1 match for "Best dev WF1: 0.4955"'
} catch {
    Add-CheckResult -Name 'Additive fusion stress evidence line present' -Passed $false -Actual $_.Exception.Message -Expected 'Readable log file'
}

$latexmk = Get-Command latexmk -ErrorAction SilentlyContinue
$pdflatex = Get-Command pdflatex -ErrorAction SilentlyContinue
$bibtex = Get-Command bibtex -ErrorAction SilentlyContinue

$localToolsReady = ($null -ne $latexmk) -or (($null -ne $pdflatex) -and ($null -ne $bibtex))
$ciWorkflowReady = Test-Path '.github/workflows/build-manuscript.yml'

$actualTools = @()
if ($null -ne $latexmk) { $actualTools += 'latexmk' }
if ($null -ne $pdflatex) { $actualTools += 'pdflatex' }
if ($null -ne $bibtex) { $actualTools += 'bibtex' }
if ($actualTools.Count -eq 0) { $actualTools = @('none') }

$buildPathReady = $localToolsReady -or $ciWorkflowReady
$actualBuildPath = "local_tools={0}; ci_workflow={1}; tools={2}" -f $localToolsReady, $ciWorkflowReady, ($actualTools -join ', ')
Add-CheckResult -Name 'Build path available (local or CI)' -Passed $buildPathReady -Actual $actualBuildPath -Expected 'local LaTeX tools OR .github/workflows/build-manuscript.yml present'

$reportDir = '.\artifacts'
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir | Out-Null
}

$report = [PSCustomObject]@{
    timestamp_utc = (Get-Date).ToUniversalTime().ToString('o')
    failure_count = $failures
    checks = $results
}

$reportPath = Join-Path $reportDir 'submission_bundle_check.json'
$report | ConvertTo-Json -Depth 8 | Set-Content -Path $reportPath -Encoding UTF8
Write-Output ("Report written: {0}" -f $reportPath)

if ($failures -gt 0) {
    Write-Output ("Verification finished with {0} failure(s)." -f $failures)
    exit 1
}

Write-Output 'Verification finished with 0 failures.'
exit 0
