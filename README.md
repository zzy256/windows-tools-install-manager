# windows-tools-install-manager

A Claude Code / Codex skill that **standardizes installs of system-level Windows tools** (ffmpeg, 7zip, OCR engines, gh CLI, GUI apps, fonts, etc.) to a single directory you control, with automatic user-scope PATH management.

> ⚠️ **Windows only.** Uses PowerShell. macOS/Linux users would need to fork and adapt.

---

## 🚀 Install

> ⚠️ **DO NOT use `/plugin install` from a Claude Code marketplace** — this skill needs path configuration that the marketplace flow can't run. **`.\setup.ps1` IS the install.**

Open PowerShell and run:

```powershell
# 1. Clone the repo to anywhere
git clone https://github.com/<your-user>/windows-tools-install-manager.git
cd windows-tools-install-manager

# 2. Run the setup script (THIS is the install)
.\setup.ps1
```

`setup.ps1` will:

1. **Explain** what the skill does
2. **Ask you for ONE path** (with a detailed explanation of what it's for and example choices):
   - **InstallRoot** — the parent directory where every installed tool will get its own subfolder (default: `D:\Tools`)
3. **Generate** a personalized `SKILL.md` from the template with your path baked in
4. **Copy** it into your agent's skills directory:
   - `%USERPROFILE%\.claude\skills\windows-tools-install-manager\SKILL.md` (Claude Code)
   - `%USERPROFILE%\.agents\skills\windows-tools-install-manager\SKILL.md` (Codex)

After it finishes, **restart Claude Code / Codex** and the skill is live.

### Non-interactive install

```powershell
.\setup.ps1 -InstallRoot "C:\MyTools" -Agent claude -Force
```

Options:
- `-InstallRoot <path>` — skip the interactive prompt
- `-Agent <claude|codex|both>` — limit which agent to install for (default: both)
- `-Force` — overwrite existing SKILL.md without confirmation

### Reconfigure later

Just re-run `setup.ps1`. To skip the prompts:

```powershell
.\setup.ps1 -InstallRoot "E:\NewToolsHome" -Force
```

---

## What the skill does

When the user (or the AI agent, mid-task) needs to install a system-level tool:

1. **Pauses** and presents an install plan (tool, version, target path, install method, PATH change)
2. **Waits for explicit user confirmation** — user can override the path or any option
3. **Installs** via the best available method, in priority order:
   - Portable zip / 7z / tar (full path control)
   - `winget install --location <path>` (when supported)
   - Official installer with silent + custom-path flags (NSIS `/S /D=`, Inno `/VERYSILENT /DIR=`, MSI `INSTALLDIR=`)
   - pip / npm CLI tools into a per-tool venv
4. **Adds** the tool's bin directory to **user-scope** PATH (no admin needed)
5. **Verifies** the install with a `--version` check
6. **Reminds** the user to restart their terminal for PATH to take effect

The skill **explicitly does NOT** handle:
- Python packages → those belong to the sister skill [miniconda-python-env](#sister-skill)
- Node/npm packages inside a project
- Claude Code / Codex themselves
- OS components, drivers, Windows updates
- Read-only questions about a tool, tool comparisons, uninstall/delete operations

## How it triggers

Once installed, the skill activates whenever:
- You explicitly ask to install: "装一下 ffmpeg", "install yt-dlp", "搞个 7zip"
- The AI agent notices mid-task that a required system tool is missing (e.g., asked to convert a video → ffmpeg not installed → skill activates and proposes an install plan)

The skill description includes precise NOT-USE cases (Python packages, opinions/comparisons, already-installed tools, etc.) to avoid false fires.

## Sister skill

For **Python package management** (deliberately NOT this skill's job), see **[miniconda-python-env](https://github.com/<your-user>/miniconda-python-env)** — handles Python deps via Miniconda envs with cleanup rules for temp scripts.

The two skills cross-reference each other:
- "装 ffmpeg" → this skill
- "装 numpy" → miniconda-python-env

If Miniconda itself is missing, miniconda-python-env chains into this skill to install it under your InstallRoot.

## Requirements

- Windows 10 / 11
- PowerShell 5+ (built-in)
- git (to clone the repo)
- Claude Code and/or Codex installed

## Why this skill exists

Without a convention, AI agents tend to:
- Install tools to whatever default location the installer picks → cluttered, hard to find later
- Skip the confirmation step and start downloading immediately
- Use elevated/admin PATH changes that affect the whole system
- Try `winget install` without `--location` even when a portable option exists

This skill enforces a clean, predictable, user-confirmed install workflow.

## License

[MIT](LICENSE)

## Contributing

Issues and PRs welcome. If you build macOS/Linux support, open a PR with the README updated — happy to link cross-platform forks from here.
