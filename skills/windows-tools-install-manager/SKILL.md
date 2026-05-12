---
name: windows-tools-install-manager
description: Use when installing or upgrading a system-level tool, CLI / GUI app, utility, archive tool, Miniconda itself (incl. when chained from miniconda-python-env), or other end-user program on this Windows machine — both when the user explicitly asks ("install X", "upgrade X", "装/安装/装个/搞一个/升级 X") AND when you discover mid-task that a required system tool isn't installed (e.g., tesseract for OCR, ffmpeg for video, 7zip, gh CLI). Default install root D:\Tools\<tool-name>\ (user-configurable). Do NOT use for: Python packages (→ miniconda-python-env), Node/npm packages inside a project, Claude Code / Codex / Cursor themselves, OS components / drivers / Windows Updates, code compilation ("compile this C++", "编译一下"), read-only questions ("what does X do", "explain Y", "X vs Y", "哪个更好"), looking up where an existing install lives ("X 装在哪"), cases where the user states the tool is already installed, uninstall / delete operations ("删了 X", "卸载 X"), extensions for VS Code or browsers, or Steam / game installs.
---

# Install Casual Tools to a Configurable Root

## Step 0 — Path Configuration (run on EVERY invocation, before anything else)

This skill needs ONE configurable path: **`<INSTALL_ROOT>`** — the parent directory where every installed tool gets its own subfolder.

**Config file location:** `<USER_HOME>\.config\claude-skills\windows-tools-install-manager.json`

(On Windows: `$env:USERPROFILE\.config\claude-skills\windows-tools-install-manager.json`)

**Procedure on every invocation:**

### Case 1 — Config file EXISTS (every invocation after the first)

Read it silently and continue:

```powershell
$cfgPath = "$env:USERPROFILE\.config\claude-skills\windows-tools-install-manager.json"
$cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
$InstallRoot = $cfg.install_root
```

Do NOT mention this to the user — it's silent infrastructure. Just use `<INSTALL_ROOT>` = `$InstallRoot` in every path reference below.

### Case 2 — Config file MISSING (first invocation only)

This is the first time the skill is being used. Tell the user, in ONE clear message:

