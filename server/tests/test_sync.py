from fastapi.testclient import TestClient

from app.main import app
from app import db, models

client = TestClient(app)


def _clear_db():
    session = db.SessionLocal()
    try:
        session.query(models.UserData).delete()
        session.query(models.User).delete()
        session.commit()
    finally:
        session.close()


def _auth_header(email="sync@example.com", password="secret123"):
    _clear_db()
    r = client.post("/auth/register", json={"email": email, "password": password})
    assert r.status_code == 200
    r = client.post("/auth/login", data={"username": email, "password": password})
    assert r.status_code == 200
    token = r.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_sync_roundtrip():
    headers = _auth_header()

    payload = {
        "categories": ["Uncategorized", "Flips"],
        "tricks": [
            {
                "id": "00000000-0000-0000-0000-000000000001",
                "name": "Kickflip",
                "category": "Flips",
                "difficulty": "medium"
            }
        ],
        "templates": [],
        "challenges": [],
        "trainingPlans": []
    }

    r = client.put("/sync", headers=headers, json=payload)
    assert r.status_code == 200

    r = client.get("/sync", headers=headers)
    assert r.status_code == 200
    data = r.json()
    assert data["categories"] == payload["categories"]
    assert data["tricks"][0]["name"] == "Kickflip"
