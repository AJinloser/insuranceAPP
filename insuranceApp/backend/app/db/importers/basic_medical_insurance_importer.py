"""
基本医保数据导入器
"""
import pandas as pd
import logging
from pathlib import Path
from typing import Dict, List, Optional, Any
from sqlalchemy.orm import Session
from sqlalchemy.exc import SQLAlchemyError

from app.models.basic_medical_insurance import BasicMedicalInsurance

logger = logging.getLogger(__name__)


class BasicMedicalInsuranceImporter:
    """基本医保数据导入器"""
    
    def __init__(self, db_session: Session):
        """
        初始化导入器
        
        Args:
            db_session: 数据库会话
        """
        self.db = db_session
        
        # 字段映射：中文字段名 -> 英文字段名
        self.field_mapping = {
            "城市": "city",
            "数据年份": "data_year", 
            "统筹层次": "coordination_level",
            "官网链接": "official_website",
            "政策文件号": "policy_document_number",
            "职工_缴费基数下限": "employee_contribution_base_lower",
            "职工_缴费基数上限": "employee_contribution_base_upper",
            "职工_单位缴费比例": "employee_unit_contribution_rate",
            "职工_个人缴费比例": "employee_personal_contribution_rate",
            "居民_个人缴费标准": "resident_personal_contribution_standard",
            "居民_财政补助标准": "resident_financial_subsidy_standard",
            "在职_职工划入比例": "active_employee_account_transfer_rate",
            "退休_职工划入定额": "retired_employee_account_fixed_amount",
            "个人账户家庭共济": "personal_account_family_sharing",
            "职工_门诊起付线": "employee_outpatient_deductible",
            "职工_门诊封顶线": "employee_outpatient_ceiling",
            "在职_门诊支付比例": "active_outpatient_payment_ratio",
            "退休_门诊支付比例": "retired_outpatient_payment_ratio",
            "门诊特殊病种数量": "outpatient_special_disease_count",
            "居民_门诊起付线": "resident_outpatient_deductible",
            "居民_门诊支付比例": "resident_outpatient_payment_ratio",
            "居民_住院支付比例": "resident_inpatient_payment_ratio",
            "职工_住院起付线_首次": "employee_inpatient_deductible_first",
            "职工_住院起付线_后续": "employee_inpatient_deductible_subsequent",
            "职工_住院封顶线": "employee_inpatient_ceiling",
            "在职_分段1_额度范围": "active_segment1_amount_range",
            "在职_分段1_一级医院_支付比例": "active_segment1_level1_hospital_ratio",
            "在职_分段1_二级医院_支付比例": "active_segment1_level2_hospital_ratio",
            "在职_分段1_三级医院_支付比例": "active_segment1_level3_hospital_ratio",
            "在职_分段2_额度范围": "active_segment2_amount_range",
            "在职_分段2_一级医院_支付比例": "active_segment2_level1_hospital_ratio",
            "在职_分段2_二级医院_支付比例": "active_segment2_level2_hospital_ratio",
            "在职_分段2_三级医院_支付比例": "active_segment2_level3_hospital_ratio",
            "在职_分段3_额度范围": "active_segment3_amount_range",
            "在职_分段3_一级医院_支付比例": "active_segment3_level1_hospital_ratio",
            "在职_分段3_二级医院_支付比例": "active_segment3_level2_hospital_ratio",
            "在职_分段3_三级医院_支付比例": "active_segment3_level3_hospital_ratio",
            "在职_分段4_额度范围": "active_segment4_amount_range",
            "在职_分段4_支付比例": "active_segment4_payment_ratio",
            "退休_分段1_额度范围": "retired_segment1_amount_range",
            "退休_分段1_一级医院_支付比例": "retired_segment1_level1_hospital_ratio",
            "退休_分段1_二级医院_支付比例": "retired_segment1_level2_hospital_ratio",
            "退休_分段1_三级医院_支付比例": "retired_segment1_level3_hospital_ratio",
            "退休_分段2_额度范围": "retired_segment2_amount_range",
            "退休_分段2_一级医院_支付比例": "retired_segment2_level1_hospital_ratio",
            "退休_分段2_二级医院_支付比例": "retired_segment2_level2_hospital_ratio",
            "退休_分段2_三级医院_支付比例": "retired_segment2_level3_hospital_ratio",
            "退休_分段3_额度范围": "retired_segment3_amount_range",
            "退休_分段3_一级医院_支付比例": "retired_segment3_level1_hospital_ratio",
            "退休_分段3_二级医院_支付比例": "retired_segment3_level2_hospital_ratio",
            "退休_分段3_三级医院_支付比例": "retired_segment3_level3_hospital_ratio",
            "退休_分段4_额度范围": "retired_segment4_amount_range",
            "退休_分段4_支付比例": "retired_segment4_payment_ratio",
            "居民_住院起付线": "resident_inpatient_deductible",
            "居民_住院封顶线": "resident_inpatient_ceiling",
            "职工_大病保险起付线": "employee_serious_illness_deductible",
            "居民_大病保险起付线": "resident_serious_illness_deductible",
            "职工_大病保险支付比例": "employee_serious_illness_payment_ratio",
            "居民_大病保险支付比例": "resident_serious_illness_payment_ratio",
            "大病封顶线": "serious_illness_ceiling",
            "大病医疗_分段1_额度范围": "serious_illness_segment1_amount_range",
            "大病医疗_分段1_支付比例": "serious_illness_segment1_payment_ratio",
            "大病医疗_分段2_额度范围": "serious_illness_segment2_amount_range",
            "大病医疗_分段2_支付比例": "serious_illness_segment2_payment_ratio",
            "异地就医备案渠道": "remote_medical_filing_channel",
            "异地就医报销规则": "remote_medical_reimbursement_rules",
            "长期护理保险": "long_term_care_insurance",
            "医保药品目录执行": "medical_insurance_drug_catalog_execution",
            "转诊保持报销比例": "referral_maintain_reimbursement_ratio",
            "谈判药报销政策": "negotiated_drug_reimbursement_policy"
        }
    
    def import_from_excel(self, excel_path: str) -> bool:
        """
        从Excel文件导入基本医保数据
        
        Args:
            excel_path: Excel文件路径
            
        Returns:
            bool: 导入是否成功
        """
        try:
            # 读取Excel文件
            df = pd.read_excel(excel_path, header=None)
            logger.info(f"成功读取Excel文件: {excel_path}, 数据形状: {df.shape}")
            
            # 获取字段名（B列，索引1）
            field_names = df.iloc[:, 1].dropna().tolist()
            logger.info(f"发现 {len(field_names)} 个字段")
            
            # 清空现有数据
            self.db.query(BasicMedicalInsurance).delete()
            self.db.commit()
            logger.info("清空现有基本医保数据")
            
            # 获取数据列（从D列开始，索引3开始）
            data_columns = list(range(3, df.shape[1]))
            imported_count = 0
            
            for col_idx in data_columns:
                city_data = df.iloc[:, col_idx]
                
                # 跳过空列
                if city_data.isna().all():
                    continue
                
                # 创建数据记录
                record_data = {}
                
                for i, field_name in enumerate(field_names):
                    if i >= len(city_data):
                        break
                        
                    value = city_data.iloc[i]
                    
                    # 处理空值
                    if pd.isna(value):
                        value = None
                    else:
                        # 统一转换为字符串
                        if isinstance(value, (int, float)):
                            # 对于数值类型，转换为字符串
                            if pd.isna(value) or value != value:  # 检查NaN
                                value = None
                            else:
                                value = str(value)
                        else:
                            value = str(value).strip()
                            # 处理空字符串
                            if value.lower() in ['nan', '', 'none', 'null']:
                                value = None
                    
                    # 映射字段名
                    if field_name in self.field_mapping:
                        english_field = self.field_mapping[field_name]
                        record_data[english_field] = value
                
                # 确保城市字段不为空
                if not record_data.get("city"):
                    logger.warning(f"跳过空城市数据，列索引: {col_idx}")
                    continue
                
                # 创建数据库记录
                try:
                    record = BasicMedicalInsurance(**record_data)
                    self.db.add(record)
                    imported_count += 1
                    logger.debug(f"添加城市数据: {record_data.get('city')}")
                except Exception as e:
                    logger.error(f"创建记录失败，城市: {record_data.get('city')}, 错误: {e}")
                    continue
            
            # 提交事务
            self.db.commit()
            logger.info(f"成功导入 {imported_count} 条基本医保数据")
            return True
            
        except Exception as e:
            logger.error(f"导入基本医保数据失败: {e}")
            self.db.rollback()
            return False
    
    def get_import_summary(self) -> Dict[str, Any]:
        """
        获取导入摘要信息
        
        Returns:
            Dict: 导入摘要
        """
        try:
            total_count = self.db.query(BasicMedicalInsurance).count()
            cities = self.db.query(BasicMedicalInsurance.city).distinct().all()
            city_list = [city[0] for city in cities]
            
            return {
                "total_records": total_count,
                "cities_count": len(city_list),
                "cities": city_list
            }
        except Exception as e:
            logger.error(f"获取导入摘要失败: {e}")
            return {
                "total_records": 0,
                "cities_count": 0,
                "cities": []
            }


def import_basic_medical_insurance_data(db: Session, excel_path: str) -> bool:
    """
    导入基本医保数据的便捷函数
    
    Args:
        db: 数据库会话
        excel_path: Excel文件路径
        
    Returns:
        bool: 导入是否成功
    """
    importer = BasicMedicalInsuranceImporter(db)
    success = importer.import_from_excel(excel_path)
    
    if success:
        summary = importer.get_import_summary()
        logger.info(f"基本医保数据导入完成: {summary}")
    
    return success
