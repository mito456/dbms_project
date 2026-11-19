import os
from pathlib import Path
import psycopg
import numpy as np
from dotenv import load_dotenv
from sentence_transformers import SentenceTransformer

load_dotenv(Path(__file__).resolve().parents[1] / ".env")

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:postgres@localhost:5433/research_db")
MODEL_NAME = "BAAI/bge-base-en-v1.5"

def validate_and_sync_embeddings(fix_invalid=True):
    print(f"Loading embedding model: {MODEL_NAME}...")
    model = SentenceTransformer(MODEL_NAME)
    
    print(f"Connecting to database at {DATABASE_URL}...")
    conn = psycopg.connect(DATABASE_URL)
    
    with conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT publication_id, title, abstract, embedding::text
                FROM publication
                ORDER BY publication_id;
            """)
            rows = cur.fetchall()
            
            print(f"Total publications retrieved: {len(rows)}")
            invalid_count = 0
            updated_count = 0
            
            for pid, title, abstract, emb_str in rows:
                text = f"Title: {title or ''}. Abstract: {abstract or ''}".strip()
                computed_vector = model.encode(text, normalize_embeddings=True)
                
                if emb_str is None:
                    print(f"[Publication {pid}] Embedding is MISSING.")
                    is_valid = False
                    cos_sim = 0.0
                else:
                    db_vec = np.array([float(x) for x in emb_str.strip("[]").split(",")])
                    norm_db = np.linalg.norm(db_vec)
                    norm_calc = np.linalg.norm(computed_vector)
                    if norm_db == 0 or norm_calc == 0:
                        cos_sim = 0.0
                    else:
                        cos_sim = float(np.dot(db_vec, computed_vector) / (norm_db * norm_calc))
                    is_valid = (cos_sim >= 0.99)
                
                print(f"Pub {pid:2d} | Similarity to true BGE embedding: {cos_sim:.4f} | Valid: {is_valid} | '{title[:45]}...'")
                
                if not is_valid:
                    invalid_count += 1
                    if fix_invalid:
                        vec_literal = "[" + ",".join(str(float(v)) for v in computed_vector) + "]"
                        cur.execute(
                            "UPDATE publication SET embedding = %s::vector WHERE publication_id = %s;",
                            (vec_literal, pid)
                        )
                        updated_count += 1
            
            if fix_invalid and updated_count > 0:
                conn.commit()
                print(f"\n[Validation & Sync] Safely regenerated and updated {updated_count} publication embeddings in DB.")
            else:
                print(f"\n[Validation] All embeddings valid: {invalid_count == 0}")

if __name__ == "__main__":
    validate_and_sync_embeddings(fix_invalid=True)
