# windows-tools-install-manager

A Claude Code / Codex skill that **standardizes installs of system-level Windows tools** to a single configurable root directory, with automatic user-scope PATH management and mandatory plan-confirmation before any install.

> ⚠️ **Windows only.** This skill uses PowerShell commands and Windows-specific installer flags. macOS/Linux users would need to fork and adapt.

## What it does

When the user (or Claude itself, mid-task) needs to install a system-level tool (ffmpeg, 7zip, tesseract, gh CLI, OBS Studio, Notepad++, etc.), the skill:

1. **Pauses** and presents an install plan (tool, version, target path, method, PATH change)
2. **Waits for explicit user confirmation** — user can override path or any option
3. Installs via portable zip / winget `--location` / silent installer with custom-path flags
4. Adds the tool's bin directory to **user-scope PATH** (no admin needed, no Machine-scope changes)
5. Verifies the install with a `--version` check
6. Reminds the user to restart their terminal

The skill **does NOT** handle:
- Python packages (those belong to [miniconda-python-env](https://github.com/) — sister skill)
- Node/npm packages inside a project
- Claude Code / Codex themselves
- OS components, drivers, Windows updates
- Read-only questions about tools, comparisons, or uninstall/delete operations

## Install

### Requirements

- Windows 10/11
- PowerShell 5+ (built-in)
- Claude Code and/or Codex installed

### Quick install

```powershell
# 1. Clone the repo
git clone https://github.com/<your-user>/windows-tools-install-manager.git
cd windows-tools-install-manager

# 2. Run the setup script
.\setup.ps1
```

The setup script asks where you want tools installed (default: `D:\Tools`), then writes the configured `SKILL.md` into both:
- `%USERPROFILE%\.claude\skills\windows-tools-install-manager\` (Claude Code)
- `%USERPROFILE%\.agents\skills\windows-tools-install-manager\` (Codex)

### Non-interactive install

```powershell
.\setup.ps1 -InstallRoot "C:\MyTools" -Agent claude -Force
```

Options:
- `-InstallRoot <path>` — your preferred install root (any absolute Windows path)
- `-Agent <claude|codex|both>` — which agent to install for (default: both)
- `-Force` — overwrite existing SKILL.md without prompting

### Restart your agent

After install, restart Claude Code or Codex so it picks up the new skill. The skill description should appear in your available-skills list.

## How it triggers

Once installed, the skill activates whenever:
- You explicitly ask to install something: "装一下 ffmpeg", "install yt-dlp", "搞个 7zip"
- Or Claude / Codex notices mid-task that a tool is missing (e.g., you ask to convert a video → ffmpeg not installed → skill activates and proposes the install)

The skill description includes a precise list of when it should NOT trigger (Python packages, opinions/comparisons, already-installed tools, etc.) to avoid false fires.

## Reconfigure

To change the install root later:

```powershell
.\setup.ps1 -InstallRoot "E:\NewToolsHome" -Force
```

This regenerates `SKILL.md` with the new path. The change takes effect after restarting your agent.

## Sister skill

For **Python package management** (which deliberately is NOT this skill's job), see [miniconda-python-env](https://github.com/) — it handles Python deps via Miniconda envs, with cleanup rules for temporary scripts.

The two skills cross-reference each other so they cleanly divide the install territory:
- "装 ffmpeg" → this skill
- "装 numpy" → miniconda-python-env

## Why this skill exists

Without a convention, AI agents tend to:
- Install tools to whatever default location the installer picks (cluttered, hard to find later)
- Skip the confirmation step and start downloading immediately
- Use elevated/admin PATH changes that affect the whole system
- Try `winget install` without `--location` even when a portable option exists

This skill enforces a clean, predictable install workflow.

## License

MIT (see [LICENSE](LICENSE))

## Contributing

Issues and PRs welcome. If you want macOS/Linux support, fork and adapt — happy to link cross-platform forks from this README.
