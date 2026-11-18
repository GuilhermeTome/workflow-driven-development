# Contributing to Workflow-Driven Development

Thank you for your interest in contributing to **Workflow-Driven Development (WDD)**! Whether you are refining skill instructions, expanding stack references, hardening git worktree scripts, or fixing documentation, your contributions help keep parallel agentic development predictable and safe.

By participating in this project, you agree to abide by our [Code of Conduct](./CODE_OF_CONDUCT.md). Please also review [`AGENTS.md`](./AGENTS.md) if you are contributing with the assistance of an AI coding agent.

---

## Ways to Contribute

### 1. Dogfooding WDD (Recommended)

Because WDD is built to coordinate structured development, we encourage contributors to dogfood the workflow itself:

- **Single, focused improvement:**
  1. Use [`wdd-create-task`](./skills/wdd-create-task/SKILL.md) (or open a clear GitHub Issue) defining the scope, allowed files, and verification steps.
  2. Execute the task inside an isolated git worktree using [`wdd-execute-task`](./skills/wdd-execute-task/SKILL.md) on a `task/<id>-<slug>` branch.
  3. Review the diff and open a Pull Request targeting `main` using [`wdd-review-task`](./skills/wdd-review-task/SKILL.md).
- **Multi-task or cross-cutting initiative:**
  1. Plan and slice the initiative into zero-overlap waves with [`wdd-create-epic`](./skills/wdd-create-epic/SKILL.md).
  2. Coordinate parallel task execution and consolidated PR delivery with [`wdd-run-epic`](./skills/wdd-run-epic/SKILL.md).
- **Standard GitHub Flow:**
  - You are always welcome to fork the repository, create a descriptive feature branch (`feat/...`, `fix/...`, `docs/...`), verify your changes locally, and open a Pull Request against `main`.

---

## Adding or Updating a Skill

All skills live under `skills/<skill-name>/` and follow the open Agent Skills structure.

### Directory Layout & Progressive Disclosure

```text
skills/wdd-<name>/
├── SKILL.md          # Core workflow & rules (< 200 lines, mandatory)
├── references/       # Templates, prompt payloads, stack guides (loaded on demand)
└── scripts/          # Deterministic Bash helpers (optional, executable)
```

1. **YAML Frontmatter:** Every `SKILL.md` must begin with YAML frontmatter:
   ```yaml
   ---
   name: wdd-example-skill
   description: >-
     Concise third-person summary of what this skill accomplishes. Use when the
     user asks to <explicit trigger conditions and contexts>.
   ---
   ```
   - `name` must exactly match the directory name (`wdd-example-skill`).
   - `description` must be written in the third person and specify **both** capability and trigger conditions.
2. **Concise `SKILL.md` (`< 200` lines):** Keep core step-by-step instructions tight so agents do not waste context window tokens. Move verbose Markdown templates, subagent prompts, and stack-specific commands into `references/` and link to them via relative paths (`./references/...`).
3. **Harness-Agnostic Design:** Avoid locking skills to a single vendor, CLI, or editor. Formulate instructions around universal capabilities (subagent dispatch, isolated `git worktree` paths, `git`, and `gh` CLI) so the pack works seamlessly across Claude Code, Codex CLI, Antigravity / Gemini CLI, Cursor, and custom orchestrators.
4. **Stack-Agnostic Core:** Keep core orchestration logic independent of any single programming language or web framework. Put language-specific bootstrap and verification recipes (Node/TypeScript, PHP/Laravel, Go, Python, Rust, etc.) in `references/bootstrap-and-verify.md`.
5. **Shell Scripts:** Any helper script under `skills/*/scripts/`, `scripts/`, or `tests/` must target Bash `>= 4.0`, start with `#!/usr/bin/env bash` and `set -euo pipefail`, quote expansions defensively, and require zero Node.js or Python runtime dependencies.

---

## Testing Changes Locally

Before opening a Pull Request, run the verification checks from the repository root:

1. **Validate shell script syntax (`bash -n`):**
   ```bash
   bash -n skills/wdd-run-epic/scripts/wdd-worktree.sh
   ```
   *(Also run `bash -n` on `scripts/install.sh` and `tests/validate-pack.sh` when modifying scripts.)*

2. **Run the automated skill-pack test suite:**
   ```bash
   bash tests/validate-pack.sh
   ```
   The validation suite verifies YAML frontmatter, `SKILL.md` and `AGENTS.md` line ceilings (`< 200` lines), relative Markdown link integrity, shell script syntax, and worktree/installer behavior.

3. **Check Markdown links and line counts manually (quick check):**
   ```bash
   wc -l AGENTS.md skills/wdd-*/SKILL.md
   ```

---

## Commit & Pull Request Conventions

### Conventional Commits

Write all commit messages and Pull Request titles in **English** using [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):

- `feat(<scope>): ...` — new skill, script capability, or supported harness
- `fix(<scope>): ...` — bug fix in worktree orchestration, installer, or skill logic
- `docs(<scope>): ...` — documentation, reference templates, or guide updates
- `refactor(<scope>): ...` — structural cleanup without changing external behavior
- `test(<scope>): ...` — new or updated checks in `tests/validate-pack.sh`
- `chore(<scope>): ...` — CI workflows, issue templates, or maintenance

Examples:
- `feat(install): add multi-harness symlink installer (#4)`
- `docs(manual): document wave partitioning invariants (#3)`
- `fix(worktree): guard against dirty task worktrees before merge (#12)`

### Pull Request Checklist

Before requesting a review, confirm that:

- [ ] All text, comments, and commit messages are written in clear **English**.
- [ ] Every `SKILL.md` and `AGENTS.md` remains strictly under **200 lines**.
- [ ] All relative Markdown links resolve to existing files in the repository.
- [ ] `bash -n` passes on all `.sh` scripts and `bash tests/validate-pack.sh` exits `0`.
- [ ] No `.env` files, credentials, or `.wdd/` scratch directories are staged.
- [ ] `CHANGELOG.md` is updated under `[Unreleased]` for user-visible changes.

---

## Security & Licensing

- **Security Vulnerabilities:** Do **not** open public issues for security bugs. Follow [`SECURITY.md`](./SECURITY.md) to report vulnerabilities privately.
- **License:** By contributing to this repository, you agree that your contributions will be licensed under the [MIT License](./LICENSE).
