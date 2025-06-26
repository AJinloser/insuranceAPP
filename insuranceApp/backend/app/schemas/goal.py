import uuid
from typing import List, Optional
from datetime import date
from pydantic import BaseModel, Field


# 子目标模型
class SubGoal(BaseModel):
    """子目标"""
    sub_goal_id: str = Field(..., description="子目标ID")
    sub_goal_name: str = Field(..., description="子目标名称")
    sub_goal_description: Optional[str] = Field(None, description="子目标描述")
    sub_goal_amount: Optional[float] = Field(None, description="子目标金额")
    sub_goal_completion_time: Optional[str] = Field(None, description="子目标预计完成时间(YYYY-MM-DD)")
    sub_goal_status: bool = Field(False, description="子目标状态(是否完成)")


# 子任务模型
class SubTask(BaseModel):
    """子任务"""
    sub_task_id: str = Field(..., description="子任务ID")
    sub_task_name: str = Field(..., description="子任务名称")
    sub_task_description: Optional[str] = Field(None, description="子任务描述")
    sub_task_status: bool = Field(False, description="子任务状态(是否完成)")
    sub_task_completion_time: Optional[str] = Field(None, description="子任务预计完成时间(YYYY-MM-DD)")
    sub_task_amount: Optional[float] = Field(None, description="子任务金额")


# 目标基础模型
class GoalBase(BaseModel):
    """目标基础模型"""
    goal_id: str = Field(..., description="目标ID")
    goal_name: str = Field(..., description="目标名称")
    goal_description: Optional[str] = Field(None, description="目标描述")
    priority: Optional[str] = Field(None, description="优先级")
    expected_completion_time: Optional[str] = Field(None, description="预计完成时间(YYYY-MM-DD)")
    target_amount: Optional[float] = Field(None, description="目标金额")
    completed_amount: Optional[float] = Field(0.0, description="已完成金额")


# 目标基本信息（包含子目标和任务统计）
class GoalBasicInfo(GoalBase):
    """目标基本信息"""
    sub_goals: List[SubGoal] = Field(default_factory=list, description="子目标列表")
    sub_task_num: int = Field(0, description="子任务总数")
    sub_task_completed_num: int = Field(0, description="子任务已完成数")


# 目标详细信息（包含完整的子目标和子任务）
class GoalDetailInfo(GoalBase):
    """目标详细信息"""
    sub_goals: List[SubGoal] = Field(default_factory=list, description="子目标列表")
    sub_tasks: List[SubTask] = Field(default_factory=list, description="子任务列表")


# API请求模型
class GetGoalBasicInfoRequest(BaseModel):
    """获取目标基本信息请求"""
    user_id: uuid.UUID = Field(..., description="用户ID")


class UpdateGoalBasicInfoRequest(BaseModel):
    """更新目标基本信息请求"""
    user_id: uuid.UUID = Field(..., description="用户ID")
    goals: List[GoalBase] = Field(..., description="目标列表")


class GetGoalDetailInfoRequest(BaseModel):
    """获取目标详细信息请求"""
    user_id: uuid.UUID = Field(..., description="用户ID")
    goal_id: str = Field(..., description="目标ID")


class UpdateSubGoalRequest(BaseModel):
    """更新子目标请求"""
    user_id: uuid.UUID = Field(..., description="用户ID")
    goal_id: str = Field(..., description="目标ID")
    sub_goals: List[SubGoal] = Field(..., description="子目标列表")


class UpdateSubTaskRequest(BaseModel):
    """更新子任务请求"""
    user_id: uuid.UUID = Field(..., description="用户ID")
    goal_id: str = Field(..., description="目标ID")
    sub_tasks: List[SubTask] = Field(..., description="子任务列表")


# API响应模型
class ApiResponse(BaseModel):
    """API响应基础模型"""
    code: int = Field(..., description="状态码")
    message: str = Field(..., description="响应消息")


class GetGoalBasicInfoResponse(ApiResponse):
    """获取目标基本信息响应"""
    goals: List[GoalBasicInfo] = Field(default_factory=list, description="目标列表")


class GetGoalDetailInfoResponse(ApiResponse):
    """获取目标详细信息响应"""
    goal_detail: Optional[GoalDetailInfo] = Field(None, description="目标详细信息") 