# Workflow-Driven Development (WDD)

A multi-skill pack for coordinating software development through **GitHub Epics**, **zero-conflict parallel Task Waves**, **isolated `git worktree` subagents**, and **single-PR delivery**.

## Overview

Workflow-Driven Development turns complex features and refactors into deterministic, conflict-free parallel execution:

```text
1. Plan & Partition         wdd-create-epic  ──►  wdd-create-task (batch or standalone)
   (GitHub Issues)          Creates Epic #<E>     Creates self-contained Task #<T1..Tn>
                            + Wave DAG + File     with strict parallel file-exclusion rules
                            Isolation Matrix
                                    │
                                    ▼
2. Orchestrate Waves        wdd-run-epic
   (Isolated Worktrees)     Creates sibling worktree on branch `epic/<E>-<slug>`
                            Loops Wave 1 ──► Wave 2 ──► Wave K:
                                    │
                     ┌──────────────┼──────────────┐
                     ▼              ▼              ▼
3. Parallel Tasks    wdd-execute-task (in isolated `task/<Ti>-<slug>` worktrees)
   (Subagents)       Fresh dependency install (no shared symlinks) + tests + clean commits
                     └──────────────┼──────────────┘
                                    ▼
4. Review & Merge    wdd-review-task (Coordinator direct diff gate)
   (Per Task)        • Changes needed? Dispatch fix subagent in same worktree (max 3 rounds)
                     • Approved? Clean merge into `epic/<E>-<slug>` + delete `task/<Ti>-<slug>`
                       worktree & temporary branch
                                    │
                                    ▼
5. Deliver PR        Final integration check on `epic/<E>-<slug>`
   (Never auto-      Open 1 consolidated PR (`epic/<E>-<slug>` ──► `main`) with
    merge `main`)    `Closes #<E>` + `Closes #<T1..Tn>` and deliver PR link to the user
```

## Skills Included

| Skill | Role | Purpose |
| :--- | :--- | :--- |
| [`wdd-create-epic`](./skills/wdd-create-epic/SKILL.md) | Author / Architect | Map affected code, partition work into zero-overlap waves, publish the GitHub Epic issue, batch-create all child Task issues, and backfill real `#ID` links. Supports single-repo and cross-repo epics. |
| [`wdd-create-task`](./skills/wdd-create-task/SKILL.md) | Author / Architect | Write a 100% self-contained GitHub Task issue with concrete file boundaries, parallel-wave exclusion rules, prescriptive contracts, and mandatory tests. Usable in batch (from `wdd-create-epic`) or standalone. |
| [`wdd-run-epic`](./skills/wdd-run-epic/SKILL.md) | Coordinator | Run an Epic end-to-end across waves in a dedicated `epic/<id>-<slug>` git worktree, dispatching parallel native subagents per wave, updating GitHub progress while keeping issues open, and opening one consolidated PR per touched repo to `main`. |
| [`wdd-execute-task`](./skills/wdd-execute-task/SKILL.md) | Subagent Implementer | Implement a single Task issue inside an isolated `task/<id>-<slug>` git worktree with fresh dependency installation, strict adherence to repository `AGENTS.md`/`CLAUDE.md` rules, full verification, and clean commits. |
| [`wdd-review-task`](./skills/wdd-review-task/SKILL.md) | Coordinator Reviewer | Review a subagent's diff directly against the Task issue and repo rules, run up to 3 scoped fix rounds if needed, cleanly merge approved work into `epic/<id>-<slug>` while pruning temporary task worktrees/branches (or open a PR to `main` for standalone tasks). |

## Core Invariants

1. **Never Merge into `main` Automatically:** Both `wdd-run-epic` and standalone `wdd-review-task` always deliver a Pull Request URL targeting `main` and leave the merge decision to a human.
2. **Dedicated Epic Integration Branch (`epic/<id>-<slug>`):** Wave tasks merge cleanly into `epic/<id>-<slug>` between waves—preventing partial production deployments on `main` while giving Wave $N+1$ immediate access to Wave $N$'s code.
3. **Zero File Overlap Within a Wave:** Tasks scheduled in the same wave for the same repository must own disjoint sets of files. Shared primitives or contracts belong in an earlier wave.
4. **Full Worktree & Dependency Isolation:** Every Epic and Task runs in a sibling `git worktree` (`<parent>/.worktrees/<repo>/...`) with dependencies installed cleanly from scratch (never symlinked across parallel workers). Temporary task worktrees and branches are deleted immediately after merging into the epic branch.
5. **Issues Stay Open Until `main` Merge:** Wave progress is tracked via Epic checkboxes and wave-summary comments, while `Closes #<epic>` and `Closes #<task>` keywords in the final PR body close everything automatically only when merged into `main`.
6. **Language Adaptation:** All skill definitions are written in English; generated GitHub issues, comments, and PR descriptions match the user's conversation / repository language while preserving Conventional Commit prefixes (`epic(...)`, `feat(...)`, `fix(...)`, `refactor(...)`).

## Installation

### Via `skills` CLI

```bash
npx skills add GuilhermeTome/workflow-driven-development
```

### Via Local Symlinks (Multi-Harness)

```bash
for dir in ~/.agents/skills ~/.claude/skills ~/.gemini/config/skills; do
  mkdir -p "$dir"
  for skill in /path/to/workflow-driven-development/skills/wdd-*; do
    ln -sfn "$skill" "$dir/$(basename "$skill")"
  done
done
```
