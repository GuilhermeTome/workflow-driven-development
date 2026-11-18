# Stack-Agnostic Worktree Bootstrap & Verification Guide

Always check the target repository's `AGENTS.md`, `CLAUDE.md`, `composer.json`, `package.json`, `Makefile`, or CI workflows (`.github/workflows/`) first—repository-specific commands take precedence over the defaults below.

Never symlink dependency folders (`vendor/`, `node_modules/`, `.venv/`) across worktrees. Install cleanly inside `<task-worktree>`.

## 1. PHP / Laravel (+ Inertia / Frontend)

```bash
# Install PHP dependencies cleanly
composer install --no-interaction --prefer-dist --no-progress

# Bootstrap isolated .env for local test execution if needed (never commit .env!)
if [[ ! -f .env && -f .env.example ]]; then
  cp .env.example .env
  php artisan key:generate --ansi
fi

# Install Node dependencies cleanly when frontend / Wayfinder / assets are involved
if [[ -f package-lock.json ]]; then
  npm ci --no-audit --no-fund
elif [[ -f pnpm-lock.yaml ]]; then
  pnpm install --frozen-lockfile
fi

# If Laravel Wayfinder is used and frontend tests import @/actions or @/routes:
php artisan wayfinder:generate 2>/dev/null || true
```

**Verification:**
- Backend tests: `php artisan test --compact --filter=<TestNameOrPath>`
- PHP formatter (Pint): `vendor/bin/pint --dirty --format agent`
- Frontend formatter (check `.oxfmtrc.json` / `package.json`): e.g., `npx oxfmt <edited-files-under-resources>`
- Frontend unit tests: `npx vitest run <test-files>`
- Frontend build (when UI/TS changed): `npm run build`

## 2. Node.js / TypeScript (Standalone Services, Next.js, Express, CLI)

```bash
if [[ -f pnpm-lock.yaml ]]; then
  pnpm install --frozen-lockfile
elif [[ -f yarn.lock ]]; then
  yarn install --frozen-lockfile
elif [[ -f package-lock.json ]]; then
  npm ci --no-audit --no-fund
else
  npm install --no-audit --no-fund
fi
```

**Verification:**
- Tests: `npm test` (or `node --test`, `npx vitest run`, `npx jest` per `package.json`)
- Types / Lint / Build: `npm run lint`, `npm run build` (or scripts defined in `package.json`)

## 3. Go (`go.mod`)

```bash
go mod download
```

**Verification:**
- Format: `gofmt -w <edited-go-files>`
- Vet & Tests: `go vet ./...` and `go test ./...` (or targeted packages `go test ./internal/...`)

## 4. Python (`pyproject.toml` / `requirements.txt`)

```bash
if command -v uv >/dev/null 2>&1 && [[ -f uv.lock || -f pyproject.toml ]]; then
  uv sync --frozen || uv venv && uv pip install -e ".[dev]"
else
  python3 -m venv .venv
  .venv/bin/pip install -q -r requirements.txt
fi
```

**Verification:**
- Tests & Lint: `pytest`, `ruff check <files>`, `ruff format --check <files>`

## 5. Rust (`Cargo.toml`)

**Verification:**
- `cargo fmt --check`, `cargo clippy --all-targets -- -D warnings`, `cargo test`
