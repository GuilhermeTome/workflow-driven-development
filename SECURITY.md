# Security Policy

## Supported Versions

The following versions of **Workflow-Driven Development (WDD)** currently receive security updates:

| Version | Supported          |
| :------ | :----------------- |
| `0.1.x` | :white_check_mark: |
| `< 0.1` | :x:                |

## Reporting a Vulnerability

Please **do not** report security vulnerabilities through public GitHub Issues, Discussions, or Pull Requests.

Instead, disclose vulnerabilities privately using **GitHub Private Vulnerability Reporting**:

1. Navigate to the [`GuilhermeTome/workflow-driven-development` Security tab](https://github.com/GuilhermeTome/workflow-driven-development/security).
2. Click **Report a vulnerability** ([direct advisory submission link](https://github.com/GuilhermeTome/workflow-driven-development/security/advisories/new)).
3. Provide a clear description of the issue, affected files (`skills/`, `scripts/`, or workflow configurations), reproduction steps or proof-of-concept input, and potential impact.

### What to Expect

- **Acknowledgment:** Maintainers aim to acknowledge receipt of private vulnerability reports within **72 hours**.
- **Triage & Remediation:** Confirmed issues will be fixed in a private advisory branch, verified against `bash tests/validate-pack.sh`, and released with credit to the reporter (unless anonymity is requested).

---

## Security Scope for Agent Skills & Git Worktree Tooling

Because WDD orchestrates autonomous AI subagents, shell scripts, `git worktree` lifecycles, and `gh` CLI commands on developer machines, security reviews focus on four primary boundaries:

### 1. Shell Injection Prevention in `scripts/`

- Helper scripts (including [`skills/wdd-run-epic/scripts/wdd-worktree.sh`](./skills/wdd-run-epic/scripts/wdd-worktree.sh) and `scripts/install.sh`) run under `#!/usr/bin/env bash` with `set -euo pipefail`.
- Untrusted or user-derived inputs (issue titles, branch slugs, summary strings, target directories) MUST be quoted across all command invocations and sanitized before constructing branch or directory names (e.g., `sanitize_slug` restricting slugs to `[a-z0-9-]`).
- Scripts MUST NOT pass unsanitized issue bodies, commit subjects, or user strings to `eval` or unquoted `bash -c`.

### 2. Worktree & Symlink Path Traversal Bounds

- Epic and Task worktrees are strictly scoped under `<repo-parent>/.worktrees/<repo-name>/` (`epic-<id>-<slug>` and `task-<id>-<slug>`).
- Destructive cleanup operations (`git worktree remove --force`, `rm`, symlink uninstallation in `scripts/install.sh`) MUST validate target paths and slugs so crafted inputs (such as `..`, empty variables, or `/` prefixes) cannot traverse outside `.worktrees/<repo-name>/` or target skill directories.

### 3. Credential & `.env` Hygiene in Subagents

- [`wdd-execute-task`](./skills/wdd-execute-task/SKILL.md) and [`wdd-review-task`](./skills/wdd-review-task/SKILL.md) enforce strict pre-commit boundary audits so temporary bootstrap `.env` files, API keys, tokens, SQLite scratch databases, and `.wdd/` metadata directories are never staged, committed, or pushed.
- Prompt templates and skill instructions MUST never instruct agents to bypass permission gates, exfiltrate environment variables, or weaken repository secret protections.

### 4. Human-Gated Merges & Repository Visibility Protection

- WDD enforces a hard invariant that **agents never merge automatically into `main`**—both `wdd-run-epic` and standalone `wdd-review-task` stop at Pull Request creation so a human reviews and merges production changes.
- Agents are strictly forbidden from altering GitHub repository visibility settings (`public`/`private`) or branch protection rules without explicit human execution.
