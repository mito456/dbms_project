from fastapi import APIRouter, Depends, HTTPException, Query
from typing import List, Optional
import psycopg
from app.core.database import get_db_connection
from app.api.deps import get_current_user
from app.schemas.all_schemas import (
    CollaboratorRecommendation,
    ConferenceRecommendation
)
from app.services.activity_service import log_research_activity

router = APIRouter()

@router.get("/collaborators", response_model=List[CollaboratorRecommendation])
def recommend_collaborators(
    target_id: Optional[int] = None,
    limit: int = Query(default=5, ge=1, le=20),
    current_user: dict = Depends(get_current_user),
    conn: psycopg.Connection = Depends(get_db_connection)
):
    """
    Recommend collaborators based on:
    1. Direct Jaccard Topic Similarity (via stored function fn_calculate_topic_similarity)
    2. Shared publication topics & co-authorship history
    3. Publication-embedding semantic similarity across authors' papers
    """
    researcher_id = target_id if (target_id and current_user.get("role") in ["admin", "super_admin"]) else current_user["id"]

    recommendations = []
    with conn.cursor() as cur:
        # Verify candidate exists
        cur.execute("SELECT researcher_id, name FROM researcher WHERE researcher_id = %s;", (researcher_id,))
        curr = cur.fetchone()
        if not curr:
            raise HTTPException(status_code=404, detail="Target researcher not found")

        # Get all other active researchers
        cur.execute(
            """
            SELECT 
                r.researcher_id,
                r.name,
                r.institution,
                r.bio,
                fn_calculate_topic_similarity(%s, r.researcher_id) AS jaccard_score
            FROM researcher r
            WHERE r.researcher_id != %s AND r.is_active = TRUE;
            """,
            (researcher_id, researcher_id)
        )
        candidates = cur.fetchall()

        for cand in candidates:
            cand_id = cand["researcher_id"]
            jaccard = float(cand["jaccard_score"])

            # 1. Fetch shared topics
            cur.execute(
                """
                SELECT t.name
                FROM researcher_topic rt1
                JOIN researcher_topic rt2 ON rt1.topic_id = rt2.topic_id
                JOIN research_topic t ON rt1.topic_id = t.topic_id
                WHERE rt1.researcher_id = %s AND rt2.researcher_id = %s;
                """,
                (researcher_id, cand_id)
            )
            shared_topics = [r["name"] for r in cur.fetchall()]

            # 2. Check existing co-authorships
            cur.execute(
                """
                SELECT COUNT(DISTINCT a1.publication_id) AS co_authored
                FROM authorship a1
                JOIN authorship a2 ON a1.publication_id = a2.publication_id
                WHERE a1.researcher_id = %s AND a2.researcher_id = %s;
                """,
                (researcher_id, cand_id)
            )
            co_authored_count = cur.fetchone()["co_authored"]

            # 3. Compute publication embedding similarity using pgvector <=> operator
            # Compare papers of researcher_id against cand_id's papers
            cur.execute(
                """
                SELECT 
                    p2.title,
                    ROUND((1 - (p1.embedding <=> p2.embedding))::numeric, 4) AS emb_sim
                FROM authorship a1
                JOIN publication p1 ON a1.publication_id = p1.publication_id
                JOIN authorship a2 ON a2.researcher_id = %s
                JOIN publication p2 ON a2.publication_id = p2.publication_id
                WHERE a1.researcher_id = %s 
                  AND p1.embedding IS NOT NULL 
                  AND p2.embedding IS NOT NULL
                ORDER BY p1.embedding <=> p2.embedding ASC
                LIMIT 1;
                """,
                (cand_id, researcher_id)
            )
            top_match = cur.fetchone()
            emb_similarity = float(top_match["emb_sim"]) if top_match else 0.0
            top_pub_title = top_match["title"] if top_match else None

            # Check pre-computed collaboration table score
            cur.execute(
                """
                SELECT similarity_score
                FROM collaboration
                WHERE (researcher_id_1 = LEAST(%s, %s) AND researcher_id_2 = GREATEST(%s, %s));
                """,
                (researcher_id, cand_id, researcher_id, cand_id)
            )
            existing_collab = cur.fetchone()
            collab_score = float(existing_collab["similarity_score"]) if existing_collab else 0.0

            # Composite hybrid score:
            # 40% embedding similarity + 30% topic jaccard + 20% table similarity + 10% co-authorship signal
            co_author_boost = min(co_authored_count * 0.05, 0.10)
            composite_score = round(
                (0.40 * emb_similarity) + (0.30 * jaccard) + (0.20 * collab_score) + co_author_boost,
                4
            )

            # Cap at 1.0000
            composite_score = min(composite_score, 1.0)

            recommendations.append(
                CollaboratorRecommendation(
                    researcher_id=cand_id,
                    name=cand["name"],
                    institution=cand["institution"],
                    bio=cand["bio"],
                    match_score=composite_score,
                    shared_topics=shared_topics,
                    co_authored_count=co_authored_count,
                    top_matching_publication=top_pub_title
                )
            )

        # Sort descending by match_score
        recommendations.sort(key=lambda x: x.match_score, reverse=True)
        results = recommendations[:limit]

    log_research_activity(
        action="RECOMMEND_COLLABORATORS",
        user_id=researcher_id,
        role=current_user.get("role"),
        details={"returned_count": len(results), "top_score": results[0].match_score if results else 0}
    )

    return results

