from typing import Any
import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.base import get_db
from app.models.user import User
from app.models.user_info import UserInfo
from app.schemas.user_info import (
    UserInfoApiResponse,
    UserInfoResponse,
    UserInfoCreate,
    UserInfoUpdate,
    UserInfoGetRequest,
    ApiResponse,
)

router = APIRouter()


@router.post("/user_info/get", response_model=UserInfoApiResponse)
def get_user_info(
    *,
    db: Session = Depends(get_db),
    request: UserInfoGetRequest,
) -> Any:
    """获取用户个人信息"""
    try:
        user_id = request.user_id
        print(f"获取用户信息请求，user_id: {user_id}, 类型: {type(user_id)}")
        
        # # 调试：列出数据库中所有用户
        # all_users = db.query(User).all()
        # print(f"数据库中的所有用户:")
        # for user in all_users:
        #     print(f"  - user_id: {user.user_id}, account: {user.account}")
        
        # 验证用户是否存在
        user = db.query(User).filter(User.user_id == user_id).first()
        print(f"查询用户结果: {user}")
        
        if not user:
            print(f"用户不存在: {user_id}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="用户不存在"
            )
        
        print(f"找到用户: {user.user_id}, 账号: {user.account}")
        
        # 查询用户个人信息
        user_info = db.query(UserInfo).filter(UserInfo.user_id == user_id).first()
        print(f"查询用户信息结果: {user_info}")
        
        if not user_info:
            print("用户信息不存在，创建默认信息")
            # 如果用户没有个人信息，创建默认的空信息
            user_info = UserInfo(user_id=user_id)
            db.add(user_info)
            db.commit()
            db.refresh(user_info)
            print(f"创建的用户信息: {user_info}")
        
        # 转换为响应格式
        user_info_response = UserInfoResponse(
            user_id=user_info.user_id,
            basic_info=user_info.basic_info or {},
            financial_info=user_info.financial_info or {},
            risk_info=user_info.risk_info or {},
            retirement_info=user_info.retirement_info or {},
            insurance_info=user_info.insurance_info or {},
            family_info=user_info.family_info or {},
            goal_info=user_info.goal_info or {},
            other_info=user_info.other_info or {},
        )
        
        print("成功获取用户信息")
        return UserInfoApiResponse(
            code=200,
            message="获取用户个人信息成功",
            user_info=user_info_response
        )
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"获取用户信息失败: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"获取用户个人信息失败: {str(e)}"
        )


@router.post("/user_info", response_model=ApiResponse)
def update_user_info(
    *,
    db: Session = Depends(get_db),
    user_info_update: UserInfoUpdate,
) -> Any:
    """更新用户个人信息"""
    try:
        user_id = user_info_update.user_id
        print(f"更新用户信息请求，user_id: {user_id}, 类型: {type(user_id)}")
        
        # 验证用户是否存在
        user = db.query(User).filter(User.user_id == user_id).first()
        print(f"查询用户结果: {user}")
        
        if not user:
            print(f"用户不存在: {user_id}")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="用户不存在"
            )
        
        print(f"找到用户: {user.user_id}, 账号: {user.account}")
        
        # 查询现有的用户个人信息
        user_info = db.query(UserInfo).filter(UserInfo.user_id == user_id).first()
        
        if not user_info:
            print("用户信息不存在，创建新的用户信息")
            # 如果不存在，创建新的用户个人信息
            user_info = UserInfo(user_id=user_id)
            db.add(user_info)
        else:
            print("找到现有用户信息，准备更新")
        
        # 更新字段，排除user_id字段
        update_data = user_info_update.dict(exclude={'user_id'}, exclude_unset=True)
        print(f"更新数据: {update_data}")
        
        for field, value in update_data.items():
            if hasattr(user_info, field):
                if isinstance(value, dict):
                    setattr(user_info, field, value)
                elif value is not None:
                    setattr(user_info, field, value)
        
        db.commit()
        db.refresh(user_info)
        
        print("用户信息更新成功")
        return ApiResponse(
            code=200,
            message="更新用户个人信息成功"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"更新用户信息失败: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"更新用户个人信息失败: {str(e)}"
        ) 