# Consolidated Final PR & Epic Summary Template

Adapt headings and prose to the user's / repository's language (e.g., PT-BR or EN) while keeping the `Closes #...` GitHub keywords exact so GitHub auto-closes the Epic and all child Tasks upon human merge into `main`.

## 1. Consolidated Pull Request Body (`epic/<epic-id>-<slug>` → `main`)

- **PR Title:** `<type>(<scope>): <epic summary> (#<epic-id>)`

```markdown
## Summary

Consolidated implementation of Epic #<epic-id> across <K> execution waves.

<!-- In a secondary repository of a cross-repo epic, replace `Closes #<epic-id>` below with:
Part of <primary-owner/repo>#<epic-id>
and keep `Closes #<task-id>` only for tasks residing in THIS repository. -->

Closes #<epic-id>
Closes #<task-1>
Closes #<task-2>
Closes #<task-3>

---

## Wave Breakdown

| Wave | Task | Commit(s) | Summary |
| :--- | :--- | :--- | :--- |
| Wave 1 | #<task-1> | `<sha>` | <1-line summary> |
| Wave 1 | #<task-2> | `<sha>` | <1-line summary> |
| Wave 2 | #<task-3> | `<sha>` | <1-line summary> |

---

## Verification & Quality Gate

- **Automated Tests:** `<exact test command & pass/assertion counts>`
- **Formatting & Lint:** `<exact formatter/linter checks>`
- **Build / Types:** `<exact build/typecheck status>`

<!-- Include if cross-repo:
## Production Merge & Deploy Order

1. Merge & deploy `<repo-A>#<pr-A>` first.
2. Merge & deploy `<repo-B>#<pr-B>` second.
-->

## Notes & Conscious Follow-Ups

- <List any intentional deviations documented during review or manual checks requiring a live browser/staging environment, or `None`.>
```

## 2. Final Comment Posted on Epic Issue `#<epic-id>` (Keep Issue OPEN)

```markdown
All waves are implemented, reviewed, and integrated on branch `epic/<epic-id>-<slug>`. Consolidated PR opened against `main`:

- **PR:** <PR_URL>

| Wave | Task | Merge Commit | Outcome |
| :--- | :--- | :--- | :--- |
| 1 | #<task-1> | `<sha>` | <summary> |
| 1 | #<task-2> | `<sha>` | <summary> |
| 2 | #<task-3> | `<sha>` | <summary> |

Epic and child Task issues remain open and will close automatically when the PR is merged into `main`.
```
