"""SQLAlchemy-Engine aus Umgebungsvariablen (.env)."""

import os

from dotenv import load_dotenv
from sqlalchemy import URL, Engine, create_engine


def get_url() -> URL:
    load_dotenv()
    return URL.create(
        "postgresql+psycopg",
        username=os.environ["POSTGRES_USER"],
        password=os.environ["POSTGRES_PASSWORD"],
        host=os.getenv("POSTGRES_HOST", "localhost"),
        port=int(os.getenv("POSTGRES_PORT", "5433")),
        database=os.environ["POSTGRES_DB"],
    )


def get_engine(**kwargs) -> Engine:
    return create_engine(get_url(), pool_pre_ping=True, **kwargs)
