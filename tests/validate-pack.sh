#!/usr/bin/env bash
set -euo pipefail

if (( BASH_VERSINFO[0] < 4 )); then
  echo "Error: Bash >= 4.0 is required (found ${BASH_VERSION})." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKTREE_HELPER="${REPO_ROOT}/skills/wdd-run-epic/scripts/wdd-worktree.sh"

TMP_ROOT="$(mktemp -d)"
# shellcheck disable=SC2317
cleanup() {
  rm -rf "${TMP_ROOT}"
}
trap cleanup EXIT

PASS_COUNT=0
FAIL_COUNT=0

suite_header() {
  printf '\n== %s ==\n' "$1"
}

pass_case() {
  PASS_COUNT=$(( PASS_COUNT + 1 ))
  printf '  [PASS] %s\n' "$1"
}

fail_case() {
  FAIL_COUNT=$(( FAIL_COUNT + 1 ))
  printf '  [FAIL] %s\n' "$1" >&2
}

EXPECTED_SKILLS=(
  "wdd-create-epic"
  "wdd-create-task"
  "wdd-run-epic"
  "wdd-execute-task"
  "wdd-review-task"
)

# ---------------------------------------------------------------------------
# Suite 1: Skill Structure & Frontmatter Check
# ---------------------------------------------------------------------------
run_suite_1_frontmatter() {
  suite_header "Suite 1/5: Skill Structure & YAML Frontmatter"

  local skill
  for skill in "${EXPECTED_SKILLS[@]}"; do
    if [[ -d "${REPO_ROOT}/skills/${skill}" && -f "${REPO_ROOT}/skills/${skill}/SKILL.md" ]]; then
      pass_case "Skill directory and SKILL.md present: ${skill}"
    else
      fail_case "Missing skill directory or SKILL.md: ${skill}"
    fi
  done

  if python3 - "${REPO_ROOT}/skills" "${EXPECTED_SKILLS[@]}" <<'PY'
import pathlib
import sys

skills_root = pathlib.Path(sys.argv[1])
expected = set(sys.argv[2:])
actual_dirs = sorted(p for p in skills_root.iterdir() if p.is_dir() and not p.name.startswith("."))
actual_names = {p.name for p in actual_dirs}

missing = sorted(expected - actual_names)
if missing:
    print(f"Missing expected skill directories: {missing}", file=sys.stderr)
    sys.exit(1)

def parse_frontmatter(md_path: pathlib.Path) -> dict[str, str]:
    lines = md_path.read_text(encoding="utf-8").splitlines()
    if not lines or lines[0].strip() != "---":
        raise ValueError("file does not start with '---' YAML frontmatter fence")
    end_idx = None
    for idx in range(1, len(lines)):
        if lines[idx].strip() == "---":
            end_idx = idx
            break
    if end_idx is None:
        raise ValueError("unterminated YAML frontmatter fence")

    fm_lines = lines[1:end_idx]
    data: dict[str, str] = {}
    current_key: str | None = None
    block_mode: str | None = None
    buf: list[str] = []

    def flush() -> None:
        nonlocal current_key, block_mode, buf
        if current_key is not None:
            joiner = "\n" if (block_mode and block_mode.startswith("|")) else " "
            val = joiner.join(part.strip() for part in buf if part.strip()).strip()
            data[current_key] = val
        current_key = None
        block_mode = None
        buf = []

    for raw in fm_lines:
        if not raw.strip() or raw.lstrip().startswith("#"):
            continue
        if not raw.startswith((" ", "\t")) and ":" in raw:
            flush()
            key, rest = raw.split(":", 1)
            current_key = key.strip()
            rest = rest.strip()
            if rest in (">", ">-", ">+", "|", "|-", "|+"):
                block_mode = rest
            elif rest == "":
                block_mode = ">"
            else:
                if len(rest) >= 2 and rest[0] == rest[-1] and rest[0] in ("'", '"'):
                    rest = rest[1:-1]
                data[current_key] = rest
                current_key = None
        elif current_key is not None:
            buf.append(raw)
        else:
            raise ValueError(f"unexpected YAML frontmatter line: {raw!r}")
    flush()
    return data

errors: list[str] = []
for skill_dir in actual_dirs:
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.is_file():
        errors.append(f"{skill_dir.name}: missing SKILL.md")
        continue
    try:
        meta = parse_frontmatter(skill_md)
    except ValueError as exc:
        errors.append(f"{skill_dir.name}: {exc}")
        continue

    name = meta.get("name", "")
    desc = meta.get("description", "")
    if name != skill_dir.name:
        errors.append(f"{skill_dir.name}: frontmatter name {name!r} != directory name {skill_dir.name!r}")
    if len(desc) <= 40:
        errors.append(f"{skill_dir.name}: description must exceed 40 chars (got {len(desc)})")

if errors:
    for err in errors:
        print(f"  -> {err}", file=sys.stderr)
    sys.exit(1)
PY
  then
    pass_case "All SKILL.md files have valid YAML frontmatter (exact name match & description > 40 chars)"
  else
    fail_case "YAML frontmatter validation failed"
  fi
}

