from datetime import datetime, date
from typing import List, Optional
from pydantic import BaseModel, EmailStr


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserCreate(BaseModel):
    email: EmailStr
    password: str


class UserOut(BaseModel):
    id: int
    email: EmailStr
    created_at: datetime

    class Config:
        from_attributes = True


class TrickCreate(BaseModel):
    name: str
    category: str
    difficulty: str = "none"


class TrickOut(TrickCreate):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True


class TrainingTemplateItemCreate(BaseModel):
    trick_name: str
    category: str
    difficulty: str = "none"
    target_count: int


class TrainingTemplateItemOut(TrainingTemplateItemCreate):
    id: int

    class Config:
        from_attributes = True


class TrainingTemplateCreate(BaseModel):
    name: str
    items: List[TrainingTemplateItemCreate] = []


class TrainingTemplateOut(BaseModel):
    id: int
    name: str
    items: List[TrainingTemplateItemOut]
    created_at: datetime

    class Config:
        from_attributes = True


class ChallengeCreate(BaseModel):
    day: date
    status: str = "notDone"
    combo_json: str


class ChallengeOut(ChallengeCreate):
    id: int

    class Config:
        from_attributes = True


class TrainingItemCreate(BaseModel):
    trick_name: str
    category: str
    difficulty: str = "none"
    target_count: int
    completed_count: int = 0
    template_id: Optional[int] = None


class TrainingItemOut(TrainingItemCreate):
    id: int

    class Config:
        from_attributes = True


class TrainingPlanCreate(BaseModel):
    day: date
    items: List[TrainingItemCreate] = []


class TrainingPlanOut(BaseModel):
    id: int
    day: date
    items: List[TrainingItemOut]

    class Config:
        from_attributes = True


class SyncPayload(BaseModel):
    categories: List[str] = []
    tricks: list[dict] = []
    templates: list[dict] = []
    challenges: list[dict] = []
    trainingPlans: list[dict] = []
