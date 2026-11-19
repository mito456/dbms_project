from datetime import datetime, timezone
from decimal import Decimal
from typing import Any, Dict, Optional
from app.core.database import get_mongo_db

def _clean_for_mongo(obj: Any) -> Any:
    if isinstance(obj, Decimal):
        return float(obj)
    if isinstance(obj, dict):
        return {k: _clean_for_mongo(v) for k, v in obj.items()}
    if isinstance(obj, list):
        return [_clean_for_mongo(item) for item in obj]
    return obj

def log_research_activity(
    action: str,
    user_id: Optional[int] = None,
    user_email: Optional[str] = None,
    role: Optional[str] = None,
    details: Optional[Dict[str, Any]] = None,
    ip_address: Optional[str] = None,
) -> bool:
    """Log researcher and user activities asynchronously or synchronously to MongoDB."""
    try:
        db = get_mongo_db()
        doc = {
            "action": action,
            "user_id": user_id,
            "user_email": user_email,
            "role": role,
            "details": _clean_for_mongo(details or {}),
            "ip_address": ip_address,
            "timestamp": datetime.now(timezone.utc)
        }
        db["activity_logs"].insert_one(doc)
        return True
    except Exception as e:
        print(f"[Mongo Activity Log Warning] Failed to write log: {e}")
        return False

def get_recent_activities(limit: int = 50, user_id: Optional[int] = None) -> list[dict]:
    try:
        db = get_mongo_db()
        query = {}
        if user_id is not None:
            query["user_id"] = user_id
        cursor = db["activity_logs"].find(query).sort("timestamp", -1).limit(limit)
        results = []
        for doc in cursor:
            doc["id"] = str(doc.pop("_id"))
            if isinstance(doc.get("timestamp"), datetime):
                doc["timestamp"] = doc["timestamp"].isoformat()
            results.append(doc)
        return results
    except Exception as e:
        print(f"[Mongo Query Warning] Failed to read activity logs: {e}")
        return []
