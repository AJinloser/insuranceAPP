import logging
from pathlib import Path
from sqlalchemy.orm import Session
from sqlalchemy import text, inspect

from app.db.base import Base, engine
from app.db.sql_importer import SQLImporter
from app.db.migration import run_database_migration
from app.db.importers import import_basic_medical_insurance_data
from app.models.user import User
from app.models.user_info import UserInfo
from app.models.insurance_list import InsuranceList
from app.models.goal import Goal
from app.models.basic_medical_insurance import BasicMedicalInsurance

logger = logging.getLogger(__name__)

def clean_insurance_tables(engine) -> None:
    """
    清理旧的保险产品表，以便重新导入
    
    Args:
        engine: 数据库引擎
    """
    logger.info("清理旧的保险产品表...")
    
    # 获取所有表名
    inspector = inspect(engine)
    all_tables = inspector.get_table_names()
    
    # 筛选出保险产品相关的表（新格式和旧格式）
    insurance_tables = [
        table for table in all_tables 
        if table.startswith("insurance_products") or "insurance" in table.lower()
    ]
    
    if not insurance_tables:
        logger.info("没有找到需要清理的保险产品表")
        return
    
    # 删除表
    with engine.begin() as conn:
        for table in insurance_tables:
            try:
                logger.info(f"删除表: {table}")
                conn.execute(text(f"DROP TABLE IF EXISTS {table} CASCADE"))
            except Exception as e:
                logger.error(f"删除表 {table} 失败: {str(e)}")
    
    logger.info(f"成功清理 {len(insurance_tables)} 个保险产品表")

def init_db(db: Session) -> None:
    """
    初始化数据库，创建表并导入数据
    
    Args:
        db: 数据库会话
    """
    # 清理旧表
    clean_insurance_tables(engine)
    
    logger.info("创建数据库表...")
    Base.metadata.create_all(bind=engine)
    
    # 运行数据库迁移
    logger.info("执行数据库迁移...")
    run_database_migration(db)
    
    logger.info("导入SQL文件...")
    # 获取SQL文件目录路径
    base_dir = Path(__file__).resolve().parent.parent.parent
    sql_dir = base_dir / "sql"
    
    # 检查SQL目录是否存在
    if not sql_dir.exists():
        logger.error(f"SQL目录不存在: {sql_dir}")
        return
    
    # 列出所有SQL文件
    sql_files = list(sql_dir.glob("*.sql"))
    logger.info(f"发现 {len(sql_files)} 个SQL文件: {', '.join([f.name for f in sql_files])}")
    
    # 导入SQL文件
    importer = SQLImporter(engine, str(sql_dir))
    imported_files = importer.import_all_sql_files()
    
    if imported_files:
        logger.info(f"成功导入 {len(imported_files)}/{len(sql_files)} 个SQL文件: ")
        for file_name, table_name in imported_files.items():
            logger.info(f"  - {file_name}")
    else:
        logger.warning("没有导入任何SQL文件")
    
    # 验证表是否成功创建
    inspector = inspect(engine)
    all_tables = inspector.get_table_names()
    insurance_tables = [table for table in all_tables if "insurance" in table.lower()]
    
    logger.info(f"数据库中的保险相关表 ({len(insurance_tables)}): {', '.join(insurance_tables)}")
    
    # 导入基本医保数据
    logger.info("导入基本医保数据...")
    excel_path = base_dir / "datas" / "基本医保.xlsx"
    if excel_path.exists():
        success = import_basic_medical_insurance_data(db, str(excel_path))
        if success:
            logger.info("基本医保数据导入成功")
        else:
            logger.error("基本医保数据导入失败")
    else:
        logger.warning(f"基本医保数据文件不存在: {excel_path}")
    
    # 添加测试用户，如果不存在
    create_test_user(db)
    
    logger.info("数据库初始化完成")
    
def create_test_user(db: Session) -> None:
    """
    创建测试用户，如果用户不存在
    
    Args:
        db: 数据库会话
    """
    from app.core.security import get_password_hash
    
    # 检查测试用户是否存在
    test_user = db.query(User).filter(User.account == "test").first()
    
    if not test_user:
        logger.info("创建测试用户...")
        
        # 创建测试用户
        test_user = User(
            account="test",
            password=get_password_hash("password")
        )
        
        db.add(test_user)
        db.commit()
        
        logger.info(f"测试用户创建成功: {test_user.user_id}")
    else:
        logger.info("测试用户已存在，跳过创建") 