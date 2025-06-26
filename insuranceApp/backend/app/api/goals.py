from typing import Any, List
import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy.orm.attributes import flag_modified

from app.db.base import get_db
from app.models.user import User
from app.models.goal import Goal
from app.schemas.goal import (
    GetGoalBasicInfoRequest,
    GetGoalBasicInfoResponse,
    UpdateGoalBasicInfoRequest,
    GetGoalDetailInfoRequest,
    GetGoalDetailInfoResponse,
    UpdateSubGoalRequest,
    UpdateSubTaskRequest,
    GoalBasicInfo,
    GoalDetailInfo,
    SubGoal,
    SubTask,
    ApiResponse,
)

router = APIRouter()


def calculate_task_stats(goal_data: dict) -> tuple[int, int]:
    """计算任务统计信息"""
    sub_tasks = goal_data.get('sub_tasks', [])
    total_tasks = len(sub_tasks)
    completed_tasks = sum(1 for task in sub_tasks if task.get('sub_task_status', False))
    return total_tasks, completed_tasks


def update_goal_completed_amount(goal_data: dict) -> float:
    """根据完成的子任务更新目标完成金额"""
    sub_tasks = goal_data.get('sub_tasks', [])
    completed_amount = 0.0
    
    for task in sub_tasks:
        if task.get('sub_task_status', False) and task.get('sub_task_amount'):
            completed_amount += float(task.get('sub_task_amount', 0))
    
    goal_data['completed_amount'] = completed_amount
    return completed_amount


@router.post("/goals/get_basic_info", response_model=GetGoalBasicInfoResponse)
def get_goal_basic_info(
    *,
    db: Session = Depends(get_db),
    request: GetGoalBasicInfoRequest,
) -> Any:
    """获取目标基本信息"""
    try:
        user_id = request.user_id
        print(f"获取目标基本信息请求，user_id: {user_id}")
        
        # 验证用户是否存在
        user = db.query(User).filter(User.user_id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="用户不存在"
            )
        
        # 查询用户目标信息
        goal_record = db.query(Goal).filter(Goal.user_id == user_id).first()
        
        if not goal_record or not goal_record.goals:
            # 如果没有目标记录，返回空列表
            return GetGoalBasicInfoResponse(
                code=200,
                message="获取目标基本信息成功",
                goals=[]
            )
        
        # 处理目标数据
        goals_data = []
        for goal_data in goal_record.goals:
            # 计算任务统计
            total_tasks, completed_tasks = calculate_task_stats(goal_data)
            
            # 获取子目标信息
            sub_goals = []
            for sub_goal_data in goal_data.get('sub_goals', []):
                sub_goals.append(SubGoal(**sub_goal_data))
            
            # 创建目标基本信息
            goal_basic_info = GoalBasicInfo(
                goal_id=goal_data.get('goal_id', ''),
                goal_name=goal_data.get('goal_name', ''),
                goal_description=goal_data.get('goal_description'),
                priority=goal_data.get('priority'),
                expected_completion_time=goal_data.get('expected_completion_time'),
                target_amount=goal_data.get('target_amount'),
                completed_amount=goal_data.get('completed_amount', 0.0),
                sub_goals=sub_goals,
                sub_task_num=total_tasks,
                sub_task_completed_num=completed_tasks
            )
            goals_data.append(goal_basic_info)
        
        return GetGoalBasicInfoResponse(
            code=200,
            message="获取目标基本信息成功",
            goals=goals_data
        )
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"获取目标基本信息失败: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"获取目标基本信息失败: {str(e)}"
        )


