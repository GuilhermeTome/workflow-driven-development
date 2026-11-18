#!/usr/bin/env bash
set -euo pipefail

if (( BASH_VERSINFO[0] < 4 )); then
  echo "Error: Bash >= 4.0 is required (found ${BASH_VERSION})." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SKILLS_SRC_DIR="${REPO_ROOT}/skills"

usage() {
  cat <<'EOF'
Usage:
  scripts/install.sh [options]

Install Workflow-Driven Development (WDD) skills across AI coding agent harnesses.

Target Options (combinable; defaults to --all when none specified):
  --all             Install canonical symlinks in ~/.agents/skills and link
                    Claude Code, Antigravity/Gemini CLI, Codex, and OpenCode
                    skill directories to ~/.agents/skills/wdd-*
  --agents          Install into ~/.agents/skills
  --claude          Install into ~/.claude/skills
  --gemini          Install into ~/.gemini/config/skills
  --codex           Install into ~/.codex/skills
  --opencode        Install into ~/.config/opencode/skills
  --target <dir>    Install all wdd-* skills into an explicit directory
                    (may be specified multiple times)

Mode Options:
  --copy            Copy skill directories (cp -R) instead of symlinking (ln -sfn)
  --check           Read-only verification of requested target directories;
                    exits non-zero if any skill is missing or broken
  -h, --help        Show this help message and exit 0
EOF
}

discover_skills() {
  SKILL_NAMES=()
  if [[ ! -d "${SKILLS_SRC_DIR}" ]]; then
    echo "Error: skills source directory not found at ${SKILLS_SRC_DIR}" >&2
    exit 1
  fi

  local path name
  shopt -s nullglob
  for path in "${SKILLS_SRC_DIR}"/wdd-*; do
    if [[ -d "${path}" && -f "${path}/SKILL.md" ]]; then
      name="$(basename "${path}")"
      SKILL_NAMES+=("${name}")
    fi
  done
  shopt -u nullglob

  if (( ${#SKILL_NAMES[@]} == 0 )); then
    echo "Error: no wdd-* skill directories found in ${SKILLS_SRC_DIR}" >&2
    exit 1
  fi
}

DO_AGENTS=0
DO_CLAUDE=0
DO_GEMINI=0
DO_CODEX=0
DO_OPENCODE=0
HAS_EXPLICIT_TARGET=0
INSTALL_MODE="symlink"
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
      INSTALL_MODE="copy"
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

discover_skills

check_target_dir() {
  local target_dir="$1"
  local issues=()
  local skill entry

  if [[ ! -d "${target_dir}" ]]; then
    printf '[MISSING] %s (directory does not exist)\n' "${target_dir}"
    return 1
  fi

  for skill in "${SKILL_NAMES[@]}"; do
    entry="${target_dir}/${skill}"
    if [[ -L "${entry}" && ! -e "${entry}" ]]; then
      issues+=("${skill}: broken symlink")
    elif [[ ! -d "${entry}" ]]; then
      issues+=("${skill}: missing directory")
    elif [[ ! -f "${entry}/SKILL.md" ]]; then
      issues+=("${skill}: missing SKILL.md")
    elif [[ "${skill}" == "wdd-run-epic" && ! -x "${entry}/scripts/wdd-worktree.sh" ]]; then
      issues+=("${skill}: scripts/wdd-worktree.sh not executable")
    fi
  done

  if (( ${#issues[@]} > 0 )); then
    printf '[BROKEN]  %s (%s)\n' "${target_dir}" "$(IFS=';'; printf '%s' "${issues[*]}")"
    return 1
  fi

  printf '[OK]      %s (%d/%d skills valid)\n' "${target_dir}" "${#SKILL_NAMES[@]}" "${#SKILL_NAMES[@]}"
  return 0
}

install_into_dir() {
  local dest_dir="$1"
  local link_source_base="$2"
  local dest_abs src_abs skill dest_entry src_entry

  mkdir -p "${dest_dir}"
  dest_abs="$(cd "${dest_dir}" && pwd)"
  src_abs="$(cd "${SKILLS_SRC_DIR}" && pwd)"

  if [[ "${dest_abs}" == "${src_abs}" ]]; then
    echo "Error: refusing to install over source directory ${SKILLS_SRC_DIR}" >&2
    exit 1
  fi

  for skill in "${SKILL_NAMES[@]}"; do
    dest_entry="${dest_dir}/${skill}"
    if [[ "${INSTALL_MODE}" == "copy" ]]; then
      src_entry="${SKILLS_SRC_DIR}/${skill}"
      if [[ -L "${dest_entry}" || -e "${dest_entry}" ]]; then
        rm -rf "${dest_entry}"
      fi
      cp -R "${src_entry}" "${dest_entry}"
    else
      src_entry="${link_source_base}/${skill}"
      if [[ -d "${dest_entry}" && ! -L "${dest_entry}" ]]; then
        rm -rf "${dest_entry}"
      fi
      ln -sfn "${src_entry}" "${dest_entry}"
    fi
  done

  printf '[INSTALLED] %s (%s mode, %d skills)\n' "${dest_dir}" "${INSTALL_MODE}" "${#SKILL_NAMES[@]}"
}

if (( CHECK_ONLY == 1 )); then
  OVERALL_STATUS=0
  if (( DO_AGENTS == 1 )); then
    check_target_dir "${HOME}/.agents/skills" || OVERALL_STATUS=1
  fi
  if (( DO_CLAUDE == 1 )); then
    check_target_dir "${HOME}/.claude/skills" || OVERALL_STATUS=1
  fi
  if (( DO_GEMINI == 1 )); then
    check_target_dir "${HOME}/.gemini/config/skills" || OVERALL_STATUS=1
  fi
  if (( DO_CODEX == 1 )); then
    check_target_dir "${HOME}/.codex/skills" || OVERALL_STATUS=1
  fi
  if (( DO_OPENCODE == 1 )); then
    check_target_dir "${HOME}/.config/opencode/skills" || OVERALL_STATUS=1
  fi
  if (( ${#CUSTOM_TARGETS[@]} > 0 )); then
    for custom_dir in "${CUSTOM_TARGETS[@]}"; do
      check_target_dir "${custom_dir}" || OVERALL_STATUS=1
    done
  fi
  exit "${OVERALL_STATUS}"
fi

if (( DO_AGENTS == 1 )); then
  install_into_dir "${HOME}/.agents/skills" "${SKILLS_SRC_DIR}"
fi

HARNESS_SOURCE_BASE="${SKILLS_SRC_DIR}"
if (( DO_AGENTS == 1 )) && [[ "${INSTALL_MODE}" == "symlink" ]]; then
  HARNESS_SOURCE_BASE="${HOME}/.agents/skills"
fi

if (( DO_CLAUDE == 1 )); then
  install_into_dir "${HOME}/.claude/skills" "${HARNESS_SOURCE_BASE}"
fi
if (( DO_GEMINI == 1 )); then
  install_into_dir "${HOME}/.gemini/config/skills" "${HARNESS_SOURCE_BASE}"
fi
if (( DO_CODEX == 1 )); then
  install_into_dir "${HOME}/.codex/skills" "${HARNESS_SOURCE_BASE}"
fi
if (( DO_OPENCODE == 1 )); then
  install_into_dir "${HOME}/.config/opencode/skills" "${HARNESS_SOURCE_BASE}"
fi
if (( ${#CUSTOM_TARGETS[@]} > 0 )); then
  for custom_dir in "${CUSTOM_TARGETS[@]}"; do
    install_into_dir "${custom_dir}" "${SKILLS_SRC_DIR}"
  done
fi
