from typing import Any

import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.core.security import create_access_token, get_password_hash, verify_password
from app.db.base import get_db
from app.models.user import User
from app.schemas.user import Token, UserCreate, UserLogin, UserResetPassword

router = APIRouter()


@router.post("/login", response_model=Token)
def login(
    db: Session = Depends(get_db), form_data: OAuth2PasswordRequestForm = Depends()
) -> Any:
    """用户登录"""
    user = db.query(User).filter(User.account == form_data.username).first()
    if not user or not verify_password(form_data.password, user.password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="账号或密码错误",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token = create_access_token(
        subject=user.account
    )
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": user.user_id
    }


@router.post("/register", response_model=Token)
def register(*, db: Session = Depends(get_db), user_in: UserCreate) -> Any:
    """用户注册"""
    # 检查用户是否已存在
    user = db.query(User).filter(User.account == user_in.account).first()
    if user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="该账号已被注册",
        )
    # 创建新用户
    hashed_password = get_password_hash(user_in.password)
    db_user = User(
        account=user_in.account,
        password=hashed_password,
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    
    # 创建访问令牌
    access_token = create_access_token(
        subject=db_user.account
    )
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user_id": db_user.user_id
    }


@router.post("/reset_password", response_model=Token)
def reset_password(
    *, db: Session = Depends(get_db), reset_data: UserResetPassword
) -> Any:
    """重置密码"""
    user = db.query(User).filter(User.account == reset_data.account).first()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="用户不存在",
        )
    
    # 更新密码
    hashed_password = get_password_hash(reset_data.new_password)
    user.password = hashed_password
    db.commit()
    db.refresh(user)
    
    # 创建新的访问令牌
    access_token = create_access_token(
        subject=user.account
    )
    return {
        "access_token": access_token,
        "token_type": "bearer", 
        "user_id": user.user_id
    } 