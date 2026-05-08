#Requires -Version 5.1
<#
.SYNOPSIS
    Link the repo's .claude/skills/* into ~/.claude/skills/ as directory junctions.

.DESCRIPTION
    For each subdirectory under <repo>/.claude/skills/, creates a Windows directory
    junction at $env:USERPROFILE\.claude\skills\<name> pointing at the repo path.
    Skips entries that already exist (real dir, junction, or symlink) — never
    overwrites or deletes anything in the target.

    Junctions don't require admin/Developer Mode and work across local drives,
    which is why this uses junctions instead of symlinks.
#>

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoSkills  = Resolve-Path (Join-Path $ScriptDir '..\.claude\skills')
$TargetRoot  = Join-Path $env:USERPROFILE '.claude\skills'

if (-not (Test-Path $TargetRoot)) {
    New-Item -ItemType Directory -Path $TargetRoot -Force | Out-Null
}

$linked  = 0
$skipped = 0

Get-ChildItem -Path $RepoSkills -Directory | ForEach-Object {
    $name   = $_.Name
    $source = $_.FullName
    $target = Join-Path $TargetRoot $name

    if (Test-Path -LiteralPath $target) {
        Write-Host "SKIP: $name (already exists at $target — remove manually if you want it linked)"
        $skipped++
        return
    }

    New-Item -ItemType Junction -Path $target -Target $source | Out-Null
    Write-Host "LINK: $name -> $source"
    $linked++
}

Write-Host ""
Write-Host "$linked linked, $skipped skipped."
