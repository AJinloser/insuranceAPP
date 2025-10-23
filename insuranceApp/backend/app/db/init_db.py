import logging
from pathlib import Path
from sqlalchemy.orm import Session
from sqlalchemy import text, inspect

from app.db.base import Base, engine
from app.db.migration import run_database_migration
from app.db.importers import import_basic_medical_insurance_data, import_insurance_products_data
from app.db.importers.social_pension_insurance_importer import import_social_pension_insurance_data
from app.models.user import User
from app.models.user_info import UserInfo
from app.models.insurance_list import InsuranceList
from app.models.goal import Goal
from app.models.basic_medical_insurance import BasicMedicalInsurance
from app.models.social_pension_insurance import SocialPensionInsurance

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
    
    logger.info("导入保险产品数据...")
    # 获取数据文件目录路径
    base_dir = Path(__file__).resolve().parent.parent.parent
    data_dir = base_dir / "datas"
    
    # 导入保险产品数据
    if data_dir.exists():
        summary = import_insurance_products_data(db, str(data_dir))
        logger.info(f"保险产品数据导入完成: 成功导入 {summary['successful_tables']}/{summary['total_tables']} 个表，共 {summary['total_records']} 条记录")
        for product_type, info in summary['tables'].items():
            logger.info(f"  - {product_type}: {info['table_name']} ({info['record_count']} 条记录)")
    else:
        logger.warning(f"数据目录不存在: {data_dir}")
    
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
    
    # 导入社会养老保险数据
    logger.info("导入社会养老保险数据...")
    pension_excel_path = base_dir / "datas" / "社会养老保险.xlsx"
    if pension_excel_path.exists():
        success = import_social_pension_insurance_data(db, str(pension_excel_path))
        if success:
            logger.info("社会养老保险数据导入成功")
        else:
            logger.error("社会养老保险数据导入失败")
    else:
        logger.warning(f"社会养老保险数据文件不存在: {pension_excel_path}")
    
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