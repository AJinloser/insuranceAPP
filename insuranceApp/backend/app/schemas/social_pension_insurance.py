"""
社会养老保险数据模式
"""
from typing import Optional, Dict, Any
from pydantic import BaseModel, Field


class SocialPensionInsuranceQuery(BaseModel):
    """社会养老保险查询请求模式"""
    province: str = Field(..., description="省份名称")
    
    class Config:
        json_schema_extra = {
            "example": {
                "province": "北京"
            }
        }


class SocialPensionInsuranceResponse(BaseModel):
    """社会养老保险查询响应模式"""
    code: int = Field(..., description="状态码")
    message: str = Field(..., description="响应消息")
    data: Optional[Dict[str, Any]] = Field(None, description="社会养老保险数据")
    
    class Config:
        json_schema_extra = {
            "example": {
                "code": 200,
                "message": "查询成功",
                "data": {
                    "省市": "北京",
                    "数据年份": 2025,
                    "城镇职工缴费基数下限": 6364.8,
                    "城镇职工缴费基数上限": 31824,
                    "城镇职工单位缴费比例": 0.16,
                    "城镇职工个人缴费比例": 0.08
                }
            }
        }