@router.post("/goals/update_basic_info", response_model=ApiResponse)
def update_goal_basic_info(
    *,
    db: Session = Depends(get_db),
    request: UpdateGoalBasicInfoRequest,
) -> Any:
    """更新目标基本信息"""
    try:
        user_id = request.user_id
        print(f"更新目标基本信息请求，user_id: {user_id}")
        
        # 验证用户是否存在
        user = db.query(User).filter(User.user_id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="用户不存在"
            )
        
        # 查询现有的目标记录
        goal_record = db.query(Goal).filter(Goal.user_id == user_id).first()
        
        if not goal_record:
            # 如果不存在，创建新的目标记录
            goal_record = Goal(user_id=user_id, goals=[])
            db.add(goal_record)
        
        # 转换目标数据
        goals_data = []
        for goal in request.goals:
            goal_dict = goal.dict()
            # 为新目标生成ID
            if not goal_dict.get('goal_id'):
                goal_dict['goal_id'] = str(uuid.uuid4())
            # 初始化子目标和子任务为空列表（如果不存在）
            if 'sub_goals' not in goal_dict:
                goal_dict['sub_goals'] = []
            if 'sub_tasks' not in goal_dict:
                goal_dict['sub_tasks'] = []
            goals_data.append(goal_dict)
        
        # 更新目标信息
        goal_record.goals = goals_data
        
        # 显式告诉SQLAlchemy该JSONB字段已被修改
        flag_modified(goal_record, 'goals')
        db.commit()
        db.refresh(goal_record)
        
        return ApiResponse(
            code=200,
            message="更新目标基本信息成功"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"更新目标基本信息失败: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"更新目标基本信息失败: {str(e)}"
        )


@router.post("/goals/get_detail_info", response_model=GetGoalDetailInfoResponse)
def get_goal_detail_info(
    *,
    db: Session = Depends(get_db),
    request: GetGoalDetailInfoRequest,
) -> Any:
    """获取目标详细信息"""
    try:
        user_id = request.user_id
        goal_id = request.goal_id
        print(f"获取目标详细信息请求，user_id: {user_id}, goal_id: {goal_id}")
        
        # 验证用户是否存在
        user = db.query(User).filter(User.user_id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="用户不存在"
            )
        
        # 查询目标记录
        goal_record = db.query(Goal).filter(Goal.user_id == user_id).first()
        
        if not goal_record or not goal_record.goals:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="目标不存在"
            )
        
        # 查找指定的目标
        goal_data = None
        for goal in goal_record.goals:
            if goal.get('goal_id') == goal_id:
                goal_data = goal
                break
        
        if not goal_data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="指定的目标不存在"
            )
        
        # 构造子目标列表
        sub_goals = []
        for sub_goal_data in goal_data.get('sub_goals', []):
            sub_goals.append(SubGoal(**sub_goal_data))
        
        # 构造子任务列表
        sub_tasks = []
        for sub_task_data in goal_data.get('sub_tasks', []):
            sub_tasks.append(SubTask(**sub_task_data))
        
        # 创建目标详细信息
        goal_detail = GoalDetailInfo(
            goal_id=goal_data.get('goal_id', ''),
            goal_name=goal_data.get('goal_name', ''),
            goal_description=goal_data.get('goal_description'),
            priority=goal_data.get('priority'),
            expected_completion_time=goal_data.get('expected_completion_time'),
            target_amount=goal_data.get('target_amount'),
            completed_amount=goal_data.get('completed_amount', 0.0),
            sub_goals=sub_goals,
            sub_tasks=sub_tasks
        )
        
        return GetGoalDetailInfoResponse(
            code=200,
            message="获取目标详细信息成功",
            goal_detail=goal_detail
        )
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"获取目标详细信息失败: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"获取目标详细信息失败: {str(e)}"
        )


