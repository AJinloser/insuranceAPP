/*
全局错误处理器
捕获和记录Flutter应用中的未处理异常
*/

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'error_logger.dart';

/// 全局错误处理器
class GlobalErrorHandler {
  static bool _initialized = false;
  
  /// 初始化全局错误处理
  static void init() {
    if (_initialized) return;
    
    // 捕获Flutter framework错误
    FlutterError.onError = (FlutterErrorDetails details) {
      // 在调试模式下也显示原始错误
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
      
      // 记录错误到日志
      _logFlutterError(details);
    };
    
    // 捕获异步错误（在isolate中未被捕获的错误）
    PlatformDispatcher.instance.onError = (error, stack) {
      // 记录异步错误到日志
      _logAsyncError(error, stack);
      return true; // 表示错误已被处理
    };
    
    _initialized = true;
    debugPrint('===> GlobalErrorHandler 初始化完成');
  }
  
  /// 记录Flutter框架错误
  static void _logFlutterError(FlutterErrorDetails details) {
    try {
      final errorMessage = details.toString();
      final stackTrace = details.stack?.toString();
      
      // 确定错误类型
      ErrorType errorType = ErrorType.ui;
      if (errorMessage.contains('Navigator') || errorMessage.contains('Route')) {
        errorType = ErrorType.navigation;
      } else if (errorMessage.contains('RenderBox') || errorMessage.contains('Widget')) {
        errorType = ErrorType.ui;
      }
      
      // 提取widget信息
      String? widgetName;
      String? pageName;
      
      if (details.context != null) {
        try {
          widgetName = details.context.runtimeType.toString();
          
          // 尝试找到页面名称
          Element? element = details.context as Element?;
          while (element != null) {
            if (element.widget is Scaffold || 
                element.widget is MaterialPageRoute ||
                element.widget.runtimeType.toString().contains('Page')) {
              pageName = element.widget.runtimeType.toString();
              break;
            }
            // 访问父级元素
            Element? parentElement;
            element.visitAncestorElements((ancestor) {
              parentElement = ancestor;
              return false; // 只访问第一个祖先
            });
            element = parentElement;
          }
        } catch (e) {
          debugPrint('提取widget信息失败: $e');
        }
      }
      
      // 异步记录错误（避免在错误处理中产生新的同步错误）
      Future.microtask(() async {
        await ErrorLogger.instance.logError(
          errorType: errorType,
          message: 'Flutter框架错误: ${details.exception}',
          pageName: pageName,
          widgetName: widgetName,
          stackTrace: stackTrace,
          additionalContext: {
            'error_source': 'FlutterError',
            'library': details.library,
            'information_collector': details.informationCollector?.toString(),
            'silent': details.silent,
          },
        );
      });
    } catch (e) {
      debugPrint('记录Flutter错误失败: $e');
    }
  }
  
  /// 记录异步错误
  static void _logAsyncError(Object error, StackTrace stack) {
    try {
      // 异步记录错误
      Future.microtask(() async {
        await ErrorLogger.instance.logError(
          errorType: ErrorType.unknown,
          message: '未捕获的异步错误: $error',
          stackTrace: stack.toString(),
          additionalContext: {
            'error_source': 'AsyncError',
            'error_type': error.runtimeType.toString(),
          },
        );
      });
    } catch (e) {
      debugPrint('记录异步错误失败: $e');
    }
  }
  
  /// 手动记录错误（供其他地方调用）
  static Future<void> logError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      await ErrorLogger.instance.logError(
        errorType: ErrorType.unknown,
        message: '手动记录的错误: $error',
        stackTrace: stackTrace?.toString(),
        additionalContext: {
          'error_source': 'ManualLog',
          'context': context,
          'error_type': error.runtimeType.toString(),
          ...?additionalData,
        },
      );
    } catch (e) {
      debugPrint('手动记录错误失败: $e');
    }
  }
  
  /// 记录页面导航错误
  static Future<void> logNavigationError(
    String message, {
    String? fromRoute,
    String? toRoute,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    try {
      await ErrorLogger.instance.logError(
        errorType: ErrorType.navigation,
        message: message,
        stackTrace: stackTrace?.toString(),
        additionalContext: {
          'from_route': fromRoute,
          'to_route': toRoute,
          'navigation_error': error?.toString(),
        },
      );
    } catch (e) {
      debugPrint('记录导航错误失败: $e');
    }
  }
}
