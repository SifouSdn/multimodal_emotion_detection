[CmdletBinding()]
param(
    [string]$RemoteName = 'origin',
    [string]$Ref = '',
    [string]$RemoteUrl = ''
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

function Get-GitHubSlug {
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

Write-Output '=== Trigger Manuscript CI Build ==='

$inside = (& git rev-parse --is-inside-work-tree 2>$null)
if (($LASTEXITCODE -ne 0) -or ($inside.Trim() -ne 'true')) {
    Fail 'Current directory is not inside a git repository.'
}

if (-not (Test-Path '.github/workflows/build-manuscript.yml')) {
    Fail 'Workflow file missing: .github/workflows/build-manuscript.yml'
}

$remotes = (& git remote 2>$null)
if ($LASTEXITCODE -ne 0) {
    Fail 'Unable to read git remotes from current repository.'
}

if ($remotes -notcontains $RemoteName) {
    if ([string]::IsNullOrWhiteSpace($RemoteUrl)) {
        Fail ("Git remote '{0}' is not configured. Re-run with -RemoteUrl <https://github.com/owner/repo.git> or add the remote manually." -f $RemoteName)
    }

    & git remote add $RemoteName $RemoteUrl
    if ($LASTEXITCODE -ne 0) {
        Fail ("Failed to add git remote '{0}' with provided URL." -f $RemoteName)
    }

    Write-Info ("Added remote ({0}): {1}" -f $RemoteName, $RemoteUrl)
    $remotes = (& git remote 2>$null)
    if ($LASTEXITCODE -ne 0 -or $remotes -notcontains $RemoteName) {
        Fail ("Remote '{0}' still not visible after add operation." -f $RemoteName)
    }
}

$remoteUrl = (& git remote get-url $RemoteName 2>$null)
if (($LASTEXITCODE -ne 0) -or [string]::IsNullOrWhiteSpace($remoteUrl)) {
    Fail ("Failed to resolve URL for git remote '{0}'." -f $RemoteName)
}
$remoteUrl = $remoteUrl.Trim()

if (-not [string]::IsNullOrWhiteSpace($RemoteUrl) -and ($remoteUrl -ne $RemoteUrl)) {
    Write-WarnLine ("Configured remote differs from -RemoteUrl input. Using configured URL: {0}" -f $remoteUrl)
}

Write-Info ("Remote ({0}): {1}" -f $RemoteName, $remoteUrl)

$repoSlug = Get-GitHubSlug -RemoteUrl $remoteUrl
if ($null -eq $repoSlug) {
    Fail ("Remote '{0}' is not a GitHub URL. Expected github.com remote, got: {1}" -f $RemoteName, $remoteUrl)
}

$currentBranch = (& git branch --show-current 2>$null).Trim()
if ([string]::IsNullOrWhiteSpace($Ref)) {
    if (-not [string]::IsNullOrWhiteSpace($currentBranch)) {
        $Ref = $currentBranch
    } else {
        $Ref = 'main'
    }
}
Write-Info ("Workflow ref: {0}" -f $Ref)

$statusLines = (& git status --porcelain 2>$null)
if ($statusLines) {
    Write-WarnLine 'Working tree has local changes. Ensure intended commits are pushed before relying on CI output.'
}

$actionsUrl = "https://github.com/{0}/actions/workflows/build-manuscript.yml" -f $repoSlug

$gh = Get-Command gh -ErrorAction SilentlyContinue
if ($null -eq $gh) {
    Write-WarnLine 'GitHub CLI (gh) is not installed. Cannot dispatch workflow from terminal.'
    Write-Output ("Manual trigger URL: {0}" -f $actionsUrl)
    Write-Output ("Workflow name: Build Manuscript PDF; ref: {0}" -f $Ref)
    exit 1
}

& gh auth status 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-WarnLine 'GitHub CLI is installed but not authenticated.'
    Write-Output ("Manual trigger URL: {0}" -f $actionsUrl)
    Write-Output ("Run: gh auth login")
    exit 1
}

$dispatchOutput = (& gh workflow run build-manuscript.yml --repo $repoSlug --ref $Ref 2>&1)
if ($LASTEXITCODE -ne 0) {
    Write-WarnLine 'Workflow dispatch failed via gh.'
    Write-Output $dispatchOutput
    Write-Output ("Manual trigger URL: {0}" -f $actionsUrl)
    Write-Output ("Push branch first if needed: git push -u {0} {1}" -f $RemoteName, $Ref)
    exit 1
}

Write-Info 'Workflow dispatch requested successfully.'
Write-Output $dispatchOutput

$runList = (& gh run list --workflow build-manuscript.yml --repo $repoSlug --limit 1 2>&1)
if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($runList)) {
    Write-Output 'Latest workflow run:'
    Write-Output $runList
}

Write-Output ("Actions page: {0}" -f $actionsUrl)
exit 0
