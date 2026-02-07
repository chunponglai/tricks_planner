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


def _register_and_login(email: str, password: str):
    r = client.post("/auth/register", json={"email": email, "password": password})
    assert r.status_code == 200
    r = client.post("/auth/login", data={"username": email, "password": password})
    assert r.status_code == 200
    token = r.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_full_flow():
    _clear_db()
    headers = _register_and_login("flow@example.com", "secret123")

    # Create tricks
    r = client.post("/tricks", headers=headers, json={"name": "Kickflip", "category": "Flips", "difficulty": "medium"})
    assert r.status_code == 200
    kickflip_id = r.json()["id"]

    r = client.post("/tricks", headers=headers, json={"name": "Ollie", "category": "Old School", "difficulty": "easy"})
    assert r.status_code == 200

    r = client.get("/tricks", headers=headers)
    assert r.status_code == 200
    assert len(r.json()) == 2

    # Delete one trick
    r = client.delete(f"/tricks/{kickflip_id}", headers=headers)
    assert r.status_code == 200

    # Create template
    r = client.post(
        "/templates",
        headers=headers,
        json={
            "name": "Daily Warmup",
            "items": [
                {"trick_name": "Ollie", "category": "Old School", "difficulty": "easy", "target_count": 5}
            ]
        },
    )
    assert r.status_code == 200
    template_id = r.json()["id"]

    r = client.get("/templates", headers=headers)
    assert r.status_code == 200
    assert len(r.json()) == 1

    # Create challenge
    r = client.post(
        "/challenges",
        headers=headers,
        json={"day": str(date(2026, 2, 6)), "status": "notDone", "combo_json": "[{\"name\":\"Ollie\"}]"},
    )
    assert r.status_code == 200

    # Create training plan
    r = client.post(
        "/training-plans",
        headers=headers,
        json={
            "day": str(date(2026, 2, 6)),
            "items": [
                {"trick_name": "Ollie", "category": "Old School", "difficulty": "easy", "target_count": 5, "completed_count": 1}
            ],
        },
    )
    assert r.status_code == 200

    # Verify lists
    r = client.get("/challenges", headers=headers)
    assert r.status_code == 200
    assert len(r.json()) == 1

    r = client.get("/training-plans", headers=headers)
    assert r.status_code == 200
    assert len(r.json()) == 1

    # Delete template
    r = client.delete(f"/templates/{template_id}", headers=headers)
    assert r.status_code == 200
