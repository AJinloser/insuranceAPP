from typing import Any, List
import traceback

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.logging_config import log_error
from app.db.base import get_db
from app.models.user import User
from app.schemas.admin import UserListResponse, UserInfo

router = APIRouter()


@router.get("/users", response_model=UserListResponse)
def get_all_users(
    db: Session = Depends(get_db)
) -> Any:
    """获取所有用户信息（仅限管理员）"""
    try:
        # 查询所有用户
        users = db.query(User).all()
        
        # 转换为响应格式
        user_list = []
        for user in users:
            user_info = UserInfo(
                user_id=str(user.user_id),
                account=user.account
            )
            user_list.append(user_info)
        
        return UserListResponse(
            code=200,
            message="获取用户列表成功",
            users=user_list
        )
        
    except Exception as e:
        log_error(
            message=f"获取用户列表失败: {str(e)}",
            error_type="ADMIN_ERROR",
            api_endpoint="/api/v1/admin/users",
            stack_trace=traceback.format_exc()
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="获取用户列表失败"
        )
