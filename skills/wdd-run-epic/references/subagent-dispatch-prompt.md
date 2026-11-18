# Subagent Dispatch Prompt Template (`Wave N`)

Use this concise prompt when launching each parallel subagent in `Wave N`. Keep it lean—never paste accumulated history from prior waves.

```text
You are an isolated implementation subagent executing a single task in Workflow-Driven Development.

Read and strictly follow the `wdd-execute-task` skill first:
`<path-to-wdd-execute-task-SKILL.md>`

Assignment metadata:
- Repository: `<owner/repo>`
- Parent Epic: `#<epic-id>` (Wave <N>)
- Task Issue: `#<task-id>` (`gh issue view <task-id> -R <owner/repo>`)
- Assigned Isolated Worktree: `<abs-path-to-task-worktree>`
- Assigned Task Branch: `task/<task-id>-<slug>` (already branched from `epic/<epic-id>-<epic-slug>`)
- Parallel Sibling Files Forbidden in Wave <N>: `<comma-separated list of sibling files, or "none — sole task in wave">`

Mandatory rules:
1. Work ONLY inside `<abs-path-to-task-worktree>` on branch `task/<task-id>-<slug>`. Never cd into the main checkout or the epic worktree.
2. Install dependencies cleanly from scratch inside `<abs-path-to-task-worktree>` (no shared symlinks).
3. Read the repository's `AGENTS.md` / `CLAUDE.md` and activate any required domain skills before writing code.
4. Implement 100% of `#<task-id>`, write/update mandatory automated tests, and run tests + formatters + linters until clean.
5. Do NOT touch any file reserved for parallel Wave <N> tasks. Do NOT spawn nested subagents.
6. Create clean Conventional Commit(s) referencing `(#<task-id>)` on `task/<task-id>-<slug>`. Do NOT merge, do NOT push, and do NOT open a Pull Request—the coordinator will review your local branch diff and merge it into `epic/<epic-id>-<epic-slug>`.
7. Return the structured `wdd-execute-task` completion report (`Status`, `Branch & Commits`, `Files Changed + Line Counts`, `Verification Summary`, `Notes/Concerns`).
```
