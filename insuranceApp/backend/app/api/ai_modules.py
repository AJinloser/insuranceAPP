from typing import Dict, List

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from app.core.config import settings
from app.api.deps import get_current_user

router = APIRouter()


class AIModuleResponse(BaseModel):
    """AI模块响应模型"""
    code: int
    message: str
    ai_modules: List[str]  # 修改为字符串列表，直接存储API密钥


@router.get("/ai_modules", response_model=AIModuleResponse)
# 临时移除认证依赖，仅用于开发测试
# def get_ai_modules(user_id: str = Depends(get_current_user)):
def get_ai_modules():
    """
    获取AI模块列表
    """
    try:
        # 从配置中读取AI模块列表
        print(f"====> API: 尝试获取AI模块列表")
        api_keys = settings.AI_MODULE_KEYS
        print(f"====> API: 从settings获取的API密钥列表: {api_keys}")
        
        # 如果配置中没有API密钥，添加默认测试密钥
        if not api_keys:
            print("====> API: 配置中未找到API密钥，使用硬编码测试数据")
            api_keys = ["app-00OIhpEJdqZ4RHX1uDprfHaR", "app-test123456", "app-test789012"]
            
        print(f"====> API: 返回的API密钥列表: {api_keys}")
        
        return {
            "code": 200,
            "message": "获取AI模块列表成功",
            "ai_modules": api_keys  # 直接返回API密钥列表
        }
    except Exception as e:
        print(f"====> API错误: 获取AI模块列表失败: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"获取AI模块列表失败: {str(e)}"
        ) 