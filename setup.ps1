#Requires -Version 5.0

<#
.SYNOPSIS
Install (and configure) the windows-tools-install-manager skill for
Claude Code and/or Codex.

.DESCRIPTION
This script IS the install. It will:
  1. Explain what the skill does
  2. Ask you where you want system tools installed
  3. Generate a personalized SKILL.md and copy it to your agent's
     skills directory

After it finishes, restart your agent (Claude Code / Codex) and the
skill is live. Re-run any time with -Force to reconfigure.

.PARAMETER InstallRoot
Override the install-root prompt. Examples: 'D:\Tools', 'C:\MyTools'.

.PARAMETER Agent
Which agent to install for: 'claude', 'codex', or 'both'. Default: both.

.PARAMETER Force
Overwrite existing SKILL.md without asking.

.EXAMPLE
.\setup.ps1
Fully interactive — recommended for first-time install.

.EXAMPLE
.\setup.ps1 -InstallRoot "C:\MyTools" -Agent claude -Force
Non-interactive — useful for scripted reinstall.
#>

[CmdletBinding()]
param(
    [string]$InstallRoot,
    [ValidateSet('claude', 'codex', 'both')]
    [string]$Agent = 'both',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# ----- Banner -----
Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  windows-tools-install-manager  — install + configure" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This skill standardizes how your AI agent installs system-level"
Write-Host "Windows tools (ffmpeg, 7zip, tesseract, gh CLI, OBS, Notepad++, etc.)"
Write-Host "so they all live under ONE directory you choose. After install, the"
Write-Host "skill also auto-adds each tool's bin folder to your user-scope PATH,"
Write-Host "so the tool is callable from any terminal."
Write-Host ""
Write-Host "Before installing, you need to tell me ONE thing: where you want"
Write-Host "tools to go." -ForegroundColor Yellow
Write-Host ""

# ----- Locate template -----
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$templatePath = Join-Path $scriptDir 'skills\windows-tools-install-manager\SKILL.md.template'

if (-not (Test-Path $templatePath)) {
    Write-Error "Template not found at: $templatePath`nAre you running setup.ps1 from the cloned repo root?"
    exit 1
}

# ----- Prompt: InstallRoot -----
if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
    Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [ Q1 ]  Tools install root" -ForegroundColor Green
    Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  The parent directory where every installed tool gets its own"
    Write-Host "  subfolder. Examples of how the skill will use it:"
    Write-Host ""
    Write-Host "    <YOUR_ROOT>\ffmpeg\" -ForegroundColor DarkGray
    Write-Host "    <YOUR_ROOT>\7zip\" -ForegroundColor DarkGray
    Write-Host "    <YOUR_ROOT>\tesseract\" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Pick a directory you have full control over (the skill will"
    Write-Host "  create subfolders and add bin paths to your PATH)."
    Write-Host ""
    Write-Host "  Common choices:"
    Write-Host "    - D:\Tools          (default)"
    Write-Host "    - C:\MyTools"
    Write-Host "    - D:\Apps"
    Write-Host "    - E:\Software"
    Write-Host ""
    Write-Host "  Note: if this directory doesn't exist yet, the skill will ASK"
    Write-Host "  the user (you, in future sessions) before creating it — it does"
    Write-Host "  not silently mkdir."
    Write-Host ""
    $default = 'D:\Tools'
    $userInput = Read-Host "  Your choice [default: $default]"
    $InstallRoot = if ([string]::IsNullOrWhiteSpace($userInput)) { $default } else { $userInput.Trim() }
}

# Normalize and validate
$InstallRoot = $InstallRoot.TrimEnd('\', '/')
if ($InstallRoot -notmatch '^[A-Za-z]:\\') {
    Write-Warning "'$InstallRoot' doesn't look like an absolute Windows path."
    $confirm = Read-Host "  Use it anyway? [y/N]"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') { exit 1 }
}

Write-Host ""
Write-Host "  ✓ InstallRoot = $InstallRoot" -ForegroundColor Green
Write-Host ""

# ----- Build content -----
$content = (Get-Content -Path $templatePath -Raw -Encoding UTF8).Replace('{{INSTALL_ROOT}}', $InstallRoot)

# ----- Resolve targets -----
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

Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  Installing SKILL.md ..." -ForegroundColor Green
Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

foreach ($target in $targets) {
    $outFile = Join-Path $target.Path 'SKILL.md'

    if ((Test-Path $outFile) -and -not $Force) {
        Write-Host "  [$($target.Agent)] $outFile already exists." -ForegroundColor Yellow
        $confirm = Read-Host "  Overwrite? [y/N]"
        if ($confirm -ne 'y' -and $confirm -ne 'Y') {
            Write-Host "  Skipped." -ForegroundColor DarkYellow
            continue
        }
    }

    New-Item -ItemType Directory -Path $target.Path -Force | Out-Null
    Set-Content -Path $outFile -Value $content -Encoding UTF8
    Write-Host "  ✓ [$($target.Agent)] $outFile" -ForegroundColor Green
}

# ----- Summary -----
Write-Host ""
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host "  Install complete." -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor Yellow
Write-Host "    1. Restart Claude Code / Codex (close and reopen)"
Write-Host "    2. Try saying:  '装个 ffmpeg'  or  'install yt-dlp'"
Write-Host "       The skill should activate and propose an install plan."
Write-Host ""
Write-Host "  To reconfigure (different InstallRoot), re-run:" -ForegroundColor DarkGray
Write-Host "    .\setup.ps1 -InstallRoot 'C:\Different\Path' -Force" -ForegroundColor DarkGray
Write-Host ""