> 我是 **windows-tools-install-manager** skill,第一次启用,需要你帮我设置一个路径。
>
> ⚠️ **这个路径 ≠ skill 自己的安装位置** —— skill 文件已经装好在 `~/.claude/skills/windows-tools-install-manager/` 里了,不需要你管。
>
> **这个路径 = 以后你让我帮你装其他软件工具时,这些工具应该被放在哪里。**
>
> 举例:以后你说"装个 ffmpeg",ffmpeg 会被放到 `<你选的根目录>\ffmpeg\`;同理 7zip 会到 `<根目录>\7zip\`,tesseract 会到 `<根目录>\tesseract\`,以此类推 —— 每个工具一个子文件夹,全都在你选的这一个根目录下面。
>
> ---
>
> **请二选一回复:**
>
> **选项 A — 用默认值** 
> 回复 "OK" 或 "默认",我用 **`D:\Tools`**(适合有 D 盘的用户)
>
> **选项 B — 自定义路径**
> 直接回复一个你想要的绝对 Windows 路径,例如:
> - `C:\MyTools`
> - `D:\Apps`
> - `E:\Software`
> - 或者任何其他你想用的绝对路径(必须是 `<盘符>:\...` 格式)
>
> ---
>
> 你回答之后,我会保存到 `~/.config/claude-skills/windows-tools-install-manager.json`,**以后所有启用都不会再问这个问题**。

Wait for the user's reply. Parse:
- "OK" / "默认" / 空回复 → use `D:\Tools`
- An absolute Windows path matching `^[A-Za-z]:\\` → use it
- Anything else (ambiguous reply, relative path, etc.) → re-ask, clarify you need an absolute path

Validate the answer roughly looks like a Windows path (matches `^[A-Za-z]:\\`). If it doesn't, ask again.

Then save it:

```powershell
$cfgDir = "$env:USERPROFILE\.config\claude-skills"
New-Item -ItemType Directory -Path $cfgDir -Force | Out-Null
$InstallRoot = $userAnswer.TrimEnd('\','/')
@{ install_root = $InstallRoot } | ConvertTo-Json | Set-Content -Path "$cfgDir\windows-tools-install-manager.json" -Encoding UTF8
```

Confirm to user: "✓ 记下了:`<INSTALL_ROOT>` = `<the value>`. 现在开始装你刚才说的那个工具…"

Then continue with the rest of this skill using `$InstallRoot` (= `<INSTALL_ROOT>`).

---

## Core Rule

Whenever a software tool needs to be installed on this Windows machine — whether user-requested or discovered during task execution:

1. Default install root is `<INSTALL_ROOT>\<tool-name>\` (loaded from config per Step 0)
2. **Pause and present an install plan to the user; get explicit confirmation before running anything**
3. **If `<INSTALL_ROOT>\` does not exist on this machine, do NOT auto-create it — ask the user** (they may say "create it" or "change the install root to something else"; if they change it, update the config file)
4. After install, auto-add the tool's bin directory to **user-scope PATH**
5. Use silent + custom-path flags when forced to use a vendor installer; fall back + warn if not possible

## When to Use

### Scenario A — User explicitly asks
- "帮我装个 OCR"
- "install yt-dlp"
- "下载一下 7-Zip"
- "set up Tesseract"
- "搞一个 ffmpeg"

### Scenario B — You discover a missing tool while executing the user's task

Examples:
- User asks: "提取这个 PDF 的文字" → you check the PDF, it's image-based, needs OCR → tesseract not installed
- User asks: "把这段视频转成 GIF" → ffmpeg not installed
- User asks: "处理这个 Excel" → pandas/openpyxl not installed in current env
- User asks: "压缩这个文件夹" → 7zip / archive tool needed

In this case:
1. **Stop the original task** at the point where the missing tool is needed
2. Tell the user: "To do X I need <tool>, which isn't installed. Here's my install plan: ..."
3. Present the install plan (same format as Scenario A)
4. Wait for confirmation
5. Install per this skill's rules
6. Resume the original task

**Do NOT** silently install to the default location (e.g., `pip install`, `winget install` without `--location`) just to keep the task moving — that defeats the user's organization preference.

## Do NOT Use When

- User explicitly names a project ("for project X", "in this repo", names a project path) → use the project's package manager normally
- Installing inside an active project's package manager (pip in a project's venv, npm in a project repo) → that's project dependency work
- Installing Claude Code, Codex, Anthropic SDK → those have their own install conventions
- Installing OS components, drivers, Windows features → those go to system locations
- The tool is already installed and on PATH → just use it

## Required Steps

### 1. Decide the tool name (folder name)

Use **lowercase kebab-case** of the canonical short name:
- Tesseract OCR → `tesseract`
- yt-dlp → `yt-dlp`
- Python 3.12 → `python` or `python-3.12`
- 7-Zip → `7zip`
- FFmpeg → `ffmpeg`

When ambiguous, pick the shortest common name. If the user named it explicitly, follow their naming.

### 2. Resolve the install root (existence check)

After Step 0, `<INSTALL_ROOT>` is already loaded. Now verify it actually exists on disk:

```powershell
Test-Path $InstallRoot
```

- **Exists** → use `<INSTALL_ROOT>\<name>\` as the install path; continue
- **Does NOT exist** → **stop and ask the user**:
  > 你配置的 `<INSTALL_ROOT>` (`<value>`) 在磁盘上不存在。要怎么办?
  > - **创建它** 并装到 `<INSTALL_ROOT>\<name>\`
  > - 或者**改用别的路径**(临时换一次,或永久改 config)

  Wait for the user's answer. If they want to permanently change the root, update the config file before continuing.

### 3. Pick install method (in this priority order)

1. **Portable zip / 7z / tar** (best — full path control)
   - Download official portable archive
   - Extract directly to `<INSTALL_ROOT>\<name>\`
2. **winget with `--location`** (when supported)
   ```powershell
   winget install --id <package-id> --location "$InstallRoot\<name>" --accept-source-agreements --accept-package-agreements
   ```
   Not all packages support `--location`; check `winget show <id>` first
3. **Official installer with silent + custom-path flags** — see "Silent Install Flags" below
4. **pip / npm CLI tools** — install into a venv at `<INSTALL_ROOT>\<name>\venv\` and add its `Scripts`/`bin` to PATH
5. **scoop / choco** if user has them — install normally, then symlink/junction under `<INSTALL_ROOT>` if needed

### 4. Present the install plan and wait for confirmation (mandatory)

Before running any install command, present a short plan and **ask the user to confirm or modify**:

```
计划安装:
- 工具:<tool name & version>
- 路径:<INSTALL_ROOT>\<name>\          ← 改路径就告诉我
- 方法:<portable / winget / silent installer / ...>
- PATH:会把 <INSTALL_ROOT>\<name>\ 加到用户 PATH
- 备注:<any caveats — admin required? size? optional components?>

按这个走可以吗?需要改路径或其他选项就直说。
```

Then **wait for explicit confirmation** ("可以" / "OK" / "go" / "改成 X"). Do not install before getting it.

### 5. Install

Create the directory first:
```powershell
New-Item -ItemType Directory -Path "$InstallRoot\<name>" -Force | Out-Null
```

Then run the chosen install method.

### 6. Add to user-scope PATH (if not already present)

```powershell
$bin = "$InstallRoot\<name>"   # or "$InstallRoot\<name>\bin" if the tool uses a bin subfolder
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath -notlike "*$bin*") {
    [Environment]::SetEnvironmentVariable("Path", "$userPath;$bin", "User")
}
```

User scope only — does NOT require admin and does NOT affect other users on the machine.

After modifying PATH, tell the user: **"Restart your terminal for PATH changes to take effect."**

For Scenario B (mid-task install), you can continue using the tool in the **current** session by invoking it with its full path (`& "$InstallRoot\<name>\<binary>.exe"`) — PATH changes only apply to new shells.

### 7. Verify install

Run a sanity check from the install path, e.g.:
```powershell
& "$InstallRoot\<name>\<binary>.exe" --version
```
Show output to user. If verification fails, report what went wrong rather than claiming success.

### 8. (Scenario B only) Resume the original task

After verifying the install works, go back to the user's original task and continue from where you paused. Reference the tool by its full path in the current session.

## Silent Install Flags Cheatsheet

| Installer type | Silent flag | Custom path flag |
|---|---|---|
| **NSIS** (most modern `.exe`) | `/S` | `/D=$InstallRoot\<name>` (must be **last arg**, no quotes, no trailing slash) |
| **Inno Setup** | `/VERYSILENT` or `/SILENT` | `/DIR="$InstallRoot\<name>"` |
| **MSI** | `msiexec /i installer.msi /qb` (basic UI) or `/qn` (no UI) | `INSTALLDIR="$InstallRoot\<name>"` |
| **InstallShield** | `/s /v"/qn"` | Varies — check `installer.exe /?` |
| **Squirrel / custom vendor** | Varies | Check `installer.exe /?` or vendor docs |

If silent install with custom path **fails or isn't supported**:
- Fall back to default install location
- Explicitly tell the user: "This installer doesn't support custom paths; installed to <actual path>. Want me to create a symlink/junction under `<INSTALL_ROOT>`, or leave it as-is?"

## Red Flags — STOP and re-check

| Rationalization | Reality |
|---|---|
| "I'll just `pip install` it quickly, the user is waiting" | Defaults the user wants prevented. Pause and propose `<INSTALL_ROOT>` install. |
| "winget install without --location is fine, it's just a CLI" | Still violates the convention. Use `--location` or pick portable. |
| "It's a small package, no need to bother the user" | Confirmation is mandatory regardless of size. |
| "User already said yes to installing X yesterday" | Each install gets its own confirmation. |
| "I can't pause mid-task to install something" | Yes you can — that's exactly Scenario B. Pause, propose, install, resume. |
| "Skip Step 0, I remember the path from earlier" | Always run Step 0. Config might have changed. It's silent if the config exists — cheap to run. |

## Common Mistakes

| Mistake | Fix |
|---|---|
| Skipping Step 0 entirely (using hardcoded path) | Always run Step 0 first — that's how `<INSTALL_ROOT>` gets resolved |
| Auto-installing mid-task without asking | Always pause and confirm — Scenario B is not an exception |
| Auto-creating `<INSTALL_ROOT>\` when it doesn't exist | Stop and ask the user — absence may be intentional |
| Folder name with spaces or capitals (`Tesseract OCR`) | Lowercase kebab-case (`tesseract`) |
| Modifying Machine-scope PATH | User scope only — no admin needed and reversible |
| Adding the same directory to PATH twice | Check existing user PATH first with `-notlike` |
| Running installer without silent flag → GUI window hangs forever | Always use silent flags for non-interactive installs |
| Installing Claude Code / Codex via this skill | Excluded — those have their own install conventions |
| Forgetting to tell the user to restart their terminal | PATH changes only apply to newly opened shells |
| Claiming success without verifying the binary runs | Always run a `--version` (or equivalent) check |

## Exclusions

This skill does NOT govern installs of:
- Claude Code, Codex, Anthropic SDK
- OS components, drivers, Windows features
- Project dependencies inside an active repo (pip in venv, npm in a repo)
- Tools the user explicitly wants installed elsewhere

## How to Change `<INSTALL_ROOT>` Later

The user can change the configured root any time by:

1. **Asking you (the AI) to change it:** "把 install root 改成 E:\NewTools" → you edit `~/.config/claude-skills/windows-tools-install-manager.json`
2. **Editing the JSON file directly** with any text editor
3. **Re-running `setup.ps1 -InstallRoot ... -Force`** from the plugin's git repo (if installed via Mode B)

Next invocation reads the new value silently.
