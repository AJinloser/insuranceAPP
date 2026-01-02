import uuid
from sqlalchemy import Column, String, Integer, Boolean
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db.base import Base


class User(Base):
    """用户模型"""

    __tablename__ = "users"

    user_id = Column(UUID(as_uuid=True), primary_key=True, index=True, default=uuid.uuid4)
    account = Column(String, unique=True, index=True, nullable=False)
    password = Column(String, nullable=False)
    
    # 实验相关字段
    experiment_id = Column(String, unique=True, index=True, nullable=True)  # 实验ID，格式如 "EXP001"
    group_code = Column(String, nullable=True)  # 分组代码，格式如 "10110" (5位二进制)
    
    # 实验流程控制字段
    completed_pre_survey = Column(Boolean, default=False)  # 是否完成测前问卷
    completed_declaration = Column(Boolean, default=False)  # 是否完成声明环节
    completed_conversation = Column(Boolean, default=False)  # 是否完成对话环节
    completed_post_survey = Column(Boolean, default=False)  # 是否完成测后问卷
    
    # 反向关系
    user_info = relationship("UserInfo", back_populates="user", uselist=False)
    insurance_list = relationship("InsuranceList", back_populates="user", uselist=False)
    goals = relationship("Goal", back_populates="user", uselist=False) 