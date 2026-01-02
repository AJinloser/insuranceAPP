from typing import List, Optional
from pydantic import BaseModel


class UserInfo(BaseModel):
    """用户信息"""
    user_id: str
    account: str
    experiment_id: Optional[str] = None
    group_code: Optional[str] = None


class UserListResponse(BaseModel):
    """用户列表响应"""
    code: int
    message: str
    users: List[UserInfo]
