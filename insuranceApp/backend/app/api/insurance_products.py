from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, Request
from sqlalchemy.orm import Session
from fastapi.openapi.utils import get_openapi
from fastapi.openapi.docs import get_swagger_ui_html

from app.api.deps import get_current_user, get_db
from app.db.crud.insurance_product import InsuranceProductCRUD
from app.models.user import User
from app.schemas.insurance_product import (
    ProductTypesResponse,
    ProductFieldsResponse,
    ProductSearchResponse,
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
    
    返回的字段列表可以用于搜索API的筛选参数
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
    sort_by: Optional[str] = Query(None, description="排序字段，为空则按默认顺序"),
    sort_order: str = Query("desc", description="排序方向 (asc/desc)"),
    db: Session = Depends(get_db),
) -> Any:
    """
    搜索保险产品 - 公开API，无需认证
    
    ## 必填参数
    - product_type: 产品类型，必须是有效的产品类型，可通过/product_types接口获取
    - page: 页码，默认为1
    - limit: 每页条数，默认为10，最大为100
    - sort_by: 排序字段，默认为空（按数据库默认顺序）
    - sort_order: 排序方向，asc为升序，desc为降序，默认为desc
    
    ## 动态筛选参数
    每种保险产品类型都有特定的字段可用于筛选，可以通过/product_fields接口获取。
    
    ### 数值型字段筛选
    支持使用数学符号进行比较：
    - '>值': 大于，例如 entry_age_min_years=>18
    - '>=值': 大于等于，例如 entry_age_max_years=>=65
    - '<值': 小于，例如 waiting_period=<90
    - '<=值': 小于等于，例如 limitation_years=<=5
    - '=值': 等于，例如 grace_days==60
    - 直接数值: 精确匹配，例如 free_look_days=15
    
    ### 布尔型字段筛选
    直接传true/false，例如：has_tpd_cover=true
    
    ### 文本型字段筛选
    支持模糊匹配，例如：product_name=寿险
    
    ## 示例
    - 基本搜索: /search?product_type=term_life&page=1&limit=10
    - 数学符号筛选: /search?product_type=term_life&entry_age_min_years=>=18&entry_age_max_years=<=65
    - 组合筛选: /search?product_type=term_life&has_tpd_cover=true&waiting_period=<180&product_name=定期
    - 排序: /search?product_type=term_life&sort_by=entry_age_min_years&sort_order=asc
    """
    # 获取所有查询参数
    query_params = dict(request.query_params)
    
    # 获取该产品类型的所有字段信息
    fields_info = InsuranceProductCRUD.get_product_fields(product_type)
    valid_fields = {f['name'] for f in fields_info}
    
    # 处理筛选参数
    filters = {}
    
    # 处理动态参数
    for key, value in query_params.items():
        # 跳过系统参数
        if key in ["product_type", "page", "limit", "sort_by", "sort_order", "user_id"]:
            continue
        
        # 只添加有效字段
        if key in valid_fields:
            filters[key] = value
    
    # 查询产品
    products, total_pages = InsuranceProductCRUD.search_products(
        db=db,
        product_type=product_type,
        page=page,
        limit=limit,
        sort_by=sort_by,
        sort_order=sort_order,
        **filters
    )
    
    return {
        "code": 200,
        "message": "搜索保险产品成功",
        "pages": total_pages,
        "products": products
    }

@router.get("/product_info")
def get_product_info(
    product_id: int = Query(..., description="产品ID"),
    product_type: str = Query(..., description="产品类型"),
    db: Session = Depends(get_db),
) -> Any:
    """
    获取保险产品详细信息 - 公开API，无需认证
    
    必须指定产品类型和产品ID，以便在正确的表中查询
    
    返回：包含中文字段名的产品详细信息
    """
    product = InsuranceProductCRUD.get_product_info(db, product_id, product_type)
    
    if not product:
        return {
            "code": 404,
            "message": "未找到指定产品"
        }
    
    # 创建响应（使用中文字段名）
    response_data = {
        "code": 200,
        "message": "获取保险产品信息成功"
    }
    
    # 添加产品信息到响应
    response_data.update(product)
    
    return response_data 