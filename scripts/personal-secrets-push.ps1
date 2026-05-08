#Requires -Version 5.1
<#
.SYNOPSIS
    Push personal secrets from local files into AWS Secrets Manager per personal-secrets/manifest.json.
.DESCRIPTION
    For each manifest entry, reads the local source (raw file body, or json-merge subtree),
    then either creates the secret if it doesn't yet exist or updates it via put-secret-value.
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

$manifest   = Get-Content -Raw $ManifestPath | ConvertFrom-Json
$Region     = $manifest.region
$AwsProfile = $manifest.profile

$null = & aws --version 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "AWS CLI not found on PATH. Install from https://aws.amazon.com/cli/"
    exit 1
}

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

$created = 0
$updated = 0
$skipped = 0

foreach ($entry in $manifest.secrets) {
    $name   = $entry.name
    $source = Resolve-HomePath $entry.destination
    $format = $entry.format

    if (-not (Test-Path $source)) {
        Write-Warning "Source missing for ${name}: $source"
        $skipped++
        continue
    }

    if ($format -eq 'raw') {
        $content = [System.IO.File]::ReadAllText($source)
    }
    elseif ($format -eq 'json-merge') {
        $mergePath = $entry.merge_path
        $existing = [System.IO.File]::ReadAllText($source) | ConvertFrom-Json
        $subtree  = $existing.$mergePath
        if ($null -eq $subtree) {
            Write-Warning "Source $source has no '$mergePath' key, skipping"
            $skipped++
            continue
        }
        $content = $subtree | ConvertTo-Json -Depth 100
    }
    else {
        Write-Warning "Unknown format '$format' for $name"
        $skipped++
        continue
    }

    # Pass content via temp file using file:// to dodge command-line escaping for newlines/quotes.
    $tempFile = [System.IO.Path]::Combine($env:TEMP, "secret-$([guid]::NewGuid()).tmp")
    try {
        [System.IO.File]::WriteAllText($tempFile, $content)
        $secretArg = "file://" + ($tempFile -replace '\\', '/')

        $null = & aws secretsmanager describe-secret `
            --secret-id $name --profile $AwsProfile --region $Region 2>&1
        $exists = ($LASTEXITCODE -eq 0)

        if ($exists) {
            $out = & aws secretsmanager put-secret-value `
                --secret-id $name `
                --profile $AwsProfile `
                --region $Region `
                --secret-string $secretArg 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Failed to update ${name}: $out"
                $skipped++
            } else {
                Write-Host "Updated $name"
                $updated++
            }
        }
        else {
            $out = & aws secretsmanager create-secret `
                --name $name `
                --profile $AwsProfile `
                --region $Region `
                --secret-string $secretArg 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Warning "Failed to create ${name}: $out"
                $skipped++
            } else {
                Write-Host "Created $name"
                $created++
            }
        }
    }
    finally {
        if (Test-Path $tempFile) { Remove-Item -LiteralPath $tempFile -Force }
    }
}

Write-Host ""
Write-Host "$created created, $updated updated, $skipped skipped."