@router.get("/conferences", response_model=List[ConferenceRecommendation])
def recommend_conferences(
    target_id: Optional[int] = None,
    limit: int = Query(default=6, ge=1, le=20),
    current_user: dict = Depends(get_current_user),
    conn: psycopg.Connection = Depends(get_db_connection)
):
    """
    Recommend upcoming conferences based on:
    1. Researcher's declared topics matching conference Call-for-Papers topics
    2. Researcher's publication topics
    3. Active conference submission timeline (days remaining until deadline)
    """
    researcher_id = target_id if (target_id and current_user.get("role") in ["admin", "super_admin"]) else current_user["id"]

    with conn.cursor() as cur:
        # Retrieve researcher's topics
        cur.execute(
            """
            SELECT DISTINCT topic_id
            FROM researcher_topic
            WHERE researcher_id = %s
            UNION
            SELECT DISTINCT pt.topic_id
            FROM authorship a
            JOIN publication_topic pt ON a.publication_id = pt.publication_id
            WHERE a.researcher_id = %s;
            """,
            (researcher_id, researcher_id)
        )
        user_topic_ids = [r["topic_id"] for r in cur.fetchall()]

        # Query upcoming conferences view v_upcoming_conferences
        cur.execute(
            """
            SELECT 
                c.conference_id,
                c.conference_name,
                c.location,
                c.submission_deadline,
                c.start_date,
                c.end_date,
                c.days_until_deadline,
                c.topic_tracks,
                c.status
            FROM v_upcoming_conferences c
            ORDER BY c.submission_deadline ASC;
            """
        )
        conferences = cur.fetchall()

        results = []
        for conf in conferences:
            cid = conf["conference_id"]
            # Find matching topics
            cur.execute(
                """
                SELECT t.name, ct.topic_id
                FROM conference_topic ct
                JOIN research_topic t ON ct.topic_id = t.topic_id
                WHERE ct.conference_id = %s;
                """,
                (cid,)
            )
            conf_topics = cur.fetchall()
            conf_topic_ids = [ct["topic_id"] for ct in conf_topics]

            shared_tids = set(user_topic_ids).intersection(set(conf_topic_ids))
            matching_topic_names = [ct["name"] for ct in conf_topics if ct["topic_id"] in shared_tids]

            # Compute match score based on Jaccard overlap of topics and deadline proximity
            if conf_topic_ids:
                topic_match = len(shared_tids) / len(conf_topic_ids)
            else:
                topic_match = 0.0

            # Proximity urgency factor (conferences with 30-180 days get higher scheduling priority)
            days = conf["days_until_deadline"]
            if days <= 0:
                urgency = 0.0
            elif days < 30:
                urgency = 0.7  # very tight deadline
            elif days <= 120:
                urgency = 1.0  # optimal submission window
            else:
                urgency = 0.85 # ample preparation time

            score = round((0.75 * topic_match) + (0.25 * urgency), 4)

            results.append(
                ConferenceRecommendation(
                    conference_id=cid,
                    name=conf["conference_name"],
                    location=conf["location"],
                    submission_deadline=conf["submission_deadline"],
                    start_date=conf["start_date"],
                    end_date=conf["end_date"],
                    days_until_deadline=conf["days_until_deadline"],
                    topic_tracks=conf["topic_tracks"],
                    match_score=score,
                    matching_topics=matching_topic_names,
                    status=conf["status"]
                )
            )

        results.sort(key=lambda x: (x.match_score, -x.days_until_deadline), reverse=True)
        final_list = results[:limit]

    log_research_activity(
        action="RECOMMEND_CONFERENCES",
        user_id=researcher_id,
        role=current_user.get("role"),
        details={"returned_count": len(final_list)}
    )

    return final_list
