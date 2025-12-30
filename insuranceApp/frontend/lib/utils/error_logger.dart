/*
Flutter前端错误日志记录器
提供统一的错误日志记录和管理功能
*/

import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 错误类型枚举
enum ErrorType {
  auth,           // 认证错误
  api,            // API错误
  chat,           // 聊天错误
  insurance,      // 保险相关错误
  goal,           // 目标管理错误
  userInfo,       // 用户信息错误
  ui,             // UI错误
  service,        // 服务错误
  navigation,     // 导航错误
  unknown,        // 未知错误
}

/// 错误日志记录器
class ErrorLogger {
  static ErrorLogger? _instance;
  static ErrorLogger get instance => _instance ??= ErrorLogger._internal();
  
  ErrorLogger._internal();
  
  late File _logFile;
  bool _initialized = false;
  String? _baseUrl;
  
  /// 初始化日志记录器
  Future<void> init() async {
    if (_initialized) return;
    
    try {
      // 初始化后端API地址
      _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api/v1';
      
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${directory.path}/logs');
      
      // 创建logs目录
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }
      
      // 创建错误日志文件（作为备份）
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _logFile = File('${logsDir.path}/error_$today.log');
      
      if (!await _logFile.exists()) {
        await _logFile.create();
      }
      
      _initialized = true;
      debugPrint('===> ErrorLogger 初始化成功');
    } catch (e) {
      debugPrint('===> ErrorLogger 初始化失败: $e');
    }
  }
  
  /// 记录错误信息
  Future<void> logError({
    required ErrorType errorType,
    required String message,
    String? userId,
    String? conversationId,
    String? apiEndpoint,
    String? serviceName,
    String? pageName,
    String? widgetName,
    String? productId,
    String? productType,
    String? goalId,
    Map<String, dynamic>? requestData,
    String? stackTrace,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      await init();
      
      final errorData = {
        'message': message,
        'error_type': errorType.name.toUpperCase(),
        'user_id': userId,
        'conversation_id': conversationId,
        'page_name': pageName,
        'service_name': serviceName,
        'stack_trace': stackTrace,
        'additional_context': {
          'api_endpoint': apiEndpoint,
          'widget_name': widgetName,
          'product_id': productId,
          'product_type': productType,
          'goal_id': goalId,
          'request_data': requestData,
          ...?additionalContext,
        }..removeWhere((key, value) => value == null),
      };
      
      // 清理null值
      errorData.removeWhere((key, value) => value == null);
      
      // 首先尝试发送到后端
      bool sentToBackend = false;
      if (_baseUrl != null) {
        sentToBackend = await _sendToBackend(errorData);
      }
      
      // 如果发送失败或者调试模式，也写入本地文件作为备份
      if (!sentToBackend || kDebugMode) {
        await _writeToLocalFile(errorData);
      }
      
      // 在调试模式下也输出到控制台
      if (kDebugMode) {
        debugPrint('===> 错误日志: ${errorType.name.toUpperCase()}: $message');
      }
    } catch (e) {
      debugPrint('===> 记录错误日志失败: $e');
      // 如果所有方法都失败，至少尝试写入本地文件
      try {
        await _writeToLocalFile({
          'message': message,
          'error_type': errorType.name.toUpperCase(),
          'error': e.toString(),
        });
      } catch (localError) {
        debugPrint('===> 本地日志写入也失败: $localError');
      }
    }
  }
  
  /// 发送日志到后端
  Future<bool> _sendToBackend(Map<String, dynamic> errorData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/logs/frontend_error'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(errorData),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('===> 发送日志到后端失败: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('===> 发送日志到后端异常: $e');
      return false;
    }
  }
  
  /// 写入本地文件
  Future<void> _writeToLocalFile(Map<String, dynamic> errorData) async {
    try {
      final jsonString = jsonEncode({
        'timestamp': DateTime.now().toIso8601String(),
        ...errorData,
      });
      
      await _logFile.writeAsString(
        '$jsonString\n',
        mode: FileMode.append,
      );
    } catch (e) {
      debugPrint('===> 写入本地文件失败: $e');
    }
  }
  
  /// 清理旧日志文件（保留最近7天）
  Future<void> cleanOldLogs() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${directory.path}/logs');
      
      if (await logsDir.exists()) {
        final files = await logsDir.list().toList();
        final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
        
        for (final file in files) {
          if (file is File && file.path.contains('error_')) {
            final stat = await file.stat();
            if (stat.modified.isBefore(cutoffDate)) {
              await file.delete();
              debugPrint('===> 删除旧日志文件: ${file.path}');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('===> 清理旧日志文件失败: $e');
    }
  }
}

/// 错误日志记录便捷函数

/// 记录认证相关错误
Future<void> logAuthError({
  required String message,
  String? userId,
  String? serviceName,
  String? stackTrace,
  Map<String, dynamic>? additionalContext,
}) {
  return ErrorLogger.instance.logError(
    errorType: ErrorType.auth,
    message: message,
    userId: userId,
    serviceName: serviceName,
    stackTrace: stackTrace,
    additionalContext: additionalContext,
  );
}

/// 记录API相关错误
Future<void> logApiError({
  required String message,
  required String apiEndpoint,
  String? userId,
  String? serviceName,
  Map<String, dynamic>? requestData,
  String? stackTrace,
  Map<String, dynamic>? additionalContext,
}) {
  return ErrorLogger.instance.logError(
    errorType: ErrorType.api,
    message: message,
    userId: userId,
    apiEndpoint: apiEndpoint,
    serviceName: serviceName,
    requestData: requestData,
    stackTrace: stackTrace,
    additionalContext: additionalContext,
  );
}

/// 记录聊天相关错误
Future<void> logChatError({
  required String message,
  String? userId,
  String? conversationId,
  String? serviceName,
  String? stackTrace,
  Map<String, dynamic>? additionalContext,
}) {
  return ErrorLogger.instance.logError(
    errorType: ErrorType.chat,
    message: message,
    userId: userId,
    conversationId: conversationId,
    serviceName: serviceName,
    stackTrace: stackTrace,
    additionalContext: additionalContext,
  );
}

/// 记录保险相关错误
Future<void> logInsuranceError({
  required String message,
  String? userId,
  String? productId,
  String? productType,
  String? serviceName,
  String? apiEndpoint,
  String? stackTrace,
  Map<String, dynamic>? additionalContext,
}) {
  return ErrorLogger.instance.logError(
    errorType: ErrorType.insurance,
    message: message,
    userId: userId,
    productId: productId,
    productType: productType,
    serviceName: serviceName,
    apiEndpoint: apiEndpoint,
    stackTrace: stackTrace,
    additionalContext: additionalContext,
  );
}

/// 记录目标管理相关错误
Future<void> logGoalError({
  required String message,
  String? userId,
  String? goalId,
  String? serviceName,
  String? apiEndpoint,
  String? stackTrace,
  Map<String, dynamic>? additionalContext,
}) {
  return ErrorLogger.instance.logError(
    errorType: ErrorType.goal,
    message: message,
    userId: userId,
    goalId: goalId,
    serviceName: serviceName,
    apiEndpoint: apiEndpoint,
    stackTrace: stackTrace,
    additionalContext: additionalContext,
  );
}

/// 记录用户信息相关错误
Future<void> logUserInfoError({
  required String message,
  String? userId,
  String? serviceName,
  String? apiEndpoint,
  String? stackTrace,
  Map<String, dynamic>? additionalContext,
}) {
  return ErrorLogger.instance.logError(
    errorType: ErrorType.userInfo,
    message: message,
    userId: userId,
    serviceName: serviceName,
    apiEndpoint: apiEndpoint,
    stackTrace: stackTrace,
    additionalContext: additionalContext,
  );
}

/// 记录UI相关错误
Future<void> logUIError({
  required String message,
  String? userId,
  String? pageName,
  String? widgetName,
  String? stackTrace,
  Map<String, dynamic>? additionalContext,
}) {
  return ErrorLogger.instance.logError(
    errorType: ErrorType.ui,
    message: message,
    userId: userId,
    pageName: pageName,
    widgetName: widgetName,
    stackTrace: stackTrace,
    additionalContext: additionalContext,
  );
}

/// 记录服务相关错误
Future<void> logServiceError({
  required String message,
  required String serviceName,
  String? userId,
  String? stackTrace,
  Map<String, dynamic>? additionalContext,
}) {
  return ErrorLogger.instance.logError(
    errorType: ErrorType.service,
    message: message,
    userId: userId,
    serviceName: serviceName,
    stackTrace: stackTrace,
    additionalContext: additionalContext,
  );
}

/// 记录导航相关错误
Future<void> logNavigationError({
  required String message,
  String? userId,
  String? fromPage,
  String? toPage,
  String? stackTrace,
  Map<String, dynamic>? additionalContext,
}) {
  return ErrorLogger.instance.logError(
    errorType: ErrorType.navigation,
    message: message,
    userId: userId,
    stackTrace: stackTrace,
    additionalContext: {
      'from_page': fromPage,
      'to_page': toPage,
      ...?additionalContext,
    },
  );
}
