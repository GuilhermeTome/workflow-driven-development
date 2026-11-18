# Multi-Harness Installation & Quickstart Manual

Workflow-Driven Development (WDD) ships as a lightweight, zero-dependency pack of five standard Agent Skills (`SKILL.md` + progressive-disclosure `references/` and `scripts/`) compatible with **Claude Code**, **Google Antigravity / Gemini CLI**, **OpenAI Codex CLI**, **OpenCode**, and any tool supporting the shared `.agents/skills` convention.

- **New to WDD concepts?** Read [Principles of Workflow-Driven Development](./principles.md).
- **Want to trace a complete Epic run?** Follow the [End-to-End Architecture Walkthrough](./architecture-walkthrough.md).

---

## 1. Prerequisites

Verify these three baseline tools on your machine before installing WDD:

| Requirement | Minimum Version | Why WDD Needs It | Verification Command |
| :--- | :--- | :--- | :--- |
| **Git** | `git >= 2.30` | Native `git worktree add`, `unlock`, `remove --force`, and `prune` support used by `wdd-worktree.sh`. | `git --version` |
| **GitHub CLI** | `gh >= 2.0` (authenticated) | Creating/editing Epics and Tasks, reading issue specs in isolated subagents, and opening final PRs. | `gh auth status` |
| **Bash** | `bash >= 4.0` | Executing `skills/wdd-run-epic/scripts/wdd-worktree.sh` and the automated installer scripts. | `bash --version` |

> [!TIP]
> **macOS Users:** macOS ships `/bin/bash` `3.2` by default. Install a modern Bash via Homebrew (`brew install bash`) and ensure `/opt/homebrew/bin` (Apple Silicon) or `/usr/local/bin` (Intel) precedes `/bin` in your `PATH` so `#!/usr/bin/env bash` resolves to Bash `>= 4.0`.

---

## 2. Installation Methods

Choose one of the three installation methods below depending on your workflow.

### Method A — `skills` CLI (Recommended Quick Install)

