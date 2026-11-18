# Scoped Fix Subagent Prompt Template (Rounds 1–3)

Use this prompt when `wdd-review-task` finds defects on `task/<task-id>-<slug>`. Dependencies are already installed inside `<task-worktree>`—do NOT re-install them unless `composer.json` / `package.json` changed.

```text
You are executing Fix Round <R>/3 for Task #<task-id> in Workflow-Driven Development.

Assignment metadata:
- Repository: `<owner/repo>`
- Task Issue: `#<task-id>` (`gh issue view <task-id> -R <owner/repo>`)
- Existing Worktree (dependencies already installed): `<abs-path-to-task-worktree>`
- Branch: `task/<task-id>-<slug>`
- Base Branch for Diff Check: `<epic/<epic-id>-<slug> OR origin/main>`
- Parallel Sibling Files Forbidden: `<list or "none">`

Coordinator review findings to resolve (ALL items are mandatory):
1. `<path/to/file>:<line>` — <exact defect, spec gap, missing test, or AGENTS.md rule violation + expected fix>
2. `<path/to/file>:<line>` — <exact defect + expected fix>

Instructions:
1. Operate strictly inside `<abs-path-to-task-worktree>` on branch `task/<task-id>-<slug>`.
2. Address every finding above without introducing regressions or touching forbidden sibling files (if a forbidden file was accidentally modified earlier, restore it via `git checkout <base-branch> -- <forbidden-file>`).
3. Re-run targeted + affected automated tests, code formatters, and linters/builds on modified files until 100% clean.
4. Commit your fixes cleanly on `task/<task-id>-<slug>` (`fix(<scope>): address review findings (#<task-id>)`) and confirm `git status --short` has zero uncommitted tracked modifications. Do NOT merge, push, or open a PR.
5. Return a concise fix report listing: commit SHA, how each numbered finding was resolved, and updated test/formatter output.
```
