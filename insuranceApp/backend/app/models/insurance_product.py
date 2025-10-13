from sqlalchemy.ext.automap import automap_base
from sqlalchemy import inspect, MetaData

from app.db.base import Base, engine

# 动态映射函数
def get_dynamic_model_class(product_type: str):
    """
    动态获取保险产品模型类
    
    Args:
        product_type: 产品类型名称（表名后缀）
        
    Returns:
        对应的SQLAlchemy模型类
    """
    # 获取表名
    table_name = f"insurance_products_{product_type}"
    
    # 检查表是否存在
    inspector = inspect(engine)
    if table_name not in inspector.get_table_names():
        print(f"警告: 表 {table_name} 不存在")
        return None
    
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