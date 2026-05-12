# windows-tools-install-manager

A Claude Code / Codex skill that **standardizes installs of system-level Windows tools** (ffmpeg, 7zip, OCR engines, gh CLI, GUI apps, fonts, etc.) to a single configurable root directory, with automatic user-scope PATH management.

> ⚠️ **Windows only.** Uses PowerShell. macOS/Linux users would need to fork and adapt.

---

## 🚀 Install — pick one of three modes

The skill is **self-configuring on first use**: whichever mode you pick, the first time the skill runs it'll ask you where you want tools installed (or read a pre-filled config). Choose the mode that matches your style.

### Mode A — Claude Code `/plugin install` (Recommended for most users)

In Claude Code:

```
/plugin marketplace add https://github.com/<your-user>/windows-tools-install-manager
/plugin install windows-tools-install-manager@windows-tools-install-manager
```

Restart Claude Code. The next time you say something like "装个 ffmpeg" or "install yt-dlp", the skill will:
1. Ask you ONCE where you want tools installed (with a clear explanation of what it's for)
2. Save your answer to `~/.config/claude-skills/windows-tools-install-manager.json`
3. Proceed with the install — and from then on, never ask again

### Mode B — Pre-configure with `setup.ps1` (Power user)

If you want to set the path BEFORE the first trigger (e.g., you're scripting an install or want zero prompts at first use):

```powershell
git clone https://github.com/<your-user>/windows-tools-install-manager.git
cd windows-tools-install-manager
.\setup.ps1
```

`setup.ps1` will:
1. Ask you for the install root (with detailed explanation)
2. Write `~/.config/claude-skills/windows-tools-install-manager.json` for you
3. Copy `SKILL.md` into both `~/.claude/skills/...` and `~/.agents/skills/...`

After this, the first trigger will silently read the config and proceed.

Non-interactive form:
```powershell
.\setup.ps1 -InstallRoot "C:\MyTools" -Agent claude -Force
```

### Mode C — Ask an AI to install it for you

Paste this entire instruction to an AI agent (Claude Code, Codex, ChatGPT with file access, etc.):

> Please install this skill for me: `https://github.com/<your-user>/windows-tools-install-manager`
>
> Steps:
> 1. Fetch the raw content of `skills/windows-tools-install-manager/SKILL.md` from the repo's `main` branch (e.g., via `raw.githubusercontent.com`)
> 2. Save it to **`~/.claude/skills/windows-tools-install-manager/SKILL.md`** (for Claude Code) AND/OR **`~/.agents/skills/windows-tools-install-manager/SKILL.md`** (for Codex) — create parent dirs as needed
> 3. Confirm to me that it's installed and tell me what the skill does
> 4. Note: do NOT try to run `setup.ps1` — it requires interactive stdin which won't work in your session. The skill self-configures on first trigger.
> 5. Suggest I restart my agent so it picks up the new skill

The skill will then ask for the install root the first time it activates.

---

## What the skill does

When the user (or the AI agent, mid-task) needs to install a system-level tool:

1. **Step 0 — silently load** `<INSTALL_ROOT>` from `~/.config/claude-skills/windows-tools-install-manager.json` (or asks you if config is missing — happens once, ever)
2. **Pauses** and presents an install plan (tool, version, target path, install method, PATH change)
3. **Waits for explicit user confirmation** — user can override the path or any option
4. **Installs** via the best available method, in priority order:
   - Portable zip / 7z / tar (full path control)
   - `winget install --location <path>` (when supported)
   - Official installer with silent + custom-path flags (NSIS `/S /D=`, Inno `/VERYSILENT /DIR=`, MSI `INSTALLDIR=`)
   - pip / npm CLI tools into a per-tool venv
5. **Adds** the tool's bin directory to **user-scope** PATH (no admin needed)
6. **Verifies** the install with a `--version` check
7. **Reminds** the user to restart their terminal for PATH to take effect

The skill **explicitly does NOT** handle:
- Python packages → those belong to the sister skill [miniconda-python-env](#sister-skill)
- Node/npm packages inside a project
- Claude Code / Codex themselves
- OS components, drivers, Windows updates
- Read-only questions about a tool, tool comparisons, uninstall/delete operations

## How to change `<INSTALL_ROOT>` later

The path is stored in `~/.config/claude-skills/windows-tools-install-manager.json`. Three ways to change it:

1. **Ask the AI:** "把 install root 改成 E:\NewTools" → it'll edit the JSON for you
2. **Edit the JSON file** with any text editor
3. **Re-run `setup.ps1 -InstallRoot ... -Force`** from the repo (if you installed via Mode B)

Next invocation reads the new value silently.

## How it triggers

Once installed, the skill activates whenever:
- You explicitly ask to install: "装一下 ffmpeg", "install yt-dlp", "搞个 7zip"
- The AI agent notices mid-task that a required system tool is missing (e.g., asked to convert a video → ffmpeg not installed → skill activates)

The skill description includes precise NOT-USE cases (Python packages, opinions/comparisons, already-installed tools, etc.) to avoid false fires.

## Sister skill

For **Python package management** (deliberately NOT this skill's job), see **[miniconda-python-env](https://github.com/<your-user>/miniconda-python-env)** — handles Python deps via Miniconda envs with cleanup rules for temp scripts. The two skills cross-reference each other.

## Requirements

- Windows 10 / 11
- PowerShell 5+ (built-in)
- Claude Code and/or Codex installed
- git (only for Mode B install)

## License

[MIT](LICENSE)

## Contributing

Issues and PRs welcome. If you build macOS/Linux support, open a PR — happy to link cross-platform forks from here.
