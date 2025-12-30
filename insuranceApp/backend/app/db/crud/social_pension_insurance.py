"""
社会养老保险数据CRUD操作
"""
import logging
from typing import Optional, Dict, Any, List
from sqlalchemy.orm import Session
from sqlalchemy import or_, and_

from app.models.social_pension_insurance import SocialPensionInsurance

logger = logging.getLogger(__name__)


class SocialPensionInsuranceCRUD:
    """社会养老保险数据CRUD操作类"""
    
    def __init__(self, db: Session):
        """
        初始化CRUD操作类
        
        Args:
            db: 数据库会话
        """
        self.db = db
    
    def get_by_province(self, province: str) -> Optional[SocialPensionInsurance]:
        """
        根据省市查询社会养老保险数据
        
        Args:
            province: 省市名称或代码
            
        Returns:
            SocialPensionInsurance: 社会养老保险数据记录，如果未找到返回None
        """
        try:
            # 使用模糊匹配查找省市
            record = self.db.query(SocialPensionInsurance).filter(
                or_(
                    SocialPensionInsurance.province_code == province,
                    SocialPensionInsurance.province_code.ilike(f"%{province}%"),
                    SocialPensionInsurance.province_code.ilike(f"{province}%"),
                    SocialPensionInsurance.province_code.ilike(f"%{province}")
                )
            ).first()
            
            return record
        except Exception as e:
            logger.error(f"查询省市 {province} 的社会养老保险数据失败: {e}")
            return None
    
    def get_data_as_dict(self, province: str) -> Optional[Dict[str, Any]]:
        """
        根据省市获取社会养老保险数据（转换为中文字段名）
        
        Args:
            province: 省市名称或代码
            
        Returns:
            Dict: 数据字典，如果未找到返回None
        """
        try:
            # 查询基础数据
            record = self.get_by_province(province)
            if not record:
                logger.warning(f"未找到省市 {province} 的社会养老保险数据")
                return None
            
            # 转换为字典
            data_dict = self._record_to_dict(record)
            return data_dict
            
        except Exception as e:
            logger.error(f"获取数据失败: {e}")
            return None
    
    def _record_to_dict(self, record: SocialPensionInsurance) -> Dict[str, Any]:
        """
        将数据库记录转换为字典（使用中文字段名）
        
        Args:
            record: 数据库记录
            
        Returns:
            Dict: 数据字典
        """
        # 字段映射：英文字段名 -> 中文字段名
        field_mapping = {
            "province_code": "省市",
            "data_year": "数据年份",
            "avg_monthly_salary_basis": "核定缴费基数的全省月平均工资",
            "contribution_base_min": "城镇职工缴费基数下限",
            "contribution_base_max": "城镇职工缴费基数上限",
            "employer_ratio": "城镇职工单位缴费比例",
            "employee_ratio": "城镇职工个人缴费比例",
            "flexible_worker_ratio": "灵活就业人员缴费比例",
            "contribution_base_min_city": "城乡居民最低缴费金额",
            "contribution_base_max_city": "城乡居民最高缴费金额",
            "retirement_age_male": "男性退休年龄",
            "retirement_age_female": "女性退休年龄",
            "retirement_age_female_worker": "女工人退休年龄",
            "min_contribution_years": "最低累计缴费年限",
            "contribution_tiers": "缴费档次",
            "government_subsidies": "政府补贴标准",
            "retirement_age": "待遇领取年龄",
            "base_pension_standard": "基础养老金标准",
            "long_term_incentive": "长缴多得激励政策",
            "more_pay_more_incentive": "多缴多得激励政策",
            "transfer_process": "转移接续流程",
            "transfer_timeframe": "转移办理时限",
            "pension_qualification_rule": "养老金领取地确定规则",
            "fund_transfer_rule": "资金划转规则",
            "remote_certification": "异地资格认证方式",
            "certification_frequency": "资格认证周期",
            "remote_payment_method": "异地发放方式",
            "special_notes": "特别说明"
        }
        
        result = {}
        for english_field, chinese_field in field_mapping.items():
            value = getattr(record, english_field, None)
            # 处理Decimal类型，转换为float
            if value is not None and hasattr(value, '__float__'):
                value = float(value)
            result[chinese_field] = value
        
        return result
    
    def get_all_provinces(self) -> List[str]:
        """
        获取所有省市列表
        
        Returns:
            List[str]: 省市名称列表
        """
        try:
            provinces = self.db.query(SocialPensionInsurance.province_code).distinct().all()
            return [province[0] for province in provinces if province[0]]
        except Exception as e:
            logger.error(f"获取省市列表失败: {e}")
            return []


def get_social_pension_insurance_crud(db: Session) -> SocialPensionInsuranceCRUD:
    """
    获取社会养老保险CRUD操作实例
    
    Args:
        db: 数据库会话
        
    Returns:
        SocialPensionInsuranceCRUD: CRUD操作实例
    """
    return SocialPensionInsuranceCRUD(db)

