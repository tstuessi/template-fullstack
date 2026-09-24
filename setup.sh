#!/usr/bin/env bash
# Resolves and installs current-latest versions of every tool this
# template uses, instead of the template itself shipping pinned
# versions that go stale. See README.md "Why there's a setup.sh".
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

for cmd in uv npm npx; do
    command -v "$cmd" >/dev/null || { echo "setup.sh: '$cmd' not found on PATH" >&2; exit 1; }
done

echo "==> Backend: resolving latest dependency versions with uv"
uv add fastapi "uvicorn[standard]" sqlmodel alembic "psycopg[binary]" \
       pydantic-settings python-multipart
uv add --dev pytest pytest-asyncio pytest-cov ruff mypy httpx respx pre-commit

echo "==> Frontend: scaffolding with npm create vite@latest"
if [ -d frontend ]; then
    echo "    frontend/ already exists — skipping scaffold (delete it first to re-scaffold)"
else
    npm create vite@latest frontend -- --template react-ts
fi

echo "==> Frontend: installing latest dependency versions"
(
    cd frontend
    npm install @mui/material @emotion/react @emotion/styled react-router openapi-fetch
    npm install -D @biomejs/biome @ladle/react vitest @vitest/coverage-v8 jsdom \
        @testing-library/react @testing-library/jest-dom @testing-library/user-event \
        openapi-typescript

    # vite's react-ts scaffold wires up ESLint by default; this template
    # standardizes on Biome instead (installed above). Left its deps
    # installed-but-unused rather than guessing exact package names to
    # uninstall, since that list drifts with vite's own template.
    rm -f eslint.config.js

    npm pkg set scripts.dev="vite"
    npm pkg set scripts.build="tsc -b && vite build"
    npm pkg set scripts.preview="vite preview"
    npm pkg set scripts.openapi="openapi-typescript --output src/types/api.d.ts http://localhost:8000/openapi.json"
    npm pkg set scripts.test="vitest"
    npm pkg set "scripts.test:run"="vitest run --coverage"
    npm pkg set "scripts.test:ts"="tsc -b --force"
    npm pkg set scripts.lint="biome check ."
    npm pkg set "scripts.lint:fix"="biome check --write ."
    npm pkg set scripts.fmt="biome format --write ."
    npm pkg set "scripts.fmt:check"="biome format ."
    npm pkg set scripts.ladle="ladle serve"
    npm pkg set "scripts.ladle:build"="ladle build"
)

echo "==> Frontend: applying hello-world overlay (replaces vite's scaffold source)"
cp -r frontend-overlay/. frontend/
rm -f frontend/src/App.css frontend/src/assets/react.svg frontend/public/vite.svg 2>/dev/null || true

echo "==> E2E: installing latest Playwright"
npm install -D @playwright/test@latest
npx playwright install --with-deps chromium

echo "==> Installing pre-commit hooks"
uv run pre-commit install

cat <<'EOF'

Setup complete.

Review what changed (uv.lock, frontend/package-lock.json,
package-lock.json, and the generated frontend/ tree), then commit it:

    git add -A
    git commit -m "Run setup.sh: resolve dependency versions"

EOF