@router.post("/goals/update_sub_goal", response_model=ApiResponse)
def update_sub_goal(
    *,
    db: Session = Depends(get_db),
    request: UpdateSubGoalRequest,
) -> Any:
    """更新子目标"""
    try:
        user_id = request.user_id
        goal_id = request.goal_id
        print(f"更新子目标请求，user_id: {user_id}, goal_id: {goal_id}")
        print(f"接收到的子目标数据: {[sg.dict() for sg in request.sub_goals]}")
        
        # 验证用户是否存在
        user = db.query(User).filter(User.user_id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="用户不存在"
            )
        
        # 查询目标记录
        goal_record = db.query(Goal).filter(Goal.user_id == user_id).first()
        
        if not goal_record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="目标记录不存在"
            )
        
        print(f"更新前的目标数据: {goal_record.goals}")
        
        # 查找并更新指定的目标
        goals_data = goal_record.goals or []
        goal_found = False
        
        for i, goal_data in enumerate(goals_data):
            if goal_data.get('goal_id') == goal_id:
                # 更新子目标
                sub_goals_data = []
                for sub_goal in request.sub_goals:
                    sub_goal_dict = sub_goal.dict()
                    # 为新子目标生成ID
                    if not sub_goal_dict.get('sub_goal_id'):
                        sub_goal_dict['sub_goal_id'] = str(uuid.uuid4())
                    sub_goals_data.append(sub_goal_dict)
                
                goals_data[i]['sub_goals'] = sub_goals_data
                goal_found = True
                print(f"更新目标 {goal_id} 的子目标: {sub_goals_data}")
                break
        
        if not goal_found:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="指定的目标不存在"
            )
        
        # 更新数据库
        goal_record.goals = goals_data
        # 显式告诉SQLAlchemy该JSONB字段已被修改
        flag_modified(goal_record, 'goals')
        db.commit()
        db.refresh(goal_record)
        
        print(f"更新后的目标数据: {goal_record.goals}")
        
        return ApiResponse(
            code=200,
            message="更新子目标成功"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"更新子目标失败: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"更新子目标失败: {str(e)}"
        )


@router.post("/goals/update_sub_task", response_model=ApiResponse)
def update_sub_task(
    *,
    db: Session = Depends(get_db),
    request: UpdateSubTaskRequest,
) -> Any:
    """更新子任务"""
    try:
        user_id = request.user_id
        goal_id = request.goal_id
        print(f"更新子任务请求，user_id: {user_id}, goal_id: {goal_id}")
        print(f"接收到的子任务数据: {[st.dict() for st in request.sub_tasks]}")
        
        # 验证用户是否存在
        user = db.query(User).filter(User.user_id == user_id).first()
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="用户不存在"
            )
        
        # 查询目标记录
        goal_record = db.query(Goal).filter(Goal.user_id == user_id).first()
        
        if not goal_record:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="目标记录不存在"
            )
        
        print(f"更新前的目标数据: {goal_record.goals}")
        
        # 查找并更新指定的目标
        goals_data = goal_record.goals or []
        goal_found = False
        
        for i, goal_data in enumerate(goals_data):
            if goal_data.get('goal_id') == goal_id:
                # 更新子任务
                sub_tasks_data = []
                for sub_task in request.sub_tasks:
                    sub_task_dict = sub_task.dict()
                    # 为新子任务生成ID
                    if not sub_task_dict.get('sub_task_id'):
                        sub_task_dict['sub_task_id'] = str(uuid.uuid4())
                    sub_tasks_data.append(sub_task_dict)
                
                goals_data[i]['sub_tasks'] = sub_tasks_data
                
                # 更新目标的完成金额
                update_goal_completed_amount(goals_data[i])
                
                goal_found = True
                print(f"更新目标 {goal_id} 的子任务: {sub_tasks_data}")
                break
        
        if not goal_found:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="指定的目标不存在"
            )
        
        # 更新数据库
        goal_record.goals = goals_data
        # 显式告诉SQLAlchemy该JSONB字段已被修改
        flag_modified(goal_record, 'goals')
        db.commit()
        db.refresh(goal_record)
        
        print(f"更新后的目标数据: {goal_record.goals}")
        
        return ApiResponse(
            code=200,
            message="更新子任务成功"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"更新子任务失败: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"更新子任务失败: {str(e)}"
        ) 