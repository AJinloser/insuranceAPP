"""
社会养老保险API路由
"""
import logging
from typing import Dict, Any
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.db.base import get_db
from app.db.crud.social_pension_insurance import get_social_pension_insurance_crud
from app.schemas.social_pension_insurance import (
    SocialPensionInsuranceQuery,
    SocialPensionInsuranceResponse
)

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("/query", response_model=SocialPensionInsuranceResponse)
async def query_social_pension_insurance(
    province: str = Query(..., description="省市名称"),
    db: Session = Depends(get_db)
):
    """
    查询社会养老保险信息
    
    Args:
        province: 省市名称
        db: 数据库会话
        
    Returns:
        SocialPensionInsuranceResponse: 社会养老保险信息响应
    """
    try:
        # 查询数据
        crud = get_social_pension_insurance_crud(db)
        data = crud.get_data_as_dict(province)
        
        if not data:
            raise HTTPException(
                status_code=404,
                detail=f"未找到省市'{province}'的社会养老保险信息"
            )
        
        return SocialPensionInsuranceResponse(
            code=200,
            message="查询成功",
            data=data
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"查询社会养老保险信息失败: {e}")
        raise HTTPException(
            status_code=500,
            detail="服务器内部错误"
        )


@router.get("/provinces", response_model=Dict[str, Any])
async def get_provinces(db: Session = Depends(get_db)):
    """
    获取所有可查询的省市列表
    
    Args:
        db: 数据库会话
        
    Returns:
        Dict: 省市列表响应
    """
    try:
        crud = get_social_pension_insurance_crud(db)
        provinces = crud.get_all_provinces()
        
        return {
            "code": 200,
            "message": "获取省市列表成功",
            "provinces": provinces,
            "count": len(provinces)
        }
        
    except Exception as e:
        logger.error(f"获取省市列表失败: {e}")
        raise HTTPException(
            status_code=500,
            detail="服务器内部错误"
        )

