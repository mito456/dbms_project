from fastapi import APIRouter, Depends
from typing import List
import psycopg
from app.core.database import get_db_connection
from app.schemas.all_schemas import TopicBase, ResearchTopicOut
from app.services.activity_service import get_recent_activities

router = APIRouter()

@router.get("/topics", response_model=List[ResearchTopicOut])
def get_research_topics(conn: psycopg.Connection = Depends(get_db_connection)):
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT 
                t.topic_id,
                t.name,
                t.category,
                t.description,
                COUNT(DISTINCT pt.publication_id) AS publication_count,
                COUNT(DISTINCT rt.researcher_id) AS researcher_count
            FROM research_topic t
            LEFT JOIN publication_topic pt ON t.topic_id = pt.topic_id
            LEFT JOIN researcher_topic rt ON t.topic_id = rt.topic_id
            GROUP BY t.topic_id, t.name, t.category, t.description
            ORDER BY t.category, t.name;
            """
        )
        return cur.fetchall()

@router.get("/conferences")
def get_conferences(conn: psycopg.Connection = Depends(get_db_connection)):
    with conn.cursor() as cur:
        cur.execute(
            """
            SELECT 
                conference_id,
                name,
                location,
                start_date,
                end_date,
                submission_deadline,
                status,
                url
            FROM conference
            ORDER BY submission_deadline ASC;
            """
        )
        return cur.fetchall()

@router.get("/stats")
def get_system_stats(conn: psycopg.Connection = Depends(get_db_connection)):
    with conn.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM publication;")
        pub_count = cur.fetchone()["count"]
        cur.execute("SELECT COUNT(*) FROM researcher;")
        res_count = cur.fetchone()["count"]
        cur.execute("SELECT COUNT(*) FROM conference;")
        conf_count = cur.fetchone()["count"]
        cur.execute("SELECT COUNT(*) FROM research_topic;")
        topic_count = cur.fetchone()["count"]
        cur.execute("SELECT COUNT(*) FROM collaboration;")
        collab_count = cur.fetchone()["count"]
        cur.execute("SELECT COUNT(*) FROM project;")
        proj_count = cur.fetchone()["count"]
    
    return {
        "publications": pub_count,
        "researchers": res_count,
        "conferences": conf_count,
        "topics": topic_count,
        "collaborations": collab_count,
        "projects": proj_count,
    }

@router.get("/activity-logs")
def get_logs(limit: int = 50):
    return get_recent_activities(limit=limit)
