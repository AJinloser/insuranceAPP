"""
基本医保API路由
"""
import logging
from typing import Optional, Dict, Any, List
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.db.base import get_db
from app.db.crud.basic_medical_insurance import get_basic_medical_insurance_crud
from app.schemas.basic_medical_insurance import (
    BasicMedicalInsuranceQuery,
    BasicMedicalInsuranceResponse
)

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("/query", response_model=BasicMedicalInsuranceResponse)
async def query_basic_medical_insurance(
    city: str = Query(..., description="城市名称"),
    category: str = Query(..., description="种类：城镇职工/城乡居民"),
    employment_status: Optional[str] = Query(None, description="在职/退休（仅在种类为城镇职工时有效）"),
    db: Session = Depends(get_db)
):
    """
    查询基本医保信息
    
    Args:
        city: 城市名称
        category: 种类（城镇职工/城乡居民）
        employment_status: 在职/退休状态（仅在种类为城镇职工时有效）
        db: 数据库会话
        
    Returns:
        BasicMedicalInsuranceResponse: 基本医保信息响应
    """
    try:
        # 参数验证
        if category not in ["城镇职工", "城乡居民"]:
            raise HTTPException(
                status_code=400,
                detail="种类参数无效，必须是'城镇职工'或'城乡居民'"
            )
        
        if category == "城镇职工" and employment_status and employment_status not in ["在职", "退休"]:
            raise HTTPException(
                status_code=400,
                detail="在职/退休状态参数无效，必须是'在职'或'退休'"
            )
        
        # 查询数据
        crud = get_basic_medical_insurance_crud(db)
        filtered_data = crud.get_filtered_data(city, category, employment_status)
        
        if not filtered_data:
            raise HTTPException(
                status_code=404,
                detail=f"未找到城市'{city}'的基本医保信息"
            )
        
        return BasicMedicalInsuranceResponse(
            code=200,
            message="查询成功",
            data=filtered_data
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"查询基本医保信息失败: {e}")
        raise HTTPException(
            status_code=500,
            detail="服务器内部错误"
        )


@router.get("/cities", response_model=Dict[str, Any])
async def get_cities(db: Session = Depends(get_db)):
    """
    获取所有可查询的城市列表
    
    Args:
        db: 数据库会话
        
    Returns:
        Dict: 城市列表响应
    """
    try:
        crud = get_basic_medical_insurance_crud(db)
        cities = crud.get_all_cities()
        
        return {
            "code": 200,
            "message": "获取城市列表成功",
            "cities": cities,
            "count": len(cities)
        }
        
    except Exception as e:
        logger.error(f"获取城市列表失败: {e}")
        raise HTTPException(
            status_code=500,
            detail="服务器内部错误"
        )
