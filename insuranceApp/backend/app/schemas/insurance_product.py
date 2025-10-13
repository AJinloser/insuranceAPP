from typing import Any, Dict, List, Optional, Union
from pydantic import BaseModel, Field, create_model

# 响应模型
class ResponseBase(BaseModel):
    """基础响应模型"""
    code: int = 200
    message: str = "操作成功"

# 保险产品类型响应
class ProductTypesResponse(ResponseBase):
    """保险产品类型响应"""
    product_types: List[str] = []

# 字段信息模型
class FieldInfo(BaseModel):
    """字段信息"""
    name: str
    type: str
    description: str

# 保险产品字段响应
class ProductFieldsResponse(ResponseBase):
    """保险产品字段响应"""
    fields: List[FieldInfo] = []

# 保险产品搜索响应（使用动态字段）
class ProductSearchResponse(ResponseBase):
    """保险产品搜索响应"""
    pages: int = 1
    products: List[Dict[str, Any]] = []

# 保险产品详情响应基类
class ProductDetailBase(ResponseBase):
    """保险产品详情响应基类"""
    product_id: Optional[int] = None
    product_name: Optional[str] = None
    company_name: Optional[str] = None
    insurance_type: Optional[str] = None
    product_type: Optional[str] = None
    
    class Config:
        from_attributes = True

# 动态创建保险产品详情响应模型
def create_product_detail_model(product_data: Dict[str, Any]) -> type:
    """
    根据产品数据动态创建Pydantic模型
    
    Args:
        product_data: 产品数据字典
        
    Returns:
        动态创建的Pydantic模型类
    """
    # 基础字段 - 所有产品都应该有的字段
    base_fields = {
        'code': (int, 200),
        'message': (str, "获取保险产品信息成功"),
        'product_id': (Optional[int], None),
        'product_name': (Optional[str], None),
        'company_name': (Optional[str], None),
        'insurance_type': (Optional[str], None),
        'product_type': (Optional[str], None)
    }
    
    # 添加产品数据中的所有字段
    for key, value in product_data.items():
        if key not in base_fields:
            base_fields[key] = (Optional[Any], None)
    
    # 创建动态模型
    return create_model('ProductDetailResponse', **base_fields)

# 兼容现有代码的ProductDetailResponse
class ProductDetailResponse(ProductDetailBase):
    """
    保险产品详情响应
    
    注意：此类保留是为了兼容现有代码，建议使用create_product_detail_model动态创建模型
    """
    coverage_content: Optional[Any] = None
    exclusion_clause: Optional[Any] = None
    renewable: Optional[Any] = None
    underwriting_rules: Optional[Any] = None
    entry_age: Optional[Any] = None
    deductible: Optional[Any] = None
    premium: Optional[Any] = None
    coverage_amount: Optional[Any] = None
    coverage_period: Optional[Any] = None
    total_score: Optional[float] = None
    
    def __init__(self, **data):
        super().__init__(**data)
        # 动态添加其他字段
        for key, value in data.items():
            if not hasattr(self, key):
                setattr(self, key, value) 