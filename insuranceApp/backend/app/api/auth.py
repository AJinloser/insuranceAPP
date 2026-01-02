from typing import Any
import traceback
import random

import uuid
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.core.security import create_access_token, get_password_hash, verify_password
from app.db.base import get_db
from app.models.user import User
from app.schemas.user import Token, UserCreate, UserLogin, UserResetPassword

router = APIRouter()


def generate_experiment_id(db: Session) -> str:
    """生成唯一的实验ID"""
    while True:
        # 获取当前最大的实验ID数字
        max_user = db.query(User).filter(User.experiment_id.isnot(None)).order_by(User.experiment_id.desc()).first()
        if max_user and max_user.experiment_id:
            try:
                # 提取数字部分
                num = int(max_user.experiment_id.replace("EXP", ""))
                new_num = num + 1
            except:
                new_num = 1
        else:
            new_num = 1
        
        exp_id = f"EXP{new_num:03d}"
        
        # 检查是否已存在
        existing = db.query(User).filter(User.experiment_id == exp_id).first()
        if not existing:
            return exp_id


def generate_group_code() -> str:
    """随机生成5位二进制分组代码
    每一位代表一个实验维度：
    - 第1位: 算法透明度 (0=不展示, 1=展示算法声明)
    - 第2位: 利益立场声明 (0=不展示, 1=展示利益立场声明)
    - 第3位: 隐私透明度 (0=不展示, 1=展示隐私声明)
    - 第4位: 数据控制权 (0=不展示, 1=展示数据控制选项)
    - 第5位: 步进问题引导 (0=无引导chatbot, 1=有引导chatbot)
    """
    return ''.join([str(random.randint(0, 1)) for _ in range(5)])


@router.post("/login", response_model=Token)
def login(
    db: Session = Depends(get_db), form_data: OAuth2PasswordRequestForm = Depends()
) -> Any:
    """用户登录"""
    try:
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
            "user_id": user.user_id,
            "experiment_id": user.experiment_id,
            "group_code": user.group_code,
            "completed_pre_survey": user.completed_pre_survey or False,
            "completed_declaration": user.completed_declaration or False,
            "completed_conversation": user.completed_conversation or False,
            "completed_post_survey": user.completed_post_survey or False,
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="登录服务暂时不可用"
        )


@router.post("/register", response_model=Token)
def register(*, db: Session = Depends(get_db), user_in: UserCreate) -> Any:
    """用户注册"""
    try:
        # 检查用户是否已存在
        user = db.query(User).filter(User.account == user_in.account).first()
        if user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="该账号已被注册",
            )
        # 创建新用户
        hashed_password = get_password_hash(user_in.password)
        
        # 生成实验ID和分组代码
        experiment_id = generate_experiment_id(db)
        group_code = generate_group_code()
        
        db_user = User(
            account=user_in.account,
            password=hashed_password,
            experiment_id=experiment_id,
            group_code=group_code,
            completed_pre_survey=False,
            completed_declaration=False,
            completed_conversation=False,
            completed_post_survey=False,
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
            "user_id": db_user.user_id,
            "experiment_id": db_user.experiment_id,
            "group_code": db_user.group_code,
            "completed_pre_survey": False,
            "completed_declaration": False,
            "completed_conversation": False,
            "completed_post_survey": False,
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="注册服务暂时不可用"
        )


@router.post("/reset_password", response_model=Token)
def reset_password(
    *, db: Session = Depends(get_db), reset_data: UserResetPassword
) -> Any:
    """重置密码"""
    try:
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
            "user_id": user.user_id,
            "experiment_id": user.experiment_id,
            "group_code": user.group_code,
            "completed_pre_survey": user.completed_pre_survey or False,
            "completed_declaration": user.completed_declaration or False,
            "completed_conversation": user.completed_conversation or False,
            "completed_post_survey": user.completed_post_survey or False,
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="重置密码服务暂时不可用"
        ) 