# ---------------------------------------------------------------------------
# Suite 2: Markdown Relative Link Integrity Check
# ---------------------------------------------------------------------------
run_suite_2_markdown_links() {
  suite_header "Suite 2/5: Markdown Relative Link Integrity"

  local summary
  if summary="$(python3 - "${REPO_ROOT}" <<'PY'
import os
import pathlib
import re
import sys

repo_root = pathlib.Path(sys.argv[1]).resolve()
excluded_dirs = {".git", ".worktrees", ".wdd", "node_modules", "vendor"}

md_files: list[pathlib.Path] = []
for dirpath, dirnames, filenames in os.walk(repo_root):
    dirnames[:] = [d for d in dirnames if d not in excluded_dirs]
    for fname in sorted(filenames):
        if fname.endswith(".md"):
            md_files.append(pathlib.Path(dirpath) / fname)

fence_re = re.compile(r"(`{3,}|~{3,}).*?\1", re.DOTALL)
comment_re = re.compile(r"<!--.*?-->", re.DOTALL)
inline_code_re = re.compile(r"(`+)[^\n]*?\1")
link_re = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
skip_prefixes = ("http://", "https://", "mailto:", "tel:", "data:", "file://", "conversation://", "#")

checked_links = 0
broken: list[str] = []

for md_path in sorted(md_files):
    text = md_path.read_text(encoding="utf-8")
    text = comment_re.sub("", text)
    text = fence_re.sub("", text)
    text = inline_code_re.sub("", text)

    for match in link_re.finditer(text):
        raw_target = match.group(1).strip()
        if not raw_target:
            continue
        if raw_target.startswith("<") and raw_target.endswith(">"):
            raw_target = raw_target[1:-1].strip()
        else:
            raw_target = raw_target.split()[0]

        if raw_target.startswith(skip_prefixes):
            continue

        rel_part = raw_target.split("#", 1)[0].split("?", 1)[0]
        if not rel_part:
            continue

        checked_links += 1
        resolved = (md_path.parent / rel_part).resolve()
        if not resolved.exists():
            rel_md = md_path.relative_to(repo_root)
            broken.append(f"{rel_md} -> {raw_target}")

if broken:
    for item in broken:
        print(f"  broken link: {item}", file=sys.stderr)
    sys.exit(1)

print(f"{len(md_files)} Markdown files scanned, {checked_links} relative links verified")
PY
  )"; then
    pass_case "${summary}"
  else
    fail_case "Broken relative Markdown links detected"
  fi
}

