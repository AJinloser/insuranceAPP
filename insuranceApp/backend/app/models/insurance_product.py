from sqlalchemy import Column, Integer, String, Boolean, Numeric, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.ext.declarative import declared_attr
from sqlalchemy.ext.automap import automap_base
from sqlalchemy import inspect, MetaData, Table

from app.db.base import Base, engine

class InsuranceProductBase:
    """保险产品基类，定义共同属性"""
    
    @declared_attr
    def __tablename__(cls):
        return "insurance_products"
    
    product_id = Column(Integer, primary_key=True, index=True)
    company_name = Column(String(100))
    product_name = Column(String(150))
    insurance_type = Column(String(50))
    coverage_content = Column(JSONB)
    exclusion_clause = Column(JSONB)
    renewable = Column(Boolean)
    underwriting_rules = Column(JSONB)
    entry_age = Column(String(50))
    deductible = Column(Numeric(12, 2))
    premium = Column(JSONB)
    coverage_amount = Column(JSONB)
    coverage_period = Column(String(50))
    total_score = Column(Numeric(6, 2))

# 动态映射函数
def get_dynamic_model_class(product_type: str):
    """
    动态获取保险产品模型类
    
    Args:
        product_type: 产品类型名称
        
    Returns:
        对应的SQLAlchemy模型类
    """
    # 获取表名
    if product_type not in PRODUCT_TYPE_MAPPING:
        # 如果产品类型无效，返回基本类
        return type(f"{product_type}Product", (Base, InsuranceProductBase), {})
    
    # 使用SQL文件名作为表名，格式：insurance_products_{文件名去掉.sql}
    file_name = PRODUCT_TYPE_MAPPING[product_type]
    table_name = f"insurance_products_{file_name.replace('.sql', '')}"
    
    # 检查表是否存在
    inspector = inspect(engine)
    if table_name not in inspector.get_table_names():
        print(f"警告: 表 {table_name} 不存在，返回基本模型")
        return type(f"{product_type}Product", (Base, InsuranceProductBase), {})
    
    # 自动映射基类
    metadata = MetaData()
    metadata.reflect(bind=engine, only=[table_name])
    
    # 使用automap创建映射
    AutomapBase = automap_base(metadata=metadata)
    AutomapBase.prepare()
    
    # 返回映射后的类
    if hasattr(AutomapBase.classes, table_name):
        return getattr(AutomapBase.classes, table_name)
    else:
        # 如果automap没有映射成功，手动创建
        table = metadata.tables[table_name]
        class_dict = {"__table__": table}
        return type(f"{product_type}Product", (Base,), class_dict)

# 产品类型到表名的映射
PRODUCT_TYPE_MAPPING = {
    "定期寿险": "termlife.sql",
    "定额终身寿险": "wholelife.sql",
    "意外险": "accident.sql",
    "年金险": "annuity.sql",
    "重疾险": "critical_illness.sql",
    "高端医疗险": "high_medical_level.sql",
    "百万医疗险及中端医疗险": "medical.sql"
}

# 根据产品类型获取字段列表
def get_product_fields(product_type: str) -> list:
    """
    获取特定产品类型的字段列表
    
    Args:
        product_type: 产品类型名称
        
    Returns:
        字段列表
    """
    if product_type not in PRODUCT_TYPE_MAPPING:
        return []
        
    # 使用SQL文件名作为表名，格式：insurance_products_{文件名去掉.sql}
    file_name = PRODUCT_TYPE_MAPPING[product_type]
    table_name = f"insurance_products_{file_name.replace('.sql', '')}"
    
    # 反射表结构
    metadata = MetaData()
    metadata.reflect(bind=engine, only=[table_name])
    
    if table_name not in metadata.tables:
        # 如果表不存在，返回基本字段
        return ["product_id", "company_name", "product_name", "insurance_type", 
                "premium", "coverage_amount", "total_score"]
    
    # 获取表的所有列
    columns = metadata.tables[table_name].columns
    
    # 返回列名列表
    return [column.name for column in columns] 