import uuid
from sqlalchemy import Column, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship

from app.db.base import Base


class User(Base):
    """用户模型"""

    __tablename__ = "users"

    user_id = Column(UUID(as_uuid=True), primary_key=True, index=True, default=uuid.uuid4)
    account = Column(String, unique=True, index=True, nullable=False)
    password = Column(String, nullable=False)
    
    # 反向关系
    user_info = relationship("UserInfo", back_populates="user", uselist=False) 