# ---------------------------------------------------------------------------
# Suite 3: Shell Syntax & Executable Permissions Check
# ---------------------------------------------------------------------------
run_suite_3_shell_syntax() {
  suite_header "Suite 3/5: Shell Syntax & Executable Permissions"

  local sh_files=()
  local file rel
  while IFS= read -r -d '' file; do
    sh_files+=("${file}")
  done < <(find "${REPO_ROOT}/scripts" "${REPO_ROOT}/tests" "${REPO_ROOT}/skills" -type f -name '*.sh' -print0 | sort -z)

  if (( ${#sh_files[@]} < 4 )); then
    fail_case "Expected at least 4 shell scripts across scripts/, tests/, and skills/**/scripts/ (found ${#sh_files[@]})"
    return
  fi

  for file in "${sh_files[@]}"; do
    rel="${file#"${REPO_ROOT}/"}"
    if [[ -x "${file}" ]]; then
      pass_case "Executable bit set (-x): ${rel}"
    else
      fail_case "Missing executable permission (-x): ${rel}"
    fi

    if bash -n "${file}"; then
      pass_case "Syntax valid (bash -n): ${rel}"
    else
      fail_case "Syntax error (bash -n): ${rel}"
    fi
  done
}

# ---------------------------------------------------------------------------
# Suite 4: wdd-worktree.sh End-to-End Integration Test (Temp Repo Sandbox)
# ---------------------------------------------------------------------------
run_suite_4_worktree_integration() {
  suite_header "Suite 4/5: wdd-worktree.sh Sandbox Integration"

  local wt_sandbox="${TMP_ROOT}/wt-sandbox"
  local origin_bare="${wt_sandbox}/origin.git"
  local workspace_parent="${wt_sandbox}/workspace"
  local clone_dir="${workspace_parent}/demo-app"
  mkdir -p "${workspace_parent}"

  git init --bare "${origin_bare}" >/dev/null 2>&1
  git --git-dir="${origin_bare}" symbolic-ref HEAD refs/heads/main

  git clone "${origin_bare}" "${clone_dir}" >/dev/null 2>&1
  git -C "${clone_dir}" checkout -b main >/dev/null 2>&1 || git -C "${clone_dir}" symbolic-ref HEAD refs/heads/main
  git -C "${clone_dir}" config user.name "WDD Sandbox"
  git -C "${clone_dir}" config user.email "wdd-sandbox@example.com"
  git -C "${clone_dir}" config commit.gpgsign false

  printf '# Demo App\n' > "${clone_dir}/README.md"
  printf 'baseline line\n' > "${clone_dir}/shared.txt"
  git -C "${clone_dir}" add README.md shared.txt
  git -C "${clone_dir}" commit -m "chore: initial commit" >/dev/null 2>&1
  git -C "${clone_dir}" push -u origin main >/dev/null 2>&1

  local epic_out epic_wt epic_branch common_dir exclude_file exclude_count
  epic_out="$(bash "${WORKTREE_HELPER}" epic-init "${clone_dir}" "42" "Webhook Retries!" "main" 2>&1)"
  epic_wt="${workspace_parent}/.worktrees/demo-app/epic-42-webhook-retries"
  epic_branch="epic/42-webhook-retries"

  if [[ -d "${epic_wt}" ]] \
    && [[ "${epic_out}" == *"EPIC_WORKTREE=${epic_wt}"* ]] \
    && [[ "$(git -C "${epic_wt}" branch --show-current)" == "${epic_branch}" ]] \
    && git --git-dir="${origin_bare}" show-ref --verify --quiet "refs/heads/${epic_branch}"; then
    pass_case "epic-init creates sibling epic worktree and pushes ${epic_branch} to origin"
  else
    fail_case "epic-init failed to initialize worktree or push ${epic_branch}"
  fi

  common_dir="$(git -C "${epic_wt}" rev-parse --git-common-dir)"
  exclude_file="${common_dir}/info/exclude"
  if [[ -d "${epic_wt}/.wdd" ]] && grep -qxF ".wdd/" "${exclude_file}"; then
    pass_case "epic-init creates .wdd/ directory and registers .wdd/ in git info/exclude"
  else
    fail_case "epic-init did not configure .wdd/ exclusion properly"
  fi

  if bash "${WORKTREE_HELPER}" epic-init "${clone_dir}" "42" "Webhook Retries!" "main" >/dev/null 2>&1; then
    exclude_count="$(grep -cxF ".wdd/" "${exclude_file}")"
    if [[ "${exclude_count}" == "1" ]]; then
      pass_case "epic-init is idempotent when invoked repeatedly"
    else
      fail_case "epic-init duplicated .wdd/ in info/exclude (count=${exclude_count})"
    fi
  else
    fail_case "epic-init failed on second idempotent invocation"
  fi

  local task_101_wt="${workspace_parent}/.worktrees/demo-app/task-101-signature-check"
  local task_102_wt="${workspace_parent}/.worktrees/demo-app/task-102-retry-queue"
  bash "${WORKTREE_HELPER}" task-init "${clone_dir}" "101" "Signature Check" "${epic_branch}" >/dev/null 2>&1
  bash "${WORKTREE_HELPER}" task-init "${clone_dir}" "102" "Retry Queue" "${epic_branch}" >/dev/null 2>&1

  if [[ -d "${task_101_wt}" && -d "${task_102_wt}" ]] \
    && [[ "$(git -C "${task_101_wt}" branch --show-current)" == "task/101-signature-check" ]] \
    && [[ "$(git -C "${task_102_wt}" branch --show-current)" == "task/102-retry-queue" ]]; then
    pass_case "task-init creates isolated parallel worktrees task-101 and task-102"
  else
    fail_case "task-init failed to create task-101 and task-102 worktrees"
  fi

  # Dirty-worktree safety check
  printf 'uncommitted edit\n' >> "${task_101_wt}/shared.txt"
  if bash "${WORKTREE_HELPER}" task-merge-and-clean \
      "${epic_wt}" "${task_101_wt}" "task/101-signature-check" "1" "101" "signature check" >/dev/null 2>&1; then
    fail_case "task-merge-and-clean should reject dirty task worktree"
  elif [[ -d "${task_101_wt}" ]]; then
    pass_case "task-merge-and-clean rejects dirty task worktree and preserves changes"
  else
    fail_case "task-merge-and-clean removed dirty task worktree unexpectedly"
  fi

  # Clean merge & prune
  git -C "${task_101_wt}" checkout -- shared.txt
  printf 'verified=true\n' > "${task_101_wt}/signature.txt"
  git -C "${task_101_wt}" add signature.txt
  git -C "${task_101_wt}" commit -m "feat: add signature verifier (#101)" >/dev/null 2>&1

  local merge_out
  merge_out="$(bash "${WORKTREE_HELPER}" task-merge-and-clean \
    "${epic_wt}" "${task_101_wt}" "task/101-signature-check" "1" "101" "signature check" 2>&1)"

  if [[ "${merge_out}" == *"MERGED_COMMIT="* ]] \
    && [[ -f "${epic_wt}/signature.txt" ]] \
    && git -C "${epic_wt}" rev-parse --verify --quiet HEAD^2 >/dev/null \
    && [[ ! -d "${task_101_wt}" ]] \
    && ! git -C "${clone_dir}" show-ref --verify --quiet "refs/heads/task/101-signature-check"; then
    pass_case "task-merge-and-clean merges --no-ff and prunes task-101 worktree and branch"
  else
    fail_case "task-merge-and-clean failed to merge --no-ff or prune task-101"
  fi

  # Conflict abort safety check
  printf 'epic conflicting change\n' > "${epic_wt}/shared.txt"
  git -C "${epic_wt}" add shared.txt
  git -C "${epic_wt}" commit -m "chore: update shared on epic" >/dev/null 2>&1

  printf 'task 102 conflicting change\n' > "${task_102_wt}/shared.txt"
  git -C "${task_102_wt}" add shared.txt
  git -C "${task_102_wt}" commit -m "feat: conflicting retry edit (#102)" >/dev/null 2>&1

  if bash "${WORKTREE_HELPER}" task-merge-and-clean \
      "${epic_wt}" "${task_102_wt}" "task/102-retry-queue" "1" "102" "retry queue" >/dev/null 2>&1; then
    fail_case "task-merge-and-clean should fail on merge conflict"
  else
    local epic_git_dir
    epic_git_dir="$(git -C "${epic_wt}" rev-parse --git-dir)"
    if [[ ! -f "${epic_git_dir}/MERGE_HEAD" ]] \
      && [[ -z "$(git -C "${epic_wt}" status --porcelain)" ]] \
      && [[ -d "${task_102_wt}" ]] \
      && git -C "${clone_dir}" show-ref --verify --quiet "refs/heads/task/102-retry-queue"; then
      pass_case "task-merge-and-clean aborts cleanly on conflict and preserves task-102 worktree"
    else
      fail_case "task-merge-and-clean left unmerged state or deleted task-102 on conflict"
    fi
  fi

  # task-clean-worktree-only check
  bash "${WORKTREE_HELPER}" task-clean-worktree-only "${clone_dir}" "${task_102_wt}" >/dev/null 2>&1
  if [[ ! -d "${task_102_wt}" ]] \
    && git -C "${clone_dir}" show-ref --verify --quiet "refs/heads/task/102-retry-queue"; then
    pass_case "task-clean-worktree-only removes worktree directory while preserving branch"
  else
    fail_case "task-clean-worktree-only failed to preserve branch or remove directory"
  fi
}

# ---------------------------------------------------------------------------
# Suite 5: install.sh & uninstall.sh Sandbox Integration Test
# ---------------------------------------------------------------------------
run_suite_5_installer_sandbox() {
  suite_header "Suite 5/5: install.sh & uninstall.sh Sandbox Integration"

  local tmp_home="${TMP_ROOT}/home-sandbox"
  local tmp_project="${TMP_ROOT}/project-sandbox"
  mkdir -p "${tmp_home}/.claude/skills/keep-me" "${tmp_project}"
  printf '# Third-party skill that must never be deleted\n' > "${tmp_home}/.claude/skills/keep-me/SKILL.md"

  if HOME="${tmp_home}" bash "${REPO_ROOT}/scripts/install.sh" --check >/dev/null 2>&1; then
    fail_case "install.sh --check should fail before skills are installed"
  else
    pass_case "install.sh --check exits non-zero when skills are missing"
  fi

  if HOME="${tmp_home}" bash "${REPO_ROOT}/scripts/install.sh" --help >/dev/null 2>&1 \
    && HOME="${tmp_home}" bash "${REPO_ROOT}/scripts/uninstall.sh" --help >/dev/null 2>&1; then
    pass_case "install.sh --help and uninstall.sh --help exit 0"
  else
    fail_case "--help flag failed on install.sh or uninstall.sh"
  fi

  HOME="${tmp_home}" bash "${REPO_ROOT}/scripts/install.sh" --all >/dev/null
  # Second run verifies idempotency
  HOME="${tmp_home}" bash "${REPO_ROOT}/scripts/install.sh" --all >/dev/null

  local links_ok=1 skill harness_dir link_target
  for skill in "${EXPECTED_SKILLS[@]}"; do
    if [[ ! -L "${tmp_home}/.agents/skills/${skill}" ]]; then
      links_ok=0
    else
      link_target="$(readlink "${tmp_home}/.agents/skills/${skill}")"
      if [[ "${link_target}" != "${REPO_ROOT}/skills/${skill}" ]]; then
        links_ok=0
      fi
    fi

    for harness_dir in \
      "${tmp_home}/.claude/skills" \
      "${tmp_home}/.gemini/config/skills" \
      "${tmp_home}/.codex/skills" \
      "${tmp_home}/.config/opencode/skills"; do
      if [[ ! -L "${harness_dir}/${skill}" ]]; then
        links_ok=0
      else
        link_target="$(readlink "${harness_dir}/${skill}")"
        if [[ "${link_target}" != "${tmp_home}/.agents/skills/${skill}" ]]; then
          links_ok=0
        fi
      fi
    done
  done

  if (( links_ok == 1 )); then
    pass_case "install.sh --all creates canonical ~/.agents/skills symlinks and harness links"
  else
    fail_case "install.sh --all symlink topology did not match contract"
  fi

  if HOME="${tmp_home}" bash "${REPO_ROOT}/scripts/install.sh" --check >/dev/null 2>&1; then
    pass_case "install.sh --check succeeds after --all installation"
  else
    fail_case "install.sh --check failed after --all installation"
  fi

  HOME="${tmp_home}" bash "${REPO_ROOT}/scripts/install.sh" \
    --target "${tmp_project}/.agents/skills" --copy >/dev/null

  local copy_ok=1
  for skill in "${EXPECTED_SKILLS[@]}"; do
    if [[ ! -d "${tmp_project}/.agents/skills/${skill}" ]] \
      || [[ -L "${tmp_project}/.agents/skills/${skill}" ]] \
      || [[ ! -f "${tmp_project}/.agents/skills/${skill}/SKILL.md" ]]; then
      copy_ok=0
    fi
  done

  if (( copy_ok == 1 )) && HOME="${tmp_home}" bash "${REPO_ROOT}/scripts/install.sh" \
      --target "${tmp_project}/.agents/skills" --check >/dev/null 2>&1; then
    pass_case "install.sh --target <dir> --copy installs standalone directory copies"
  else
    fail_case "install.sh --target <dir> --copy failed validation"
  fi

  HOME="${tmp_home}" bash "${REPO_ROOT}/scripts/uninstall.sh" \
    --target "${tmp_project}/.agents/skills" >/dev/null
  HOME="${tmp_home}" bash "${REPO_ROOT}/scripts/uninstall.sh" --all >/dev/null
  # Second run verifies idempotency
  HOME="${tmp_home}" bash "${REPO_ROOT}/scripts/uninstall.sh" --all >/dev/null

  local uninstall_ok=1
  for skill in "${EXPECTED_SKILLS[@]}"; do
    for harness_dir in \
      "${tmp_home}/.agents/skills" \
      "${tmp_home}/.claude/skills" \
      "${tmp_home}/.gemini/config/skills" \
      "${tmp_home}/.codex/skills" \
      "${tmp_home}/.config/opencode/skills" \
      "${tmp_project}/.agents/skills"; do
      if [[ -L "${harness_dir}/${skill}" || -e "${harness_dir}/${skill}" ]]; then
        uninstall_ok=0
      fi
    done
  done

  if (( uninstall_ok == 1 )) && [[ -f "${tmp_home}/.claude/skills/keep-me/SKILL.md" ]]; then
    pass_case "uninstall.sh --all removes all WDD skills while preserving third-party skills"
  else
    fail_case "uninstall.sh --all either left WDD entries behind or touched keep-me"
  fi

  # Test combinable individual harness flags (--claude --gemini --codex --opencode --agents)
  HOME="${tmp_home}" bash "${REPO_ROOT}/scripts/install.sh" --claude --gemini >/dev/null
  if HOME="${tmp_home}" bash "${REPO_ROOT}/scripts/install.sh" --claude --gemini --check >/dev/null 2>&1 \
    && ! HOME="${tmp_home}" bash "${REPO_ROOT}/scripts/install.sh" --codex --check >/dev/null 2>&1; then
    pass_case "Individual combinable harness flags (--claude --gemini --codex --opencode --agents) scope accurately"
  else
    fail_case "Individual combinable harness flags did not scope target directories accurately"
  fi
  HOME="${tmp_home}" bash "${REPO_ROOT}/scripts/uninstall.sh" --claude --gemini >/dev/null
}

run_suite_1_frontmatter
run_suite_2_markdown_links
run_suite_3_shell_syntax
run_suite_4_worktree_integration
run_suite_5_installer_sandbox

printf '\n========================================\n'
printf 'Validation Summary: %d passed, %d failed\n' "${PASS_COUNT}" "${FAIL_COUNT}"
printf '========================================\n'

if (( FAIL_COUNT > 0 )); then
  exit 1
fi
