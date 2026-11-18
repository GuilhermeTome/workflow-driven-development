# Changelog

All notable changes to **Workflow-Driven Development (WDD)** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Open-source governance and community documentation: [`LICENSE`](./LICENSE) (MIT), [`AGENTS.md`](./AGENTS.md), [`CONTRIBUTING.md`](./CONTRIBUTING.md), [`CODE_OF_CONDUCT.md`](./CODE_OF_CONDUCT.md), [`SECURITY.md`](./SECURITY.md), and [`CHANGELOG.md`](./CHANGELOG.md).
- Comprehensive user manual, core principles guide, and harness installation documentation under `docs/`.
- Multi-harness CLI installer and uninstaller (`scripts/install.sh`) supporting global and project-local installations across Claude Code, Codex, Antigravity / Gemini, Cursor, and `.agents/skills`.
- Automated pack validation test suite (`tests/validate-pack.sh`) and GitHub Actions CI workflow plus issue and pull request templates.

## [0.1.0] - 2026-11-18

### Added

- Initial release of the 5-skill **Workflow-Driven Development (WDD)** pack:
  - [`wdd-create-epic`](./skills/wdd-create-epic/SKILL.md): Grounded codebase discovery, zero-overlap wave DAG partitioning, GitHub Epic issue publication, and batch Task issue creation with automatic `#ID` backfilling.
  - [`wdd-create-task`](./skills/wdd-create-task/SKILL.md): Self-contained GitHub Task issue authoring with explicit file-boundary ownership, parallel-wave exclusion lists, and mandatory test specifications.
  - [`wdd-run-epic`](./skills/wdd-run-epic/SKILL.md): End-to-end Epic wave coordinator operating in dedicated `epic/<id>-<slug>` worktrees, dispatching parallel native subagents per wave, tracking live GitHub progress, and opening a single consolidated Pull Request targeting `main`.
  - [`wdd-execute-task`](./skills/wdd-execute-task/SKILL.md): Isolated subagent task implementer enforcing fresh dependency installation (zero shared symlinks), repository `AGENTS.md`/`CLAUDE.md` compliance, programmatic verification, and Conventional Commits on `task/<id>-<slug>` branches.
  - [`wdd-review-task`](./skills/wdd-review-task/SKILL.md): Coordinator diff quality gate supporting up to 3 scoped fix rounds in the existing task worktree before merging cleanly into the epic branch (or opening a standalone PR to `main`).
- Deterministic Git worktree lifecycle helper [`wdd-worktree.sh`](./skills/wdd-run-epic/scripts/wdd-worktree.sh) (`epic-init`, `task-init`, `task-merge-and-clean`, `task-clean-worktree-only`).

[Unreleased]: https://github.com/GuilhermeTome/workflow-driven-development/compare/c988b16...HEAD
[0.1.0]: https://github.com/GuilhermeTome/workflow-driven-development/commits/c988b16
