from typing import List
from pydantic import BaseModel


class UserInfo(BaseModel):
    """用户信息"""
    user_id: str
    account: str


class UserListResponse(BaseModel):
    """用户列表响应"""
    code: int
    message: str
    users: List[UserInfo]
