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
    GetGoalsByDateRequest,
    GetGoalsByDateResponse,
    UpdateDateRequest,
    UpdateSubTaskStatusRequest,
    ScheduleGoal,
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
            # 动态计算并更新已完成金额（根据子任务完成状态）
            update_goal_completed_amount(goal_data)
            
            # 计算任务统计
            total_tasks, completed_tasks = calculate_task_stats(goal_data)
            
            # 获取子目标信息
            sub_goals = []
            for sub_goal_data in goal_data.get('sub_goals', []):
                sub_goals.append(SubGoal(**sub_goal_data))
            
            # 创建目标基本信息（使用动态计算的已完成金额）
            goal_basic_info = GoalBasicInfo(
                goal_id=goal_data.get('goal_id', ''),
                goal_name=goal_data.get('goal_name', ''),
                goal_description=goal_data.get('goal_description'),
                priority=goal_data.get('priority'),
                expected_completion_time=goal_data.get('expected_completion_time'),
                target_amount=goal_data.get('target_amount'),
                completed_amount=goal_data.get('completed_amount', 0.0),  # 这里现在是动态计算的值
                sub_goals=sub_goals,
                sub_task_num=total_tasks,
                sub_task_completed_num=completed_tasks
            )
            goals_data.append(goal_basic_info)
        
        # 更新数据库中的已完成金额（保存动态计算的结果）
        goal_record.goals = [goal_data for goal_data in goal_record.goals]
        flag_modified(goal_record, 'goals')
        db.commit()
        db.refresh(goal_record)
        
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
        
        # 创建现有目标的映射，以便保留子目标和子任务
        existing_goals_map = {}
        if goal_record.goals:
            for existing_goal in goal_record.goals:
                existing_goals_map[existing_goal.get('goal_id')] = existing_goal
        
        # 转换目标数据，保留现有的子目标和子任务
        goals_data = []
        for goal in request.goals:
            goal_dict = goal.dict()
            goal_id = goal_dict.get('goal_id')
            
            # 为新目标生成ID
            if not goal_id:
                goal_id = str(uuid.uuid4())
                goal_dict['goal_id'] = goal_id
            
            # 如果是现有目标，保留其子目标和子任务
            if goal_id in existing_goals_map:
                existing_goal = existing_goals_map[goal_id]
                goal_dict['sub_goals'] = existing_goal.get('sub_goals', [])
                goal_dict['sub_tasks'] = existing_goal.get('sub_tasks', [])
                # 重新计算已完成金额（根据子任务状态）
                update_goal_completed_amount(goal_dict)
            else:
                # 新目标初始化子目标和子任务为空列表
                goal_dict['sub_goals'] = []
                goal_dict['sub_tasks'] = []
                # 新目标的已完成金额为0（因为没有子任务）
                goal_dict['completed_amount'] = 0.0
            
            goals_data.append(goal_dict)
        
        # 更新目标信息
        goal_record.goals = goals_data
        
        # 显式告诉SQLAlchemy该JSONB字段已被修改
        flag_modified(goal_record, 'goals')
        db.commit()
        db.refresh(goal_record)
        
        print(f"更新目标基本信息成功，保留了现有的子目标和子任务数据")
        print(f"更新后的目标数据: {goal_record.goals}")
        
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
        
        # 动态计算并更新已完成金额（根据子任务完成状态）
        update_goal_completed_amount(goal_data)
        
        # 构造子目标列表
        sub_goals = []
        for sub_goal_data in goal_data.get('sub_goals', []):
            sub_goals.append(SubGoal(**sub_goal_data))
        
        # 构造子任务列表
        sub_tasks = []
        for sub_task_data in goal_data.get('sub_tasks', []):
            sub_tasks.append(SubTask(**sub_task_data))
        
        # 创建目标详细信息（使用动态计算的已完成金额）
        goal_detail = GoalDetailInfo(
            goal_id=goal_data.get('goal_id', ''),
            goal_name=goal_data.get('goal_name', ''),
            goal_description=goal_data.get('goal_description'),
            priority=goal_data.get('priority'),
            expected_completion_time=goal_data.get('expected_completion_time'),
            target_amount=goal_data.get('target_amount'),
            completed_amount=goal_data.get('completed_amount', 0.0),  # 使用动态计算的值
            sub_goals=sub_goals,
            sub_tasks=sub_tasks
        )
        
        # 更新数据库中的已完成金额
        flag_modified(goal_record, 'goals')
        db.commit()
        db.refresh(goal_record)
        
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


# 新增的日程相关API

