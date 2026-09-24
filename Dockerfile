# syntax=docker/dockerfile:1

# Build stage: uv resolves/installs into a venv baked into the image.
FROM python:3.13-slim-bookworm AS build
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

# Dependencies first, separate from source, so this (slow) layer only
# invalidates on pyproject.toml/uv.lock changes. --locked, not
# --frozen: fail loudly if uv.lock is out of sync rather than silently
# building from a stale lock. README.md has to come along even for
# this deps-only pass -- hatchling reads pyproject.toml's
# `readme = "README.md"` and fails the build outright without it.
COPY pyproject.toml uv.lock README.md ./
RUN uv sync --locked --no-install-project --no-dev

COPY src/ ./src/
COPY alembic/ ./alembic/
COPY alembic.ini ./
RUN uv sync --locked --no-dev

# Runtime stage: no uv, no build tooling, no dev dependency group.
FROM python:3.13-slim-bookworm AS runtime

RUN groupadd --gid 1000 app \
    && useradd --uid 1000 --gid app --create-home --shell /usr/sbin/nologin app

WORKDIR /app
COPY --from=build --chown=app:app /app /app
# `task build` runs before this (see Taskfile.yml's `prod` task) and
# copies the built frontend into src/app/static before the build
# context is sent, so it's already part of the COPY above.

USER app
ENV PATH="/app/.venv/bin:$PATH"

EXPOSE 8000
CMD ["sh", "-c", "alembic upgrade head && uvicorn app.main:app --host 0.0.0.0 --port 8000"]
