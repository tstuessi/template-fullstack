"""Truncate all app tables in the database named by DATABASE_URL.

Usage: uv run scripts/db_reset.py [--yes]
"""

import os
import sys

from sqlalchemy import create_engine, text
from sqlmodel import SQLModel

# Import model modules here so their tables register on SQLModel.metadata.
# from app import models


def main() -> None:
    yes = "--yes" in sys.argv[1:]
    url = os.environ.get(
        "DATABASE_URL",
        "postgresql+psycopg://postgres:postgres@localhost:5432/app_dev",
    )

    tables = list(SQLModel.metadata.tables)
    if not tables:
        print("No tables registered on SQLModel.metadata — nothing to truncate.")
        return

    if not yes:
        answer = input(f"Truncate {len(tables)} table(s) in {url!r}? [y/N] ")
        if answer.strip().lower() != "y":
            print("Aborted.")
            return

    engine = create_engine(url)
    with engine.begin() as conn:
        conn.execute(text(f"TRUNCATE TABLE {', '.join(tables)} RESTART IDENTITY CASCADE"))
    print(f"Truncated {len(tables)} table(s).")


if __name__ == "__main__":
    main()
