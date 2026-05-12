#Requires -Version 5.0

<#
.SYNOPSIS
Install the windows-tools-install-manager skill for Claude Code and/or Codex.

.DESCRIPTION
Reads SKILL.md.template, substitutes the install-root placeholder with your
preferred path, and writes the final SKILL.md into your agent's skills folder.

.PARAMETER InstallRoot
Where the skill should install system-level tools (e.g., ffmpeg, 7zip).
Default: D:\Tools. Examples: C:\MyTools, D:\Apps, E:\Software.

.PARAMETER Agent
Which agent to install the skill for: 'claude', 'codex', or 'both'.
Default: both.

.PARAMETER Force
Overwrite existing SKILL.md without prompting.

.EXAMPLE
.\setup.ps1
Interactive setup using defaults.

.EXAMPLE
.\setup.ps1 -InstallRoot "C:\MyTools" -Agent claude
Non-interactive setup for Claude Code only.
#>

[CmdletBinding()]
param(
    [string]$InstallRoot,
    [ValidateSet('claude', 'codex', 'both')]
    [string]$Agent = 'both',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# Locate the template (relative to this script)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$templatePath = Join-Path $scriptDir 'skills\windows-tools-install-manager\SKILL.md.template'

if (-not (Test-Path $templatePath)) {
    Write-Error "Template not found at: $templatePath`nAre you running setup.ps1 from the plugin repo root?"
    exit 1
}

# Prompt for InstallRoot if not provided
if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
    $default = 'D:\Tools'
    Write-Host ""
    Write-Host "Where should installed tools go (the skill's default install root)?" -ForegroundColor Cyan
    Write-Host "  Examples: D:\Tools, C:\MyTools, D:\Apps"
    $userInput = Read-Host "Path [default: $default]"
    $InstallRoot = if ([string]::IsNullOrWhiteSpace($userInput)) { $default } else { $userInput.Trim() }
}

# Normalize: strip trailing slashes
$InstallRoot = $InstallRoot.TrimEnd('\', '/')

# Validate it's a plausible absolute Windows path
if ($InstallRoot -notmatch '^[A-Za-z]:\\') {
    Write-Warning "InstallRoot '$InstallRoot' doesn't look like an absolute Windows path (e.g., 'D:\Tools')."
    $confirm = Read-Host "Use it anyway? [y/N]"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') { exit 1 }
}

Write-Host ""
Write-Host "Configured:" -ForegroundColor Cyan
Write-Host "  InstallRoot = $InstallRoot"
Write-Host "  Agent       = $Agent"
Write-Host ""

# Read template and substitute placeholders (literal string replace, not regex)
$content = (Get-Content -Path $templatePath -Raw -Encoding UTF8).Replace('{{INSTALL_ROOT}}', $InstallRoot)

# Determine target installation locations
$targets = @()
if ($Agent -in @('claude', 'both')) {
    $targets += [PSCustomObject]@{
        Agent = 'Claude Code'
        Path  = Join-Path $env:USERPROFILE '.claude\skills\windows-tools-install-manager'
    }
}
if ($Agent -in @('codex', 'both')) {
    $targets += [PSCustomObject]@{
        Agent = 'Codex'
        Path  = Join-Path $env:USERPROFILE '.agents\skills\windows-tools-install-manager'
    }
}

# Install
foreach ($target in $targets) {
    $outFile = Join-Path $target.Path 'SKILL.md'

    if ((Test-Path $outFile) -and -not $Force) {
        Write-Host "[$($target.Agent)] SKILL.md already exists at: $outFile" -ForegroundColor Yellow
        $confirm = Read-Host "  Overwrite? [y/N]"
        if ($confirm -ne 'y' -and $confirm -ne 'Y') {
            Write-Host "  Skipped." -ForegroundColor DarkYellow
            continue
        }
    }

    New-Item -ItemType Directory -Path $target.Path -Force | Out-Null
    Set-Content -Path $outFile -Value $content -Encoding UTF8
    Write-Host "[$($target.Agent)] Installed: $outFile" -ForegroundColor Green
}

Write-Host ""
Write-Host "Done. Restart Claude Code / Codex to pick up the skill." -ForegroundColor Yellow
Write-Host "To reconfigure (different InstallRoot), just re-run this script with -Force." -ForegroundColor DarkGray
