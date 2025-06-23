from typing import List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy.orm.attributes import flag_modified
from uuid import UUID

from app.api.deps import get_db
from app.models.insurance_list import InsuranceList
from app.schemas.insurance_list import (
    InsuranceListGetResponse,
    InsuranceListAddRequest,
    InsuranceListUpdateRequest,
    BaseResponse
)

router = APIRouter()


@router.get("/get")
def get_insurance_list(
    user_id: UUID,
    db: Session = Depends(get_db)
) -> InsuranceListGetResponse:
    """获取用户保单信息"""
    try:
        # 查询用户保单信息
        insurance_list_obj = db.query(InsuranceList).filter(
            InsuranceList.user_id == user_id
        ).first()
        
        if not insurance_list_obj:
            # 如果用户没有保单记录，创建空的保单记录
            insurance_list_obj = InsuranceList(
                user_id=user_id,
                insurance_list=[]
            )
            db.add(insurance_list_obj)
            db.commit()
            db.refresh(insurance_list_obj)

        print(f"获取保单信息: {insurance_list_obj.insurance_list}")
        
        return InsuranceListGetResponse(
            code=200,
            message="获取用户保单信息成功",
            insurance_list=insurance_list_obj.insurance_list or []
        )
        
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"获取用户保单信息失败: {str(e)}"
        )


@router.post("/add")
def add_insurance_to_list(
    request: InsuranceListAddRequest,
    db: Session = Depends(get_db)
) -> BaseResponse:
    """添加保险产品到用户保单"""
    try:
        print(f"尝试添加保险产品: product_id={request.product_id}, product_type={request.product_type}")
        
        # 查询用户保单信息
        insurance_list_obj = db.query(InsuranceList).filter(
            InsuranceList.user_id == request.user_id
        ).first()
        
        if not insurance_list_obj:
            # 如果用户没有保单记录，创建新的
            insurance_list_obj = InsuranceList(
                user_id=request.user_id,
                insurance_list=[]
            )
            db.add(insurance_list_obj)
        
        # 准备要添加的保险产品信息
        new_insurance_item = {
            "product_id": request.product_id,
            "product_type": request.product_type
        }
        
        # 检查是否已经存在相同的保险产品
        current_list = insurance_list_obj.insurance_list or []
        print(f"当前保单列表: {current_list}")
        
        for item in current_list:
            if (item.get("product_id") == request.product_id and 
                item.get("product_type") == request.product_type):
                return BaseResponse(
                    code=400,
                    message="该保险产品已存在于保单中"
                )
        
        # 创建新的列表对象（重要：不要直接修改现有列表）
        new_list = list(current_list)  # 创建副本
        new_list.append(new_insurance_item)
        
        # 设置新的列表
        insurance_list_obj.insurance_list = new_list
        
        # 明确告诉SQLAlchemy字段已被修改
        flag_modified(insurance_list_obj, 'insurance_list')
        
        db.commit()
        db.refresh(insurance_list_obj)
        
        print(f"添加后的保单列表: {insurance_list_obj.insurance_list}")
        return BaseResponse(
            code=200,
            message="成功添加保险产品到保单"
        )
        
    except Exception as e:
        db.rollback()
        print(f"添加保险产品失败: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"添加保险产品到保单失败: {str(e)}"
        )


@router.post("/update")
def update_insurance_list(
    request: InsuranceListUpdateRequest,
    db: Session = Depends(get_db)
) -> BaseResponse:
    """更新用户保单信息"""
    try:
        print(f"尝试更新保单列表: {request.insurance_list}")
        
        # 查询用户保单信息
        insurance_list_obj = db.query(InsuranceList).filter(
            InsuranceList.user_id == request.user_id
        ).first()
        
        if not insurance_list_obj:
            # 如果用户没有保单记录，创建新的
            insurance_list_obj = InsuranceList(
                user_id=request.user_id,
                insurance_list=request.insurance_list
            )
            db.add(insurance_list_obj)
        else:
            # 更新现有的保单信息
            insurance_list_obj.insurance_list = request.insurance_list
            # 明确告诉SQLAlchemy字段已被修改
            flag_modified(insurance_list_obj, 'insurance_list')
        
        db.commit()
        db.refresh(insurance_list_obj)
        
        print(f"更新后的保单列表: {insurance_list_obj.insurance_list}")
        return BaseResponse(
            code=200,
            message="更新用户保单信息成功"
        )
        
    except Exception as e:
        db.rollback()
        print(f"更新保单信息失败: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"更新用户保单信息失败: {str(e)}"
        ) 