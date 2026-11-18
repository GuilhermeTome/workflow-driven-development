---
name: wdd-review-task
description: >-
  Coordinator quality gate that directly reviews a subagent's task diff against
  the GitHub Task issue and repository rules, dispatches up to 3 scoped fix
  rounds in the same task worktree if needed, and on approval either merges
  cleanly into the epic branch and deletes the temporary worktree/branch (Epic
  mode) or opens a PR against main without merging (Standalone mode). Use after
  wdd-execute-task completes.
---

# WDD — Review, Fix or Merge Task (`wdd-review-task`)

Act as the **Coordinator Reviewer** directly inspecting the finished `task/<task-id>-<slug>` branch—without spawning a separate reviewer subagent—and enforce a strict quality gate before either merging into `epic/<epic-id>-<slug>` (Epic Wave mode) or opening a Pull Request against `main` (Standalone Task mode).

## Core Review Rules

1. **Direct Coordinator Review (No Reviewer Subagent):** Read the git log and diff directly in the Coordinator turn. Never delegate review to an extra subagent, and never accept a subagent's self-report without inspecting the actual diff.
2. **Never Patch Code Inline as Coordinator:** If anything is missing, broken, out-of-bounds, or unformatted, dispatch a scoped fix subagent inside the existing `<task-worktree>` (up to 3 rounds). Keeping fixes inside the subagent preserves Coordinator context and re-runs tests in the isolated worktree.
3. **Never Merge into `main`:**
   - **Epic Wave mode (`target_branch = epic/<epic-id>-<slug>`):** Merge cleanly into `epic/<epic-id>-<slug>`, then immediately delete `<task-worktree>` and temporary branch `task/<task-id>-<slug>`.
   - **Standalone Task mode (`target_branch = main`):** Push `task/<task-id>-<slug>` to `origin`, open a PR targeting `main` (`Closes #<task-id>`), remove the local `<task-worktree>`, and return the PR URL—**never run `gh pr merge`**.

## Step-by-Step Review Workflow

### 1. Inspect the Task Branch Diff & Issue Spec

Determine `<base-ref>`:
- **Epic Wave mode:** `epic/<epic-id>-<slug>` (run git commands with `-C <epic-worktree>`)
- **Standalone Task mode:** `origin/main` (run git commands with `-C <repo-root>`)

Inspect the exact commit range and full diff:

```bash
gh issue view <task-id> -R <owner/repo>
git -C "<git-dir>" log --oneline "<base-ref>..task/<task-id>-<slug>"
git -C "<git-dir>" diff --stat "<base-ref>...task/<task-id>-<slug>"
git -C "<git-dir>" diff "<base-ref>...task/<task-id>-<slug>"
```

 Also check that `<task-worktree>` has zero uncommitted tracked changes (`git -C "<task-worktree>" status --short`).

### 2. Evaluate Across Three Mandatory Lenses

1. **Lens 1 — Spec & Contract Completeness:**
   - Every acceptance criterion, migration column, method signature, HTTP route/status, JSON payload, and UI state in `#<task-id>` is genuinely implemented.
   - Zero fake placeholders (e.g., buttons firing only a toast, stubbed returns, skipped edge cases).
   - Every mandatory test scenario in `#<task-id>` exists in the diff and asserts real behavior (not tautological mocks), and the subagent's report shows passing test execution.
2. **Lens 2 — Wave File Isolation & Diff Hygiene:**
   - Zero modifications to files reserved for parallel tasks in the same wave.
   - Zero stray files committed (`.env`, `.sqlite`, debug dumps, unrelated lockfile churn when dependencies did not change, or out-of-scope refactors).
3. **Lens 3 — Repository Rules (`AGENTS.md` / `CLAUDE.md`):**
   - File and method line-count limits respected (check line counts of touched files if near ceilings).
   - Required formatters and linters reported clean with zero new errors above baseline.
   - Security & correctness: authorization/tenancy checks, idempotency, transaction boundaries, and null/edge handling are sound.

### 3. Decision Gate

#### Path A — `CHANGES_REQUESTED` (Fix Loop: Max 3 Rounds)

