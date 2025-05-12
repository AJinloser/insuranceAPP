import os
from typing import Any, Dict, Optional

from dotenv import load_dotenv
from pydantic import PostgresDsn, field_validator
from pydantic_settings import BaseSettings

# 加载环境变量
load_dotenv()


class Settings(BaseSettings):
    """应用配置"""

    APP_NAME: str = "Insurance App"
    DEBUG: bool = False

    # JWT配置
    SECRET_KEY: str = os.getenv("SECRET_KEY", "your_secret_key_here")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    # 数据库配置
    DATABASE_URL: Optional[PostgresDsn] = None

    @field_validator("DATABASE_URL", mode="before")
    def assemble_db_connection(cls, v: Optional[str]) -> Any:
        if isinstance(v, str):
            return v
        return PostgresDsn.build(
            scheme="postgresql",
            username=os.getenv("POSTGRES_USER", "postgres"),
            password=os.getenv("POSTGRES_PASSWORD", "postgres"),
            host=os.getenv("POSTGRES_HOST", "localhost"),
            port=os.getenv("POSTGRES_PORT", "5432"),
            path=f"/{os.getenv('POSTGRES_DB', 'insurance_app')}",
        )

    class Config:
        env_file = ".env"
        case_sensitive = True


settings = Settings() 