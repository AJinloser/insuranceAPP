"""
基本医保数据模型
"""
from sqlalchemy import Column, Integer, String, Text, Numeric, Boolean
from sqlalchemy.dialects.postgresql import UUID
import uuid

from app.db.base import Base


class BasicMedicalInsurance(Base):
    """基本医保数据表"""
    __tablename__ = "basic_medical_insurance"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    
    # 基础信息
    city = Column(String(100), nullable=False, index=True, comment="城市")
    data_year = Column(String(20), comment="数据年份")
    coordination_level = Column(String(50), comment="统筹层次")
    official_website = Column(Text, comment="官网链接")
    policy_document_number = Column(String(200), comment="政策文件号")
    
    # 职工缴费标准
    employee_contribution_base_lower = Column(String(200), comment="职工_缴费基数下限")
    employee_contribution_base_upper = Column(String(200), comment="职工_缴费基数上限")
    employee_unit_contribution_rate = Column(String(100), comment="职工_单位缴费比例")
    employee_personal_contribution_rate = Column(String(100), comment="职工_个人缴费比例")
    
    # 居民缴费标准
    resident_personal_contribution_standard = Column(String(200), comment="居民_个人缴费标准")
    resident_financial_subsidy_standard = Column(String(200), comment="居民_财政补助标准")
    
    # 个人账户
    active_employee_account_transfer_rate = Column(String(200), comment="在职_职工划入比例")
    retired_employee_account_fixed_amount = Column(String(200), comment="退休_职工划入定额")
    personal_account_family_sharing = Column(String(100), comment="个人账户家庭共济")
    
    # 职工门诊
    employee_outpatient_deductible = Column(String(200), comment="职工_门诊起付线")
    employee_outpatient_ceiling = Column(String(200), comment="职工_门诊封顶线")
    active_outpatient_payment_ratio = Column(String(200), comment="在职_门诊支付比例")
    retired_outpatient_payment_ratio = Column(String(200), comment="退休_门诊支付比例")
    outpatient_special_disease_count = Column(String(100), comment="门诊特殊病种数量")
    
    # 居民门诊
    resident_outpatient_deductible = Column(String(200), comment="居民_门诊起付线")
    resident_outpatient_payment_ratio = Column(String(200), comment="居民_门诊支付比例")
    resident_inpatient_payment_ratio = Column(String(200), comment="居民_住院支付比例")
    
    # 职工住院
    employee_inpatient_deductible_first = Column(String(200), comment="职工_住院起付线_首次")
    employee_inpatient_deductible_subsequent = Column(String(200), comment="职工_住院起付线_后续")
    employee_inpatient_ceiling = Column(String(200), comment="职工_住院封顶线")
    
    # 在职分段支付
    active_segment1_amount_range = Column(String(200), comment="在职_分段1_额度范围")
    active_segment1_level1_hospital_ratio = Column(String(100), comment="在职_分段1_一级医院_支付比例")
    active_segment1_level2_hospital_ratio = Column(String(100), comment="在职_分段1_二级医院_支付比例")
    active_segment1_level3_hospital_ratio = Column(String(100), comment="在职_分段1_三级医院_支付比例")
    
    active_segment2_amount_range = Column(String(200), comment="在职_分段2_额度范围")
    active_segment2_level1_hospital_ratio = Column(String(100), comment="在职_分段2_一级医院_支付比例")
    active_segment2_level2_hospital_ratio = Column(String(100), comment="在职_分段2_二级医院_支付比例")
    active_segment2_level3_hospital_ratio = Column(String(100), comment="在职_分段2_三级医院_支付比例")
    
    active_segment3_amount_range = Column(String(200), comment="在职_分段3_额度范围")
    active_segment3_level1_hospital_ratio = Column(String(100), comment="在职_分段3_一级医院_支付比例")
    active_segment3_level2_hospital_ratio = Column(String(100), comment="在职_分段3_二级医院_支付比例")
    active_segment3_level3_hospital_ratio = Column(String(100), comment="在职_分段3_三级医院_支付比例")
    
    active_segment4_amount_range = Column(String(200), comment="在职_分段4_额度范围")
    active_segment4_payment_ratio = Column(String(100), comment="在职_分段4_支付比例")
    
    # 退休分段支付
    retired_segment1_amount_range = Column(String(200), comment="退休_分段1_额度范围")
    retired_segment1_level1_hospital_ratio = Column(String(100), comment="退休_分段1_一级医院_支付比例")
    retired_segment1_level2_hospital_ratio = Column(String(100), comment="退休_分段1_二级医院_支付比例")
    retired_segment1_level3_hospital_ratio = Column(String(100), comment="退休_分段1_三级医院_支付比例")
    
    retired_segment2_amount_range = Column(String(200), comment="退休_分段2_额度范围")
    retired_segment2_level1_hospital_ratio = Column(String(100), comment="退休_分段2_一级医院_支付比例")
    retired_segment2_level2_hospital_ratio = Column(String(100), comment="退休_分段2_二级医院_支付比例")
    retired_segment2_level3_hospital_ratio = Column(String(100), comment="退休_分段2_三级医院_支付比例")
    
    retired_segment3_amount_range = Column(String(200), comment="退休_分段3_额度范围")
    retired_segment3_level1_hospital_ratio = Column(String(100), comment="退休_分段3_一级医院_支付比例")
    retired_segment3_level2_hospital_ratio = Column(String(100), comment="退休_分段3_二级医院_支付比例")
    retired_segment3_level3_hospital_ratio = Column(String(100), comment="退休_分段3_三级医院_支付比例")
    
    retired_segment4_amount_range = Column(String(200), comment="退休_分段4_额度范围")
    retired_segment4_payment_ratio = Column(String(100), comment="退休_分段4_支付比例")
    
    # 居民住院
    resident_inpatient_deductible = Column(String(200), comment="居民_住院起付线")
    resident_inpatient_ceiling = Column(String(200), comment="居民_住院封顶线")
    
    # 大病保险
    employee_serious_illness_deductible = Column(String(200), comment="职工_大病保险起付线")
    resident_serious_illness_deductible = Column(String(200), comment="居民_大病保险起付线")
    employee_serious_illness_payment_ratio = Column(String(200), comment="职工_大病保险支付比例")
    resident_serious_illness_payment_ratio = Column(String(200), comment="居民_大病保险支付比例")
    serious_illness_ceiling = Column(String(200), comment="大病封顶线")
    
    serious_illness_segment1_amount_range = Column(String(200), comment="大病医疗_分段1_额度范围")
    serious_illness_segment1_payment_ratio = Column(String(100), comment="大病医疗_分段1_支付比例")
    serious_illness_segment2_amount_range = Column(String(200), comment="大病医疗_分段2_额度范围")
    serious_illness_segment2_payment_ratio = Column(String(100), comment="大病医疗_分段2_支付比例")
    
    # 其他政策
    remote_medical_filing_channel = Column(Text, comment="异地就医备案渠道")
    remote_medical_reimbursement_rules = Column(Text, comment="异地就医报销规则")
    long_term_care_insurance = Column(String(200), comment="长期护理保险")
    medical_insurance_drug_catalog_execution = Column(String(200), comment="医保药品目录执行")
    referral_maintain_reimbursement_ratio = Column(String(200), comment="转诊保持报销比例")
    negotiated_drug_reimbursement_policy = Column(Text, comment="谈判药报销政策")

    def __repr__(self):
        return f"<BasicMedicalInsurance(city='{self.city}', data_year='{self.data_year}')>"
