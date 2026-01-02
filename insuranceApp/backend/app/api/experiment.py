from typing import Any
import traceback
import os

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db.base import get_db
from app.models.user import User
from app.schemas.user import ExperimentProgress, ExperimentInfo

router = APIRouter()


def parse_group_code(group_code: str) -> dict:
    """解析分组代码,返回各维度的配置
    
    Args:
        group_code: 5位二进制字符串,如 "10110"
        
    Returns:
        包含各实验维度配置的字典
    """
    if not group_code or len(group_code) != 5:
        # 默认配置
        return {
            "show_algorithm_declaration": False,
            "show_interest_declaration": False,
            "show_privacy_declaration": False,
            "show_data_control": False,
            "has_guided_questions": False,
        }
    
    return {
        "show_algorithm_declaration": group_code[0] == '1',
        "show_interest_declaration": group_code[1] == '1',
        "show_privacy_declaration": group_code[2] == '1',
        "show_data_control": group_code[3] == '1',
        "has_guided_questions": group_code[4] == '1',
    }


@router.get("/experiment/info", response_model=ExperimentInfo)
def get_experiment_info(
    user_id: str,
    db: Session = Depends(get_db)
) -> Any:
    """获取用户的实验信息和分组配置"""
    try:
        user = db.query(User).filter(User.user_id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="用户不存在",
            )
        
        # 解析分组代码
        group_config = parse_group_code(user.group_code or "00000")
        
        # 根据分组配置选择chatbot API key
        # 从环境变量中读取
        if group_config["has_guided_questions"]:
            chatbot_api_key = os.getenv("EXPERIMENT_CHATBOT_WITH_GUIDE", "")
        else:
            chatbot_api_key = os.getenv("EXPERIMENT_CHATBOT_WITHOUT_GUIDE", "")
        
        return {
            "experiment_id": user.experiment_id or "",
            "group_code": user.group_code or "00000",
            "show_algorithm_declaration": group_config["show_algorithm_declaration"],
            "show_interest_declaration": group_config["show_interest_declaration"],
            "show_privacy_declaration": group_config["show_privacy_declaration"],
            "show_data_control": group_config["show_data_control"],
            "has_guided_questions": group_config["has_guided_questions"],
            "chatbot_api_key": chatbot_api_key,
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
            detail="获取实验信息失败"
        )


@router.post("/experiment/progress")
def update_experiment_progress(
    progress: ExperimentProgress,
    db: Session = Depends(get_db)
) -> Any:
    """更新用户的实验进度"""
    try:
        user = db.query(User).filter(User.user_id == progress.user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="用户不存在",
            )
        
        # 更新实验进度
        if progress.completed_pre_survey is not None:
            user.completed_pre_survey = progress.completed_pre_survey
        if progress.completed_declaration is not None:
            user.completed_declaration = progress.completed_declaration
        if progress.completed_conversation is not None:
            user.completed_conversation = progress.completed_conversation
        if progress.completed_post_survey is not None:
            user.completed_post_survey = progress.completed_post_survey
        
        db.commit()
        db.refresh(user)
        
        return {
            "code": 200,
            "message": "实验进度更新成功",
            "completed_pre_survey": user.completed_pre_survey,
            "completed_declaration": user.completed_declaration,
            "completed_conversation": user.completed_conversation,
            "completed_post_survey": user.completed_post_survey,
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="更新实验进度失败"
        )