Trigger whenever Lens 1, Lens 2, or Lens 3 uncovers any spec gap, bug, missing test, file-isolation violation, or `AGENTS.md` breach.

1. **Check Round Counter (`round = 1..3`):**
   - If `round > 3`: **Trip the circuit breaker.** Stop dispatching fix rounds for `#<task-id>`, preserve `<task-worktree>` for inspection, record the exact unresolved findings in `.wdd/state.md` (if in an Epic), and escalate to the user with a concise diagnosis and options.
2. **Dispatch Scoped Fix Subagent (`round <= 3`):**
   - Because `<task-worktree>` still exists with all dependencies already installed, dispatch (or resume) a native subagent inside `<task-worktree>` on branch `task/<task-id>-<slug>` using [references/fix-subagent-prompt.md](./references/fix-subagent-prompt.md).
   - **Subagent Model Selection:** Use the task's `Subagent Model` (**defaulting to `flash`**—or the harness's fast/flash tier—whenever unspecified during task planning) for Fix Rounds 1–2; if a `flash` subagent fails to converge after Round 2, you may escalate Round 3 to a higher reasoning tier (`pro` / `inherit`) before tripping the circuit breaker.
   - List every defect with exact `file:line` references and concrete acceptance expectations. If the subagent touched a forbidden sibling-wave file, instruct it to `git checkout <base-ref> -- <forbidden-file>` and solve the requirement within its allowed scope (or report `BLOCKED` if impossible).
3. When the fix subagent finishes, increment `round` and **re-run Step 1 & Step 2** over the full `<base-ref>...task/<task-id>-<slug>` range. Never skip re-review after a fix!

#### Path B — `APPROVED` in Epic Wave Mode (`target_branch = epic/<epic-id>-<slug>`)

When all three lenses pass cleanly inside an Epic wave:

1. Merge `task/<task-id>-<slug>` cleanly into `<epic-worktree>` and immediately remove both the temporary task worktree and temporary branch using [`wdd-run-epic/scripts/wdd-worktree.sh`](../wdd-run-epic/scripts/wdd-worktree.sh):
   ```bash
   bash <wdd-run-epic-dir>/scripts/wdd-worktree.sh task-merge-and-clean \
     "<epic-worktree>" \
     "<task-worktree>" \
     "task/<task-id>-<slug>" \
     "<wave-num>" \
     "<task-id>" \
     "<concise task title>"
   ```
2. *Unexpected Merge Conflict Fallback:* If `task-merge-and-clean` aborts due to an unforeseen git conflict with an earlier task merged in the same wave, dispatch a 1-round rebase subagent inside `<task-worktree>` (`git rebase epic/<epic-id>-<slug>`, re-run tests + formatters), re-verify the diff, and re-run `task-merge-and-clean`.
3. Record `Task #<task-id>: merged (<MERGED_COMMIT>, review clean after <R> fix rounds)` in `<epic-worktree>/.wdd/state.md` and return control to `wdd-run-epic`.

#### Path C — `APPROVED` in Standalone Task Mode (`target_branch = main`)

When `wdd-review-task` is used for a standalone Task issue (not part of an Epic):

1. **NEVER merge into `main`.**
2. Push the approved branch from `<task-worktree>` to `origin`:
   ```bash
   git -C "<task-worktree>" push -u origin "task/<task-id>-<slug>"
   ```
3. Open a Pull Request targeting `main` (matching the user's / repository's language and including `Closes #<task-id>`):
   ```bash
   gh pr create -R <owner/repo> \
     --base main \
     --head "task/<task-id>-<slug>" \
     --title "<commit-style title> (#<task-id>)" \
     --body-file /tmp/wdd-standalone-pr.md
   rm -f /tmp/wdd-standalone-pr.md
   ```
4. Clean up the local temporary worktree directory while preserving the pushed branch for the open PR:
   ```bash
   bash <wdd-run-epic-dir>/scripts/wdd-worktree.sh task-clean-worktree-only \
     "<repo-root>" "<task-worktree>"
   ```
5. Deliver the PR URL and concise verification summary to the user.
