#!/usr/bin/env bash
# Resolves and installs current-latest versions of every tool this
# template uses, instead of the template itself shipping pinned
# versions that go stale. See README.md "Why there's a setup.sh".
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

for cmd in uv npm npx; do
    command -v "$cmd" >/dev/null || { echo "setup.sh: '$cmd' not found on PATH" >&2; exit 1; }
done

if [ -t 0 ]; then
    read -r -p "Project name [fullstack-template]: " project_name
else
    project_name=""
    echo "Non-interactive shell — using default project name 'fullstack-template'."
fi
project_name="${project_name:-fullstack-template}"

echo "==> Setting project name to '${project_name}' in pyproject.toml"
sed -i "s|^name = \".*\"|name = \"${project_name}\"|" pyproject.toml

echo "==> Backend: resolving latest dependency versions with uv"
uv add fastapi "uvicorn[standard]" sqlmodel alembic "psycopg[binary]" \
       pydantic-settings python-multipart
uv add --dev pytest pytest-asyncio pytest-cov ruff mypy httpx respx pre-commit

echo "==> Frontend: scaffolding with create-vite"
if [ -d frontend ]; then
    echo "    frontend/ already exists — skipping scaffold (delete it first to re-scaffold)"
else
    # `npx --yes` (not `npm create ... --`) so npm's "Need to install
    # create-vite@x — Ok to proceed?" confirmation never blocks on stdin.
    # `< /dev/null` is defense-in-depth: if anything downstream still
    # tries to prompt, it fails fast on EOF instead of hanging and
    # leaking whatever gets typed next into the next command.
    npx --yes create-vite@latest frontend --template react-ts < /dev/null
fi

echo "==> Frontend: applying hello-world overlay (replaces vite's scaffold source)"
# Applied before `npm install` below, not after — the overlay's
# .npmrc (force=true) has to be in place before any npm install runs
# in frontend/, or a peer-dependency mismatch between two
# independently-"latest" packages fails the install outright.
cp -r frontend-overlay/. frontend/
# Leftover create-vite scaffold source that isn't referenced by the
# overlay above. Not the default asset files in src/assets/ or
# public/ (e.g. favicon.svg) — those change name across create-vite
# versions and index.html/nothing here depends on chasing them by
# name; biome.json excludes public/ from lint instead.
rm -f frontend/src/App.css

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

    # `npm pkg set` above rewrites package.json with its own (tab)
    # formatting, which fails `task lint:frontend` the moment it's run
    # -- normalize everything to biome's own formatting now so the repo
    # starts clean instead of failing its own first lint check.
    npm run fmt
)

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
