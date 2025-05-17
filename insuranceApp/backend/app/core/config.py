import os
import json
from typing import Any, Dict, Optional, List

from dotenv import load_dotenv
from pydantic import PostgresDsn, field_validator
from pydantic_settings import BaseSettings

# 加载环境变量
load_dotenv()
print("====> 加载.env文件完成")

# 直接查看环境变量中的AI_MODULE_KEYS
# ai_module_keys_env = os.getenv("AI_MODULE_KEYS", "{}")
# print(f"====> 环境变量中的AI_MODULE_KEYS: {ai_module_keys_env}")

# try:
#     parsed_keys = json.loads(ai_module_keys_env)
#     print(f"====> 解析后的AI_MODULE_KEYS: {parsed_keys}")
# except json.JSONDecodeError as e:
#     print(f"====> 解析AI_MODULE_KEYS失败: {e}")


class Settings(BaseSettings):
    """应用配置"""

    APP_NAME: str = "Insurance App"
    DEBUG: bool = False

    # JWT配置
    SECRET_KEY: str = os.getenv("SECRET_KEY", "your_secret_key_here")
    print(f"====> 原始SECRET_KEY环境变量: {SECRET_KEY}")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    # AI模块API密钥
    AI_MODULE_KEYS: List[str] = os.getenv("AI_MODULE_KEYS", "[]")

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
print(f"====> 配置加载完成，AI_MODULE_KEYS: {settings.AI_MODULE_KEYS}") 