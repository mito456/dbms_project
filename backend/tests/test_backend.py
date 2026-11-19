import pytest
from fastapi.testclient import TestClient
import psycopg
from app.main import app
from app.core.config import settings

client = TestClient(app)

def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"

def test_get_publications():
    response = client.get("/api/v1/publications?limit=5")
    assert response.status_code == 200
    data = response.json()
    assert len(data) > 0
    assert "title" in data[0]
    assert "publication_id" in data[0]

def test_semantic_search():
    # Test semantic query for vector database / indexing papers
    req_body = {
        "query": "vector indexing and nearest neighbor search in databases",
        "limit": 5,
        "min_similarity": 0.0
    }
    response = client.post("/api/v1/publications/search/semantic", json=req_body)
    assert response.status_code == 200
    results = response.json()
    assert len(results) > 0
    # Top result should be related to vector search / indexing
    top_result = results[0]
    assert "similarity_score" in top_result
    assert top_result["similarity_score"] > 0.60
    print(f"Top semantic match: '{top_result['title']}' with score {top_result['similarity_score']}")

def test_login_and_auth():
    # Login as Dr. Eleanor Vance (admin)
    login_data = {
        "email": "e.vance@system.admin.org",
        "password": "password"  # handled by our backward-compatible simulatedHash verifier
    }
    response = client.post("/api/v1/auth/login", json=login_data)
    assert response.status_code == 200
    token_info = response.json()
    assert "access_token" in token_info
    assert token_info["role"] in ["admin", "super_admin"]

def test_collaborator_recommendations():
    # Test recommendation endpoint
    # First login as a researcher (Dr. Mei-Ling Zhou)
    login_resp = client.post("/api/v1/auth/login", json={"email": "ml.zhou@shanghai-tech.edu", "password": "password"})
    assert login_resp.status_code == 200
    token = login_resp.json()["access_token"]

    response = client.get(
        "/api/v1/recommendations/collaborators?limit=4",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    recs = response.json()
    assert len(recs) > 0
    assert recs[0]["match_score"] > 0
    print(f"Top collaborator recommendation for Zhou: {recs[0]['name']} (Score: {recs[0]['match_score']})")

def test_conference_recommendations():
    login_resp = client.post("/api/v1/auth/login", json={"email": "ml.zhou@shanghai-tech.edu", "password": "password"})
    assert login_resp.status_code == 200
    token = login_resp.json()["access_token"]

    response = client.get(
        "/api/v1/recommendations/conferences?limit=4",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert response.status_code == 200
    confs = response.json()
    assert len(confs) > 0
    print(f"Top conference recommendation: {confs[0]['name']} (Score: {confs[0]['match_score']})")

def test_metadata_and_stats():
    resp = client.get("/api/v1/meta/stats")
    assert resp.status_code == 200
    stats = resp.json()
    assert stats["publications"] >= 12
    assert stats["researchers"] >= 8