@router.get("/goals/get_by_date", response_model=GetGoalsByDateResponse)
def get_goals_by_date(
    *,
    db: Session = Depends(get_db),
    user_id: str,
    date: str,
) -> Any:
    """通过日期获取目标、子目标、子任务"""
    try:
        print(f"通过日期获取目标请求，user_id: {user_id}, date: {date}")
        
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
            return GetGoalsByDateResponse(
                code=200,
                message="通过日期获取目标成功",
                goals=[]
            )
        
        # 处理目标数据，筛选指定日期的目标、子目标和子任务
        schedule_goals = []
        for goal_data in goal_record.goals:
            # 动态计算并更新已完成金额（根据子任务完成状态）
            update_goal_completed_amount(goal_data)
            
            # 检查目标是否在指定日期
            goal_matches = goal_data.get('expected_completion_time') == date
            
            # 筛选指定日期的子目标
            matching_sub_goals = []
            for sub_goal_data in goal_data.get('sub_goals', []):
                if sub_goal_data.get('sub_goal_completion_time') == date:
                    matching_sub_goals.append(SubGoal(**sub_goal_data))
            
            # 筛选指定日期的子任务
            matching_sub_tasks = []
            for sub_task_data in goal_data.get('sub_tasks', []):
                if sub_task_data.get('sub_task_completion_time') == date:
                    matching_sub_tasks.append(SubTask(**sub_task_data))
            
            # 如果目标本身或有匹配的子目标/子任务，则包含该目标
            if goal_matches or matching_sub_goals or matching_sub_tasks:
                schedule_goal = ScheduleGoal(
                    goal_id=goal_data.get('goal_id', ''),
                    goal_name=goal_data.get('goal_name', ''),
                    target_amount=goal_data.get('target_amount'),
                    completed_amount=goal_data.get('completed_amount', 0.0),  # 使用动态计算的值
                    sub_goals=matching_sub_goals,
                    sub_tasks=matching_sub_tasks
                )
                schedule_goals.append(schedule_goal)
        
        return GetGoalsByDateResponse(
            code=200,
            message="通过日期获取目标成功",
            goals=schedule_goals
        )
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"通过日期获取目标失败: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"通过日期获取目标失败: {str(e)}"
        )


@router.post("/goals/update_date", response_model=ApiResponse)
def update_date(
    *,
    db: Session = Depends(get_db),
    request: UpdateDateRequest,
) -> Any:
    """通过id修改时间"""
    try:
        user_id = request.user_id
        item_type = request.type
        goal_id = request.goal_id
        sub_goal_id = request.sub_goal_id
        sub_task_id = request.sub_task_id
        date = request.date
        
        print(f"修改时间请求，user_id: {user_id}, type: {item_type}, goal_id: {goal_id}, date: {date}")
        
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
        
        # 查找并更新指定的目标/子目标/子任务
        goals_data = goal_record.goals or []
        updated = False
        
        for i, goal_data in enumerate(goals_data):
            if goal_data.get('goal_id') == goal_id:
                if item_type == 'goal':
                    # 更新目标时间
                    goals_data[i]['expected_completion_time'] = date
                    updated = True
                    break
                elif item_type == 'sub_goal' and sub_goal_id:
                    # 更新子目标时间
                    for j, sub_goal_data in enumerate(goal_data.get('sub_goals', [])):
                        if sub_goal_data.get('sub_goal_id') == sub_goal_id:
                            goals_data[i]['sub_goals'][j]['sub_goal_completion_time'] = date
                            updated = True
                            break
                elif item_type == 'sub_task' and sub_task_id:
                    # 更新子任务时间
                    for j, sub_task_data in enumerate(goal_data.get('sub_tasks', [])):
                        if sub_task_data.get('sub_task_id') == sub_task_id:
                            goals_data[i]['sub_tasks'][j]['sub_task_completion_time'] = date
                            updated = True
                            break
                
                if updated:
                    break
        
        if not updated:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="指定的目标/子目标/子任务不存在"
            )
        
        # 更新数据库
        goal_record.goals = goals_data
        flag_modified(goal_record, 'goals')
        db.commit()
        db.refresh(goal_record)
        
        return ApiResponse(
            code=200,
            message="修改时间成功"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"修改时间失败: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"修改时间失败: {str(e)}"
        )


@router.post("/goals/update_sub_task_status", response_model=ApiResponse)
def update_sub_task_status(
    *,
    db: Session = Depends(get_db),
    request: UpdateSubTaskStatusRequest,
) -> Any:
    """通过id更新子任务状态"""
    try:
        user_id = request.user_id
        goal_id = request.goal_id
        sub_task_id = request.sub_task_id
        new_status = request.sub_task_status
        
        print(f"更新子任务状态请求，user_id: {user_id}, goal_id: {goal_id}, sub_task_id: {sub_task_id}, status: {new_status}")
        
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
        
        # 查找并更新子任务状态
        goals_data = goal_record.goals or []
        updated = False
        
        for i, goal_data in enumerate(goals_data):
            if goal_data.get('goal_id') == goal_id:
                for j, sub_task_data in enumerate(goal_data.get('sub_tasks', [])):
                    if sub_task_data.get('sub_task_id') == sub_task_id:
                        old_status = sub_task_data.get('sub_task_status', False)
                        goals_data[i]['sub_tasks'][j]['sub_task_status'] = new_status
                        
                        # 根据状态变化更新目标的完成金额
                        if old_status != new_status:
                            update_goal_completed_amount(goals_data[i])
                        
                        updated = True
                        break
                
                if updated:
                    break
        
        if not updated:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="指定的子任务不存在"
            )
        
        # 更新数据库
        goal_record.goals = goals_data
        flag_modified(goal_record, 'goals')
        db.commit()
        db.refresh(goal_record)
        
        return ApiResponse(
            code=200,
            message="更新子任务状态成功"
        )
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"更新子任务状态失败: {e}")
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"更新子任务状态失败: {str(e)}"
        ) 