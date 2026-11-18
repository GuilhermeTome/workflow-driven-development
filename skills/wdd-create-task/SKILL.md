---
name: wdd-create-task
description: >-
  Author a self-contained GitHub Task issue engineered for isolated subagent
  execution, either standalone or attached to an existing WDD Epic wave. Use
  when creating an implementation task issue on GitHub, adding a new task to an
  existing epic, or invoked in batch by wdd-create-epic.
---

# WDD — Create Task (`wdd-create-task`)

Write and publish a **100% self-contained GitHub Task issue** that an isolated subagent running [`wdd-execute-task`](../wdd-execute-task/SKILL.md) can execute from start to finish by reading `gh issue view <id>` alone—with zero reliance on chat history and zero file collisions with sibling tasks.

## Operating Modes

1. **Batch Mode (called from `wdd-create-epic`):** Author and publish each child task for a newly created Epic `#<epic-id>`.
2. **Append-to-Epic Mode:** Add one or more new tasks to an already open Epic `#<epic-id>`, validating wave dependencies and updating the Epic's Wave DAG and File Isolation Matrix afterward.
3. **Standalone Task Mode:** Create a single focused Task issue without a parent Epic (executed later via `wdd-execute-task` + `wdd-review-task` to produce a direct PR against `main`).

## Language & Title Convention

- Match the **user's conversation / repository issue language** (e.g., PT-BR or EN) for prose, headings, and checklists.
- Use **Conventional Commit format** for the issue title: `feat(<scope>): <summary>`, `fix(<scope>): <summary>`, `refactor(<scope>): <summary>`, or `chore(<scope>): <summary>`.

## Step-by-Step Workflow

### 1. Verify Exact Code Context Before Writing

Never publish a vague wish-list issue. Inspect the target repository first (using Graphify MCP when configured, plus targeted file reads):

1. Locate the exact files, classes, functions, database tables, routes, and existing tests affected by the task.
2. Check the repository's `AGENTS.md` / `CLAUDE.md` constraints:
   - File and method line-count limits (if adding to a legacy file over the repo ceiling, explicitly instruct the task to extract a focused collaborator/partial/composable rather than bloating the file inline).
   - Required test framework, code formatters, and known baseline debt (e.g., pre-existing typecheck/lint counts that must not grow).
3. **If attached to an Epic:** Read `gh issue view <epic-id>` (when appending to an existing epic) and verify **strict file disjointness** against every other task in the same wave and repository. If a file collision exists, place this task in a subsequent wave (`Depends on: #<conflicting-task>`) or adjust boundaries before creating the issue.

### 2. Draft the Self-Contained Task Body

Structure the issue body following [references/task-issue-template.md](./references/task-issue-template.md). Every Task issue MUST contain these seven elements:

1. **Parent Epic & Wave Header** *(omit only in Standalone mode)*: Link to `#<epic-id>` (or `<owner/repo>#<epic-id>`), assigned `Wave N`, and explicit `Depends on` list.
2. **Context & Concrete Blockers:** Cite the exact files/methods/lines and explain what currently fails, is missing, or violates canonical patterns.
3. **Prescriptive Implementation Scope:** Numbered subsections specifying:
   - Exact class/action/service/component names and method signatures;
   - Idempotent DB migration details (columns, types, indexes, SQLite/SQL compatibility if applicable);
   - Exact HTTP routes, status codes, headers, DTOs, and JSON request/response schemas;
   - UI states (loading, empty, error, dark/light tokens, accessibility attributes) when touching frontend code.
4. **File Ownership & Parallelism Guardrails:**
   - **Allowed Files (Create / Modify):** Explicit list of paths this task owns.
   - **Parallel Wave Exclusion Warning:** Callout box naming the files reserved for sibling tasks in the same wave that this subagent MUST NOT touch.
5. **Mandatory Automated Tests:** Exact test file path(s) to create/update and concrete behavioral scenarios (happy path, authorization/validation errors, edge cases, regression guards).
6. **Verification & Formatting Commands:** Exact test, formatter, linter, and build commands expected by the target repo.
7. **Acceptance Criteria & Out of Scope:** Checkable `[ ]` criteria and explicit boundaries.

### 3. Publish the Issue on GitHub

1. Check existing repository labels (`gh label list -R <owner/repo> --limit 100`) and apply only valid domain labels (`enhancement`, `bug`, `refactor`, `backend`, `frontend`, `tests`, etc.).
2. Write the body to a temporary file and create the issue:
   ```bash
   gh issue create -R <owner/repo> \
     --title "<type>(<scope>): <summary>" \
     --label "<valid-labels>" \
     --body-file /tmp/wdd-task.md
   rm -f /tmp/wdd-task.md
   ```

### 4. Sync Parent Epic (Append-to-Epic Mode)

When adding a task to an existing Epic (outside `wdd-create-epic`'s initial batch):

1. Fetch the current Epic body (`gh issue view <epic-id> -R <epic-repo> --json body -q .body > /tmp/wdd-epic-sync.md`).
2. Add the new `#<task-id>` to the Epic's **Child Issues & Wave DAG** table, **File Isolation Matrix**, and **Epic Completion Criteria** checklist.
3. Update the Epic (`gh issue edit <epic-id> -R <epic-repo> --body-file /tmp/wdd-epic-sync.md && rm -f /tmp/wdd-epic-sync.md`).

### 5. Confirm Output

Return the created `#<task-id>`, clickable GitHub URL, assigned wave (if any), and exclusive file list.
