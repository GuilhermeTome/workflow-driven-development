# Canonical GitHub Epic Issue Template

Adapt section headings and prose to the user's / repository's language (e.g., PT-BR or EN) while preserving the structural sections below.

```markdown
## Objective

<1–2 concise paragraphs explaining the current state/problem, the end-to-end target outcome, and affected repositories.>

---

## Approved Product & Architecture Decisions

| Axis / Domain | Frozen Rule / Contract |
| :--- | :--- |
| <Axis 1> | <Exact decision, schema, route, status code, or canonical component> |
| <Axis 2> | <Exact decision> |

### Out of Scope

- <Explicit item 1 that subagents must NOT change>
- <Explicit item 2 (e.g., unrelated global lint/typecheck baseline debt)>

---

## Child Issues & Wave DAG

### Repository: `<owner/repo>`

| Issue | Wave | Title | Depends On |
| :--- | :--- | :--- | :--- |
| #<id> | Wave 1 | `feat(<scope>): <title>` | — |
| #<id> | Wave 1 | `feat(<scope>): <title>` | — |
| #<id> | Wave 2 | `feat(<scope>): <title>` | #<id>, #<id> |

<!-- Include additional repository tables here if the Epic is cross-repo -->

---

## Wave Execution Plan & File Isolation Matrix

Tasks within each wave are surgically partitioned for **zero file overlap** and MUST be dispatched in parallel via `wdd-run-epic`. Each wave merges cleanly into `epic/<epic-id>-<slug>` before the next wave branches off it.

```text
Wave 1 (parallel):   #<id>  ∥  #<id>  ∥  #<id>
                              │
             [direct review + clean merge into epic/<epic-id>-<slug>]
                              ▼
Wave 2 (parallel):       #<id>  ∥  #<id>
                              │
             [direct review + clean merge into epic/<epic-id>-<slug>]
                              ▼
Final Delivery:   Integration check ──► Open consolidated PR (`epic/<epic-id>-<slug>` ──► `main`)
                  (NEVER merge into `main` automatically; deliver PR URL)
```

### File Isolation Matrix (Zero-Conflict Guarantee)

- **Wave 1 (`#<id> ∥ #<id>`):**
  - `#<id>` touches exclusively: `<path/to/fileA>`, `<path/to/fileB>`, `<tests/path/TestA>`.
  - `#<id>` touches exclusively: `<path/to/fileC>`, `<path/to/fileD>`, `<tests/path/TestB>`.
- **Wave 2 (`#<id>`):**
  - `#<id>` touches exclusively: `<path/to/fileE>`, `<tests/path/TestE>`.

<!-- If cross-repo, add a "Production Merge & Deploy Order" subsection specifying exact PR merge order -->

---

## Coordinator Execution Protocol (`wdd-run-epic`)

1. **Target Branch:** `epic/<epic-id>-<slug>` branched from `origin/main` in an isolated sibling git worktree (`<parent>/.worktrees/<repo>/epic-<epic-id>-<slug>`).
2. **Wave Dispatch:** Spawn one isolated subagent per task in the current wave (`task/<task-id>-<slug>` worktree) using `wdd-execute-task` with fresh dependency installation (no shared symlinks).
3. **Wave Gate (`wdd-review-task`):** Coordinator reviews `git diff epic/<epic-id>-<slug>...task/<task-id>-<slug>` directly (up to 3 fix rounds in the task worktree if needed), merges cleanly into `epic/<epic-id>-<slug>`, and immediately removes the temporary task worktree and `task/<task-id>-<slug>` branch.
4. **Progress & Final PR:** Keep Epic and Task issues **OPEN** during wave execution (update checkboxes and post concise wave-completion comments here). After the final wave passes integration checks, open **one consolidated PR per repo** against `main` containing `Closes #<epic-id>` and `Closes #<all-repo-task-ids>`, and deliver the PR link without merging.

---

## Epic Completion Criteria

- [ ] Wave 1 merged into `epic/<epic-id>-<slug>`: #<id>, #<id>
- [ ] Wave 2 merged into `epic/<epic-id>-<slug>`: #<id>
- [ ] Integrated test suite, build, and code formatters passing on `epic/<epic-id>-<slug>` with zero new lint/type errors
- [ ] Consolidated PR opened against `main` with `Closes` references for the Epic and all child Tasks
```
