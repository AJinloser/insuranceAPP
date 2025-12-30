from typing import Any, Dict, List, Optional, Union, Tuple
import logging
from sqlalchemy.orm import Session
from sqlalchemy import text, desc, asc, func, and_, or_
from sqlalchemy.sql.expression import cast
from sqlalchemy.dialects.postgresql import JSONB

from app.models.insurance_product import get_dynamic_model_class
from app.db.base import engine

logger = logging.getLogger(__name__)

# 产品类型映射：产品类型 -> 表名后缀
PRODUCT_TYPE_MAPPING = {
    '定期寿险': 'term_life',
    '非年金': 'non_annuity',
    '年金': 'annuity',
    '医疗保险': 'medical',
    '重疾险': 'critical_illness',
}

class InsuranceProductCRUD:
    """保险产品数据访问对象"""
    
    @staticmethod
    def get_product_types() -> List[str]:
        """获取所有保险产品类型"""
        # 返回产品类型的表名后缀列表
        return list(PRODUCT_TYPE_MAPPING.values())
    
    @staticmethod
    def get_product_fields(product_type: str) -> List[Dict[str, Any]]:
        """
        获取特定产品类型的所有字段及其中文说明
        
        Args:
            product_type: 产品类型（表名后缀）
            
        Returns:
            字段列表，每个字段包含：name（字段名）、type（数据类型）、description（中文说明）
        """
        # 构造表名
        table_name = f"insurance_products_{product_type}"
        
        # 查询表字段及其注释
        query = text("""
            SELECT 
                c.column_name,
                c.data_type,
                pgd.description
            FROM information_schema.columns c
            LEFT JOIN pg_catalog.pg_statio_all_tables st 
                ON c.table_name = st.relname
            LEFT JOIN pg_catalog.pg_description pgd 
                ON pgd.objoid = st.relid 
                AND pgd.objsubid = c.ordinal_position
            WHERE c.table_name = :table_name
            AND c.column_name != 'product_id'
            ORDER BY c.ordinal_position
        """)
        
        try:
            with engine.connect() as conn:
                result = conn.execute(query, {"table_name": table_name})
                fields = []
                
                for row in result:
                    field_name, data_type, description = row
                    fields.append({
                        'name': field_name,
                        'type': data_type,
                        'description': description if description else field_name
                    })
                
                if not fields:
                    logger.warning(f"表 {table_name} 不存在或没有列")
                    return []
                    
                return fields
        except Exception as e:
            logger.error(f"获取表字段失败: {e}")
            return []
    
    @staticmethod
    def search_products(
        db: Session, 
        product_type: str,
        page: int = 1,
        limit: int = 10,
        sort_by: str = None,
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
            sort_by: 排序字段（为空则按默认顺序）
            sort_order: 排序方向 (asc/desc)
            **filters: 过滤条件
            
        Returns:
            包含产品列表（带中文字段）和总页数的元组
        """
        # 构造表名
        table_name = f"insurance_products_{product_type}"
        
        # 获取字段及其中文说明
        fields_info = InsuranceProductCRUD.get_product_fields(product_type)
        field_desc_map = {f['name']: f['description'] for f in fields_info}
        
        try:
            # 构建基础查询
            where_clauses = []
            params = {}
            
            # 应用筛选条件
            for field, value in filters.items():
                if value is None or value == '':
                    continue
                
                # 处理范围筛选（字典形式）
                if isinstance(value, dict) and ("min" in value or "max" in value):
                    if "min" in value and value["min"] not in (None, ''):
                        where_clauses.append(f"{field} >= :min_{field}")
                        params[f"min_{field}"] = value["min"]
                    if "max" in value and value["max"] not in (None, ''):
                        where_clauses.append(f"{field} <= :max_{field}")
                        params[f"max_{field}"] = value["max"]
                
                # BOOLEAN类型筛选
                elif isinstance(value, bool):
                    where_clauses.append(f"{field} = :{field}")
                    params[field] = value
                
                # 数值类型筛选（支持大于、小于等符号）
                elif isinstance(value, str) and value:
                    # 检查是否包含比较符号
                    if value.startswith('>='):
                        where_clauses.append(f"CAST({field} AS NUMERIC) >= :{field}")
                        params[field] = float(value[2:].strip())
                    elif value.startswith('<='):
                        where_clauses.append(f"CAST({field} AS NUMERIC) <= :{field}")
                        params[field] = float(value[2:].strip())
                    elif value.startswith('>'):
                        where_clauses.append(f"CAST({field} AS NUMERIC) > :{field}")
                        params[field] = float(value[1:].strip())
                    elif value.startswith('<'):
                        where_clauses.append(f"CAST({field} AS NUMERIC) < :{field}")
                        params[field] = float(value[1:].strip())
                    elif value.startswith('='):
                        where_clauses.append(f"CAST({field} AS NUMERIC) = :{field}")
                        params[field] = float(value[1:].strip())
                    else:
                        # 文本模糊搜索
                        where_clauses.append(f"{field}::text ILIKE :{field}")
                        params[field] = f"%{value}%"
                
                # 数值类型精确匹配
                elif isinstance(value, (int, float)):
                    where_clauses.append(f"CAST({field} AS NUMERIC) = :{field}")
                    params[field] = value
            
            # 构建WHERE子句
            where_sql = ""
            if where_clauses:
                where_sql = "WHERE " + " AND ".join(where_clauses)
            
            # 计算总记录数
            count_query = text(f"SELECT COUNT(*) FROM {table_name} {where_sql}")
            
            with engine.connect() as conn:
                total_count = conn.execute(count_query, params).scalar()
                total_pages = (total_count + limit - 1) // limit if total_count > 0 else 1
                
                # 构建排序子句
                order_sql = ""
                if sort_by and sort_by.strip():
                    order_direction = "ASC" if sort_order.lower() == "asc" else "DESC"
                    order_sql = f"ORDER BY {sort_by} {order_direction}"
                
                # 构建查询语句
                offset = (page - 1) * limit
                query = text(f"""
                    SELECT * FROM {table_name} 
                    {where_sql}
                    {order_sql}
                    LIMIT :limit OFFSET :offset
                """)
                
                params['limit'] = limit
                params['offset'] = offset
                
                result = conn.execute(query, params)
                
                # 转换为字典列表（使用中文字段名）
                products = []
                for row in result:
                    product_dict = {}
                    for idx, column in enumerate(result.keys()):
                        chinese_name = field_desc_map.get(column, column)
                        product_dict[chinese_name] = row[idx]
                        
                        # 同时保留product_id的英文版本（作为唯一标识）
                        if column == 'product_id':
                            product_dict['product_id'] = row[idx]
                    
                    products.append(product_dict)
                
                return products, total_pages
                
        except Exception as e:
            logger.error(f"搜索产品失败: {e}")
            return [], 1
    
    @staticmethod
    def get_product_info(db: Session, product_id: int, product_type: str) -> Optional[Dict[str, Any]]:
        """
        获取产品详细信息（使用中文字段名）
        
        Args:
            db: 数据库会话
            product_id: 产品ID
            product_type: 产品类型
            
        Returns:
            产品详细信息字典（中文字段名），未找到则返回None
        """
        # 构造表名
        table_name = f"insurance_products_{product_type}"
        
        # 获取字段及其中文说明
        fields_info = InsuranceProductCRUD.get_product_fields(product_type)
        field_desc_map = {f['name']: f['description'] for f in fields_info}
        
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
                    
                # 转换为字典（使用中文字段名）
                result_dict = {}
                for idx, column in enumerate(result.keys()):
                    chinese_name = field_desc_map.get(column, column)
                    result_dict[chinese_name] = row[idx]
                    
                    # 同时保留product_id的英文版本（作为唯一标识）
                    if column == 'product_id':
                        result_dict['product_id'] = row[idx]
                
                # 添加产品类型，方便前端使用
                result_dict["product_type"] = product_type
                
                return result_dict
        except Exception as e:
            logger.error(f"查询表 {table_name} 失败: {e}")
            return None