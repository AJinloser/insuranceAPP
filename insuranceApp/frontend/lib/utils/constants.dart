/// 应用常量
class Constants {
  /// Dify API基础URL
  static const String difyApiBaseUrl = 'http://47.238.246.199/v1';
  
  /// 后端API基础URL
  static const String apiBaseUrl = 'http://localhost:8000/api/v1';
  
  /// 共享首选项键
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String moduleListKey = 'ai_module_list';
  
  /// 其他常量
  static const int messagePageSize = 20;
  static const Duration tokenRefreshInterval = Duration(hours: 23);
} 