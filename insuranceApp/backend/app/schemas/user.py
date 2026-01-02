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
    experiment_id: Optional[str] = Field(None, description="实验ID")
    group_code: Optional[str] = Field(None, description="分组代码")
    completed_pre_survey: bool = Field(False, description="是否完成测前问卷")
    completed_declaration: bool = Field(False, description="是否完成声明环节")
    completed_conversation: bool = Field(False, description="是否完成对话环节")
    completed_post_survey: bool = Field(False, description="是否完成测后问卷")


class TokenPayload(BaseModel):
    """令牌载荷模式"""
    sub: Optional[str] = None


class ExperimentProgress(BaseModel):
    """实验进度更新模式"""
    user_id: uuid.UUID = Field(..., description="用户ID")
    completed_pre_survey: Optional[bool] = Field(None, description="是否完成测前问卷")
    completed_declaration: Optional[bool] = Field(None, description="是否完成声明环节")
    completed_conversation: Optional[bool] = Field(None, description="是否完成对话环节")
    completed_post_survey: Optional[bool] = Field(None, description="是否完成测后问卷")


class ExperimentInfo(BaseModel):
    """实验信息响应模式"""
    experiment_id: str = Field(..., description="实验ID")
    group_code: str = Field(..., description="分组代码")
    show_algorithm_declaration: bool = Field(..., description="是否展示算法声明")
    show_interest_declaration: bool = Field(..., description="是否展示利益立场声明")
    show_privacy_declaration: bool = Field(..., description="是否展示隐私声明")
    show_data_control: bool = Field(..., description="是否展示数据控制权选项")
    has_guided_questions: bool = Field(..., description="是否有步进问题引导")
    chatbot_api_key: str = Field(..., description="分配的chatbot API key")
    completed_pre_survey: bool = Field(..., description="是否完成测前问卷")
    completed_declaration: bool = Field(..., description="是否完成声明环节")
    completed_conversation: bool = Field(..., description="是否完成对话环节")
    completed_post_survey: bool = Field(..., description="是否完成测后问卷") 