from typing import Any, Dict, List, Optional, Union
from pydantic import BaseModel, Field

# 响应模型
class ResponseBase(BaseModel):
    """基础响应模型"""
    code: int = 200
    message: str = "操作成功"

# 保险产品类型响应
class ProductTypesResponse(ResponseBase):
    """保险产品类型响应"""
    product_types: List[str] = []

# 保险产品字段响应
class ProductFieldsResponse(ResponseBase):
    """保险产品字段响应"""
    fields: List[str] = []

# 保险产品信息
class ProductInfo(BaseModel):
    """保险产品基本信息"""
    product_id: int
    product_name: str
    company_name: str
    insurance_type: str
    premium: Any
    total_score: Optional[float] = None
    
    class Config:
        from_attributes = True

# 保险产品搜索响应
class ProductSearchResponse(ResponseBase):
    """保险产品搜索响应"""
    pages: int = 1
    products: List[ProductInfo] = []

# 保险产品详情响应
class ProductDetailResponse(ResponseBase):
    """保险产品详情响应"""
    product_id: Optional[Any] = None
    product_name: Optional[Any] = None
    company_name: Optional[Any] = None
    insurance_type: Optional[Any] = None
    product_type: Optional[Any] = None
    coverage_content: Optional[Any] = None
    exclusion_clause: Optional[Any] = None
    renewable: Optional[Any] = None
    underwriting_rules: Optional[Any] = None
    entry_age: Optional[Any] = None
    deductible: Optional[Any] = None
    premium: Optional[Any] = None
    coverage_amount: Optional[Any] = None
    coverage_period: Optional[Any] = None
    total_score: Optional[float] = None
    # 以下字段可能在某些产品中不存在
    payment_period: Optional[Any] = None
    waiting_period: Optional[Any] = None
    payment_method: Optional[Any] = None
    occupation: Optional[Any] = None
    hospital_scope: Optional[Any] = None
    reimbursement_scope: Optional[Any] = None
    reimbursement_ratio: Optional[Any] = None
    coverage_region: Optional[Any] = None
    second_insured: Optional[Any] = None
    intergenerational_insurance: Optional[Any] = None
    trust: Optional[Any] = None
    trust_threshold: Optional[Any] = None
    retirement_community: Optional[Any] = None
    reduction_supported: Optional[Any] = None
    reduced_paid_up: Optional[Any] = None
    policy_loan_rate: Optional[Any] = None
    value_added_services: Optional[Any] = None
    sales_regions: Optional[Any] = None
    accidental_death: Optional[Any] = None
    accidental_disability: Optional[Any] = None
    accidental_medical: Optional[Any] = None
    payout_method: Optional[Any] = None
    universal_account: Optional[Any] = None
    irr_15y: Optional[Any] = None
    irr_20y: Optional[Any] = None
    irr_30y: Optional[Any] = None
    irr_40y: Optional[Any] = None
    beneficiaries: Optional[Any] = None
    bonus_distribution: Optional[Any] = None
    clause_link: Optional[Any] = None
    optional_liabilities: Optional[Any] = None
    insurance_option: Optional[Any] = None
    addtl_owner_waiver: Optional[Any] = None
    payment_term_options: Optional[Any] = None
    insurance_rules: Optional[Any] = None
    owner_waiver: Optional[Any] = None
    additional_riders: Optional[Any] = None
    highlights: Optional[Any] = None
    commission: Optional[Any] = None
    commission_year1: Optional[Any] = None
    commission_year2: Optional[Any] = None
    commission_year3: Optional[Any] = None
    commission_year4: Optional[Any] = None
    commission_year5: Optional[Any] = None
    expensive_hospital: Optional[Any] = None
    inpatient_day_treatment: Optional[Any] = None
    special_outpatient_surgery: Optional[Any] = None
    outpatient_benefit: Optional[Any] = None
    emergency_medical: Optional[Any] = None
    check_dental_maternity: Optional[Any] = None
    health_management: Optional[Any] = None
    preexisting_congenital: Optional[Any] = None
    gender: Optional[Any] = None
    age: Optional[Any] = None
    other_info: Optional[Any] = None
    outpatient_liability: Optional[Any] = None
    premium_discount: Optional[Any] = None
    remarks: Optional[Any] = None
    medical_network: Optional[Any] = None
    benefit_details: Optional[Any] = None
    service_manual: Optional[Any] = None
    clause_original: Optional[Any] = None
    company_intro: Optional[Any] = None
    plan_choice: Optional[Any] = None
    drug_list: Optional[Any] = None
    discount: Optional[Any] = None
    # 其他可能的字段将根据实际情况动态添加
    
    class Config:
        from_attributes = True
        
    def __init__(self, **data):
        super().__init__(**data)
        # 动态添加其他字段
        for key, value in data.items():
            if not hasattr(self, key):
                setattr(self, key, value) 