from datetime import datetime, date
from typing import Optional
from sqlalchemy import String, Integer, DateTime, Date, ForeignKey, Text, Boolean
from sqlalchemy.orm import Mapped, mapped_column, relationship
from .db import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    tricks = relationship("Trick", back_populates="user", cascade="all, delete-orphan")
    templates = relationship("TrainingTemplate", back_populates="user", cascade="all, delete-orphan")
    challenges = relationship("Challenge", back_populates="user", cascade="all, delete-orphan")
    training_plans = relationship("DailyTrainingPlan", back_populates="user", cascade="all, delete-orphan")
    data_blob = relationship("UserData", back_populates="user", cascade="all, delete-orphan", uselist=False)


class Trick(Base):
    __tablename__ = "tricks"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    name: Mapped[str] = mapped_column(String(255))
    category: Mapped[str] = mapped_column(String(255))
    difficulty: Mapped[str] = mapped_column(String(32), default="none")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="tricks")


class TrainingTemplate(Base):
    __tablename__ = "training_templates"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    name: Mapped[str] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="templates")
    items = relationship("TrainingTemplateItem", back_populates="template", cascade="all, delete-orphan")


class TrainingTemplateItem(Base):
    __tablename__ = "training_template_items"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    template_id: Mapped[int] = mapped_column(ForeignKey("training_templates.id"), index=True)
    trick_name: Mapped[str] = mapped_column(String(255))
    category: Mapped[str] = mapped_column(String(255))
    difficulty: Mapped[str] = mapped_column(String(32), default="none")
    target_count: Mapped[int] = mapped_column(Integer)

    template = relationship("TrainingTemplate", back_populates="items")


class Challenge(Base):
    __tablename__ = "challenges"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    day: Mapped[date] = mapped_column(Date)
    status: Mapped[str] = mapped_column(String(16), default="notDone")
    combo_json: Mapped[str] = mapped_column(Text)

    user = relationship("User", back_populates="challenges")


class DailyTrainingPlan(Base):
    __tablename__ = "training_plans"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    day: Mapped[date] = mapped_column(Date, index=True)

    user = relationship("User", back_populates="training_plans")
    items = relationship("TrainingItem", back_populates="plan", cascade="all, delete-orphan")


class TrainingItem(Base):
    __tablename__ = "training_items"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    plan_id: Mapped[int] = mapped_column(ForeignKey("training_plans.id"), index=True)
    trick_name: Mapped[str] = mapped_column(String(255))
    category: Mapped[str] = mapped_column(String(255))
    difficulty: Mapped[str] = mapped_column(String(32), default="none")
    target_count: Mapped[int] = mapped_column(Integer)
    completed_count: Mapped[int] = mapped_column(Integer, default=0)
    template_id: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)

    plan = relationship("DailyTrainingPlan", back_populates="items")


class UserData(Base):
    __tablename__ = "user_data"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), unique=True, index=True)
    data_json: Mapped[str] = mapped_column(Text)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="data_blob")
