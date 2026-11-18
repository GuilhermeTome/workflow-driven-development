---
name: wdd-run-epic
description: >-
  Execute and coordinate a GitHub Epic end-to-end across parallel task waves
  using isolated git worktrees and native subagents, merging approved tasks into
  a dedicated epic branch and delivering a consolidated PR against main without
  auto-merging. Use when starting, resuming, or supervising an Epic in
  Workflow-Driven Development.
---

# WDD — Run Epic (`wdd-run-epic`)

Orchestrate a GitHub Epic wave-by-wave from start to finish: isolate the epic in a dedicated `epic/<id>-<slug>` git worktree, dispatch parallel native subagents per wave in temporary `task/<id>-<slug>` worktrees ([`wdd-execute-task`](../wdd-execute-task/SKILL.md)), review and merge each task directly ([`wdd-review-task`](../wdd-review-task/SKILL.md)), update GitHub progress while keeping issues open, and finish by opening **one consolidated Pull Request per touched repository** targeting `main`—**never merging into `main` automatically**.

## Core Coordinator Rules

1. **Continuous Execution:** Do NOT pause between waves to ask "Should I continue?". Execute all waves continuously until the final PR(s) are opened or one of the four stop gates triggers:
   - An irreversible or destructive external operation;
   - Missing credentials/secrets or a security/permission boundary;
   - A task failing review after 3 fix rounds;
   - A contradictory specification where every path forward is guesswork.
2. **Never Merge into `main`:** Wave merges happen **exclusively** into `epic/<id>-<slug>` (preventing partial production deployments). Delivery to `main` is **always** a Pull Request URL handed to the user.
3. **Native Subagents + Git Worktrees (Harness-Agnostic):**
   - Use the current agent harness's native subagent tool (`Task` in Claude Code, `invoke_subagent` in Antigravity, etc.) to launch all tasks of the active wave in parallel in a single turn.
   - Give every subagent its own dedicated `<parent>/.worktrees/<repo>/task-<id>-<slug>` directory created via [scripts/wdd-worktree.sh](./scripts/wdd-worktree.sh). Never run two subagents in the same directory, and never touch the user's primary `main` checkout.
4. **Issues Stay Open Until `main` Merge:** Update Epic checkboxes and post concise wave-completion comments as waves land on `epic/<id>-<slug>`, but **do NOT close** the Epic or child Task issues manually—let GitHub close them automatically via `Closes #<id>` when the human merges the final PR into `main`.

## Step-by-Step Workflow

### 1. Pre-Flight Inspection & Recovery Check

1. Read the Epic issue (`gh issue view <epic-id> -R <primary-owner/repo>`) and fetch every child Task issue listed in its Wave DAG across all touched repositories.
2. Verify the Wave DAG and File Isolation Matrix: confirm that within each `(Wave, Repo)` pair, no two tasks edit the same file. If the Epic missed an obvious file collision, record a coordinator ruling (`Ruling: sequence #<B> after #<A> due to shared <file>`) in the ledger and move `#<B>` to the next wave before dispatching.
3. For every repository touched by the Epic, initialize (or attach to) its dedicated Epic worktree and target branch using the helper script:
   ```bash
   bash <skill-dir>/scripts/wdd-worktree.sh epic-init "<repo-path>" "<epic-id>" "<slug>" "main"
   ```
   This sets up `<parent>/.worktrees/<repo>/epic-<epic-id>-<slug>` on branch `epic/<epic-id>-<slug>`, pushes it to `origin`, and prepares `<epic-worktree>/.wdd/` (excluded via `.git/info/exclude` so `.gitignore` is never dirtied).
4. **Crash / Compaction Recovery:** Check `<epic-worktree>/.wdd/state.md` and `git -C "<epic-worktree>" log --oneline origin/main..HEAD`.
   - Trust `git log` + `.wdd/state.md` over conversation memory.
   - If earlier waves or tasks are already merged into `epic/<epic-id>-<slug>`, mark them complete in `.wdd/state.md` and resume from the first incomplete task/wave—never re-dispatch already merged tasks.

### 2. Initialize / Maintain the Local Ledger (`.wdd/state.md`)

Maintain `<epic-worktree>/.wdd/state.md` throughout execution:

```markdown
# WDD Epic Ledger — #<epic-id> (`epic/<epic-id>-<slug>`)

- Primary Repo: `<owner/repo>`
- Epic Branch: `epic/<epic-id>-<slug>`
- Epic Worktree: `<abs-path>`

## Waves
- [ ] Wave 1: #<t1>, #<t2>
- [ ] Wave 2: #<t3>

## Task Log & Rulings
```

### 3. Execute Waves Sequentially (`Wave 1` → `Wave K`), Parallel Within Each Wave

