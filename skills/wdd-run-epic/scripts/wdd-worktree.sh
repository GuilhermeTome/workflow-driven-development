#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  wdd-worktree.sh epic-init <repo-dir> <epic-id> <slug> [base-branch]
  wdd-worktree.sh task-init <repo-dir> <task-id> <slug> <source-ref>
  wdd-worktree.sh task-merge-and-clean <epic-worktree> <task-worktree> <task-branch> <wave-num> <task-id> <short-summary>
  wdd-worktree.sh task-clean-worktree-only <repo-dir> <task-worktree>
EOF
  exit 1
}

[[ $# -lt 1 ]] && usage
CMD="$1"
shift

sanitize_slug() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' | cut -c1-48
}

ensure_exclude_wdd() {
  local wt_dir="$1"
  local common_dir
  common_dir="$(git -C "$wt_dir" rev-parse --git-common-dir)"
  mkdir -p "$common_dir/info" "$wt_dir/.wdd"
  local exclude_file="$common_dir/info/exclude"
  touch "$exclude_file"
  if ! grep -qxF ".wdd/" "$exclude_file"; then
    echo ".wdd/" >> "$exclude_file"
  fi
}

case "$CMD" in
  epic-init)
    [[ $# -lt 3 ]] && usage
    REPO_DIR="$1"
    EPIC_ID="$2"
    SLUG="$(sanitize_slug "$3")"
    BASE_BRANCH="${4:-main}"

    REPO_ROOT="$(git -C "$REPO_DIR" rev-parse --show-toplevel)"
    REPO_NAME="$(basename "$REPO_ROOT")"
    PARENT_DIR="$(dirname "$REPO_ROOT")"
    WT_BASE="${PARENT_DIR}/.worktrees/${REPO_NAME}"
    mkdir -p "$WT_BASE"

    EPIC_BRANCH="epic/${EPIC_ID}-${SLUG}"
    EPIC_WT="${WT_BASE}/epic-${EPIC_ID}-${SLUG}"

    git -C "$REPO_ROOT" fetch origin --prune
    git -C "$REPO_ROOT" worktree prune

    if [[ -d "$EPIC_WT/.git" || -f "$EPIC_WT/.git" ]]; then
      CURRENT_BRANCH="$(git -C "$EPIC_WT" branch --show-current)"
      if [[ "$CURRENT_BRANCH" != "$EPIC_BRANCH" ]]; then
        echo "Error: existing worktree $EPIC_WT is on branch '$CURRENT_BRANCH', expected '$EPIC_BRANCH'" >&2
        exit 1
      fi
    elif git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/${EPIC_BRANCH}"; then
      git -C "$REPO_ROOT" worktree add "$EPIC_WT" "$EPIC_BRANCH"
    elif git -C "$REPO_ROOT" show-ref --verify --quiet "refs/remotes/origin/${EPIC_BRANCH}"; then
      git -C "$REPO_ROOT" worktree add -b "$EPIC_BRANCH" "$EPIC_WT" "origin/${EPIC_BRANCH}"
    else
      git -C "$REPO_ROOT" worktree add -b "$EPIC_BRANCH" "$EPIC_WT" "origin/${BASE_BRANCH}"
      git -C "$EPIC_WT" push -u origin "$EPIC_BRANCH"
    fi

    ensure_exclude_wdd "$EPIC_WT"
    echo "EPIC_WORKTREE=${EPIC_WT}"
    echo "EPIC_BRANCH=${EPIC_BRANCH}"
    ;;

  task-init)
    [[ $# -lt 4 ]] && usage
    REPO_DIR="$1"
    TASK_ID="$2"
    SLUG="$(sanitize_slug "$3")"
    SOURCE_REF="$4"

    REPO_ROOT="$(git -C "$REPO_DIR" rev-parse --show-toplevel)"
    REPO_NAME="$(basename "$REPO_ROOT")"
    PARENT_DIR="$(dirname "$REPO_ROOT")"
    WT_BASE="${PARENT_DIR}/.worktrees/${REPO_NAME}"
    mkdir -p "$WT_BASE"

    TASK_BRANCH="task/${TASK_ID}-${SLUG}"
    TASK_WT="${WT_BASE}/task-${TASK_ID}-${SLUG}"

    git -C "$REPO_ROOT" worktree prune

    if [[ -d "$TASK_WT/.git" || -f "$TASK_WT/.git" ]]; then
      CURRENT_BRANCH="$(git -C "$TASK_WT" branch --show-current)"
      if [[ "$CURRENT_BRANCH" != "$TASK_BRANCH" ]]; then
        echo "Error: existing worktree $TASK_WT is on branch '$CURRENT_BRANCH', expected '$TASK_BRANCH'" >&2
        exit 1
      fi
    elif git -C "$REPO_ROOT" show-ref --verify --quiet "refs/heads/${TASK_BRANCH}"; then
      git -C "$REPO_ROOT" worktree add "$TASK_WT" "$TASK_BRANCH"
    else
      git -C "$REPO_ROOT" worktree add -b "$TASK_BRANCH" "$TASK_WT" "$SOURCE_REF"
    fi

    echo "TASK_WORKTREE=${TASK_WT}"
    echo "TASK_BRANCH=${TASK_BRANCH}"
    ;;

  task-merge-and-clean)
    [[ $# -lt 6 ]] && usage
    EPIC_WT="$1"
    TASK_WT="$2"
    TASK_BRANCH="$3"
    WAVE_NUM="$4"
    TASK_ID="$5"
    SUMMARY="$6"

    if [[ -d "$TASK_WT" ]]; then
      if ! git -C "$TASK_WT" diff --quiet || ! git -C "$TASK_WT" diff --cached --quiet; then
        echo "Error: task worktree $TASK_WT has uncommitted tracked modifications; commit or discard before merging." >&2
        exit 1
      fi
    fi

    if ! git -C "$EPIC_WT" merge --no-ff "$TASK_BRANCH" -m "merge(wave-${WAVE_NUM}): #${TASK_ID} ${SUMMARY}"; then
      git -C "$EPIC_WT" merge --abort 2>/dev/null || true
      echo "Error: merge conflict merging $TASK_BRANCH into $(git -C "$EPIC_WT" branch --show-current). Task worktree preserved for rebase/fix." >&2
      exit 1
    fi

    MERGED_SHA="$(git -C "$EPIC_WT" rev-parse --short HEAD)"

    if [[ -d "$TASK_WT" ]]; then
      git -C "$EPIC_WT" worktree unlock "$TASK_WT" 2>/dev/null || true
      git -C "$EPIC_WT" worktree remove --force "$TASK_WT"
    fi
    git -C "$EPIC_WT" worktree prune
    git -C "$EPIC_WT" branch -D "$TASK_BRANCH"
    git -C "$EPIC_WT" push origin --delete "$TASK_BRANCH" 2>/dev/null || true

    echo "MERGED_COMMIT=${MERGED_SHA}"
    ;;

  task-clean-worktree-only)
    [[ $# -lt 2 ]] && usage
    REPO_DIR="$1"
    TASK_WT="$2"

    if [[ -d "$TASK_WT" ]]; then
      git -C "$REPO_DIR" worktree unlock "$TASK_WT" 2>/dev/null || true
      git -C "$REPO_DIR" worktree remove --force "$TASK_WT"
    fi
    git -C "$REPO_DIR" worktree prune
    echo "CLEANED_WORKTREE=${TASK_WT}"
    ;;

  *)
    usage
    ;;
esac
