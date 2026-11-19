from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List, Optional
import psycopg
from app.core.database import get_db_connection
from app.api.deps import get_current_user
from app.schemas.all_schemas import (
    PublicationOut,
    PublicationCreate,
    SemanticSearchQuery
)
from app.services.embedding_service import embedding_service
from app.services.activity_service import log_research_activity

router = APIRouter()

@router.get("", response_model=List[PublicationOut])
def list_publications(
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    topic_id: Optional[int] = None,
    conn: psycopg.Connection = Depends(get_db_connection)
):
    with conn.cursor() as cur:
        if topic_id:
            cur.execute(
                """
                SELECT v.publication_id, v.title, p.abstract, v.publication_date, v.doi, v.url,
                       p.created_at, v.authors, v.topics
                FROM v_publication_details v
                JOIN publication p ON v.publication_id = p.publication_id
                JOIN publication_topic pt ON p.publication_id = pt.publication_id
                WHERE pt.topic_id = %s
                ORDER BY v.publication_date DESC
                LIMIT %s OFFSET %s;
                """,
                (topic_id, limit, offset)
            )
        else:
            cur.execute(
                """
                SELECT v.publication_id, v.title, p.abstract, v.publication_date, v.doi, v.url,
                       p.created_at, v.authors, v.topics
                FROM v_publication_details v
                JOIN publication p ON v.publication_id = p.publication_id
                ORDER BY v.publication_date DESC
                LIMIT %s OFFSET %s;
                """,
                (limit, offset)
            )
        rows = cur.fetchall()
        return rows

@router.get("/{publication_id}", response_model=PublicationOut)
def get_publication(
    publication_id: int,
    conn: psycopg.Connection = Depends(get_db_connection)
):
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT v.publication_id, v.title, p.abstract, v.publication_date, v.doi, v.url,
                   p.created_at, v.authors, v.topics
            FROM v_publication_details v
            JOIN publication p ON v.publication_id = p.publication_id
            WHERE v.publication_id = %s;
            """,
            (publication_id,)
        )
        row = cur.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Publication not found")
        return row

@router.post("/search/semantic", response_model=List[PublicationOut])
def semantic_search_publications(
    req: SemanticSearchQuery,
    conn: psycopg.Connection = Depends(get_db_connection)
):
    """
    Cosines similarity vector search using pgvector (<=> operator).
    Similarity = 1 - (embedding <=> query_vector).
    """
    # 1. Encode query with BAAI/bge-base-en-v1.5
    query_vector = embedding_service.encode_text(req.query)
    vec_str = "[" + ",".join(str(v) for v in query_vector) + "]"

    with conn.cursor() as cur:
        if req.topic_id:
            cur.execute(
                """
                SELECT 
                    p.publication_id,
                    p.title,
                    p.abstract,
                    p.publication_date,
                    p.doi,
                    p.url,
                    p.created_at,
                    v.authors,
                    v.topics,
                    ROUND((1 - (p.embedding <=> %s::vector))::numeric, 4) AS similarity_score
                FROM publication p
                LEFT JOIN v_publication_details v ON p.publication_id = v.publication_id
                JOIN publication_topic pt ON p.publication_id = pt.publication_id
                WHERE p.embedding IS NOT NULL 
                  AND pt.topic_id = %s
                  AND (1 - (p.embedding <=> %s::vector)) >= %s
                ORDER BY p.embedding <=> %s::vector ASC
                LIMIT %s;
                """,
                (vec_str, req.topic_id, vec_str, req.min_similarity, vec_str, req.limit)
            )
        else:
            cur.execute(
                """
                SELECT 
                    p.publication_id,
                    p.title,
                    p.abstract,
                    p.publication_date,
                    p.doi,
                    p.url,
                    p.created_at,
                    v.authors,
                    v.topics,
                    ROUND((1 - (p.embedding <=> %s::vector))::numeric, 4) AS similarity_score
                FROM publication p
                LEFT JOIN v_publication_details v ON p.publication_id = v.publication_id
                WHERE p.embedding IS NOT NULL
                  AND (1 - (p.embedding <=> %s::vector)) >= %s
                ORDER BY p.embedding <=> %s::vector ASC
                LIMIT %s;
                """,
                (vec_str, vec_str, req.min_similarity, vec_str, req.limit)
            )
        results = cur.fetchall()

    # Log semantic search query to MongoDB
    log_research_activity(
        action="SEMANTIC_SEARCH",
        details={
            "query": req.query,
            "topic_filter": req.topic_id,
            "results_count": len(results),
            "top_similarity": results[0]["similarity_score"] if results else None
        }
    )

    return results

@router.post("", response_model=PublicationOut)
def create_publication(
    pub: PublicationCreate,
    current_user: dict = Depends(get_current_user),
    conn: psycopg.Connection = Depends(get_db_connection)
):
    """
    Creates a new publication, generates its embedding via BGE model,
    assigns primary author (current_user), and links research topics.
    """
    text_to_embed = f"Title: {pub.title}. Abstract: {pub.abstract or ''}".strip()
    embedding = embedding_service.encode_text(text_to_embed)
    vec_str = "[" + ",".join(str(v) for v in embedding) + "]"

    with conn.cursor() as cur:
        cur.execute(
            """
            INSERT INTO publication (title, abstract, publication_date, url, doi, embedding)
            VALUES (%s, %s, %s, %s, %s, %s::vector)
            RETURNING publication_id, title, abstract, publication_date, url, doi, created_at;
            """,
            (pub.title, pub.abstract, pub.publication_date, pub.url, pub.doi, vec_str)
        )
        new_pub = cur.fetchone()
        pid = new_pub["publication_id"]

        # Link author (current researcher or if admin, author_id)
        if current_user.get("role") == "researcher":
            cur.execute(
                """
                INSERT INTO authorship (researcher_id, publication_id, author_order)
                VALUES (%s, %s, 1);
                """,
                (current_user["id"], pid)
            )
            
        # Optional co-authors
        if pub.co_author_ids:
            order = 2
            for ca_id in pub.co_author_ids:
                if ca_id != current_user.get("id"):
                    cur.execute(
                        """
                        INSERT INTO authorship (researcher_id, publication_id, author_order)
                        VALUES (%s, %s, %s)
                        ON CONFLICT DO NOTHING;
                        """,
                        (ca_id, pid, order)
                    )
                    order += 1

        # Link topics
        if pub.topic_ids:
            for tid in pub.topic_ids:
                cur.execute(
                    """
                    INSERT INTO publication_topic (publication_id, topic_id)
                    VALUES (%s, %s)
                    ON CONFLICT DO NOTHING;
                    """,
                    (pid, tid)
                )

        conn.commit()

        # Retrieve enriched view
        cur.execute(
            """
            SELECT v.publication_id, v.title, p.abstract, v.publication_date, v.doi, v.url,
                   p.created_at, v.authors, v.topics
            FROM v_publication_details v
            JOIN publication p ON v.publication_id = p.publication_id
            WHERE v.publication_id = %s;
            """,
            (pid,)
        )
        enriched = cur.fetchone()

    log_research_activity(
        action="PUBLICATION_CREATED",
        user_id=current_user.get("id"),
        user_email=current_user.get("email"),
        role=current_user.get("role"),
        details={"publication_id": pid, "title": pub.title}
    )

    return enriched
