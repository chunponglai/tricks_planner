from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "TricksPlanner API"
    database_url: str = "sqlite:///./tricks_planner.db"
    secret_key: str = "change-me-in-prod"
    access_token_expire_minutes: int = 60 * 24 * 7
    algorithm: str = "HS256"


settings = Settings()
