import logging
from typing import Dict, List, Any
from sqlalchemy.orm import Session
from sqlalchemy import text, inspect, Column, String, Integer, DateTime, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.exc import ProgrammingError
import uuid
from datetime import datetime

from app.db.base import Base, engine

logger = logging.getLogger(__name__)

class DatabaseMigration:
    """数据库迁移工具，提供灵活的数据库结构更新和数据迁移功能"""
    
    def __init__(self, db_session: Session):
        self.db = db_session
        self.engine = engine
        self.inspector = inspect(engine)
        
    def get_current_version(self) -> int:
        """获取当前数据库版本"""
        try:
            with self.engine.begin() as conn:
                result = conn.execute(text("SELECT version FROM schema_version ORDER BY id DESC LIMIT 1"))
                row = result.fetchone()
                return row[0] if row else 0
        except ProgrammingError:
            # 如果表不存在，创建版本表
            self.create_version_table()
            return 0
    
    def create_version_table(self):
        """创建版本管理表"""
        try:
            with self.engine.begin() as conn:
                conn.execute(text("""
                    CREATE TABLE IF NOT EXISTS schema_version (
                        id SERIAL PRIMARY KEY,
                        version INTEGER NOT NULL,
                        description TEXT,
                        applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                """))
                # 插入初始版本
                conn.execute(text("""
                    INSERT INTO schema_version (version, description) 
                    VALUES (0, 'Initial database setup')
                """))
            logger.info("创建版本管理表成功")
        except Exception as e:
            logger.error(f"创建版本管理表失败: {e}")
    
    def update_version(self, version: int, description: str):
        """更新数据库版本"""
        try:
            with self.engine.begin() as conn:
                conn.execute(text("""
                    INSERT INTO schema_version (version, description) 
                    VALUES (:version, :description)
                """), {"version": version, "description": description})
            logger.info(f"数据库版本更新为: {version} - {description}")
        except Exception as e:
            logger.error(f"更新版本失败: {e}")
    
    def table_exists(self, table_name: str) -> bool:
        """检查表是否存在"""
        return table_name in self.inspector.get_table_names()
    
    def column_exists(self, table_name: str, column_name: str) -> bool:
        """检查列是否存在"""
        if not self.table_exists(table_name):
            return False
        
        columns = self.inspector.get_columns(table_name)
        return any(col['name'] == column_name for col in columns)
    
    def add_column_if_not_exists(self, table_name: str, column_name: str, column_type: str):
        """如果列不存在则添加"""
        if not self.column_exists(table_name, column_name):
            try:
                with self.engine.begin() as conn:
                    conn.execute(text(f"ALTER TABLE {table_name} ADD COLUMN {column_name} {column_type}"))
                logger.info(f"为表 {table_name} 添加列 {column_name}")
            except Exception as e:
                logger.error(f"添加列失败: {e}")
    
    def create_table_if_not_exists(self, table_name: str, sql: str):
        """如果表不存在则创建"""
        if not self.table_exists(table_name):
            try:
                with self.engine.begin() as conn:
                    conn.execute(text(sql))
                logger.info(f"创建表 {table_name}")
            except Exception as e:
                logger.error(f"创建表失败: {e}")
    
    def migrate_jsonb_data(self, table_name: str, column_name: str, old_structure: Dict[str, Any], new_structure: Dict[str, Any]):
        """迁移JSONB数据结构"""
        try:
            with self.engine.begin() as conn:
                # 获取所有记录
                result = conn.execute(text(f"SELECT * FROM {table_name}"))
                rows = result.fetchall()
                
                for row in rows:
                    row_dict = dict(row._mapping)
                    old_data = row_dict.get(column_name, {})
                    
                    if old_data:
                        # 执行数据迁移逻辑
                        new_data = self.transform_data_structure(old_data, old_structure, new_structure)
                        
                        # 更新记录
                        primary_key = list(row_dict.keys())[0]  # 假设第一列是主键
                        conn.execute(text(f"""
                            UPDATE {table_name} 
                            SET {column_name} = :new_data 
                            WHERE {primary_key} = :pk_value
                        """), {"new_data": new_data, "pk_value": row_dict[primary_key]})
                
            logger.info(f"成功迁移表 {table_name} 的 {column_name} 数据")
        except Exception as e:
            logger.error(f"数据迁移失败: {e}")
    
    def transform_data_structure(self, old_data: Dict[str, Any], old_structure: Dict[str, Any], new_structure: Dict[str, Any]) -> Dict[str, Any]:
        """转换数据结构"""
        new_data = {}
        
        # 复制现有的兼容数据
        for new_key, new_config in new_structure.items():
            if new_key in old_data:
                new_data[new_key] = old_data[new_key]
            else:
                # 设置默认值
                default_value = new_config.get('default')
                if default_value is not None:
                    new_data[new_key] = default_value
        
        return new_data
    
    def run_migrations(self):
        """运行所有需要的迁移"""
        current_version = self.get_current_version()
        logger.info(f"当前数据库版本: {current_version}")
        
        # 定义迁移步骤
        migrations = [
            (1, "添加目标管理表", self.migrate_to_v1),
            (2, "优化目标数据结构", self.migrate_to_v2),
            (3, "添加用户信息新字段", self.migrate_to_v3),
            # 在这里添加更多迁移...
        ]
        
        for version, description, migration_func in migrations:
            if current_version < version:
                logger.info(f"执行迁移到版本 {version}: {description}")
                try:
                    migration_func()
                    self.update_version(version, description)
                    logger.info(f"成功迁移到版本 {version}")
                except Exception as e:
                    logger.error(f"迁移到版本 {version} 失败: {e}")
                    break
    
    def migrate_to_v1(self):
        """迁移到版本1：添加目标管理表"""
        # 创建目标表
        self.create_table_if_not_exists('goals', """
            CREATE TABLE goals (
                user_id UUID PRIMARY KEY REFERENCES users(user_id),
                goals JSONB DEFAULT '[]'
            )
        """)
    
    def migrate_to_v2(self):
        """迁移到版本2：优化目标数据结构"""
        # 添加创建时间和更新时间列
        self.add_column_if_not_exists('goals', 'created_at', 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP')
        self.add_column_if_not_exists('goals', 'updated_at', 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP')
        
        # 如果需要，可以在这里执行数据结构迁移
        # self.migrate_jsonb_data('goals', 'goals', old_structure, new_structure)
    
    def migrate_to_v3(self):
        """迁移到版本3：添加用户信息新字段"""
        # 添加insurance_info列到user_info表
        self.add_column_if_not_exists('user_info', 'insurance_info', 'JSONB DEFAULT \'{}\'')
        
        # 添加创建时间和更新时间列（如果需要）
        self.add_column_if_not_exists('user_info', 'created_at', 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP')
        self.add_column_if_not_exists('user_info', 'updated_at', 'TIMESTAMP DEFAULT CURRENT_TIMESTAMP')
        
        # 如果需要，可以在这里执行数据结构迁移
        # self.migrate_jsonb_data('user_info', 'user_info', old_structure, new_structure)
    
    def backup_table(self, table_name: str):
        """备份表数据"""
        backup_table_name = f"{table_name}_backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        try:
            with self.engine.begin() as conn:
                conn.execute(text(f"CREATE TABLE {backup_table_name} AS SELECT * FROM {table_name}"))
            logger.info(f"成功备份表 {table_name} 到 {backup_table_name}")
        except Exception as e:
            logger.error(f"备份表失败: {e}")
    
    def rollback_to_version(self, target_version: int):
        """回滚到指定版本"""
        current_version = self.get_current_version()
        
        if target_version >= current_version:
            logger.warning(f"目标版本 {target_version} 不小于当前版本 {current_version}")
            return
        
        logger.info(f"开始回滚从版本 {current_version} 到版本 {target_version}")
        
        # 这里可以实现具体的回滚逻辑
        # 注意：回滚通常比较复杂，需要根据具体的迁移步骤来实现
        
    def validate_data_integrity(self) -> bool:
        """验证数据完整性"""
        try:
            # 检查必要的表是否存在
            required_tables = ['users', 'user_info', 'insurance_list', 'goals']
            
            for table in required_tables:
                if not self.table_exists(table):
                    logger.error(f"必要的表 {table} 不存在")
                    return False
            
            # 检查外键约束
            with self.engine.begin() as conn:
                # 检查目标表的外键约束
                result = conn.execute(text("""
                    SELECT COUNT(*) FROM goals g 
                    LEFT JOIN users u ON g.user_id = u.user_id 
                    WHERE u.user_id IS NULL
                """))
                orphaned_goals = result.scalar()
                
                if orphaned_goals > 0:
                    logger.warning(f"发现 {orphaned_goals} 个孤立的目标记录")
            
            logger.info("数据完整性验证通过")
            return True
        except Exception as e:
            logger.error(f"数据完整性验证失败: {e}")
            return False

def run_database_migration(db: Session):
    """运行数据库迁移的入口函数"""
    logger.info("开始数据库迁移...")
    
    migration = DatabaseMigration(db)
    
    # 运行迁移
    migration.run_migrations()
    
    # 验证数据完整性
    if migration.validate_data_integrity():
        logger.info("数据库迁移完成，数据完整性验证通过")
    else:
        logger.error("数据库迁移完成，但数据完整性验证失败")
    
    return migration 