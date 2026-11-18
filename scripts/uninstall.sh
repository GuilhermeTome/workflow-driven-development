#!/usr/bin/env bash
set -euo pipefail

if (( BASH_VERSINFO[0] < 4 )); then
  echo "Error: Bash >= 4.0 is required (found ${BASH_VERSION})." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SKILLS_SRC_DIR="${REPO_ROOT}/skills"

WDD_SKILLS=(
  "wdd-create-epic"
  "wdd-create-task"
  "wdd-run-epic"
  "wdd-execute-task"
  "wdd-review-task"
)

usage() {
  cat <<'EOF'
Usage:
  scripts/uninstall.sh [options]

Remove Workflow-Driven Development (WDD) skills from selected agent harnesses
without touching any unrelated third-party or user skills.

Target Options (combinable; defaults to --all when none specified):
  --all             Remove wdd-* skills from ~/.agents/skills, ~/.claude/skills,
                    ~/.gemini/config/skills, ~/.codex/skills, and
                    ~/.config/opencode/skills
  --agents          Remove wdd-* skills from ~/.agents/skills
  --claude          Remove wdd-* skills from ~/.claude/skills
  --gemini          Remove wdd-* skills from ~/.gemini/config/skills
  --codex           Remove wdd-* skills from ~/.codex/skills
  --opencode        Remove wdd-* skills from ~/.config/opencode/skills
  --target <dir>    Remove wdd-* skills from an explicit directory
                    (may be specified multiple times)

Other Options:
  --check           Read-only check exiting non-zero if any wdd-* entry remains
                    in the selected target directories
  -h, --help        Show this help message and exit 0
EOF
}

DO_AGENTS=0
DO_CLAUDE=0
DO_GEMINI=0
DO_CODEX=0
DO_OPENCODE=0
HAS_EXPLICIT_TARGET=0
CHECK_ONLY=0
CUSTOM_TARGETS=()

while (( $# > 0 )); do
  case "$1" in
    --all)
      DO_AGENTS=1
      DO_CLAUDE=1
      DO_GEMINI=1
      DO_CODEX=1
      DO_OPENCODE=1
      HAS_EXPLICIT_TARGET=1
      shift
      ;;
    --agents)
      DO_AGENTS=1
      HAS_EXPLICIT_TARGET=1
      shift
      ;;
    --claude)
      DO_CLAUDE=1
      HAS_EXPLICIT_TARGET=1
      shift
      ;;
    --gemini)
      DO_GEMINI=1
      HAS_EXPLICIT_TARGET=1
      shift
      ;;
    --codex)
      DO_CODEX=1
      HAS_EXPLICIT_TARGET=1
      shift
      ;;
    --opencode)
      DO_OPENCODE=1
      HAS_EXPLICIT_TARGET=1
      shift
      ;;
    --target)
      if (( $# < 2 )) || [[ -z "${2}" ]]; then
        echo "Error: --target requires a non-empty directory argument." >&2
        usage >&2
        exit 1
      fi
      CUSTOM_TARGETS+=("$2")
      HAS_EXPLICIT_TARGET=1
      shift 2
      ;;
    --target=*)
      target_val="${1#--target=}"
      if [[ -z "${target_val}" ]]; then
        echo "Error: --target requires a non-empty directory argument." >&2
        usage >&2
        exit 1
      fi
      CUSTOM_TARGETS+=("${target_val}")
      HAS_EXPLICIT_TARGET=1
      shift
      ;;
    --copy)
      # Accepted as a harmless compatibility flag; uninstall removes both symlinks and copies.
      shift
      ;;
    --check)
      CHECK_ONLY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option '$1'" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if (( HAS_EXPLICIT_TARGET == 0 )); then
  DO_AGENTS=1
  DO_CLAUDE=1
  DO_GEMINI=1
  DO_CODEX=1
  DO_OPENCODE=1
fi

if (( DO_AGENTS == 1 || DO_CLAUDE == 1 || DO_GEMINI == 1 || DO_CODEX == 1 || DO_OPENCODE == 1 )); then
  if [[ -z "${HOME:-}" ]]; then
    echo "Error: HOME environment variable is not set." >&2
    exit 1
  fi
