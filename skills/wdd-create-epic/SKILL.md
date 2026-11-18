---
name: wdd-create-epic
description: >-
  Design, partition, and publish a GitHub Epic issue and all of its wave-ordered
  child Task issues for parallel subagent execution. Use when the user asks to
  create, slice, or plan an epic and its GitHub issues, break a feature/refactor
  into waves of tasks, or prepare a multi-task / cross-repo initiative for
  Workflow-Driven Development.
---

# WDD — Create Epic (`wdd-create-epic`)

Author a GitHub Epic issue that acts as both the **binding architectural specification** and the **flight manual** for [`wdd-run-epic`](../wdd-run-epic/SKILL.md), then batch-create all child Task issues following [`wdd-create-task`](../wdd-create-task/SKILL.md) and backfill their real issue numbers into the Epic.

## Language & Naming Rule

- Keep all skill reasoning systematic, but write the **GitHub Epic body, Task bodies, and comments in the language used by the user / repository's existing issues** (e.g., Portuguese in PT-BR repositories, English in EN repositories).
- Always use **Conventional Commit prefixes** in issue titles: `epic(<scope>): <concise summary>`.

## Step-by-Step Workflow

### 1. Grounded Codebase Discovery (Read-Only)

Never slice an epic from assumptions or unverified file names.

1. If a knowledge-graph MCP (such as `graphify`) is configured in the environment, query it first to locate modules, symbols, and cross-repository touchpoints.
2. When multiple subsystems, screens, or sibling repositories are involved, dispatch **parallel read-only subagents** to inventory:
   - Exact file paths, existing reusable components/services/actions, and line counts.
   - Repository rules in `AGENTS.md` / `CLAUDE.md` (modularity/line-count ceilings, test frameworks, formatters, baseline lint/type debt).
   - Cross-repository boundaries (e.g., backend API repo vs. frontend/funnel repo) and git remotes (`gh repo view --json nameWithOwner`).
3. If critical product or architectural ambiguities remain unresolved, clarify them with the user before opening GitHub issues. Once resolved, freeze them as explicit rules in the Epic.

### 2. Freeze Contracts & Partition into Zero-Conflict Waves

Design the Directed Acyclic Graph (DAG) of child tasks (`Wave 1`, `Wave 2`, ..., `Wave K`):

1. **Freeze Shared Contracts Upfront:** Any JSON payload, HTTP route/header, DB column, DTO, or UI token shared between tasks (or across repositories) must be specified verbatim in the Epic and copied into the relevant Task issues so no subagent ever guesses an interface.
2. **Enforce the Zero File-Overlap Invariant:**
   - Within the **same wave and same repository**, **no two tasks may create or edit the same file** (including route files, shared enums, barrel exports, or global stylesheets).
   - If Task A and Task B both need to modify `routes/web.php` or `User.php`, choose one of three resolutions before creating issues:
     1. Move the shared model/contract change into an earlier foundational wave;
     2. Sequence Task B into the next wave (`Depends on: Task A`); or
     3. Consolidate the overlapping edits into one cohesive task (respecting repo file-size limits).
3. **Cross-Repository Epics:**
   - Host the Epic issue in the **primary repository** (usually the core backend/platform repo, or the current repo).
   - Child tasks may live in the primary repo (`#<id>`) or sibling repos (`<owner>/<repo>#<id>`).
   - Tasks in different repositories *may* run in parallel in the same wave once their shared API/JSON contract is frozen in both issue bodies.
   - Document the required **production merge/deploy order** across repositories (e.g., *"Merge & deploy backend PR first, then merge & deploy funnel PR"*).
4. **Verify Partition Table:** Construct the **File Isolation Matrix** mapping every `(Wave, Repo, Task)` to its exclusive list of created/modified files. Double-check that the intersection of file sets within every `(Wave, Repo)` pair is strictly empty (`∅`).

### 3. Publish the Epic Issue First (Obtain `#<epic-id>`)

1. Format the initial Epic body using [references/epic-issue-template.md](./references/epic-issue-template.md), placing temporary `<TBD>` markers in the `#Issue` column of the child-tasks table.
2. Check available labels in the primary repository (`gh label list --limit 100`) and include `epic` plus relevant domain labels (`backend`, `frontend`, `refactor`, `enhancement`, `tests`, etc.) only if they exist (create the `epic` label via `gh label create epic --color 5319e7` if missing).
3. Create the Epic issue via a temporary file (never inline complex markdown inside shell quotes):
   ```bash
   gh issue create -R <primary-owner/repo> \
     --title "epic(<scope>): <summary>" \
     --label "epic" \
     --body-file /tmp/wdd-epic-body.md
   ```
4. Capture the created `<epic-id>` and URL.

### 4. Batch-Create All Child Task Issues (`wdd-create-task`)

1. Read and follow [`wdd-create-task`](../wdd-create-task/SKILL.md) to author each child Task issue file (`/tmp/wdd-task-1.md`, `/tmp/wdd-task-2.md`, ...).
2. Every child Task issue MUST include:
   - Reference to the parent Epic (`#<epic-id>` if same repo, `<primary-owner/repo>#<epic-id>` if cross-repo).
   - Its assigned Wave number and upstream task dependencies (for Wave 2+, create Wave 1 issues first so Wave 2+ bodies can cite real `#<id>` numbers!).
   - Its exclusive **Allowed Files** list AND the **Parallel Wave Exclusion** warning listing sibling files in the same wave that it must NOT touch.
3. Create the issues wave-by-wave (parallel `gh issue create` calls within each wave are safe and fast) and record every returned `#<task-id>` and URL.

### 5. Backfill the Epic Issue with Real Task IDs

1. Replace all `<TBD>` placeholders in the Epic markdown file with the real `#<task-id>` (or `<owner>/<repo>#<task-id>`) references in:
   - The **Child Issues & Wave DAG** table;
   - The **Wave Execution Diagram**;
   - The **File Isolation Matrix**;
   - The **Epic Completion Checklist** (`[ ] Wave 1: #<id>, #<id> ...`).
2. Update the Epic issue on GitHub and clean up temporary markdown files:
   ```bash
   gh issue edit <epic-id> -R <primary-owner/repo> --body-file /tmp/wdd-epic-body.md
   rm -f /tmp/wdd-epic-body.md /tmp/wdd-task-*.md
   ```

### 6. Final Verification & Handoff

1. Run `gh issue view <epic-id> -R <primary-owner/repo>` to verify clean Markdown rendering, valid issue links, and zero leftover `<TBD>` placeholders.
2. Present a concise summary to the user containing:
   - Clickable link to the Epic issue;
   - Markdown table of Waves, Task `#ID`s, Repositories, and Dependencies;
   - Note that the Epic is ready to execute via `wdd-run-epic`.
