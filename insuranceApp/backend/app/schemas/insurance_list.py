from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
from uuid import UUID


class InsuranceItemBase(BaseModel):
    """保险产品基础信息"""
    product_id: int = Field(..., description="产品ID")
    product_type: str = Field(..., description="产品类型")


class InsuranceItemCreate(InsuranceItemBase):
    """添加保险产品到保单的请求模型"""
    pass


class InsuranceItem(InsuranceItemBase):
    """保险产品信息"""
    
    class Config:
        from_attributes = True


class InsuranceListBase(BaseModel):
    """用户保单基础信息"""
    insurance_list: List[Dict[str, Any]] = Field(default=[], description="保单列表")


class InsuranceListCreate(InsuranceListBase):
    """创建用户保单的请求模型"""
    pass


class InsuranceListUpdate(BaseModel):
    """更新用户保单的请求模型"""
    insurance_list: List[Dict[str, Any]] = Field(..., description="保单列表")


class InsuranceListResponse(InsuranceListBase):
    """用户保单响应模型"""
    user_id: UUID = Field(..., description="用户ID")
    
    class Config:
        from_attributes = True


class InsuranceListAddRequest(BaseModel):
    """添加保险产品到保单的请求模型"""
    user_id: UUID = Field(..., description="用户ID")
    product_id: int = Field(..., description="产品ID")
    product_type: str = Field(..., description="产品类型")


class InsuranceListUpdateRequest(BaseModel):
    """更新用户保单的请求模型"""
    user_id: UUID = Field(..., description="用户ID")
    insurance_list: List[Dict[str, Any]] = Field(..., description="保单列表")


class InsuranceListGetRequest(BaseModel):
    """获取用户保单的请求模型"""
    user_id: UUID = Field(..., description="用户ID")


class BaseResponse(BaseModel):
    """基础响应模型"""
    code: int = Field(..., description="状态码")
    message: str = Field(..., description="消息")


class InsuranceListGetResponse(BaseResponse):
    """获取用户保单的响应模型"""
    insurance_list: List[Dict[str, Any]] = Field(default=[], description="保单列表") 