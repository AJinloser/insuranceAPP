"""
基本医保数据模式
"""
from typing import Optional, Dict, Any
from pydantic import BaseModel, Field


class BasicMedicalInsuranceQuery(BaseModel):
    """基本医保查询请求模式"""
    city: str = Field(..., description="城市名称")
    category: str = Field(..., description="种类：城镇职工/城乡居民")
    employment_status: Optional[str] = Field(None, description="在职/退休（仅在种类为城镇职工时有效）")
    
    class Config:
        json_schema_extra = {
            "example": {
                "city": "北京",
                "category": "城镇职工",
                "employment_status": "在职"
            }
        }


class BasicMedicalInsuranceResponse(BaseModel):
    """基本医保查询响应模式"""
    code: int = Field(..., description="状态码")
    message: str = Field(..., description="响应消息")
    data: Optional[Dict[str, Any]] = Field(None, description="基本医保数据")
    
    class Config:
        json_schema_extra = {
            "example": {
                "code": 200,
                "message": "查询成功",
                "data": {
                    "城市": "北京",
                    "数据年份": "2023",
                    "统筹层次": "市级统筹",
                    "职工_缴费基数下限": "6336元",
                    "职工_缴费基数上限": "33882元",
                    "在职_门诊支付比例": "70%"
                }
            }
        }
