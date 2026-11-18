# Canonical GitHub Task Issue Template

Adapt section headings and prose to the user's / repository's language (e.g., PT-BR or EN) while preserving all structural guarantees below.

```markdown
> **Epic:** #<epic-id> · **Wave:** Wave <N> · **Depends on:** <`—` or `#<id>, #<id>`>
<!-- Omit blockquote above only for standalone tasks without a parent Epic -->

## Context

<Concise explanation of the user/system goal and the concrete blockers in the current codebase, citing exact file paths and methods.>

1. `<path/to/FileA>` (`<methodName>`): <exact current limitation or missing behavior>.
2. `<path/to/FileB>`: <exact current limitation>.

---

## Implementation Scope

### 1. <Layer / Subsystem 1 (e.g., Database & Model / Domain Contract)>

- <Exact changes: idempotent migration rules, columns, casts, scopes, DTOs, exact method signatures and return types.>

### 2. <Layer / Subsystem 2 (e.g., Action / Service / HTTP Endpoint / UI Component)>

- <Exact business rules, routes, middleware, JSON request/response payloads, status codes, UI states, modularity/partial extraction rules to stay within `AGENTS.md` line ceilings.>

---

## File Ownership & Parallelism Guardrails

### Allowed Files (Create / Modify)

- `<path/to/file1>`
- `<path/to/file2>`
- `<tests/path/to/TestFile>`

> [!IMPORTANT]
> **Wave <N> Parallelism Rule:** Do **NOT** modify `<sibling/fileA>`, `<sibling/fileB>`, or `<sibling/routesFile>` — those files belong exclusively to parallel tasks running simultaneously in Wave <N>. If an unexpected cross-file dependency arises, stop and report `BLOCKED` to the coordinator rather than editing reserved files.
<!-- Omit the Wave Parallelism Rule callout only when the task runs alone in its wave or standalone -->

---

## Mandatory Automated Tests

Create or update `<tests/path/to/TestFile>` covering:

- <Concrete scenario 1 (happy path + state assertion)>
- <Concrete scenario 2 (edge case / idempotency / boundary)>
- <Concrete scenario 3 (authorization / validation / error handling)>

## Verification Commands

- Tests: `<exact targeted test command>`
- Formatting / Lint: `<exact formatter & linter commands on touched files>`
- Build / Types *(if applicable)*: `<exact build/typecheck command + baseline debt note if any>`

---

## Acceptance Criteria

- [ ] <Criterion 1 — observable & testable>
- [ ] <Criterion 2 — observable & testable>
- [ ] Repository modularity / line-count limits (`AGENTS.md` / `CLAUDE.md`) respected
- [ ] Automated tests and code formatters passing cleanly
```
