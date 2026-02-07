from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from .db import Base, engine, get_db
from . import models, schemas, auth

Base.metadata.create_all(bind=engine)

app = FastAPI(title="TricksPlanner API")


@app.post("/auth/register", response_model=schemas.UserOut)
def register(payload: schemas.UserCreate, db: Session = Depends(get_db)):
    existing = db.query(models.User).filter(models.User.email == payload.email).first()
    if existing:
        raise HTTPException(status_code=400, detail="Email already registered")
    user = models.User(email=payload.email, password_hash=auth.hash_password(payload.password))
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@app.post("/auth/login", response_model=schemas.Token)
def login(form: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = db.query(models.User).filter(models.User.email == form.username).first()
    if not user or not auth.verify_password(form.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    token = auth.create_access_token(user.email)
    return schemas.Token(access_token=token)


@app.get("/me", response_model=schemas.UserOut)
def me(current: models.User = Depends(auth.get_current_user)):
    return current


# Tricks
@app.get("/tricks", response_model=list[schemas.TrickOut])
def list_tricks(db: Session = Depends(get_db), current: models.User = Depends(auth.get_current_user)):
    return db.query(models.Trick).filter(models.Trick.user_id == current.id).all()


@app.post("/tricks", response_model=schemas.TrickOut)
def create_trick(payload: schemas.TrickCreate, db: Session = Depends(get_db), current: models.User = Depends(auth.get_current_user)):
    trick = models.Trick(user_id=current.id, **payload.model_dump())
    db.add(trick)
    db.commit()
    db.refresh(trick)
    return trick


@app.delete("/tricks/{trick_id}")
def delete_trick(trick_id: int, db: Session = Depends(get_db), current: models.User = Depends(auth.get_current_user)):
    trick = db.query(models.Trick).filter(models.Trick.id == trick_id, models.Trick.user_id == current.id).first()
    if not trick:
        raise HTTPException(status_code=404, detail="Trick not found")
    db.delete(trick)
    db.commit()
    return {"ok": True}


# Templates
@app.get("/templates", response_model=list[schemas.TrainingTemplateOut])
def list_templates(db: Session = Depends(get_db), current: models.User = Depends(auth.get_current_user)):
    return db.query(models.TrainingTemplate).filter(models.TrainingTemplate.user_id == current.id).all()


@app.post("/templates", response_model=schemas.TrainingTemplateOut)
def create_template(payload: schemas.TrainingTemplateCreate, db: Session = Depends(get_db), current: models.User = Depends(auth.get_current_user)):
    template = models.TrainingTemplate(user_id=current.id, name=payload.name)
    db.add(template)
    db.flush()
    for item in payload.items:
        db.add(models.TrainingTemplateItem(template_id=template.id, **item.model_dump()))
    db.commit()
    db.refresh(template)
    return template


@app.delete("/templates/{template_id}")
def delete_template(template_id: int, db: Session = Depends(get_db), current: models.User = Depends(auth.get_current_user)):
    template = db.query(models.TrainingTemplate).filter(models.TrainingTemplate.id == template_id, models.TrainingTemplate.user_id == current.id).first()
    if not template:
        raise HTTPException(status_code=404, detail="Template not found")
    db.delete(template)
    db.commit()
    return {"ok": True}


# Challenges
@app.get("/challenges", response_model=list[schemas.ChallengeOut])
def list_challenges(db: Session = Depends(get_db), current: models.User = Depends(auth.get_current_user)):
    return db.query(models.Challenge).filter(models.Challenge.user_id == current.id).all()


@app.post("/challenges", response_model=schemas.ChallengeOut)
def create_challenge(payload: schemas.ChallengeCreate, db: Session = Depends(get_db), current: models.User = Depends(auth.get_current_user)):
    challenge = models.Challenge(user_id=current.id, **payload.model_dump())
    db.add(challenge)
    db.commit()
    db.refresh(challenge)
    return challenge


# Training plans
@app.get("/training-plans", response_model=list[schemas.TrainingPlanOut])
def list_training_plans(db: Session = Depends(get_db), current: models.User = Depends(auth.get_current_user)):
    return db.query(models.DailyTrainingPlan).filter(models.DailyTrainingPlan.user_id == current.id).all()


@app.post("/training-plans", response_model=schemas.TrainingPlanOut)
def create_training_plan(payload: schemas.TrainingPlanCreate, db: Session = Depends(get_db), current: models.User = Depends(auth.get_current_user)):
    plan = models.DailyTrainingPlan(user_id=current.id, day=payload.day)
    db.add(plan)
    db.flush()
    for item in payload.items:
        db.add(models.TrainingItem(plan_id=plan.id, **item.model_dump()))
    db.commit()
    db.refresh(plan)
    return plan
