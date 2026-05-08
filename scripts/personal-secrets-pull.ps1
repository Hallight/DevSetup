#Requires -Version 5.1
<#
.SYNOPSIS
    Pull personal secrets from AWS Secrets Manager into local files per personal-secrets/manifest.json.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$ScriptDir    = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot     = (Resolve-Path (Join-Path $ScriptDir '..')).Path
$ManifestPath = Join-Path $RepoRoot 'personal-secrets\manifest.json'

if (-not (Test-Path $ManifestPath)) {
    Write-Error "Manifest not found at $ManifestPath"
    exit 1
}

$manifest    = Get-Content -Raw $ManifestPath | ConvertFrom-Json
$Region      = $manifest.region
$AwsProfile  = $manifest.profile

# Verify AWS CLI is on PATH
$awsVersion = & aws --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "AWS CLI not found on PATH. Install from https://aws.amazon.com/cli/"
    exit 1
}

# Verify profile auth
$identity = & aws sts get-caller-identity --profile $AwsProfile --output text 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Profile '$AwsProfile' not authenticated. Run: aws configure --profile $AwsProfile`n$identity"
    exit 1
}

function Resolve-HomePath {
    param([string]$Path)
    if ($Path.StartsWith('~/') -or $Path.StartsWith('~\')) {
        return Join-Path $env:USERPROFILE $Path.Substring(2).Replace('/', '\')
    }
    return $Path
}

$pulled = 0
$total  = $manifest.secrets.Count

foreach ($entry in $manifest.secrets) {
    $name        = $entry.name
    $destination = Resolve-HomePath $entry.destination
    $format      = $entry.format

    Write-Host "Pulling $name -> $destination"

    # Use --output json (not text) — text mode strips newlines from multi-line secrets.
    $jsonResponse = & aws secretsmanager get-secret-value `
        --secret-id $name `
        --profile $AwsProfile `
        --region $Region `
        --output json 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "  Failed to fetch ${name}: $jsonResponse"
        continue
    }
    $content = ($jsonResponse | Out-String | ConvertFrom-Json).SecretString

    $parent = Split-Path -Parent $destination
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    if ($format -eq 'raw') {
        [System.IO.File]::WriteAllText($destination, $content)
        Write-Host "  Wrote raw file"
    }
    elseif ($format -eq 'json-merge') {
        $mergePath = $entry.merge_path
        $existing = if (Test-Path $destination) {
            [System.IO.File]::ReadAllText($destination) | ConvertFrom-Json
        } else {
            New-Object PSObject
        }
        $newValue = $content | ConvertFrom-Json
        if ($existing.PSObject.Properties[$mergePath]) {
            $existing.PSObject.Properties.Remove($mergePath)
        }
        $existing | Add-Member -MemberType NoteProperty -Name $mergePath -Value $newValue
        $merged = $existing | ConvertTo-Json -Depth 100
        [System.IO.File]::WriteAllText($destination, $merged)
        Write-Host "  Merged '$mergePath' into $destination"
    }
    else {
        Write-Warning "  Unknown format '$format' for $name"
        continue
    }

    $pulled++
}

Write-Host ""
Write-Host "$pulled of $total secrets pulled."
