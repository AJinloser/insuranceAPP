"""
简化的全局错误处理中间件
自动捕获和记录所有API错误
"""

import traceback
from typing import Optional
from fastapi import Request, HTTPException
from fastapi.responses import JSONResponse
from sqlalchemy.exc import SQLAlchemyError
from pydantic import ValidationError

from .logging_config import log_error


def get_user_id_from_request(request: Request) -> Optional[str]:
    """从请求中提取用户ID"""
    try:
        # 尝试从查询参数获取
        return request.query_params.get('user_id')
    except:
        return None


def determine_error_type(endpoint: str) -> str:
    """根据API端点确定错误类型"""
    if '/login' in endpoint or '/register' in endpoint or '/reset_password' in endpoint:
        return 'AUTH_ERROR'
    elif '/insurance_products' in endpoint or '/insurance_list' in endpoint:
        return 'INSURANCE_ERROR'
    elif '/goals' in endpoint:
        return 'GOAL_ERROR'
    elif '/ai_modules' in endpoint:
        return 'CHAT_ERROR'
    elif '/user_info' in endpoint:
        return 'USER_INFO_ERROR'
    else:
        return 'API_ERROR'


async def global_exception_handler(request: Request, exc: Exception):
    """简化的全局异常处理器"""
    
    # 获取基本信息
    endpoint = str(request.url.path)
    user_id = get_user_id_from_request(request)
    error_type = determine_error_type(endpoint)
    stack_trace = traceback.format_exc()
    
    # 根据异常类型处理
    if isinstance(exc, HTTPException):
        # HTTP异常
        log_error(
            message=f"HTTP {exc.status_code}: {exc.detail}",
            error_type=error_type,
            user_id=user_id,
            api_endpoint=endpoint,
            status_code=exc.status_code
        )
        
        return JSONResponse(
            status_code=exc.status_code,
            content={"detail": exc.detail}
        )
    
    elif isinstance(exc, ValidationError):
        # 验证错误
        log_error(
            message=f"数据验证错误: {str(exc)}",
            error_type="VALIDATION_ERROR",
            user_id=user_id,
            api_endpoint=endpoint,
            stack_trace=stack_trace
        )
        
        return JSONResponse(
            status_code=422,
            content={"detail": "数据验证失败", "errors": exc.errors()}
        )
    
    elif isinstance(exc, SQLAlchemyError):
        # 数据库错误
        log_error(
            message=f"数据库错误: {str(exc)}",
            error_type="DATABASE_ERROR",
            user_id=user_id,
            api_endpoint=endpoint,
            stack_trace=stack_trace
        )
        
        return JSONResponse(
            status_code=500,
            content={"detail": "数据库操作失败"}
        )
    
    else:
        # 其他未处理的异常
        log_error(
            message=f"未处理的异常: {str(exc)}",
            error_type=error_type,
            user_id=user_id,
            api_endpoint=endpoint,
            stack_trace=stack_trace,
            exception_type=type(exc).__name__
        )
        
        return JSONResponse(
            status_code=500,
            content={"detail": "服务器内部错误"}
        )
