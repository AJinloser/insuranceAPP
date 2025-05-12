import uuid
from typing import Optional

from pydantic import BaseModel, Field


class UserBase(BaseModel):
    """用户基本信息"""
    account: str = Field(..., description="用户账号")


class UserCreate(UserBase):
    """用户创建模式"""
    password: str = Field(..., description="用户密码")


class UserInDB(UserBase):
    """数据库中的用户模式"""
    user_id: uuid.UUID = Field(..., description="用户ID")
    
    class Config:
        from_attributes = True


class UserResponse(UserInDB):
    """用户响应模式"""
    pass


class UserLogin(BaseModel):
    """用户登录模式"""
    account: str = Field(..., description="用户账号")
    password: str = Field(..., description="用户密码")


class UserResetPassword(BaseModel):
    """重置密码模式"""
    account: str = Field(..., description="用户账号")
    new_password: str = Field(..., description="新密码")


class Token(BaseModel):
    """令牌模式"""
    access_token: str = Field(..., description="访问令牌")
    token_type: str = Field(..., description="令牌类型")
    user_id: uuid.UUID = Field(..., description="用户ID")


class TokenPayload(BaseModel):
    """令牌载荷模式"""
    sub: Optional[str] = None 