If you have Node.js (`npx`) installed, the [`skills` CLI](https://github.com/vercel-labs/skills) installs and links all five WDD skills automatically:

```bash
# Global installation across detected agent harnesses (recommended)
npx skills add GuilhermeTome/workflow-driven-development -g

# Project-local installation inside the current repository
npx skills add GuilhermeTome/workflow-driven-development
```

### Method B — Repository Clone + Automated Installer (`scripts/install.sh`)

Cloning the repository and running `scripts/install.sh` requires **zero Node/npm dependencies** and lets you pull future updates instantly via `git pull`.

#### 1. Clone the repository

```bash
git clone https://github.com/GuilhermeTome/workflow-driven-development.git ~/.local/share/workflow-driven-development
cd ~/.local/share/workflow-driven-development
```

#### 2. Install globally across all harnesses (`--all`)

Running `scripts/install.sh` with `--all` (or with no target flags) creates canonical symlinks in `~/.agents/skills/wdd-*` pointing to `<repo>/skills/wdd-*`, and links `~/.claude/skills`, `~/.gemini/config/skills`, `~/.codex/skills`, and `~/.config/opencode/skills` to `~/.agents/skills/wdd-*`:

```bash
bash scripts/install.sh --all
```

#### 3. Install for specific harnesses only

Pass one or more combinable harness flags to target only the tools you use:

```bash
# Claude Code only (~/.claude/skills)
bash scripts/install.sh --claude

# Google Antigravity / Gemini CLI + OpenAI Codex CLI
bash scripts/install.sh --gemini --codex

# OpenCode + Canonical ~/.agents/skills root
bash scripts/install.sh --opencode --agents
```

#### 4. Project-local installation (`--target` and `--copy`)

To scope WDD to a single repository—or commit the skills directly into a team repository so every contributor gets them automatically on checkout—use `--target <dir>` (optionally paired with `--copy`):

```bash
# Symlink WDD skills into a project's .agents/skills directory
bash scripts/install.sh --target /path/to/your-project/.agents/skills

# Copy files instead of symlinking (ideal when committing skills into git)
bash scripts/install.sh --target /path/to/your-project/.agents/skills --copy
```

#### Complete `scripts/install.sh` Flag Reference

| Flag | Target Path / Behavior |
| :--- | :--- |
| `--all` *(default)* | Installs canonical symlinks into `$HOME/.agents/skills` and links Claude, Gemini/Antigravity, Codex, and OpenCode global skill directories. |
| `--agents` | Installs into `$HOME/.agents/skills`. |
| `--claude` | Installs into `$HOME/.claude/skills`. |
| `--gemini` | Installs into `$HOME/.gemini/config/skills`. |
| `--codex` | Installs into `$HOME/.codex/skills`. |
| `--opencode` | Installs into `$HOME/.config/opencode/skills`. |
| `--target <dir>` | Installs all `wdd-*` skills into the explicit directory `<dir>`. |
| `--copy` | Copies skill directories (`cp -R`) instead of creating symlinks (`ln -sfn`). |
| `--check` | Read-only health check verifying that all 5 `wdd-*` skills exist and resolve cleanly in the selected target(s). Exits non-zero if any skill is missing or broken. |
| `--help`, `-h` | Prints CLI usage documentation and exits `0`. |

---

### Method C — Manual Symlink Installation per Harness

If you prefer full manual control without running installer scripts, inspect the discovery paths table below and run the snippet for your harness.

#### Harness Skill Discovery Paths

| Agent Harness | Global Skills Directory | Workspace / Project Directory |
| :--- | :--- | :--- |
| **Canonical Shared Root** | `~/.agents/skills/` | `.agents/skills/` |
| **Claude Code** | `~/.claude/skills/` | `.claude/skills/` |
| **Google Antigravity / Gemini CLI** | `~/.gemini/config/skills/` | `.agents/skills/` |
| **OpenAI Codex CLI** | `~/.codex/skills/` | `.agents/skills/` |
| **OpenCode** | `~/.config/opencode/skills/` | `.agents/skills/` |

#### Copy-Pasteable Manual Symlink Commands

Set `WDD_REPO` to the absolute path where you cloned `workflow-driven-development`:

```bash
export WDD_REPO="$HOME/.local/share/workflow-driven-development"
```

- **Canonical Shared Root (`~/.agents/skills/`):**
  ```bash
  mkdir -p ~/.agents/skills
  for skill in "$WDD_REPO"/skills/wdd-*; do
    ln -sfn "$skill" ~/.agents/skills/"$(basename "$skill")"
  done
  ```

- **Claude Code (Global `~/.claude/skills/` or Workspace `.claude/skills/`):**
  ```bash
  # Global
  mkdir -p ~/.claude/skills
  for skill in "$WDD_REPO"/skills/wdd-*; do
    ln -sfn "$skill" ~/.claude/skills/"$(basename "$skill")"
  done

  # Workspace-only (run inside your target project root)
  mkdir -p .claude/skills
  for skill in "$WDD_REPO"/skills/wdd-*; do
    ln -sfn "$skill" .claude/skills/"$(basename "$skill")"
  done
  ```

- **Google Antigravity / Gemini CLI (Global `~/.gemini/config/skills/` or Workspace `.agents/skills/`):**
  ```bash
  # Global
  mkdir -p ~/.gemini/config/skills
  for skill in "$WDD_REPO"/skills/wdd-*; do
    ln -sfn "$skill" ~/.gemini/config/skills/"$(basename "$skill")"
  done

  # Workspace-only (run inside your target project root)
  mkdir -p .agents/skills
  for skill in "$WDD_REPO"/skills/wdd-*; do
    ln -sfn "$skill" .agents/skills/"$(basename "$skill")"
  done
  ```

- **OpenAI Codex CLI (Global `~/.codex/skills/` or Workspace `.agents/skills/`):**
  ```bash
  # Global
  mkdir -p ~/.codex/skills
  for skill in "$WDD_REPO"/skills/wdd-*; do
    ln -sfn "$skill" ~/.codex/skills/"$(basename "$skill")"
  done
  ```

- **OpenCode (Global `~/.config/opencode/skills/`):**
  ```bash
  mkdir -p ~/.config/opencode/skills
  for skill in "$WDD_REPO"/skills/wdd-*; do
    ln -sfn "$skill" ~/.config/opencode/skills/"$(basename "$skill")"
  done
  ```

---

## 3. Verifying Your Installation

After installing, confirm that all five skills are discoverable and that the worktree helper script is executable:

1. **Run the built-in health check** (if you cloned the repository):
   ```bash
   bash scripts/install.sh --check
   ```
   To check a specific harness or project directory:
   ```bash
   bash scripts/install.sh --claude --check
   bash scripts/install.sh --target /path/to/your-project/.agents/skills --check
   ```

2. **Verify the 5 skill directories and executable helper manually:**
   Every target skills folder should contain all five skill directories:
   - [`wdd-create-epic`](../skills/wdd-create-epic/SKILL.md)
   - [`wdd-create-task`](../skills/wdd-create-task/SKILL.md)
   - [`wdd-run-epic`](../skills/wdd-run-epic/SKILL.md)
   - [`wdd-execute-task`](../skills/wdd-execute-task/SKILL.md)
   - [`wdd-review-task`](../skills/wdd-review-task/SKILL.md)

   And `wdd-worktree.sh` must have executable permissions (`+x`):
   ```bash
   ls -ld ~/.agents/skills/wdd-*
   test -x ~/.agents/skills/wdd-run-epic/scripts/wdd-worktree.sh && echo "wdd-worktree.sh is executable"
   ```

3. **Run your first WDD prompt inside a target repository:**
   Start a fresh session in your AI coding harness and invoke a WDD skill directly (either via `/wdd-create-epic` slash syntax where supported, or by naming the skill in natural language):
   ```text
   Use wdd-create-epic to plan and publish a GitHub Epic and wave-ordered Tasks for adding rate-limited API keys to this repository.
   ```
   Once you review the published Epic `#<id>` on GitHub, execute all waves end-to-end:
   ```text
   Run Epic #<id> using wdd-run-epic.
   ```

---

## 4. Updating & Uninstalling

### Updating WDD

- **If installed via symlinks (Method B or Method C):** Pull the latest `main` branch in your cloned repository—all symlinked harnesses pick up updates immediately with zero re-installation:
  ```bash
  git -C ~/.local/share/workflow-driven-development pull --ff-only
  ```
- **If installed with `--copy` into a team repository:** Pull updates in your WDD clone, then re-run `scripts/install.sh --target <dir> --copy` and commit the updated files.
- **If installed via `npx skills` (Method A):** Re-run `npx skills add GuilhermeTome/workflow-driven-development -g` to fetch the latest commit.

### Uninstalling WDD

`scripts/uninstall.sh` removes **only** the five `wdd-*` entries (`wdd-create-epic`, `wdd-create-task`, `wdd-run-epic`, `wdd-execute-task`, `wdd-review-task`) and never touches unrelated third-party or custom skills in your skill directories:

```bash
# Remove from all global harness directories (~/.agents, ~/.claude, ~/.gemini, ~/.codex, ~/.config/opencode)
bash scripts/uninstall.sh --all

# Remove from a single harness only
bash scripts/uninstall.sh --claude

# Remove from a project-local directory
bash scripts/uninstall.sh --target /path/to/your-project/.agents/skills
```

For manual removal without the script:

```bash
rm -rf ~/.agents/skills/wdd-{create-epic,create-task,run-epic,execute-task,review-task} \
       ~/.claude/skills/wdd-{create-epic,create-task,run-epic,execute-task,review-task} \
       ~/.gemini/config/skills/wdd-{create-epic,create-task,run-epic,execute-task,review-task} \
       ~/.codex/skills/wdd-{create-epic,create-task,run-epic,execute-task,review-task} \
       ~/.config/opencode/skills/wdd-{create-epic,create-task,run-epic,execute-task,review-task}
```

---

## 5. Troubleshooting & `AGENTS.md` Integration Tips

### Unauthenticated or Misconfigured `gh` CLI
- **Symptom:** `gh issue create` or `gh issue view` fails with `authentication required` or `HTTP 401/404`.
- **Fix:** Run `gh auth status` to inspect active credentials, or re-authenticate via `gh auth login` ensuring the `repo` scope is granted for private repositories. Verify your repository has a valid `origin` remote (`gh repo view --json nameWithOwner`).

### Stale or Locked Git Worktrees
- **Symptom:** `git worktree add` reports `fatal: '<path>' is already a checked out branch` or `already registered worktree` after a hard system reboot or manually deleted folder.
- **Fix:** Inspect active worktrees from your main repository checkout and prune stale metadata:
  ```bash
  git worktree list
  # If a specific worktree was locked before interruption:
  git worktree unlock /path/to/.worktrees/<repo>/task-<id>-<slug>
  git worktree remove --force /path/to/.worktrees/<repo>/task-<id>-<slug>
  # Clean up metadata for directories already deleted from disk:
  git worktree prune
  ```

### Getting the Most Out of WDD with Repository `AGENTS.md`
[`wdd-create-epic`](../skills/wdd-create-epic/SKILL.md), [`wdd-create-task`](../skills/wdd-create-task/SKILL.md), [`wdd-execute-task`](../skills/wdd-execute-task/SKILL.md), and [`wdd-review-task`](../skills/wdd-review-task/SKILL.md) automatically read your target repository's `AGENTS.md` (and/or `CLAUDE.md`) to enforce project-specific standards. For best results, include these four items in your project's `AGENTS.md`:
1. **Exact Test Runner Command:** e.g., `npm test -- <file>`, `php artisan test --compact <file>`, `pytest <file>`, or `go test ./...`.
2. **Scoped Formatter & Linter Commands:** Commands that format *only* modified files (e.g., `npx prettier --write <files>`, `vendor/bin/pint --dirty`) so parallel Wave subagents never reformat sibling tasks' files.
3. **File & Module Line-Count Guardrails:** Maximum line ceilings for controllers, UI pages, services, or components so `wdd-create-task` instructs subagents to extract modular collaborators proactively.
4. **Known Baseline Lint / Type Debt:** Note any pre-existing warnings so `wdd-review-task` enforces "zero *new* errors above baseline" without blocking tasks on legacy debt.

> [!IMPORTANT]
> **Note on Auto-Push Rules in `AGENTS.md`:** If your repository's `AGENTS.md` normally instructs agents to `git push` or merge immediately after every task, `wdd-run-epic`'s subagent dispatch prompt automatically scopes task subagents to commit locally on `task/<id>-<slug>` without pushing or opening intermediate PRs—ensuring clean Coordinator review and single-PR delivery to `main`.
