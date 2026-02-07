import uuid
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)


def test_register_and_login():
    email = f"test-{uuid.uuid4().hex}@example.com"
    password = "secret123"

    r = client.post("/auth/register", json={"email": email, "password": password})
    assert r.status_code == 200

    r = client.post("/auth/login", data={"username": email, "password": password})
    assert r.status_code == 200
    data = r.json()
    assert "access_token" in data
