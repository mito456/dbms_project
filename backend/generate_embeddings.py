from pathlib import Path
import os

import psycopg
from dotenv import load_dotenv
from sentence_transformers import SentenceTransformer

# Load environment variables from the project root .env
ROOT_DIR = Path(__file__).resolve().parents[1]
load_dotenv(ROOT_DIR / ".env")

DATABASE_URL = os.getenv("DATABASE_URL")
DB_HOST = os.getenv("DB_HOST", "127.0.0.1")
DB_PORT = os.getenv("POSTGRES_PORT", "5433")
DB_NAME = os.getenv("POSTGRES_DB", "research_db")
DB_USER = os.getenv("POSTGRES_USER", "postgres")
DB_PASSWORD = os.getenv("POSTGRES_PASSWORD", "postgres")

MODEL_NAME = "BAAI/bge-base-en-v1.5"


def get_connection():
    """Connect using DATABASE_URL or individual connection parameters with timeout."""
    conn_params = {
        "connect_timeout": 10,
    }

    if DATABASE_URL:
        try:
            return psycopg.connect(DATABASE_URL, **conn_params)
        except psycopg.Error:
            pass

    conn_str = (
        f"host={DB_HOST} "
        f"port={DB_PORT} "
        f"dbname={DB_NAME} "
        f"user={DB_USER} "
        f"password={DB_PASSWORD}"
    )
    return psycopg.connect(conn_str, **conn_params)


def main():
    print(f"Loading embedding model: {MODEL_NAME}")
    model = SentenceTransformer(MODEL_NAME)

    print(f"Connecting to PostgreSQL (host: {DB_HOST}, port: {DB_PORT}, db: {DB_NAME})...")

    try:
        conn = get_connection()
    except Exception as exc:
        print(f"\n[Connection Error] Could not connect to PostgreSQL on port {DB_PORT}.")
        print("Please check that:")
        print("  1. The Docker container 'research_intelligence_db' is running (`docker compose up -d postgres`)")
        print("  2. If using local PostgreSQL instead of Docker, verify POSTGRES_PORT in .env (default Docker port is 5433, local service is typically 5432)")
        print(f"Error details: {exc}\n")
        raise

    with conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT publication_id, title, abstract
                FROM publication
                WHERE embedding IS NULL
                ORDER BY publication_id
                """
            )
            publications = cur.fetchall()

            if not publications:
                print("No publications need embeddings.")
                return

            print(f"Generating embeddings for {len(publications)} publications...")

            texts = [
                f"Title: {title or ''}. Abstract: {abstract or ''}".strip()
                for _, title, abstract in publications
            ]

            embeddings = model.encode(
                texts,
                normalize_embeddings=True,
                show_progress_bar=True,
            )

            for (publication_id, _, _), embedding in zip(
                publications, embeddings
            ):
                vector_text = "[" + ",".join(
                    str(float(value)) for value in embedding
                ) + "]"

                cur.execute(
                    """
                    UPDATE publication
                    SET embedding = %s::vector
                    WHERE publication_id = %s
                    """,
                    (vector_text, publication_id),
                )

        conn.commit()

    print(f"Successfully stored {len(publications)} publication embeddings.")


if __name__ == "__main__":
    main()

