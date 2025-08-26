"""
日志接收API
接收前端发送的错误日志并统一记录
"""

from typing import Any, Dict, List, Optional
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.core.logging_config import log_frontend_error

router = APIRouter()


class FrontendLogRequest(BaseModel):
    """前端日志请求模型"""
    message: str
    error_type: str
    user_id: Optional[str] = None
    conversation_id: Optional[str] = None
    page_name: Optional[str] = None
    service_name: Optional[str] = None
    stack_trace: Optional[str] = None
    additional_context: Optional[Dict[str, Any]] = None


class BatchLogRequest(BaseModel):
    """批量日志请求模型"""
    logs: List[FrontendLogRequest]


@router.post("/frontend_error")
def receive_frontend_error(log_data: FrontendLogRequest) -> Dict[str, Any]:
    """
    接收单个前端错误日志
    """
    try:
        log_frontend_error(
            message=log_data.message,
            error_type=log_data.error_type,
            user_id=log_data.user_id,
            conversation_id=log_data.conversation_id,
            page_name=log_data.page_name,
            service_name=log_data.service_name,
            stack_trace=log_data.stack_trace,
            additional_context=log_data.additional_context
        )
        
        return {
            "code": 200,
            "message": "日志记录成功"
        }
    
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"日志记录失败: {str(e)}"
        )


@router.post("/frontend_errors_batch")
def receive_frontend_errors_batch(batch_data: BatchLogRequest) -> Dict[str, Any]:
    """
    批量接收前端错误日志
    """
    success_count = 0
    error_count = 0
    
    for log_data in batch_data.logs:
        try:
            log_frontend_error(
                message=log_data.message,
                error_type=log_data.error_type,
                user_id=log_data.user_id,
                conversation_id=log_data.conversation_id,
                page_name=log_data.page_name,
                service_name=log_data.service_name,
                stack_trace=log_data.stack_trace,
                additional_context=log_data.additional_context
            )
            success_count += 1
        except Exception as e:
            error_count += 1
            print(f"批量日志记录失败: {e}")
    
    return {
        "code": 200,
        "message": f"批量日志处理完成: 成功 {success_count}，失败 {error_count}",
        "success_count": success_count,
        "error_count": error_count
    }
