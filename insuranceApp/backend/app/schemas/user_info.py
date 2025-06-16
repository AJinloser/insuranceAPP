import uuid
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field


class BasicInfo(BaseModel):
    """用户基本信息"""
    age: Optional[str] = Field(None, description="年龄")
    city: Optional[str] = Field(None, description="城市")
    gender: Optional[str] = Field(None, description="性别")


class FinancialInfo(BaseModel):
    """用户财务信息"""
    occupation: Optional[str] = Field(None, description="职业")
    income: Optional[str] = Field(None, description="收入")
    expenses: Optional[str] = Field(None, description="支出")
    assets: Optional[str] = Field(None, description="资产")
    liabilities: Optional[str] = Field(None, description="负债")


class RiskInfo(BaseModel):
    """用户风险信息"""
    risk_aversion: Optional[str] = Field(None, description="风险厌恶程度")


class RetirementInfo(BaseModel):
    """用户退休信息"""
    retirement_age: Optional[str] = Field(None, description="退休年龄")
    retirement_income: Optional[str] = Field(None, description="退休收入")


class FamilyMember(BaseModel):
    """家庭成员"""
    relation: Optional[str] = Field(None, description="关系")
    age: Optional[str] = Field(None, description="年龄")
    occupation: Optional[str] = Field(None, description="职业")
    income: Optional[str] = Field(None, description="收入")


class FamilyInfo(BaseModel):
    """用户家庭信息"""
    family_members: Optional[List[FamilyMember]] = Field(default_factory=list, description="家庭成员列表")


class Goal(BaseModel):
    """目标"""
    goal_details: Optional[str] = Field(None, description="目标详情")


class GoalInfo(BaseModel):
    """用户目标信息"""
    goals: Optional[List[Goal]] = Field(default_factory=list, description="目标列表")


class OtherInfo(BaseModel):
    """其他信息"""
    pass


class UserInfoBase(BaseModel):
    """用户个人信息基础模型"""
    basic_info: Optional[BasicInfo] = Field(default_factory=BasicInfo, description="基本信息")
    financial_info: Optional[FinancialInfo] = Field(default_factory=FinancialInfo, description="财务信息")
    risk_info: Optional[RiskInfo] = Field(default_factory=RiskInfo, description="风险信息")
    retirement_info: Optional[RetirementInfo] = Field(default_factory=RetirementInfo, description="退休信息")
    family_info: Optional[FamilyInfo] = Field(default_factory=FamilyInfo, description="家庭信息")
    goal_info: Optional[GoalInfo] = Field(default_factory=GoalInfo, description="目标信息")
    other_info: Optional[Dict[str, Any]] = Field(default_factory=dict, description="其他信息")


class UserInfoGetRequest(BaseModel):
    """获取用户个人信息请求"""
    user_id: uuid.UUID = Field(..., description="用户ID")


class UserInfoCreate(UserInfoBase):
    """创建用户个人信息"""
    user_id: uuid.UUID = Field(..., description="用户ID")


class UserInfoUpdate(UserInfoBase):
    """更新用户个人信息"""
    user_id: uuid.UUID = Field(..., description="用户ID")


class UserInfoInDB(UserInfoBase):
    """数据库中的用户个人信息"""
    user_id: uuid.UUID = Field(..., description="用户ID")
    
    class Config:
        from_attributes = True


class UserInfoResponse(UserInfoInDB):
    """用户个人信息响应"""
    pass


class ApiResponse(BaseModel):
    """API响应基础模型"""
    code: int = Field(..., description="状态码")
    message: str = Field(..., description="响应消息")


class UserInfoApiResponse(ApiResponse):
    """用户个人信息API响应"""
    user_info: Optional[UserInfoResponse] = Field(None, description="用户个人信息") 