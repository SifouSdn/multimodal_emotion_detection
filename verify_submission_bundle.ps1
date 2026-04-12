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

function Get-GitHubRepoSlug {
    param([string]$RemoteUrl)

    $pattern = 'github\.com[:/](?<owner>[^/]+)/(?<repo>[^/]+?)(?:\.git)?$'
    $match = [System.Text.RegularExpressions.Regex]::Match($RemoteUrl, $pattern)
    if (-not $match.Success) {
        return $null
    }

    $owner = $match.Groups['owner'].Value
    $repo = $match.Groups['repo'].Value
    if ([string]::IsNullOrWhiteSpace($owner) -or [string]::IsNullOrWhiteSpace($repo)) {
        return $null
    }

    return ("{0}/{1}" -f $owner, $repo)
}

Write-Output '=== Submission Bundle Verification ==='

$requiredFiles = @(
    '00_START_HERE.md',
    'STATUS_CHECKLIST.md',
    'PROJECT_GOVERNANCE.md',
    'METRIC_PROVENANCE_LEDGER.md',
    'RESULTS_TRACEABILITY.md',
    'MODEL_RISK_GATES.md',
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
    $paperText = Get-Content .\seif_paper_revised.tex -Raw

    $reverseCoverageRow = 'Zero-shot IEMOCAP\,$\rightarrow$\,MELD (current freeze) & -- & --'
    $reverseCoveragePass = $paperText.Contains($reverseCoverageRow)
    $reverseCoverageActual = if ($reverseCoveragePass) { 'present' } else { 'missing explicit reverse-direction freeze row' }
    Add-CheckResult -Name 'Cross-corpus reverse-direction scope row present in manuscript' -Passed $reverseCoveragePass -Actual $reverseCoverageActual -Expected $reverseCoverageRow

    $tailRiskTokens = @(
        '\label{tab:tail_risk_audit}',
        '57.87\%',
        '38.73\%',
        '11.74\%',
        '61.1\%',
        '0.00 / 0.00'
    )

    $missingTailTokens = @()
    foreach ($token in $tailRiskTokens) {
        if (-not $paperText.Contains($token)) {
            $missingTailTokens += $token
        }
    }

    $tailRiskPass = $missingTailTokens.Count -eq 0
    $tailRiskActual = if ($tailRiskPass) { 'all expected tokens present' } else { 'missing: ' + ($missingTailTokens -join '; ') }
    Add-CheckResult -Name 'Tail-risk audit table tokens present in manuscript' -Passed $tailRiskPass -Actual $tailRiskActual -Expected 'label + 57.87%, 38.73%, 11.74%, 61.1%, 0.00 / 0.00'
} catch {
    Add-CheckResult -Name 'Cross-corpus reverse-direction scope row present in manuscript' -Passed $false -Actual $_.Exception.Message -Expected 'Readable manuscript tex file'
    Add-CheckResult -Name 'Tail-risk audit table tokens present in manuscript' -Passed $false -Actual $_.Exception.Message -Expected 'Readable manuscript tex file'
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

try {
    $risk = Get-Content .\outputs\recovery_R9b_kd_k4_fullDev\metrics_best.json | ConvertFrom-Json

    $hasCore = ($null -ne $risk.dev_weighted_f1) -and ($null -ne $risk.dev_macro_f1) -and ($null -ne $risk.minority_mean_f1) -and ($null -ne $risk.neutral_prediction_ratio)
    $hasTail = ($null -ne $risk.per_class_f1) -and ($null -ne $risk.per_class_f1.fear) -and ($null -ne $risk.per_class_f1.disgust)
    $riskFieldsPass = $hasCore -and $hasTail

    $riskActual = "dev_wf1={0}; dev_macro_f1={1}; minority_f1={2}; neutral_ratio={3}; fear_f1={4}; disgust_f1={5}" -f $risk.dev_weighted_f1, $risk.dev_macro_f1, $risk.minority_mean_f1, $risk.neutral_prediction_ratio, $risk.per_class_f1.fear, $risk.per_class_f1.disgust
    Add-CheckResult -Name 'Risk gate metrics present (weighted/macro/minority/neutral/tail)' -Passed $riskFieldsPass -Actual $riskActual -Expected 'metrics_best.json includes dev_weighted_f1, dev_macro_f1, minority_mean_f1, neutral_prediction_ratio, per_class_f1.fear, per_class_f1.disgust'

    $gateMacro = [bool]$risk.checkpoint_promotion_gates.macro_pass
    $gateMinority = [bool]$risk.checkpoint_promotion_gates.minority_pass
    $gateNeutral = [bool]$risk.checkpoint_promotion_gates.neutral_pass
    $promotionPass = $gateMacro -and $gateMinority -and $gateNeutral

    $gateActual = "macro_pass={0}; minority_pass={1}; neutral_pass={2}" -f $gateMacro, $gateMinority, $gateNeutral
    Add-CheckResult -Name 'Recovery checkpoint promotion gates passed' -Passed $promotionPass -Actual $gateActual -Expected 'macro_pass=true, minority_pass=true, neutral_pass=true'
} catch {
    Add-CheckResult -Name 'Risk gate metrics present (weighted/macro/minority/neutral/tail)' -Passed $false -Actual $_.Exception.Message -Expected 'Readable outputs/recovery_R9b_kd_k4_fullDev/metrics_best.json'
    Add-CheckResult -Name 'Recovery checkpoint promotion gates passed' -Passed $false -Actual $_.Exception.Message -Expected 'macro_pass=true, minority_pass=true, neutral_pass=true'
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

$ciBuildProven = $false
$ciBuildActual = 'not-checked'

if ($ciWorkflowReady) {
    try {
        $originUrl = (& git remote get-url origin 2>$null)
        if (($LASTEXITCODE -ne 0) -or [string]::IsNullOrWhiteSpace($originUrl)) {
            throw [System.Exception]::new('git remote origin is missing')
        }

        $originUrl = $originUrl.Trim()
        $repoSlug = Get-GitHubRepoSlug -RemoteUrl $originUrl
        if ([string]::IsNullOrWhiteSpace($repoSlug)) {
            throw [System.Exception]::new(("origin is not a GitHub remote: {0}" -f $originUrl))
        }

        $headers = @{
            Accept = 'application/vnd.github+json'
            'User-Agent' = 'submission-bundle-verifier'
        }

        $runsUri = "https://api.github.com/repos/{0}/actions/workflows/build-manuscript.yml/runs?per_page=1" -f $repoSlug
        $runsResponse = Invoke-RestMethod -Headers $headers -Uri $runsUri -Method Get
        $latestRun = @($runsResponse.workflow_runs) | Select-Object -First 1
        if ($null -eq $latestRun) {
            throw [System.Exception]::new('no workflow runs found for build-manuscript.yml')
        }

        $runId = [string]$latestRun.id
        $runStatus = [string]$latestRun.status
        $runConclusion = [string]$latestRun.conclusion

        $artifactUri = "https://api.github.com/repos/{0}/actions/runs/{1}/artifacts" -f $repoSlug, $runId
        $artifactResponse = Invoke-RestMethod -Headers $headers -Uri $artifactUri -Method Get
        $artifact = @($artifactResponse.artifacts) | Where-Object { $_.name -eq 'seif_paper_revised-pdf' } | Select-Object -First 1

        $artifactPresent = $null -ne $artifact
        $artifactExpired = if ($artifactPresent) { [bool]$artifact.expired } else { $true }

        $ciBuildProven = ($runStatus -eq 'completed') -and ($runConclusion -eq 'success') -and $artifactPresent -and (-not $artifactExpired)
        $ciBuildActual = "repo={0}; run_id={1}; status={2}; conclusion={3}; artifact_present={4}; artifact_expired={5}" -f $repoSlug, $runId, $runStatus, $runConclusion, $artifactPresent, $artifactExpired
    } catch {
        $ciBuildActual = "unverified: {0}" -f $_.Exception.Message
    }
} else {
    $ciBuildActual = 'unverified: .github/workflows/build-manuscript.yml missing'
}

$buildReadinessProven = $localToolsReady -or $ciBuildProven
$actualBuildReadiness = "local_tools={0}; ci_build_proof={1}; ci_details={2}; tools={3}" -f $localToolsReady, $ciBuildProven, $ciBuildActual, ($actualTools -join ', ')
Add-CheckResult -Name 'Build readiness proven (local tools or successful CI artifact)' -Passed $buildReadinessProven -Actual $actualBuildReadiness -Expected 'local LaTeX tools OR latest Build Manuscript PDF run succeeded with seif_paper_revised-pdf artifact'

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
