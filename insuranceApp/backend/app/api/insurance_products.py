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
    create_product_detail_model,
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
    sort_by: str = Query("total_score", description="排序字段"),
    sort_order: str = Query("desc", description="排序方向 (asc/desc)"),
    product_name: Optional[str] = Query(None, description="产品名称，支持模糊搜索"),
    company_name: Optional[str] = Query(None, description="公司名称，支持模糊搜索"),
    db: Session = Depends(get_db),
) -> Any:
    """
    搜索保险产品 - 公开API，无需认证
    
    ## 必填参数
    - product_type: 产品类型，必须是有效的产品类型，可通过/product_types接口获取
    - page: 页码，默认为1
    - limit: 每页条数，默认为10，最大为100
    - sort_by: 排序字段，默认为total_score
    - sort_order: 排序方向，asc为升序，desc为降序，默认为desc
    
    ## 常用筛选参数
    - product_name: 产品名称，支持模糊搜索
    - company_name: 公司名称，支持模糊搜索
    
    ## 动态筛选参数
    每种保险产品类型都有特定的字段可用于筛选，可以通过/product_fields接口获取特定产品类型的所有字段。
    对于数值型字段，支持范围筛选，格式为：field_name_min和field_name_max，例如：
    - premium_min: 最低保费
    - premium_max: 最高保费
    
    所有筛选参数均为可选，不提供则不进行筛选。
    
    示例：
    - /search?product_type=wholelife&page=1&limit=10&sort_by=total_score&company_name=中荷人寿&product_name=荣耀
    - /search?product_type=termlife&premium_min=1000&premium_max=5000
    """
    # 获取查询参数
    filters = {}
    if product_name:
        filters["product_name"] = product_name
    if company_name:
        filters["company_name"] = company_name
    
    # 获取所有查询参数
    query_params = dict(request.query_params)
    
    # 处理范围筛选参数（字段名_min和字段名_max）
    range_filters = {}
    
    # 处理其他动态参数
    for key, value in query_params.items():
        if key not in ["product_type", "page", "limit", "sort_by", "sort_order", "product_name", "company_name", "user_id"]:
            # 处理范围查询参数
            if key.endswith("_min") or key.endswith("_max"):
                base_field = key[:-4]  # 去掉_min或_max后缀
                if base_field not in range_filters:
                    range_filters[base_field] = {}
                
                if key.endswith("_min"):
                    range_filters[base_field]["min"] = value
                else:
                    range_filters[base_field]["max"] = value
            else:
                # 普通参数
                filters[key] = value
    
    # 将范围筛选参数添加到filters中
    for field, range_value in range_filters.items():
        filters[field] = range_value
    
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
    
    注意：此API不再使用固定的响应模型，而是根据产品类型动态生成响应模型
    """
    product = InsuranceProductCRUD.get_product_info(db, product_id, product_type)
    
    if not product:
        return {
            "code": 404,
            "message": "未找到指定产品"
        }
    
    # 使用创建的动态响应模型
    response_model = create_product_detail_model(product)
    
    # 创建响应
    response_data = {
        "code": 200,
        "message": "获取保险产品信息成功"
    }
    
    # 添加产品信息到响应
    response_data.update(product)
    
    # 验证并返回响应
    return response_model(**response_data) 