"""
基本医保数据CRUD操作
"""
import logging
from typing import Optional, Dict, Any, List
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_

from app.models.basic_medical_insurance import BasicMedicalInsurance

logger = logging.getLogger(__name__)


class BasicMedicalInsuranceCRUD:
    """基本医保数据CRUD操作类"""
    
    def __init__(self, db: Session):
        """
        初始化CRUD操作类
        
        Args:
            db: 数据库会话
        """
        self.db = db
    
    def get_by_city(self, city: str) -> Optional[BasicMedicalInsurance]:
        """
        根据城市查询基本医保数据
        
        Args:
            city: 城市名称
            
        Returns:
            BasicMedicalInsurance: 基本医保数据记录，如果未找到返回None
        """
        try:
            # 使用模糊匹配查找城市
            record = self.db.query(BasicMedicalInsurance).filter(
                or_(
                    BasicMedicalInsurance.city == city,
                    BasicMedicalInsurance.city.ilike(f"%{city}%"),
                    BasicMedicalInsurance.city.ilike(f"{city}%"),
                    BasicMedicalInsurance.city.ilike(f"%{city}")
                )
            ).first()
            
            return record
        except Exception as e:
            logger.error(f"查询城市 {city} 的基本医保数据失败: {e}")
            return None
    
    def get_filtered_data(self, city: str, category: str, employment_status: Optional[str] = None) -> Optional[Dict[str, Any]]:
        """
        根据条件获取过滤后的基本医保数据
        
        Args:
            city: 城市名称
            category: 种类（城镇职工/城乡居民）
            employment_status: 在职/退休状态（仅在种类为城镇职工时有效）
            
        Returns:
            Dict: 过滤后的数据字典，如果未找到返回None
        """
        try:
            # 查询基础数据
            record = self.get_by_city(city)
            if not record:
                logger.warning(f"未找到城市 {city} 的基本医保数据")
                return None
            
            # 转换为字典
            data_dict = self._record_to_dict(record)
            
            # 根据种类过滤数据
            if category == "城乡居民":
                filtered_data = self._filter_resident_data(data_dict)
            elif category == "城镇职工":
                filtered_data = self._filter_employee_data(data_dict, employment_status)
            else:
                logger.error(f"不支持的种类: {category}")
                return None
            
            return filtered_data
            
        except Exception as e:
            logger.error(f"获取过滤数据失败: {e}")
            return None
    
    def _record_to_dict(self, record: BasicMedicalInsurance) -> Dict[str, Any]:
        """
        将数据库记录转换为字典
        
        Args:
            record: 数据库记录
            
        Returns:
            Dict: 数据字典
        """
        # 字段映射：英文字段名 -> 中文字段名
        field_mapping = {
            "city": "城市",
            "data_year": "数据年份", 
            "coordination_level": "统筹层次",
            "official_website": "官网链接",
            "policy_document_number": "政策文件号",
            "employee_contribution_base_lower": "职工_缴费基数下限",
            "employee_contribution_base_upper": "职工_缴费基数上限",
            "employee_unit_contribution_rate": "职工_单位缴费比例",
            "employee_personal_contribution_rate": "职工_个人缴费比例",
            "resident_personal_contribution_standard": "居民_个人缴费标准",
            "resident_financial_subsidy_standard": "居民_财政补助标准",
            "active_employee_account_transfer_rate": "在职_职工划入比例",
            "retired_employee_account_fixed_amount": "退休_职工划入定额",
            "personal_account_family_sharing": "个人账户家庭共济",
            "employee_outpatient_deductible": "职工_门诊起付线",
            "employee_outpatient_ceiling": "职工_门诊封顶线",
            "active_outpatient_payment_ratio": "在职_门诊支付比例",
            "retired_outpatient_payment_ratio": "退休_门诊支付比例",
            "outpatient_special_disease_count": "门诊特殊病种数量",
            "resident_outpatient_deductible": "居民_门诊起付线",
            "resident_outpatient_payment_ratio": "居民_门诊支付比例",
            "resident_inpatient_payment_ratio": "居民_住院支付比例",
            "employee_inpatient_deductible_first": "职工_住院起付线_首次",
            "employee_inpatient_deductible_subsequent": "职工_住院起付线_后续",
            "employee_inpatient_ceiling": "职工_住院封顶线",
            "active_segment1_amount_range": "在职_分段1_额度范围",
            "active_segment1_level1_hospital_ratio": "在职_分段1_一级医院_支付比例",
            "active_segment1_level2_hospital_ratio": "在职_分段1_二级医院_支付比例",
            "active_segment1_level3_hospital_ratio": "在职_分段1_三级医院_支付比例",
            "active_segment2_amount_range": "在职_分段2_额度范围",
            "active_segment2_level1_hospital_ratio": "在职_分段2_一级医院_支付比例",
            "active_segment2_level2_hospital_ratio": "在职_分段2_二级医院_支付比例",
            "active_segment2_level3_hospital_ratio": "在职_分段2_三级医院_支付比例",
            "active_segment3_amount_range": "在职_分段3_额度范围",
            "active_segment3_level1_hospital_ratio": "在职_分段3_一级医院_支付比例",
            "active_segment3_level2_hospital_ratio": "在职_分段3_二级医院_支付比例",
            "active_segment3_level3_hospital_ratio": "在职_分段3_三级医院_支付比例",
            "active_segment4_amount_range": "在职_分段4_额度范围",
            "active_segment4_payment_ratio": "在职_分段4_支付比例",
            "retired_segment1_amount_range": "退休_分段1_额度范围",
            "retired_segment1_level1_hospital_ratio": "退休_分段1_一级医院_支付比例",
            "retired_segment1_level2_hospital_ratio": "退休_分段1_二级医院_支付比例",
            "retired_segment1_level3_hospital_ratio": "退休_分段1_三级医院_支付比例",
            "retired_segment2_amount_range": "退休_分段2_额度范围",
            "retired_segment2_level1_hospital_ratio": "退休_分段2_一级医院_支付比例",
            "retired_segment2_level2_hospital_ratio": "退休_分段2_二级医院_支付比例",
            "retired_segment2_level3_hospital_ratio": "退休_分段2_三级医院_支付比例",
            "retired_segment3_amount_range": "退休_分段3_额度范围",
            "retired_segment3_level1_hospital_ratio": "退休_分段3_一级医院_支付比例",
            "retired_segment3_level2_hospital_ratio": "退休_分段3_二级医院_支付比例",
            "retired_segment3_level3_hospital_ratio": "退休_分段3_三级医院_支付比例",
            "retired_segment4_amount_range": "退休_分段4_额度范围",
            "retired_segment4_payment_ratio": "退休_分段4_支付比例",
            "resident_inpatient_deductible": "居民_住院起付线",
            "resident_inpatient_ceiling": "居民_住院封顶线",
            "employee_serious_illness_deductible": "职工_大病保险起付线",
            "resident_serious_illness_deductible": "居民_大病保险起付线",
            "employee_serious_illness_payment_ratio": "职工_大病保险支付比例",
            "resident_serious_illness_payment_ratio": "居民_大病保险支付比例",
            "serious_illness_ceiling": "大病封顶线",
            "serious_illness_segment1_amount_range": "大病医疗_分段1_额度范围",
            "serious_illness_segment1_payment_ratio": "大病医疗_分段1_支付比例",
            "serious_illness_segment2_amount_range": "大病医疗_分段2_额度范围",
            "serious_illness_segment2_payment_ratio": "大病医疗_分段2_支付比例",
            "remote_medical_filing_channel": "异地就医备案渠道",
            "remote_medical_reimbursement_rules": "异地就医报销规则",
            "long_term_care_insurance": "长期护理保险",
            "medical_insurance_drug_catalog_execution": "医保药品目录执行",
            "referral_maintain_reimbursement_ratio": "转诊保持报销比例",
            "negotiated_drug_reimbursement_policy": "谈判药报销政策"
        }
        
        result = {}
        for english_field, chinese_field in field_mapping.items():
            value = getattr(record, english_field, None)
            result[chinese_field] = value
        
        return result
    
    def _filter_resident_data(self, data_dict: Dict[str, Any]) -> Dict[str, Any]:
        """
        过滤居民相关数据
        
        Args:
            data_dict: 原始数据字典
            
        Returns:
            Dict: 过滤后的数据字典
        """
        filtered_data = {}
        
        for field_name, value in data_dict.items():
            # 包含居民前缀的字段
            if field_name.startswith("居民_"):
                filtered_data[field_name] = value
            # 不包含任何特定前缀的通用字段
            elif not any(prefix in field_name for prefix in ["职工_", "在职_", "退休_"]):
                filtered_data[field_name] = value
        
        return filtered_data
    
    def _filter_employee_data(self, data_dict: Dict[str, Any], employment_status: Optional[str]) -> Dict[str, Any]:
        """
        过滤职工相关数据
        
        Args:
            data_dict: 原始数据字典
            employment_status: 在职/退休状态
            
        Returns:
            Dict: 过滤后的数据字典
        """
        filtered_data = {}
        
        for field_name, value in data_dict.items():
            # 包含职工前缀的字段
            if field_name.startswith("职工_"):
                filtered_data[field_name] = value
                continue
            
            if not employment_status:
                if field_name.startswith("在职_") or field_name.startswith("退休_"):
                    filtered_data[field_name] = value
                    continue
            else:
                if employment_status == "在职" and field_name.startswith("在职_"):
                    filtered_data[field_name] = value
                    continue
                elif employment_status == "退休" and field_name.startswith("退休_"):
                    filtered_data[field_name] = value
                    continue
            if not any(prefix in field_name for prefix in ["居民_", "职工_", "在职_", "退休_"]):
                filtered_data[field_name] = value
                continue
        
        return filtered_data
    
    def get_all_cities(self) -> List[str]:
        """
        获取所有城市列表
        
        Returns:
            List[str]: 城市名称列表
        """
        try:
            cities = self.db.query(BasicMedicalInsurance.city).distinct().all()
            return [city[0] for city in cities if city[0]]
        except Exception as e:
            logger.error(f"获取城市列表失败: {e}")
            return []


def get_basic_medical_insurance_crud(db: Session) -> BasicMedicalInsuranceCRUD:
    """
    获取基本医保CRUD操作实例
    
    Args:
        db: 数据库会话
        
    Returns:
        BasicMedicalInsuranceCRUD: CRUD操作实例
    """
    return BasicMedicalInsuranceCRUD(db)
