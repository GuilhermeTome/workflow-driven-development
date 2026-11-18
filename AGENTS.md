# AGENTS.md — Canonical Instructions for AI Coding Agents

This file defines binding rules for any AI coding agent reading, modifying, or extending `GuilhermeTome/workflow-driven-development`. Follow every rule below without exception.

## 1. Repository Purpose & Layout

**Workflow-Driven Development (WDD)** is a portable, harness-agnostic, stack-agnostic multi-skill pack that coordinates software delivery through GitHub Epics, zero-conflict parallel Task Waves, isolated `git worktree` subagents, and human-gated single-PR delivery.

```text
workflow-driven-development/
├── skills/                         # Distributable Agent Skills (core product)
│   ├── wdd-create-epic/            # Architecture discovery, wave DAG, Epic + batch Task creation
│   ├── wdd-create-task/            # Self-contained GitHub Task authoring (wave or standalone)
│   ├── wdd-run-epic/               # Wave orchestrator + scripts/wdd-worktree.sh helper
│   ├── wdd-execute-task/           # Isolated subagent task execution & verification
│   └── wdd-review-task/            # Coordinator diff review gate, fix loop, & merge/clean
├── docs/                           # User manual, core principles, and installation guides
├── scripts/                        # Multi-harness installer / uninstaller utilities (`scripts/install.sh`)
└── tests/                          # Automated pack validation suite (`tests/validate-pack.sh`)
```

Core skills:
- [`wdd-create-epic`](./skills/wdd-create-epic/SKILL.md)
- [`wdd-create-task`](./skills/wdd-create-task/SKILL.md)
- [`wdd-run-epic`](./skills/wdd-run-epic/SKILL.md) (includes [`wdd-worktree.sh`](./skills/wdd-run-epic/scripts/wdd-worktree.sh))
- [`wdd-execute-task`](./skills/wdd-execute-task/SKILL.md)
- [`wdd-review-task`](./skills/wdd-review-task/SKILL.md)

## 2. Language Policy

- **100% English** across this repository: all Markdown files, skill instructions, references, shell scripts, code comments, commit messages, GitHub issues, and pull requests targeting `workflow-driven-development` MUST be written in clear, idiomatic English.
- *(Note: While WDD skills adapt to a target project's language when used externally, this repository itself is strictly English-only.)*

## 3. Skill Authoring Rules

1. **Directory & Entrypoint:** Every skill lives in `skills/<skill-name>/` and MUST contain a `SKILL.md` file.
2. **YAML Frontmatter:** Every `SKILL.md` MUST open with valid YAML frontmatter containing:
   - `name`: Must match the parent directory name `<skill-name>` exactly (`kebab-case`, prefixed with `wdd-`).
   - `description`: Written in the **third person**, concisely stating both **what** the skill does and **when** an agent should trigger it.
3. **Progressive Disclosure & Size Ceiling:**
   - Keep every `SKILL.md` concise and actionable (**strictly `< 200` lines**).
   - Move detailed issue/PR templates, prompt templates, stack matrices, and schemas into `skills/<skill-name>/references/`.
   - Place deterministic automation helpers in `skills/<skill-name>/scripts/`.
4. **Link Integrity:** Every relative Markdown link (`./references/...`, `./scripts/...`, `../wdd-.../SKILL.md`) MUST resolve to an existing file on disk.
5. **Harness & Stack Agnosticism:** Never hardcode vendor-specific paths, proprietary IDE commands, or single-framework assumptions inside core skill instructions. Keep stack-specific examples modular inside `references/`.

## 4. Shell Script Standards

All shell scripts in `skills/*/scripts/`, `scripts/`, and `tests/` MUST adhere to:

- **Target Shell:** Bash `>= 4.0` with `#!/usr/bin/env bash` on line 1.
- **Strict Mode:** Enable `set -euo pipefail` immediately after the shebang.
- **Zero Heavy Runtime Dependencies:** Rely only on standard POSIX utilities, `bash`, `git`, and `gh` (when interacting with GitHub). Do **not** require Node.js, Python, Ruby, or external packages at runtime.
- **Defensive Quoting & Path Safety:** Quote all variable expansions (`"$var"`), sanitize user/branch slugs (`sanitize_slug`), validate argument counts, and ensure worktree cleanup commands only operate inside expected worktree paths.
- **Syntax Gate:** Every script MUST pass `bash -n <script>` with zero warnings or errors.

## 5. Verification & Git Rules

1. **Mandatory Verification Before Committing:**
   - Run `bash -n` on every created or modified `.sh` file (e.g., `bash -n skills/wdd-run-epic/scripts/wdd-worktree.sh`).
   - Run `bash tests/validate-pack.sh` whenever `tests/validate-pack.sh` is present in the checkout to validate frontmatter, line limits, relative links, and script syntax.
2. **Conventional Commits:** Format all commit titles and PR titles as `<type>(<scope>): <concise summary>` (`feat`, `fix`, `docs`, `refactor`, `test`, `chore`), referencing the task/issue number (`(#<id>)`) when applicable.
3. **Never Auto-Merge into `main`:** Agents MUST deliver changes via a branch/PR and leave merging into `main` to a human maintainer.
4. **Never Stage Secrets or Scratch State:** Never commit `.env` files, tokens, `.wdd/` scratch directories, or temporary test artifacts.
5. **Repository Visibility Lock:** **NEVER change the GitHub repository visibility** (e.g., `gh repo edit --visibility ...`) under any circumstances without explicit manual execution by the human repository owner.

## 6. Related Governance Documents

- Contributor workflow: [`CONTRIBUTING.md`](./CONTRIBUTING.md)
- Security policy & vulnerability reporting: [`SECURITY.md`](./SECURITY.md)
- Community standards: [`CODE_OF_CONDUCT.md`](./CODE_OF_CONDUCT.md)
- Release history: [`CHANGELOG.md`](./CHANGELOG.md)
- License: [`LICENSE`](./LICENSE)
