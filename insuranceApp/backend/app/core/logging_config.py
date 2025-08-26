"""
统一错误日志记录配置
前端和后端错误统一记录到application_errors.log
"""

import logging
import logging.handlers
from datetime import datetime
from typing import Dict, Any, Optional
from pathlib import Path

# 创建日志目录
LOG_DIR = Path("logs")
LOG_DIR.mkdir(exist_ok=True)

# 统一日志文件路径
UNIFIED_ERROR_LOG_FILE = LOG_DIR / "application_errors.log"
ACCESS_LOG_FILE = LOG_DIR / "access.log"


class UnifiedErrorLogger:
    """统一错误日志记录器 - 处理前端和后端的所有错误日志"""
    
    def __init__(self):
        self.logger = logging.getLogger("unified_error_logger")
        self.logger.setLevel(logging.ERROR)
        
        # 避免重复添加处理器
        if not self.logger.handlers:
            # 文件处理器 - 按日期轮转
            file_handler = logging.handlers.TimedRotatingFileHandler(
                UNIFIED_ERROR_LOG_FILE,
                when='midnight',
                interval=1,
                backupCount=30,
                encoding='utf-8'
            )
            file_handler.setLevel(logging.ERROR)
            
            # 简化的日志格式 - 直接输出可读的文本
            formatter = logging.Formatter(
                '%(asctime)s | %(message)s',
                datefmt='%Y-%m-%d %H:%M:%S'
            )
            file_handler.setFormatter(formatter)
            
            self.logger.addHandler(file_handler)
    
    def log_error(self, 
                  error_type: str,
                  message: str,
                  source: str = "BACKEND",  # 新增：区分前端/后端
                  user_id: Optional[str] = None,
                  conversation_id: Optional[str] = None,
                  api_endpoint: Optional[str] = None,
                  page_name: Optional[str] = None,
                  service_name: Optional[str] = None,
                  stack_trace: Optional[str] = None,
                  additional_context: Optional[Dict[str, Any]] = None):
        """
        统一记录前端和后端错误信息
        
        Args:
            error_type: 错误类型
            message: 错误消息
            source: 错误来源 (FRONTEND/BACKEND)
            user_id: 用户ID
            conversation_id: 对话ID
            api_endpoint: API端点（后端）
            page_name: 页面名称（前端）
            service_name: 服务名称
            stack_trace: 堆栈跟踪
            additional_context: 额外上下文信息
        """
        # 创建可读的日志消息
        log_parts = []
        
        # 基本信息
        log_parts.append(f"[{source}]")
        log_parts.append(f"[{error_type}]")
        log_parts.append(message)
        
        # 用户信息
        if user_id:
            log_parts.append(f"| User: {user_id}")
        
        # 位置信息
        if api_endpoint:
            log_parts.append(f"| API: {api_endpoint}")
        if page_name:
            log_parts.append(f"| Page: {page_name}")
        if service_name:
            log_parts.append(f"| Service: {service_name}")
        if conversation_id:
            log_parts.append(f"| Conversation: {conversation_id}")
        
        # 附加信息
        if additional_context:
            context_str = ", ".join([f"{k}={v}" for k, v in additional_context.items() if v])
            if context_str:
                log_parts.append(f"| Context: {context_str}")
        
        # 错误详情（如果有堆栈跟踪，放在下一行）
        readable_message = " ".join(log_parts)
        
        if stack_trace:
            # 截取堆栈跟踪的前几行，避免日志过长
            stack_lines = stack_trace.split('\n')[:5]
            readable_message += "\n  Stack: " + " | ".join(line.strip() for line in stack_lines if line.strip())
        
        # 记录可读的日志
        self.logger.error(readable_message)


# 全局统一错误日志记录器实例
unified_logger = UnifiedErrorLogger()


# 简化的日志记录函数

def log_error(message: str, error_type: str, user_id: Optional[str] = None,
              api_endpoint: Optional[str] = None, stack_trace: Optional[str] = None,
              **kwargs):
    """记录后端错误的通用函数"""
    unified_logger.log_error(
        error_type=error_type.upper(),
        message=message,
        source="BACKEND",
        user_id=user_id,
        api_endpoint=api_endpoint,
        stack_trace=stack_trace,
        additional_context=kwargs
    )


def log_frontend_error(message: str, error_type: str, user_id: Optional[str] = None,
                      conversation_id: Optional[str] = None, page_name: Optional[str] = None,
                      service_name: Optional[str] = None, stack_trace: Optional[str] = None,
                      additional_context: Optional[Dict[str, Any]] = None):
    """记录来自前端的错误"""
    unified_logger.log_error(
        error_type=error_type.upper(),
        message=message,
        source="FRONTEND",
        user_id=user_id,
        conversation_id=conversation_id,
        page_name=page_name,
        service_name=service_name,
        stack_trace=stack_trace,
        additional_context=additional_context
    )
