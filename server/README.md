# TricksPlanner API (FastAPI + SQLite)

## Setup

```bash
cd server
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Run locally

```bash
uvicorn app.main:app --reload
```

## Run tests

```bash
pytest -q
```

## Notes
- SQLite DB file: `server/tricks_planner.db`
- Update `app/config.py` for secrets before deployment.
