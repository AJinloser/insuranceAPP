import uuid
from sqlalchemy import Column, ForeignKey
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship

from app.db.base import Base


class UserInfo(Base):
    """用户个人信息模型"""

    __tablename__ = "user_info"

    user_id = Column(UUID(as_uuid=True), ForeignKey("users.user_id"), primary_key=True, index=True)
    basic_info = Column(JSONB, nullable=True, default={})
    financial_info = Column(JSONB, nullable=True, default={})
    risk_info = Column(JSONB, nullable=True, default={})
    retirement_info = Column(JSONB, nullable=True, default={})
    family_info = Column(JSONB, nullable=True, default={})
    goal_info = Column(JSONB, nullable=True, default={})
    other_info = Column(JSONB, nullable=True, default={})

    # 外键关系
    user = relationship("User", back_populates="user_info") 