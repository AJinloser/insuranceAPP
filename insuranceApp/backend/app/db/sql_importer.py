import os
import logging
import re
from pathlib import Path
from typing import List, Optional, Dict, Tuple

from sqlalchemy import text
from sqlalchemy.engine import Engine
from sqlalchemy.exc import SQLAlchemyError

logger = logging.getLogger(__name__)

class SQLImporter:
    """SQL文件导入工具，用于将SQL文件导入到数据库中"""
    
    def __init__(self, engine: Engine, sql_dir: str):
        """
        初始化SQL导入器
        
        Args:
            engine: SQLAlchemy引擎
            sql_dir: SQL文件目录路径
        """
        self.engine = engine
        self.sql_dir = Path(sql_dir)
        
    def import_all_sql_files(self) -> Dict[str, str]:
        """
        导入所有SQL文件
        
        Returns:
            导入成功的文件字典 {SQL文件名: 表名}
        """
        if not self.sql_dir.exists():
            logger.error(f"SQL目录不存在: {self.sql_dir}")
            return {}
            
        sql_files = list(self.sql_dir.glob("*.sql"))
        imported_files = {}
        
        # 获取产品类型与SQL文件的映射
        product_mapping = self.get_product_type_mapping()
        
        # 先尝试删除所有旧表
        self._drop_all_tables()
        
        for sql_file in sql_files:
            file_name = sql_file.name
            # 提取对应的产品类型
            product_type = None
            for pt, fn in product_mapping.items():
                if fn == file_name:
                    product_type = pt
                    break
            
            # 构建表名 insurance_products_{文件名去掉.sql}
            table_name = f"insurance_products_{file_name.replace('.sql', '')}"
            
            # 导入SQL文件
            import_success, error_msg = self.import_sql_file(sql_file)
            if import_success:
                # 记录导入成功的文件及其表名
                imported_files[file_name] = table_name
                logger.info(f"成功导入SQL文件: {file_name} -> {table_name}")
            else:
                logger.error(f"导入SQL文件 {file_name} 失败: {error_msg}")
                
        return imported_files
    
    def _drop_all_tables(self) -> None:
        """删除所有保险产品相关的表"""
        try:
            # 获取所有表
            table_query = text("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public' AND
                (table_name LIKE 'insurance_products%' OR table_name = 'insurance_products')
            """)
            
            with self.engine.begin() as conn:
                result = conn.execute(table_query)
                tables = [row[0] for row in result]
                
                # 删除每个表
                for table in tables:
                    logger.info(f"删除表: {table}")
                    conn.execute(text(f"DROP TABLE IF EXISTS {table} CASCADE"))
                    
            logger.info(f"已清除 {len(tables)} 个保险产品相关表")
        except Exception as e:
            logger.error(f"删除表失败: {str(e)}")
    
    def import_sql_file(self, sql_file: Path) -> Tuple[bool, str]:
        """
        导入单个SQL文件
        
        Args:
            sql_file: SQL文件路径
            
        Returns:
            成功标志和错误信息的元组
        """
        try:
            logger.info(f"正在导入SQL文件: {sql_file}")
            
            # 读取SQL文件内容
            sql_content = sql_file.read_text(encoding='utf-8')
            
            # 如果SQL文件包含多条语句，拆分并逐条执行
            statements = self._split_sql_statements(sql_content)
            
            with self.engine.begin() as conn:
                for i, stmt in enumerate(statements):
                    if stmt.strip():
                        try:
                            conn.execute(text(stmt))
                        except SQLAlchemyError as e:
                            logger.error(f"执行SQL语句失败 ({i+1}/{len(statements)}): {e}")
                            logger.error(f"问题语句: {stmt[:100]}...")
                            raise
            
            return True, ""
        except Exception as e:
            error_msg = str(e)
            logger.error(f"导入SQL文件 {sql_file} 失败: {error_msg}")
            return False, error_msg
    
    def _split_sql_statements(self, sql_content: str) -> List[str]:
        """
        将SQL内容拆分为多个语句
        
        Args:
            sql_content: SQL内容
            
        Returns:
            SQL语句列表
        """
        # 简单按分号拆分，忽略引号中的分号
        statements = []
        current_stmt = []
        in_string = False
        string_char = None
        
        for char in sql_content:
            if char in ['"', "'"]:
                if not in_string:
                    in_string = True
                    string_char = char
                elif char == string_char:
                    in_string = False
                    string_char = None
            
            current_stmt.append(char)
            
            if char == ';' and not in_string:
                statements.append(''.join(current_stmt))
                current_stmt = []
        
        # 添加最后一个语句（如果没有以分号结尾）
        if current_stmt:
            statements.append(''.join(current_stmt))
        
        return statements
    
    def _sanitize_table_name(self, name: str) -> str:
        """
        将产品类型名称转换为有效的表名
        
        Args:
            name: 产品类型名称
            
        Returns:
            有效的表名
        """
        # 移除特殊字符，将中文转为拼音或使用简单的替换
        replacements = {
            "定期寿险": "termlife",
            "定额终身寿险": "wholelife",
            "意外险": "accident",
            "年金险": "annuity",
            "重疾险": "critical_illness",
            "高端医疗险": "high_medical",
            "百万医疗险及中端医疗险": "medical"
        }
        
        if name in replacements:
            return replacements[name]
        
        # 默认情况下，移除所有非字母数字字符
        return re.sub(r'[^a-zA-Z0-9]', '_', name)
            
    def get_product_type_mapping(self) -> dict:
        """
        获取产品类型与SQL文件的映射关系
        
        Returns:
            产品类型映射字典 {产品类型: SQL文件名}
        """
        mapping = {
            "定期寿险": "termlife.sql",
            "定额终身寿险": "wholelife.sql",
            "意外险": "accident.sql",
            "年金险": "annuity.sql",
            "重疾险": "critical_illness.sql",
            "高端医疗险": "high_medical_level.sql",
            "百万医疗险及中端医疗险": "medical.sql"
        }
        
        return mapping 