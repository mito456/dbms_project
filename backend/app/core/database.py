from typing import Generator
import psycopg
from psycopg.rows import dict_row
from pymongo import MongoClient
from app.core.config import settings

def get_db_connection() -> Generator[psycopg.Connection, None, None]:
    """Dependency generator that yields a PostgreSQL connection with dict cursor."""
    conn = psycopg.connect(
        settings.DATABASE_URL,
        row_factory=dict_row,
        autocommit=False
    )
    try:
        yield conn
    finally:
        conn.close()

_mongo_client: MongoClient | None = None

def get_mongo_client() -> MongoClient:
    global _mongo_client
    if _mongo_client is None:
        _mongo_client = MongoClient(settings.MONGO_URI, serverSelectionTimeoutMS=4000)
    return _mongo_client

def get_mongo_db():
    client = get_mongo_client()
    return client[settings.MONGO_DB_NAME]
