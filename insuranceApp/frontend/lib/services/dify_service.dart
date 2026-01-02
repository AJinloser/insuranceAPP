import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/dify_models.dart';

/// Dify API服务类
/// 用于与Dify API进行交互
class DifyService {
  late final String _baseUrl;
  late String _apiKey;
  late final Dio _dio;
  
  // 单例模式
  static final DifyService _instance = DifyService._internal();
  factory DifyService() => _instance;
  
  DifyService._internal() {
    _baseUrl = dotenv.env['DIFY_API_BASE_URL'] ?? 'http://skysail.top/v1';
    _apiKey = dotenv.env['DIFY_API_KEY'] ?? '';
    
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 120), // 增加到120秒
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
      ),
    );
    
    // 添加日志拦截器
    _dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
      logPrint: (object) => debugPrint(object.toString()),
    ));
  }
  
  /// 设置API密钥
  void setApiKey(String apiKey) {
    _apiKey = apiKey;
    _dio.options.headers['Authorization'] = 'Bearer $_apiKey';
  }
  
  /// 获取应用信息
  Future<AppInfo> getAppInfo() async {
    try {
      final response = await _dio.get('/info');
      return AppInfo.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// 获取应用参数
  Future<AppParameters> getParameters() async {
    try {
      final response = await _dio.get('/parameters');
      return AppParameters.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// 获取会话列表
  Future<List<Conversation>> getConversations({
    required String userId,
    String? lastId,
    int limit = 20,
    String sortBy = '-updated_at',
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'user': userId,
        'limit': limit,
        'sort_by': sortBy,
      };
      
      if (lastId != null) {
        queryParams['last_id'] = lastId;
      }
      
      final response = await _dio.get(
        '/conversations',
        queryParameters: queryParams,
      );
      
      final List<dynamic> conversationsData = response.data['data'];
      return conversationsData.map((json) => Conversation.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// 删除会话
  Future<void> deleteConversation({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await _dio.delete(
        '/conversations/$conversationId',
        data: {'user': userId},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// 重命名会话
  Future<Conversation> renameConversation({
    required String conversationId,
    required String userId,
    String? name,
    bool autoGenerate = false,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'user': userId,
        'auto_generate': autoGenerate,
      };
      
      if (name != null) {
        data['name'] = name;
      }
      
      final response = await _dio.post(
        '/conversations/$conversationId/name',
        data: data,
      );
      
      return Conversation.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// 获取会话历史消息
  Future<List<ChatMessage>> getMessages({
    required String conversationId,
    required String userId,
    String? firstId,
    int limit = 20,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'conversation_id': conversationId,
        'user': userId,
        'limit': limit,
      };
      
      if (firstId != null) {
        queryParams['first_id'] = firstId;
      }
      
      final response = await _dio.get(
        '/messages',
        queryParameters: queryParams,
      );
      
      final List<dynamic> messagesData = response.data['data'];
      return messagesData.map((json) => ChatMessage.fromJson(json)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// 发送消息（阻塞模式）
  Future<ChatMessage> sendMessage({
    required String query,
    required String userId,
    String? conversationId,
    Map<String, dynamic>? inputs,
    List<FileItem>? files,
    bool? autoGenerateName,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'query': query,
        'inputs': inputs ?? {},
        'user': userId,
        'response_mode': 'blocking',
      };
      
      if (conversationId != null) {
        data['conversation_id'] = conversationId;
      }
      
      if (inputs != null) {
        data['inputs'] = inputs;
      }
      
      if (files != null) {
        data['files'] = files.map((file) => file.toJson()).toList();
      }
      
      if (autoGenerateName != null) {
        data['auto_generate_name'] = autoGenerateName;
      }
      
      final response = await _dio.post(
        '/chat-messages',
        data: data,
      );
      
      return ChatMessage.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// 停止响应
  Future<void> stopResponse({
    required String taskId,
    required String userId,
  }) async {
    try {
      await _dio.post(
        '/chat-messages/$taskId/stop',
        data: {'user': userId},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// 消息反馈（点赞/点踩）
  Future<void> sendFeedback({
    required String messageId,
    required String userId,
    required String? rating,
    String? content,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'user': userId,
        'rating': rating,
      };
      
      if (content != null) {
        data['content'] = content;
      }
      
      await _dio.post(
        '/messages/$messageId/feedbacks',
        data: data,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// 获取下一轮建议问题列表
  Future<List<String>> getSuggestedQuestions({
    required String messageId,
    required String userId,
  }) async {
    try {
      final response = await _dio.get(
        '/messages/$messageId/suggested',
        queryParameters: {'user': userId},
      );
      
      final List<dynamic> questions = response.data['data'];
      return questions.map((q) => q.toString()).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// 上传文件
  Future<UploadedFile> uploadFile({
    required File file,
    required String userId,
  }) async {
    try {
      final String fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'user': userId,
      });
      
      final response = await _dio.post(
        '/files/upload',
        data: formData,
      );
      
      return UploadedFile.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// 语音转文字
  Future<String> audioToText({
    required File audioFile,
    required String userId,
  }) async {
    try {
      final String fileName = audioFile.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(audioFile.path, filename: fileName),
        'user': userId,
      });
      
      final response = await _dio.post(
        '/audio-to-text',
        data: formData,
      );
      
      return response.data['text'];
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// 文字转语音
  Future<Uint8List> textToAudio({
    String? messageId,
    String? text,
    required String userId,
  }) async {
    try {
      final Map<String, dynamic> data = {
        'user': userId,
      };
      
      if (messageId != null) {
        data['message_id'] = messageId;
      }
      
      if (text != null) {
        data['text'] = text;
      }
      
      final response = await _dio.post(
        '/text-to-audio',
        data: data,
        options: Options(responseType: ResponseType.bytes),
      );
      
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// 错误处理
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final statusCode = error.response!.statusCode;
        final data = error.response!.data;
        
        String message = 'Unknown error';
        if (data is Map<String, dynamic> && data.containsKey('message')) {
          message = data['message'].toString();
        } else if (data is String) {
          message = data;
        }
        
        return DifyApiException(
          statusCode: statusCode ?? 500,
          message: message,
        );
      }
      
      return DifyApiException(
        statusCode: 503,
        message: 'Network error: ${error.message}',
      );
    }
    
    return DifyApiException(
      statusCode: 500,
      message: 'Unexpected error: $error',
    );
  }
}

/// Dify API异常类
class DifyApiException implements Exception {
  final int statusCode;
  final String message;
  
  DifyApiException({
    required this.statusCode,
    required this.message,
  });
  
  @override
  String toString() => 'DifyApiException: [$statusCode] $message';
} 