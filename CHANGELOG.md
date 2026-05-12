# Changelog

All notable changes to `windows-tools-install-manager` are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-05-12

Initial public release.

### Added

- Skill: **`windows-tools-install-manager`** — standardizes system-level Windows tool installs to a single user-configurable root
- **Three install modes** for end users:
  - ⭐ Mode 1: AI-driven install (paste a prompt to an AI; recommended for non-technical users)
  - Mode 2: `/plugin install` from Claude Code marketplace
  - Mode 3: `git clone` + `setup.ps1` (power user / scripted install)
- **Self-configuring `SKILL.md`** via "Step 0 — Path Configuration":
  - Reads `~/.config/claude-skills/windows-tools-install-manager.json` silently on every invocation
  - On first run, asks the user once for the install root (with explicit two-option prompt: default vs custom)
  - Disambiguation warning that the path is NOT where the skill itself lives
- **`setup.ps1`** for pre-configuration: writes the config file + copies SKILL.md to agent skills dirs (Claude Code + Codex)
- Cross-agent support: `.claude-plugin/plugin.json` + `.codex-plugin/plugin.json` with Codex `interface` metadata
- Install method priority: portable archives → `winget --location` → silent installer with custom-path flags → per-tool venv → scoop/choco fallback
- User-scope PATH auto-management (no admin needed)
- Strict NOT-USE clauses in the skill description for Python packages, npm packages, code compilation, tool comparisons, uninstall ops, looking-up-existing-install, VS Code/browser extensions, Steam games, and Windows OS components

### Notes

- Windows-only by design. macOS/Linux users would need to fork and adapt the PowerShell snippets.
- Sister skill: [miniconda-python-env](https://github.com/zzy256/miniconda-python-env) for Python package management.
