import logging
from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from app.api.auth import router as auth_router
from app.api.ai_modules import router as ai_modules_router
from app.api.insurance_products import router as insurance_products_router
from app.api.insurance_list import router as insurance_list_router
from app.api.user_info import router as user_info_router
from app.api.goals import router as goals_router
from app.core.config import settings
from app.db.base import Base, engine, get_db
from app.db.init_db import init_db

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler()]
)

logger = logging.getLogger(__name__)

# 创建FastAPI应用
app = FastAPI(
    title=settings.APP_NAME,
    openapi_url="/api/v1/openapi.json",
    docs_url="/api/docs",
    redoc_url="/api/redoc",
)

# 添加CORS中间件，确保允许跨域请求
origins = [
    "http://localhost",
    "http://localhost:8080",
    "http://127.0.0.1",
    "http://127.0.0.1:8080",
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    # 添加您的Flutter Web应用可能运行的其他地址
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 注册路由
app.include_router(auth_router, prefix="/api/v1", tags=["认证"])
app.include_router(ai_modules_router, prefix="/api/v1", tags=["AI模块"])
app.include_router(
    insurance_products_router, 
    prefix="/api/v1/insurance_products", 
    tags=["保险产品"]
)
app.include_router(
    insurance_list_router,
    prefix="/api/v1/insurance_list",
    tags=["用户保单"]
)
app.include_router(user_info_router, prefix="/api/v1", tags=["用户个人信息"])
app.include_router(goals_router, prefix="/api/v1", tags=["目标管理"])


@app.get("/api/health")
def health_check():
    """健康检查接口"""
    return {"status": "ok"} 


@app.on_event("startup")
def startup_event():
    """应用启动时执行的事件"""
    logger.info("应用启动中...")
    
    # 创建数据库表并初始化
    db = next(get_db())
    try:
        logger.info("初始化数据库...")
        init_db(db)
    except Exception as e:
        logger.error(f"数据库初始化失败: {e}")
    finally:
        db.close()
    
    logger.info("应用启动完成") 