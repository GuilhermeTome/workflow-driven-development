---
name: wdd-execute-task
description: >-
  Implement a single GitHub Task issue inside an isolated subagent git worktree
  with fresh dependency installation, strict parallel file-boundary enforcement,
  full programmatic verification, and clean Conventional Commits. Use when
  dispatched as a task subagent by wdd-run-epic or when executing a standalone
  GitHub task issue in isolation.
---

# WDD — Execute Task (`wdd-execute-task`)

Carry out a single GitHub Task issue end-to-end inside an isolated `git worktree` (`task/<task-id>-<slug>`), leaving verified, formatted commits ready for [`wdd-review-task`](../wdd-review-task/SKILL.md).

## Non-Negotiable Subagent Contract

1. **Worktree Confinement:** Operate strictly inside your assigned `<task-worktree>` on branch `task/<task-id>-<slug>`. Never `cd` into or edit the main checkout or the `epic/*` worktree.
2. **Fresh Dependency Isolation (Zero Symlinks):** Never symlink `vendor/`, `node_modules/`, `.venv/`, or build caches from another checkout—parallel subagents running code generators or autoloaders will race and corrupt shared state. Always install dependencies cleanly inside `<task-worktree>`.
3. **Wave File Isolation:** Never edit, format, or rename any file reserved for parallel tasks in the same wave. If completing your task genuinely requires changing a locked file or an undefined shared contract, stop without dirtying locked files and return `Status: BLOCKED`.
4. **No Nested Subagents:** Execute the task yourself. Never spawn subagents, helper workers, or sub-reviewers—review is performed centrally by the Coordinator via `wdd-review-task`.
5. **Commit Only — Never Merge or Open Intermediate PRs:** Create clean Conventional Commit(s) on `task/<task-id>-<slug>`. Never merge into `epic/*` or `main`, never delete branches, and never open a GitHub PR yourself (`wdd-review-task` owns merging into the epic branch or opening a standalone PR).

## Step-by-Step Execution

### 1. Verify Worktree & Branch Isolation

1. If dispatched by `wdd-run-epic`, `cd` into the assigned `<task-worktree>` and verify:
   ```bash
   pwd
   git branch --show-current   # must be task/<task-id>-<slug>
   git status --short          # must be clean
   ```
2. If invoked **standalone** by a user without a pre-created worktree, create one first from `origin/main` using [`wdd-run-epic/scripts/wdd-worktree.sh`](../wdd-run-epic/scripts/wdd-worktree.sh):
   ```bash
   git fetch origin --prune
   bash <wdd-run-epic-dir>/scripts/wdd-worktree.sh task-init "." "<task-id>" "<slug>" "origin/main"
   ```
   Then operate exclusively inside the printed `TASK_WORKTREE`.

### 2. Read the Task Issue & Repository Rules

1. Read the complete GitHub issue:
   ```bash
   gh issue view <task-id> -R <owner/repo>
   ```
2. Read the target repository's `AGENTS.md` and/or `CLAUDE.md` from `<task-worktree>`.
   - Note every file-size / anti-monolith ceiling (e.g., thin controllers, max component/service lines), architecture rule, and required formatter/linter.
   - Activate any domain-specific skills mandated by the repository for the layers this task touches.
3. Inspect the existing sibling files around your target paths so naming, types, imports, error handling, and test styles match the codebase.

### 3. Bootstrap Clean Dependencies in `<task-worktree>`

Install dependencies from scratch inside `<task-worktree>` before running generators or tests. Consult [references/bootstrap-and-verify.md](./references/bootstrap-and-verify.md) for stack-specific commands (PHP/Laravel, Node/TS/Vue, Go, Python, Rust). Ensure local untracked bootstrap files (such as a temporary `.env` or test SQLite database) remain untracked and are removed or git-ignored before committing.

### 4. Implement & Write Automated Tests

1. Implement every requirement, schema, edge case, and UI/API behavior specified in `#<task-id>`.
2. Keep modules small and single-responsibility: if touching a large legacy file near or above the repository's line limit, extract the new logic into a focused Action, Service, DTO, composable, or Partial component within your allowed scope.
3. Write or update all mandatory automated tests listed in `#<task-id>` (covering happy paths, validation/authorization boundaries, idempotency, and edge cases).

### 5. Programmatic Verification & Formatting Gate

Before staging anything, run all verification checks inside `<task-worktree>`:

1. **Targeted & Affected Tests:** Run the new/updated test suite plus neighboring tests in the touched domain until 100% green.
2. **Code Formatters:** Run the repository's mandatory formatters on your modified files only (never run a repo-wide reformat that touches sibling tasks' files!).
3. **Static Analysis / Lint / Build:** Run typechecks, linters (scoped to changed files when baseline debt exists), and production build if frontend/compiled assets were altered. Confirm zero new errors were introduced.
4. **File Boundary Audit:** Run `git status --short` and `git diff --name-only` and verify:
   - Zero forbidden sibling-wave files were modified;
   - Zero temporary `.env`, debug logs, or scratch files are staged;
   - Every created/modified file complies with the repository's line-count guardrails (`wc -l <files>`).

### 6. Commit Cleanly on `task/<task-id>-<slug>`

Stage only task-relevant files and create one or more logical Conventional Commits matching the repository's language and referencing `(#<task-id>)`:

```bash
git add <explicit-file-paths>
git commit -m "<type>(<scope>): <concise summary> (#<task-id>)"
```

Verify `git status --short` has zero uncommitted tracked modifications (clean worktree is required for `wdd-worktree.sh task-merge-and-clean`). Clean up any temporary untracked `.env` files created solely for test bootstrap if `.gitignore` does not already ignore them.

### 7. Return Structured Completion Report

Return **only** this concise report to the Coordinator (keep raw logs out of the Coordinator's context unless reporting a failure):

```markdown
## Task Report — #<task-id>

- **Status:** `DONE` | `DONE_WITH_CONCERNS` | `BLOCKED`
- **Worktree:** `<abs-path-to-task-worktree>`
- **Branch:** `task/<task-id>-<slug>`
- **Commit(s):** `<short-sha> <commit subject>`
- **Files Changed (with line counts):**
  - `<path/to/file>` (`<N> lines`, created/modified)
- **Verification:**
  - Tests: `<command>` → `<X passed, Y assertions>`
  - Formatting / Lint: `<command>` → `clean`
  - Build / Types: `<command>` → `<result>`
- **Notes / Concerns:** `<intentional deviations, baseline debt notes, or exact blocker details; otherwise "None">`
```
