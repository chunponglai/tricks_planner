from datetime import date
from fastapi.testclient import TestClient

from app.main import app
from app import db, models

client = TestClient(app)


def _clear_db():
    session = db.SessionLocal()
    try:
        session.query(models.TrainingItem).delete()
        session.query(models.DailyTrainingPlan).delete()
        session.query(models.TrainingTemplateItem).delete()
        session.query(models.TrainingTemplate).delete()
        session.query(models.Challenge).delete()
        session.query(models.Trick).delete()
        session.query(models.User).delete()
        session.commit()
    finally:
        session.close()


def _auth_header(email="test@example.com", password="secret123"):
    _clear_db()
    r = client.post("/auth/register", json={"email": email, "password": password})
    assert r.status_code == 200
    r = client.post("/auth/login", data={"username": email, "password": password})
    assert r.status_code == 200
    token = r.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_auth_me():
    headers = _auth_header()
    r = client.get("/me", headers=headers)
    assert r.status_code == 200
    assert r.json()["email"] == "test@example.com"


def test_tricks_crud():
    headers = _auth_header()
    r = client.post("/tricks", headers=headers, json={"name": "Kickflip", "category": "Flips", "difficulty": "medium"})
    assert r.status_code == 200
    trick_id = r.json()["id"]

    r = client.get("/tricks", headers=headers)
    assert r.status_code == 200
    assert len(r.json()) == 1

    r = client.delete(f"/tricks/{trick_id}", headers=headers)
    assert r.status_code == 200

    r = client.get("/tricks", headers=headers)
    assert r.status_code == 200
    assert len(r.json()) == 0


def test_templates_crud():
    headers = _auth_header()
    payload = {
        "name": "Daily Warmup",
        "items": [
            {"trick_name": "Ollie", "category": "Old School", "difficulty": "easy", "target_count": 5},
            {"trick_name": "Kickflip", "category": "Flips", "difficulty": "medium", "target_count": 5}
        ]
    }
    r = client.post("/templates", headers=headers, json=payload)
    assert r.status_code == 200
    template_id = r.json()["id"]

    r = client.get("/templates", headers=headers)
    assert r.status_code == 200
    assert len(r.json()) == 1

    r = client.delete(f"/templates/{template_id}", headers=headers)
    assert r.status_code == 200


def test_challenges():
    headers = _auth_header()
    payload = {
        "day": str(date(2026, 2, 5)),
        "status": "notDone",
        "combo_json": "[{\"name\":\"Kickflip\"}]"
    }
    r = client.post("/challenges", headers=headers, json=payload)
    assert r.status_code == 200

    r = client.get("/challenges", headers=headers)
    assert r.status_code == 200
    assert len(r.json()) == 1


def test_training_plans():
    headers = _auth_header()
    payload = {
        "day": str(date(2026, 2, 5)),
        "items": [
            {"trick_name": "Manual", "category": "Manuals", "difficulty": "easy", "target_count": 5, "completed_count": 2}
        ]
    }
    r = client.post("/training-plans", headers=headers, json=payload)
    assert r.status_code == 200

    r = client.get("/training-plans", headers=headers)
    assert r.status_code == 200
    assert len(r.json()) == 1
