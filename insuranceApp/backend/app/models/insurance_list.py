import uuid
from sqlalchemy import Column, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship

from app.db.base import Base


class InsuranceList(Base):
    """用户保单信息模型"""

    __tablename__ = "insurance_list"

    user_id = Column(UUID(as_uuid=True), ForeignKey("users.user_id"), primary_key=True, index=True)
    insurance_list = Column(JSONB, nullable=True, default=[])

    # 外键关系
    user = relationship("User", back_populates="insurance_list") 