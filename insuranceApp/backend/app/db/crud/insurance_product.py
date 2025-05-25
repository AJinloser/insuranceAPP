from typing import Any, Dict, List, Optional, Union, Tuple
import logging
from sqlalchemy.orm import Session
from sqlalchemy import text, desc, asc, func, and_, or_
from sqlalchemy.sql.expression import cast
from sqlalchemy.dialects.postgresql import JSONB

from app.models.insurance_product import get_dynamic_model_class, get_product_tables
from app.db.sql_importer import SQLImporter
from app.db.base import engine

logger = logging.getLogger(__name__)

class InsuranceProductCRUD:
    """保险产品数据访问对象"""
    
    @staticmethod
    def get_product_types() -> List[str]:
        """获取所有保险产品类型"""
        # 通过已导入的表来获取产品类型
        product_tables = get_product_tables()
        return list(product_tables.keys())
    
    @staticmethod
    def get_product_fields(product_type: str) -> List[str]:
        """
        获取特定产品类型的所有字段
        
        Args:
            product_type: 产品类型
            
        Returns:
            字段列表
        """
        # 构造表名
        table_name = f"insurance_products_{product_type}"
        
        # 反射表结构
        metadata = text(f"""
            SELECT column_name, data_type 
            FROM information_schema.columns 
            WHERE table_name = :table_name
        """)
        
        try:
            with engine.connect() as conn:
                result = conn.execute(metadata, {"table_name": table_name})
                columns = [row[0] for row in result]
                
                if not columns:
                    logger.warning(f"表 {table_name} 不存在或没有列")
                    return []
                    
                return columns
        except Exception as e:
            logger.error(f"获取表字段失败: {e}")
            return []
    
    @staticmethod
    def search_products(
        db: Session, 
        product_type: str,
        page: int = 1,
        limit: int = 10,
        sort_by: str = "total_score",
        sort_order: str = "desc",
        **filters
    ) -> Tuple[List[Dict[str, Any]], int]:
        """
        搜索保险产品
        
        Args:
            db: 数据库会话
            product_type: 产品类型
            page: 页码
            limit: 每页数量
            sort_by: 排序字段
            sort_order: 排序方向 (asc/desc)
            **filters: 过滤条件
            
        Returns:
            包含产品列表和总页数的元组
        """
        # 获取模型类
        product_model = get_dynamic_model_class(product_type)
        
        # 构建查询
        query = db.query(product_model)
        
        # 应用过滤条件
        for field, value in filters.items():
            if value is None:
                continue
                
            # 处理常规字段
            if field == "product_name" and value:
                query = query.filter(product_model.product_name.ilike(f"%{value}%"))
            elif field == "company_name" and value:
                query = query.filter(product_model.company_name.ilike(f"%{value}%"))
            elif hasattr(product_model, field):
                # 处理不同类型的筛选
                attr = getattr(product_model, field)
                
                # 范围筛选 (字典形式 {"min": 值, "max": 值})
                if isinstance(value, dict) and ("min" in value or "max" in value):
                    if "min" in value and value["min"] is not None:
                        query = query.filter(attr >= value["min"])
                    if "max" in value and value["max"] is not None:
                        query = query.filter(attr <= value["max"])
                
                # JSONB字段筛选
                elif str(attr.type) == "JSONB" and isinstance(value, dict):
                    # 逐个筛选JSONB字段中的键值对
                    for json_key, json_value in value.items():
                        if json_value is not None:
                            # 使用PostgreSQL的JSONB操作符筛选
                            query = query.filter(attr.contains({json_key: json_value}))
                
                # 文本字段模糊搜索
                elif str(attr.type) in ('VARCHAR', 'TEXT', 'String') and isinstance(value, str):
                    query = query.filter(attr.ilike(f"%{value}%"))
                
                # 其他情况使用精确匹配
                else:
                    query = query.filter(attr == value)
        
        # 计算总记录数和总页数
        total_count = query.count()
        total_pages = (total_count + limit - 1) // limit if total_count > 0 else 1
        
        # 应用排序
        if sort_by and hasattr(product_model, sort_by):
            if sort_order.lower() == "asc":
                query = query.order_by(asc(getattr(product_model, sort_by)))
            else:
                query = query.order_by(desc(getattr(product_model, sort_by)))
        
        # 应用分页
        offset = (page - 1) * limit
        query = query.offset(offset).limit(limit)
        
        # 执行查询
        products = query.all()
        
        # 转换为字典列表
        result = []
        for product in products:
            # 转换为字典，并保留显示所需的字段
            product_dict = {
                "product_id": product.product_id,
                "product_name": product.product_name,
                "company_name": product.company_name,
                "insurance_type": product.insurance_type,
                "premium": product.premium,
                "total_score": float(product.total_score) if product.total_score else None
            }
            result.append(product_dict)
        
        return result, total_pages
    
    @staticmethod
    def get_product_info(db: Session, product_id: int, product_type: str) -> Optional[Dict[str, Any]]:
        """
        获取产品详细信息
        
        Args:
            db: 数据库会话
            product_id: 产品ID
            product_type: 产品类型
            
        Returns:
            产品详细信息字典，未找到则返回None
        """
        # 构造表名
        table_name = f"insurance_products_{product_type}"
        
        try:
            # 检查表是否存在
            check_table = text(f"""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_name = :table_name
                )
            """)
            
            with engine.connect() as conn:
                result = conn.execute(check_table, {"table_name": table_name})
                if not result.scalar():
                    logger.error(f"表 {table_name} 不存在")
                    return None
                
                # 表存在，查询产品
                query = text(f"""
                    SELECT * FROM {table_name} WHERE product_id = :product_id
                """)
                
                result = conn.execute(query, {"product_id": product_id})
                row = result.fetchone()
                
                if not row:
                    return None
                    
                # 转换为字典
                result_dict = {}
                for idx, column in enumerate(result.keys()):
                    result_dict[column] = row[idx]
                
                # 添加产品类型，方便前端使用
                result_dict["product_type"] = product_type
                
                return result_dict
        except Exception as e:
            logger.error(f"查询表 {table_name} 失败: {e}")
            return None
    
    @staticmethod
    def import_sql_files():
        """导入SQL文件到数据库"""
        import os
        from pathlib import Path
        
        # 获取SQL文件目录路径
        base_dir = Path(__file__).resolve().parent.parent.parent.parent
        sql_dir = base_dir / "sql"
        
        # 创建SQL导入器并执行导入
        importer = SQLImporter(engine, str(sql_dir))
        imported_files = importer.import_all_sql_files()
        
        return imported_files 