For the current `Wave N`:

#### 3a. Create Isolated Task Worktrees

For each incomplete task `#<task-id>` in `Wave N`, create its isolated worktree branched off the **current HEAD** of `epic/<epic-id>-<slug>` in that task's repository:

```bash
bash <skill-dir>/scripts/wdd-worktree.sh task-init \
  "<repo-path>" "<task-id>" "<task-slug>" "epic/<epic-id>-<slug>"
```

#### 3b. Dispatch All `Wave N` Subagents in Parallel

In **one single turn**, launch one native subagent per `Wave N` task using [references/subagent-dispatch-prompt.md](./references/subagent-dispatch-prompt.md):

- Instruct each subagent to read and follow [`wdd-execute-task`](../wdd-execute-task/SKILL.md).
- Pass only what it needs: repository `owner/repo`, `<task-id>`, `<task-worktree>`, `task/<task-id>-<task-slug>`, `epic/<epic-id>-<slug>`, the sibling files reserved in `Wave N`, and the path to `wdd-execute-task/SKILL.md`. Do NOT paste session history into subagent prompts.

#### 3c. Review, Fix & Merge Each Task (`wdd-review-task`)

As `Wave N` subagents report back, read and execute [`wdd-review-task`](../wdd-review-task/SKILL.md) for every task in `Wave N`:

- Review `git diff epic/<epic-id>-<slug>...task/<task-id>-<task-slug>` directly as Coordinator (no reviewer subagent).
- Dispatch up to 3 scoped fix rounds in the existing `<task-worktree>` if any spec, file-isolation, test, or `AGENTS.md` violation exists.
- Once approved, merge `task/<task-id>-<task-slug>` cleanly into `epic/<epic-id>-<slug>` and immediately delete `<task-worktree>` and temporary branch `task/<task-id>-<task-slug>` via `wdd-worktree.sh task-merge-and-clean`.

#### 3d. Sync `Wave N` & Update GitHub Progress

Only after **every** task in `Wave N` is merged into `epic/<epic-id>-<slug>` and its temporary worktree/branch is cleaned up:

1. Push the updated epic branch:
   ```bash
   git -C "<epic-worktree>" push origin "epic/<epic-id>-<slug>"
   ```
2. Update `<epic-worktree>/.wdd/state.md` marking `Wave N` complete with merge commit SHAs.
3. Update progress on GitHub (matching the Epic's language, keeping Epic and Tasks **OPEN**):
   - Check off `- [x] Wave N ...` in the Epic body (`gh issue edit <epic-id> --body-file ...`), and
   - Post a concise wave-completion comment on `#<epic-id>` listing the `Wave N` tasks, commit SHAs on `epic/<epic-id>-<slug>`, and test counts.
4. Immediately proceed to `Wave N+1` (whose task worktrees will now branch from the updated `epic/<epic-id>-<slug>` containing `Wave N`).

### 4. Whole-Epic Integration Gate (Before Opening Final PR)

After the final wave (`Wave K`) merges into `epic/<epic-id>-<slug>`, run an integration check inside each touched repository's `<epic-worktree>`:

1. Install clean dependencies in `<epic-worktree>` (following [`wdd-execute-task/references/bootstrap-and-verify.md`](../wdd-execute-task/references/bootstrap-and-verify.md)) so cross-wave interactions are tested together.
2. Run the affected test suites, production asset build (if frontend changed), and formatter/linter checks across `git diff --name-only origin/main...HEAD`.
3. If cross-wave integration broke a test or build:
   - Create a short-lived fix worktree (`task-init "<repo-path>" "<epic-id>-intfix" "integration-fix" "epic/<epic-id>-<slug>"`), dispatch a subagent to fix the exact regression, review and merge it via `wdd-review-task`, and push `epic/<epic-id>-<slug>`.

### 5. Open Consolidated PR(s) Against `main` & Deliver Links

1. For each touched repository, open **one consolidated Pull Request** from `epic/<epic-id>-<slug>` into `main` using [references/final-pr-template.md](./references/final-pr-template.md):
   - **Primary repo PR body MUST include:** `Closes #<epic-id>` AND `Closes #<task-id>` for every task in that repository.
   - **Secondary repo PR body (if cross-repo) MUST include:** `Part of <primary-owner/repo>#<epic-id>`, `Closes #<task-id>` for every task in that secondary repository, and the **explicit merge/deploy order** across repositories.
2. Post a final summary comment on the Epic issue (`#<epic-id>`) with the Wave summary table, verification totals, any conscious manual follow-ups (e.g., visual browser QA), and the opened PR URL(s). Leave the Epic issue **OPEN**.
3. **NEVER run `gh pr merge` on `main`.** Present the PR URL(s) and concise executive summary to the user.
