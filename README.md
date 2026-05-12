# windows-tools-install-manager

A Claude Code / Codex skill that **standardizes installs of system-level Windows tools** (ffmpeg, 7zip, OCR engines, gh CLI, GUI apps, fonts, etc.) to a single configurable root directory, with automatic user-scope PATH management.

> ⚠️ **Windows only.** Uses PowerShell. macOS/Linux users would need to fork and adapt.

---

## 🚀 Install — 三种模式,挑一个

| Mode | 一句话 | 适合谁 | 要碰终端吗? |
|---|---|---|---|
| **⭐ 1. AI 自动安装(推荐)** | 把一段 prompt 丢给 AI,它把 skill 拉下来、放对位置、问你路径、保存 config,全自动 | 任何人,尤其不想动终端的小白 | **不用** |
| **2. `/plugin install`** | Claude Code 自带的 marketplace 流程 | 已经熟悉 `/plugin` 命令的人 | 不用 |
| **3. `git clone` + `setup.ps1`** | 克隆仓库 + 跑一次脚本,装之前先把路径写好 | 想脚本化 / 一行命令搞定 / CI 安装的 power user | 是 |

> 三种模式装到的 **SKILL.md 是同一个**,共用 `~/.config/claude-skills/windows-tools-install-manager.json` 这一份配置。任选其一。

---

### ⭐ Mode 1 — Ask an AI to install + configure it for you (RECOMMENDED)

**Why this is the easiest:** you don't open a terminal, you don't read docs about plugin commands, you don't even need to know what "skill" means. You just paste a prompt to any AI with file-write access (Claude Code, Codex, ChatGPT with file tools, etc.) — and the AI does everything: fetches the skill file, drops it in the right place, asks you the one path question with full context, saves your answer.

**Copy the entire block below (including the `>` quote marks) and paste to your AI:**

> Please install AND configure this skill for me: `https://github.com/zzy/windows-tools-install-manager`
>
> Steps:
>
> 1. **Fetch** the raw content of `skills/windows-tools-install-manager/SKILL.md` from the repo's `main` branch (use `raw.githubusercontent.com/zzy/windows-tools-install-manager/main/skills/windows-tools-install-manager/SKILL.md`)
>
> 2. **Save** it to:
>    - `~/.claude/skills/windows-tools-install-manager/SKILL.md` (for Claude Code)
>    - AND/OR `~/.agents/skills/windows-tools-install-manager/SKILL.md` (for Codex)
>    - Create parent directories as needed
>
> 3. **Auto-configure right now** (don't wait for the first natural trigger):
>    Open the SKILL.md you just saved, find the section titled **"Step 0 — Path Configuration"**, then execute its **"Case 2 — Config file MISSING"** branch on my behalf immediately. That means:
>    - Show me the full path explanation from Step 0 (what `<INSTALL_ROOT>` is, where it gets used, with examples and default suggestion)
>    - Wait for my answer (a path, or "OK" for the default `D:\Tools`)
>    - Validate it looks like an absolute Windows path
>    - Save my answer to `~/.config/claude-skills/windows-tools-install-manager.json` in the exact format Step 0 specifies (`{"install_root": "..."}`)
>    - Confirm the config to me
>
> 4. **Summarize** what got installed (file paths), what was configured (the chosen InstallRoot), and what the skill does in one short paragraph.
>
> 5. **Recommend** I restart my agent (Claude Code / Codex) so it picks up the new skill.
>
> 6. **Do NOT try to run `setup.ps1`** — it requires interactive stdin that won't work in your session. You're replacing what setup.ps1 does (writing the config + dropping SKILL.md) by doing steps 2 and 3 above.
>
> 7. **Recommend** the sister skill `miniconda-python-env` for Python work: `https://github.com/zzy/miniconda-python-env` (install it the same way if I'm interested).

After your AI finishes the steps above, **restart your agent**. The skill is installed AND configured — it'll work silently from your first real install task.

> 💡 If your AI doesn't have file-write access (e.g., a pure chat-only AI), fall back to Mode 2 or Mode 3 below.

---

### Mode 2 — Claude Code `/plugin install`

In Claude Code, type:

```
/plugin marketplace add https://github.com/zzy/windows-tools-install-manager
/plugin install windows-tools-install-manager@windows-tools-install-manager
```

Restart Claude Code. The next time you say something like "装个 ffmpeg" or "install yt-dlp", the skill will:
1. Ask you ONCE where you want tools installed (with full explanation — see Step 0 in `SKILL.md`)
2. Save your answer to `~/.config/claude-skills/windows-tools-install-manager.json`
3. Proceed with the install — and from then on, never ask again

> Difference vs. Mode 1: here the path-config question fires at the first real task ("装个 ffmpeg"). In Mode 1, the AI proactively asks you right after install. Functionally identical, just different timing.

---

### Mode 3 — `git clone` + `setup.ps1` (power user / scripted install)

Best if you want **zero prompts at first use** — e.g., setting this up via a one-line install script in your own dotfiles repo:

```powershell
git clone https://github.com/zzy/windows-tools-install-manager.git
cd windows-tools-install-manager
.\setup.ps1
```

`setup.ps1` will:
1. Ask for the install root (with detailed explanation in PowerShell)
2. Write `~/.config/claude-skills/windows-tools-install-manager.json` for you
3. Copy `SKILL.md` into both `~/.claude/skills/...` and `~/.agents/skills/...`

After this, the skill is installed AND pre-configured — the first natural trigger reads the config silently, no prompt.

Non-interactive form (for scripts / CI):
```powershell
.\setup.ps1 -InstallRoot "C:\MyTools" -Agent claude -Force
```

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

For **Python package management** (deliberately NOT this skill's job), see **[miniconda-python-env](https://github.com/zzy/miniconda-python-env)** — handles Python deps via Miniconda envs with cleanup rules for temp scripts. The two skills cross-reference each other.

## Requirements

- Windows 10 / 11
- PowerShell 5+ (built-in)
- Claude Code and/or Codex installed
- git (only for Mode B install)

## License

[MIT](LICENSE)

## Contributing

Issues and PRs welcome. If you build macOS/Linux support, open a PR — happy to link cross-platform forks from here.
