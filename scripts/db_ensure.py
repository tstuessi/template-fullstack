"""Create the database named in DATABASE_URL if it doesn't already exist.

Pass --recreate to drop it first, for a guaranteed-empty database.
"""

import os
import re
import sys

import psycopg
from psycopg import sql


def _parse(url: str) -> tuple[str, str]:
    # postgresql+psycopg://user:pass@host:port/dbname -> (maintenance dsn, dbname)
    match = re.match(r"^postgresql\+psycopg://(.+)/([^/?]+)(\?.*)?$", url)
    if not match:
        raise ValueError(f"Unrecognized DATABASE_URL: {url}")
    auth_host, dbname = match.group(1), match.group(2)
    return f"postgresql://{auth_host}/postgres", dbname


def main() -> None:
    url = os.environ.get(
        "DATABASE_URL",
        "postgresql+psycopg://postgres:postgres@localhost:5432/app_dev",
    )
    maintenance_dsn, dbname = _parse(url)
    recreate = "--recreate" in sys.argv[1:]

    with psycopg.connect(maintenance_dsn, autocommit=True) as conn:
        if recreate:
            conn.execute(sql.SQL("DROP DATABASE IF EXISTS {} WITH (FORCE)").format(sql.Identifier(dbname)))
            print(f"Dropped database {dbname!r}.")
        exists = conn.execute("SELECT 1 FROM pg_database WHERE datname = %s", (dbname,)).fetchone()
        if exists:
            print(f"Database {dbname!r} already exists.")
            return
        conn.execute(sql.SQL("CREATE DATABASE {}").format(sql.Identifier(dbname)))
        print(f"Created database {dbname!r}.")


if __name__ == "__main__":
    sys.exit(main())
