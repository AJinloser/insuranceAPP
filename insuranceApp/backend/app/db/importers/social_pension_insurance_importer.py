"""
社会养老保险数据导入器
"""
import pandas as pd
import logging
import json
from pathlib import Path
from typing import Dict, List, Optional, Any
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError

from app.models.social_pension_insurance import SocialPensionInsurance

logger = logging.getLogger(__name__)


class SocialPensionInsuranceImporter:
    """社会养老保险数据导入器"""
    
    def __init__(self, db_session: Session):
        """
        初始化导入器
        
        Args:
            db_session: 数据库会话
        """
        self.db = db_session
        
        # 字段映射：中文字段名 -> 英文字段名
        self.field_mapping = {
            "唯一记录ID，自增": "id",
            "关联省市代码": "province_code",
            "关联数据年份": "data_year",
            "核定缴费基数的全省月平均工资": "avg_monthly_salary_basis",
            "城镇职工缴费基数下限": "contribution_base_min",
            "城镇职工缴费基数上限": "contribution_base_max",
            "城镇职工单位缴费比例": "employer_ratio",
            "城镇职工个人缴费比例": "employee_ratio",
            "灵活就业人员缴费比例": "flexible_worker_ratio",
            "城乡居民最低缴费金额": "contribution_base_min_city",
            "城乡居民最高缴费金额": "contribution_base_max_city",
            "男性退休年龄": "retirement_age_male",
            "女性退休年龄": "retirement_age_female",
            "女工人退休年龄（如不同）": "retirement_age_female_worker",
            "最低累计缴费年限": "min_contribution_years",
            "缴费档次": "contribution_tiers",
            "与缴费档次对应的政府补贴标准": "government_subsidies",
            "待遇领取年龄": "retirement_age",
            "省级城乡居民基础养老金最低标准（元/月）": "base_pension_standard",
            "长缴多得激励政策描述": "long_term_incentive",
            "多缴多得激励政策描述": "more_pay_more_incentive",
            "跨省关系转移接续流程": "transfer_process",
            "转移办理时限（官方承诺）": "transfer_timeframe",
            "养老金领取地确定规则（简述户籍优先从长从后的原则）": "pension_qualification_rule",
            "转移时资金划转规则": "fund_transfer_rule",
            "异地待遇领取资格认证方式": "remote_certification",
            "资格认证周期": "certification_frequency",
            "养老金异地发放方式": "remote_payment_method",
            "特别说明/地方性规定": "special_notes"
        }
        
        # JSON字段列表
        self.json_fields = ["contribution_tiers", "government_subsidies"]
    
    def import_from_excel(self, excel_path: str) -> bool:
        """
        从Excel文件导入社会养老保险数据
        
        Args:
            excel_path: Excel文件路径
            
        Returns:
            bool: 导入是否成功
        """
        try:
            # 读取Excel文件
            df = pd.read_excel(excel_path, header=None)
            logger.info(f"成功读取Excel文件: {excel_path}, 数据形状: {df.shape}")
            
            # 获取字段名（C列，索引2）
            field_names = df.iloc[:, 2].dropna().tolist()
            logger.info(f"发现 {len(field_names)} 个字段")
            
            # 清空现有数据
            self.db.query(SocialPensionInsurance).delete()
            self.db.commit()
            logger.info("清空现有社会养老保险数据")
            
            # 获取数据列（从D列开始，索引3开始）
            data_columns = list(range(3, df.shape[1]))
            imported_count = 0
            
            for col_idx in data_columns:
                province_data = df.iloc[:, col_idx]
                
                # 跳过空列
                if province_data.isna().all():
                    continue
                
                # 创建数据记录
                record_data = {}
                
                for i, field_name in enumerate(field_names):
                    if i >= len(province_data):
                        break
                        
                    value = province_data.iloc[i]
                    
                    # 获取对应的英文字段名
                    english_field = self.field_mapping.get(field_name)
                    if not english_field:
                        logger.warning(f"未找到字段映射: {field_name}")
                        continue
                    
                    # 跳过id字段，使用自动生成的UUID
                    if english_field == "id":
                        continue
                    
                    # 处理空值
                    if pd.isna(value):
                        value = None
                    else:
                        # 根据字段类型处理值
                        if english_field in self.json_fields:
                            # JSON字段处理
                            try:
                                if isinstance(value, str):
                                    # 尝试解析JSON字符串
                                    value = json.loads(value)
                                elif isinstance(value, list):
                                    # 已经是列表
                                    pass
                                else:
                                    # 转换为字符串后再解析
                                    value = json.loads(str(value))
                            except (json.JSONDecodeError, ValueError):
                                logger.warning(f"JSON解析失败: {field_name} = {value}")
                                value = None
                        else:
                            # 非JSON字段
                            if isinstance(value, (int, float)):
                                # 对于数值类型，检查是否为NaN
                                if pd.isna(value) or value != value:
                                    value = None
                            else:
                                # 字符串类型
                                value = str(value).strip()
                                # 处理空字符串
                                if value.lower() in ['nan', '', 'none', 'null']:
                                    value = None
                    
                    record_data[english_field] = value
                
                # 确保省市代码字段不为空
                if not record_data.get("province_code"):
                    logger.warning(f"跳过空省市数据，列索引: {col_idx}")
                    continue
                
                # 创建数据库记录
                try:
                    record = SocialPensionInsurance(**record_data)
                    self.db.add(record)
                    imported_count += 1
                    logger.debug(f"添加省市数据: {record_data.get('province_code')}")
                except Exception as e:
                    logger.error(f"创建记录失败，省市: {record_data.get('province_code')}, 错误: {e}")
                    continue
            
            # 提交事务
            self.db.commit()
            logger.info(f"成功导入 {imported_count} 条社会养老保险数据")
            return True
            
        except Exception as e:
            logger.error(f"导入社会养老保险数据失败: {e}")
            self.db.rollback()
            return False
    
    def get_import_summary(self) -> Dict[str, Any]:
        """
        获取导入摘要信息
        
        Returns:
            Dict: 导入摘要
        """
        try:
            total_count = self.db.query(SocialPensionInsurance).count()
            provinces = self.db.query(SocialPensionInsurance.province_code).distinct().all()
            province_list = [province[0] for province in provinces]
            
            return {
                "total_records": total_count,
                "provinces_count": len(province_list),
                "provinces": province_list
            }
        except Exception as e:
            logger.error(f"获取导入摘要失败: {e}")
            return {
                "total_records": 0,
                "provinces_count": 0,
                "provinces": []
            }


def import_social_pension_insurance_data(db: Session, excel_path: str) -> bool:
    """
    导入社会养老保险数据的便捷函数
    
    Args:
        db: 数据库会话
        excel_path: Excel文件路径
        
    Returns:
        bool: 导入是否成功
    """
    importer = SocialPensionInsuranceImporter(db)
    success = importer.import_from_excel(excel_path)
    
    if success:
        summary = importer.get_import_summary()
        logger.info(f"社会养老保险数据导入完成: {summary}")
    
    return success

