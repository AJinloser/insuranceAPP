from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy.orm import Session

from app.api.deps import get_current_user, get_db
from app.db.crud.insurance_product import InsuranceProductCRUD
from app.models.user import User
from app.schemas.insurance_product import (
    ProductTypesResponse,
    ProductFieldsResponse,
    ProductSearchResponse,
    ProductDetailResponse,
)

router = APIRouter()

@router.get("/product_types", response_model=ProductTypesResponse)
def get_product_types() -> Any:
    """
    获取保险产品类型列表 - 公开API，无需认证
    """
    product_types = InsuranceProductCRUD.get_product_types()
    
    return {
        "code": 200,
        "message": "获取保险产品类型成功",
        "product_types": product_types
    }

@router.get("/product_fields", response_model=ProductFieldsResponse)
def get_product_fields(
    product_type: str = Query(..., description="产品类型"),
) -> Any:
    """
    获取保险产品类型对应字段列表 - 公开API，无需认证
    """
    fields = InsuranceProductCRUD.get_product_fields(product_type)
    
    if not fields:
        return {
            "code": 404,
            "message": "未找到指定产品类型",
            "fields": []
        }
    
    return {
        "code": 200,
        "message": "获取保险产品字段成功",
        "fields": fields
    }

@router.get("/search", response_model=ProductSearchResponse)
async def search_products(
    request: Request,
    product_type: str = Query(..., description="产品类型"),
    page: int = Query(1, ge=1, description="页码"),
    limit: int = Query(10, ge=1, le=100, description="每页条数"),
    sort_by: str = Query("total_score", description="排序字段"),
    product_name: Optional[str] = Query(None, description="产品名称"),
    company_name: Optional[str] = Query(None, description="公司名称"),
    db: Session = Depends(get_db),
) -> Any:
    """
    搜索保险产品 - 公开API，无需认证
    
    其他可选参数根据不同产品类型自动处理
    """
    # 获取查询参数
    filters = {}
    if product_name:
        filters["product_name"] = product_name
    if company_name:
        filters["company_name"] = company_name
    
    # 获取所有查询参数
    query_params = dict(request.query_params)
    
    # 处理其他动态参数
    for key, value in query_params.items():
        if key not in ["product_type", "page", "limit", "sort_by", "product_name", "company_name", "user_id"]:
            filters[key] = value
    
    # 查询产品
    products, total_pages = InsuranceProductCRUD.search_products(
        db=db,
        product_type=product_type,
        page=page,
        limit=limit,
        sort_by=sort_by,
        **filters
    )
    
    return {
        "code": 200,
        "message": "搜索保险产品成功",
        "pages": total_pages,
        "products": products
    }

@router.get("/product_info", response_model=ProductDetailResponse)
def get_product_info(
    product_id: int = Query(..., description="产品ID"),
    product_type: str = Query(..., description="产品类型"),
    db: Session = Depends(get_db),
) -> Any:
    """
    获取保险产品详细信息 - 公开API，无需认证
    
    必须指定产品类型和产品ID，以便在正确的表中查询
    """
    product = InsuranceProductCRUD.get_product_info(db, product_id, product_type)
    
    if not product:
        return {
            "code": 404,
            "message": "未找到指定产品"
        }
    
    response_data = {
        "code": 200,
        "message": "获取保险产品信息成功"
    }
    
    # 添加产品信息到响应
    response_data.update(product)
    
    return response_data 