fi

check_uninstalled_dir() {
  local target_dir="$1"
  local remaining=()
  local skill entry

  if [[ ! -d "${target_dir}" ]]; then
    printf '[CLEAN]   %s (directory absent)\n' "${target_dir}"
    return 0
  fi

  for skill in "${WDD_SKILLS[@]}"; do
    entry="${target_dir}/${skill}"
    if [[ -L "${entry}" || -e "${entry}" ]]; then
      remaining+=("${skill}")
    fi
  done

  if (( ${#remaining[@]} > 0 )); then
    printf '[PRESENT] %s (%s)\n' "${target_dir}" "$(IFS=','; printf '%s' "${remaining[*]}")"
    return 1
  fi

  printf '[CLEAN]   %s (0 WDD skills present)\n' "${target_dir}"
  return 0
}

uninstall_from_dir() {
  local target_dir="$1"
  local target_abs src_abs removed=0 skill entry

  if [[ ! -d "${target_dir}" ]]; then
    printf '[SKIPPED] %s (directory does not exist)\n' "${target_dir}"
    return 0
  fi

  target_abs="$(cd "${target_dir}" && pwd)"
  if [[ -d "${SKILLS_SRC_DIR}" ]]; then
    src_abs="$(cd "${SKILLS_SRC_DIR}" && pwd)"
    if [[ "${target_abs}" == "${src_abs}" ]]; then
      echo "Error: refusing to uninstall repository source directory ${SKILLS_SRC_DIR}" >&2
      exit 1
    fi
  fi

  for skill in "${WDD_SKILLS[@]}"; do
    entry="${target_dir}/${skill}"
    if [[ -L "${entry}" || -e "${entry}" ]]; then
      rm -rf "${entry}"
      removed=$(( removed + 1 ))
    fi
  done

  printf '[REMOVED] %s (%d WDD skill entries removed)\n' "${target_dir}" "${removed}"
}

if (( CHECK_ONLY == 1 )); then
  OVERALL_CLEAN=0
  if (( DO_CLAUDE == 1 )); then
    check_uninstalled_dir "${HOME}/.claude/skills" || OVERALL_CLEAN=1
  fi
  if (( DO_GEMINI == 1 )); then
    check_uninstalled_dir "${HOME}/.gemini/config/skills" || OVERALL_CLEAN=1
  fi
  if (( DO_CODEX == 1 )); then
    check_uninstalled_dir "${HOME}/.codex/skills" || OVERALL_CLEAN=1
  fi
  if (( DO_OPENCODE == 1 )); then
    check_uninstalled_dir "${HOME}/.config/opencode/skills" || OVERALL_CLEAN=1
  fi
  if (( DO_AGENTS == 1 )); then
    check_uninstalled_dir "${HOME}/.agents/skills" || OVERALL_CLEAN=1
  fi
  if (( ${#CUSTOM_TARGETS[@]} > 0 )); then
    for custom_dir in "${CUSTOM_TARGETS[@]}"; do
      check_uninstalled_dir "${custom_dir}" || OVERALL_CLEAN=1
    done
  fi
  exit "${OVERALL_CLEAN}"
fi

# Remove secondary harness symlinks first, then canonical ~/.agents/skills last.
if (( DO_CLAUDE == 1 )); then
  uninstall_from_dir "${HOME}/.claude/skills"
fi
if (( DO_GEMINI == 1 )); then
  uninstall_from_dir "${HOME}/.gemini/config/skills"
fi
if (( DO_CODEX == 1 )); then
  uninstall_from_dir "${HOME}/.codex/skills"
fi
if (( DO_OPENCODE == 1 )); then
  uninstall_from_dir "${HOME}/.config/opencode/skills"
fi
if (( DO_AGENTS == 1 )); then
  uninstall_from_dir "${HOME}/.agents/skills"
fi
if (( ${#CUSTOM_TARGETS[@]} > 0 )); then
  for custom_dir in "${CUSTOM_TARGETS[@]}"; do
    uninstall_from_dir "${custom_dir}"
  done
fi
