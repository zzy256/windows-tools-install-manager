#Requires -Version 5.0

<#
.SYNOPSIS
[Mode B install] Pre-configure paths AND copy the skill to your agent.

.DESCRIPTION
This is the "power user" install path. It does TWO things:
  1. Pre-fills the skill's config file at:
     $env:USERPROFILE\.config\claude-skills\windows-tools-install-manager.json
     ...so the skill won't prompt you for paths on first use.
  2. Copies the skill's SKILL.md into your agent's skills directory.

If you'd rather have the skill ask you on first trigger (Mode A or C), you
don't need this script — just install the plugin via `/plugin install` or
have an AI drop SKILL.md for you. See README.md.

.PARAMETER InstallRoot
The directory where the skill should install system tools. Default: D:\Tools.

.PARAMETER Agent
'claude' / 'codex' / 'both'. Default: both.

.PARAMETER Force
Overwrite existing SKILL.md and config without asking.

.EXAMPLE
.\setup.ps1
Fully interactive.

.EXAMPLE
.\setup.ps1 -InstallRoot "C:\MyTools" -Agent claude -Force
Non-interactive.
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
Write-Host "  windows-tools-install-manager  — Mode B install (pre-config)" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "This skill standardizes how your AI agent installs system-level"
Write-Host "Windows tools (ffmpeg, 7zip, tesseract, gh CLI, OBS, Notepad++, etc.)"
Write-Host "to ONE directory you choose, and auto-adds each tool's bin folder"
Write-Host "to your user-scope PATH."
Write-Host ""
Write-Host "Mode B (this script) lets you set the InstallRoot upfront, so the"
Write-Host "skill won't ask the first time you use it." -ForegroundColor Yellow
Write-Host ""

# ----- Locate skill file -----
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$skillSource = Join-Path $scriptDir 'skills\windows-tools-install-manager\SKILL.md'

if (-not (Test-Path $skillSource)) {
    Write-Error "SKILL.md not found at: $skillSource`nAre you running setup.ps1 from the cloned repo root?"
    exit 1
}

# ----- Prompt: InstallRoot -----
if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
    Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [ Q1 ]  Tools install root" -ForegroundColor Green
    Write-Host "------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  The parent directory where every installed tool gets its own"
    Write-Host "  subfolder. Examples:"
    Write-Host ""
    Write-Host "    <YOUR_ROOT>\ffmpeg\" -ForegroundColor DarkGray
    Write-Host "    <YOUR_ROOT>\7zip\" -ForegroundColor DarkGray
    Write-Host "    <YOUR_ROOT>\tesseract\" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Pick a directory you control. Common choices:"
    Write-Host "    - D:\Tools          (default)"
    Write-Host "    - C:\MyTools"
    Write-Host "    - D:\Apps"
    Write-Host "    - E:\Software"
    Write-Host ""
    $default = 'D:\Tools'
    $userInput = Read-Host "  Your choice [default: $default]"
    $InstallRoot = if ([string]::IsNullOrWhiteSpace($userInput)) { $default } else { $userInput.Trim() }
}

$InstallRoot = $InstallRoot.TrimEnd('\', '/')
if ($InstallRoot -notmatch '^[A-Za-z]:\\') {
    Write-Warning "'$InstallRoot' doesn't look like an absolute Windows path."
    $confirm = Read-Host "  Use it anyway? [y/N]"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') { exit 1 }
}

Write-Host ""
Write-Host "  ✓ InstallRoot = $InstallRoot" -ForegroundColor Green
Write-Host ""

# ----- Step 1: write config file (this is what makes Mode B different from Mode A) -----
$cfgDir = Join-Path $env:USERPROFILE '.config\claude-skills'
$cfgPath = Join-Path $cfgDir 'windows-tools-install-manager.json'

if ((Test-Path $cfgPath) -and -not $Force) {
    Write-Host "  Config already exists at: $cfgPath" -ForegroundColor Yellow
    $existing = Get-Content $cfgPath -Raw | ConvertFrom-Json
    Write-Host "    current install_root = $($existing.install_root)" -ForegroundColor DarkGray
    $confirm = Read-Host "  Overwrite with new value? [y/N]"
    if ($confirm -ne 'y' -and $confirm -ne 'Y') {
        Write-Host "  Skipped config write." -ForegroundColor DarkYellow
    }
    else {
        New-Item -ItemType Directory -Path $cfgDir -Force | Out-Null
        @{ install_root = $InstallRoot } | ConvertTo-Json | Set-Content -Path $cfgPath -Encoding UTF8
        Write-Host "  ✓ Wrote config: $cfgPath" -ForegroundColor Green
    }
}
else {
    New-Item -ItemType Directory -Path $cfgDir -Force | Out-Null
    @{ install_root = $InstallRoot } | ConvertTo-Json | Set-Content -Path $cfgPath -Encoding UTF8
    Write-Host "  ✓ Wrote config: $cfgPath" -ForegroundColor Green
}

# ----- Step 2: copy SKILL.md to agent skill dirs -----
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
    Copy-Item -Path $skillSource -Destination $outFile -Force
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
Write-Host "       The skill should activate, read the config, and propose"
Write-Host "       an install plan WITHOUT asking you for a path."
Write-Host ""
Write-Host "  To change the install root later:" -ForegroundColor DarkGray
Write-Host "    .\setup.ps1 -InstallRoot 'E:\NewRoot' -Force" -ForegroundColor DarkGray
Write-Host "    (or just edit $cfgPath directly)" -ForegroundColor DarkGray
Write-Host ""
