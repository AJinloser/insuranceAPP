"""
社会养老保险数据模型
"""
from sqlalchemy import Column, Integer, String, Text, Numeric
from sqlalchemy.dialects.postgresql import UUID, JSON
import uuid

from app.db.base import Base


class SocialPensionInsurance(Base):
    """社会养老保险数据表"""
    __tablename__ = "social_pension_insurance"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4, index=True)
    
    # 基础信息
    province_code = Column(String(10), nullable=False, index=True, comment="省市代码")
    data_year = Column(Integer, comment="数据年份")
    
    # 城镇职工养老保险
    avg_monthly_salary_basis = Column(Numeric(10, 2), comment="核定缴费基数的全省月平均工资")
    contribution_base_min = Column(Numeric(10, 2), comment="城镇职工缴费基数下限")
    contribution_base_max = Column(Numeric(10, 2), comment="城镇职工缴费基数上限")
    employer_ratio = Column(Numeric(4, 2), comment="城镇职工单位缴费比例")
    employee_ratio = Column(Numeric(4, 2), comment="城镇职工个人缴费比例")
    flexible_worker_ratio = Column(Numeric(4, 2), comment="灵活就业人员缴费比例")
    
    # 城乡居民养老保险缴费标准
    contribution_base_min_city = Column(Numeric(10, 2), comment="城乡居民最低缴费金额")
    contribution_base_max_city = Column(Numeric(10, 2), comment="城乡居民最高缴费金额")
    
    # 退休年龄
    retirement_age_male = Column(Integer, comment="男性退休年龄")
    retirement_age_female = Column(Integer, comment="女性退休年龄")
    retirement_age_female_worker = Column(Integer, comment="女工人退休年龄（如不同）")
    min_contribution_years = Column(Integer, comment="最低累计缴费年限")
    
    # 城乡居民养老保险待遇
    contribution_tiers = Column(JSON, comment="缴费档次")
    government_subsidies = Column(JSON, comment="与缴费档次对应的政府补贴标准")
    retirement_age = Column(Integer, comment="待遇领取年龄")
    base_pension_standard = Column(Numeric(10, 2), comment="省级城乡居民基础养老金最低标准（元/月）")
    long_term_incentive = Column(Text, comment="长缴多得激励政策描述")
    more_pay_more_incentive = Column(Text, comment="多缴多得激励政策描述")
    
    # 转移接续
    transfer_process = Column(Text, comment="跨省关系转移接续流程")
    transfer_timeframe = Column(String(255), comment="转移办理时限（官方承诺）")
    pension_qualification_rule = Column(Text, comment="养老金领取地确定规则")
    fund_transfer_rule = Column(Text, comment="转移时资金划转规则")
    
    # 异地待遇领取
    remote_certification = Column(Text, comment="异地待遇领取资格认证方式")
    certification_frequency = Column(String(50), comment="资格认证周期")
    remote_payment_method = Column(String(255), comment="养老金异地发放方式")
    
    # 其他
    special_notes = Column(Text, comment="特别说明/地方性规定")

    def __repr__(self):
        return f"<SocialPensionInsurance(province='{self.province_code}', year='{self.data_year}')>"

