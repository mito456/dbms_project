from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List, Optional
import psycopg
from app.core.database import get_db_connection
from app.api.deps import get_current_user
from app.schemas.all_schemas import (
    ResearcherProfile,
    ResearcherUpdate,
    ResearcherTopicOut,
    PublicationOut
)
from app.services.activity_service import log_research_activity

router = APIRouter()

@router.get("/me", response_model=ResearcherProfile)
def get_my_profile(
    current_user: dict = Depends(get_current_user),
    conn: psycopg.Connection = Depends(get_db_connection)
):
    user_id = current_user["id"]
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT researcher_id, name, email, institution, bio, is_active, created_at
            FROM researcher
            WHERE researcher_id = %s;
            """,
            (user_id,)
        )
        profile = cur.fetchone()
        if not profile:
            raise HTTPException(status_code=404, detail="Researcher profile not found")

        # Fetch topics
        cur.execute(
            """
            SELECT t.topic_id, t.name, t.category, rt.interest_level
            FROM researcher_topic rt
            JOIN research_topic t ON rt.topic_id = t.topic_id
            WHERE rt.researcher_id = %s
            ORDER BY t.name;
            """,
            (user_id,)
        )
        topics = cur.fetchall()

        # Fetch publication count via stored function fn_get_researcher_pub_count
        cur.execute("SELECT fn_get_researcher_pub_count(%s);", (user_id,))
        pub_count = cur.fetchone()["fn_get_researcher_pub_count"]

    profile["topics"] = topics
    profile["publications_count"] = pub_count
    return profile

@router.get("/{researcher_id}", response_model=ResearcherProfile)
def get_researcher_profile(
    researcher_id: int,
    conn: psycopg.Connection = Depends(get_db_connection)
):
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT researcher_id, name, email, institution, bio, is_active, created_at
            FROM researcher
            WHERE researcher_id = %s;
            """,
            (researcher_id,)
        )
        profile = cur.fetchone()
        if not profile:
            raise HTTPException(status_code=404, detail="Researcher not found")

        cur.execute(
            """
            SELECT t.topic_id, t.name, t.category, rt.interest_level
            FROM researcher_topic rt
            JOIN research_topic t ON rt.topic_id = t.topic_id
            WHERE rt.researcher_id = %s
            ORDER BY t.name;
            """,
            (researcher_id,)
        )
        topics = cur.fetchall()

        cur.execute("SELECT fn_get_researcher_pub_count(%s);", (researcher_id,))
        pub_count = cur.fetchone()["fn_get_researcher_pub_count"]

    profile["topics"] = topics
    profile["publications_count"] = pub_count
    return profile

@router.get("", response_model=List[ResearcherProfile])
def list_researchers(
    limit: int = Query(default=20, ge=1, le=100),
    topic_id: Optional[int] = None,
    conn: psycopg.Connection = Depends(get_db_connection)
):
    with conn.cursor() as cur:
        if topic_id:
            cur.execute(
                """
                SELECT r.researcher_id, r.name, r.email, r.institution, r.bio, r.is_active, r.created_at,
                       COALESCE(rpc.total_publications, 0) AS publications_count
                FROM researcher r
                JOIN researcher_topic rt ON r.researcher_id = rt.researcher_id
                LEFT JOIN v_researcher_publication_counts rpc ON r.researcher_id = rpc.researcher_id
                WHERE rt.topic_id = %s
                ORDER BY r.name
                LIMIT %s;
                """,
                (topic_id, limit)
            )
        else:
            cur.execute(
                """
                SELECT r.researcher_id, r.name, r.email, r.institution, r.bio, r.is_active, r.created_at,
                       COALESCE(rpc.total_publications, 0) AS publications_count
                FROM researcher r
                LEFT JOIN v_researcher_publication_counts rpc ON r.researcher_id = rpc.researcher_id
                ORDER BY r.name
                LIMIT %s;
                """,
                (limit,)
            )
        researchers = cur.fetchall()
        for r in researchers:
            cur.execute(
                """
                SELECT t.topic_id, t.name, t.category, rt.interest_level
                FROM researcher_topic rt
                JOIN research_topic t ON rt.topic_id = t.topic_id
                WHERE rt.researcher_id = %s;
                """,
                (r["researcher_id"],)
            )
            r["topics"] = cur.fetchall()

    return researchers

@router.put("/me", response_model=ResearcherProfile)
def update_my_profile(
    update_data: ResearcherUpdate,
    current_user: dict = Depends(get_current_user),
    conn: psycopg.Connection = Depends(get_db_connection)
):
    user_id = current_user["id"]
    with conn.cursor() as cur:
        if update_data.name or update_data.institution or update_data.bio:
            cur.execute(
                """
                UPDATE researcher
                SET name = COALESCE(%s, name),
                    institution = COALESCE(%s, institution),
                    bio = COALESCE(%s, bio)
                WHERE researcher_id = %s;
                """,
                (update_data.name, update_data.institution, update_data.bio, user_id)
            )

        # Update topics if supplied
        if update_data.topics is not None:
            cur.execute("DELETE FROM researcher_topic WHERE researcher_id = %s;", (user_id,))
            for item in update_data.topics:
                tid = item.get("topic_id")
                level = item.get("interest_level", "intermediate")
                cur.execute(
                    """
                    INSERT INTO researcher_topic (researcher_id, topic_id, interest_level)
                    VALUES (%s, %s, %s);
                    """,
                    (user_id, tid, level)
                )

        conn.commit()

    log_research_activity(
        action="PROFILE_UPDATED",
        user_id=user_id,
        user_email=current_user.get("email"),
        role="researcher",
        details={"updated_fields": [k for k, v in update_data.dict().items() if v is not None]}
    )

    return get_my_profile(current_user, conn)
