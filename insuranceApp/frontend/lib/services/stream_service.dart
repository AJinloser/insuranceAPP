import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/stream_models.dart';

/// 流式服务类，用于处理Dify API的SSE（Server-Sent Events）流式响应
/// 
/// 优化要点：
/// 1. 使用自定义SSE解析器，立即处理每个数据块，避免等待缓冲
/// 2. 采用StringBuffer增量解析，支持跨chunk的消息处理
/// 3. 模块化的响应解析逻辑，提高代码可维护性
class StreamService {
  // 基础URL
  final String baseUrl = dotenv.env['DIFY_API_BASE_URL'] ?? 'http://47.238.246.199/v1';

  /// 创建一个流式HTTP请求
  /// 
  /// [endpoint] API端点
  /// [apiKey] API密钥
  /// [body] 请求体
  /// [onData] 接收到消息数据时的回调
  /// [onMessage] 接收到message事件时的回调
  /// [onMessageEnd] 接收到message_end事件时的回调
  /// [onError] 错误回调
  /// [onWorkflowStarted] 工作流开始事件回调
  /// [onWorkflowFinished] 工作流完成事件回调
  /// [onNodeStarted] 节点开始事件回调
  /// [onNodeFinished] 节点完成事件回调
  Stream<StreamResponse> createSSERequest({
    required String endpoint,
    required String apiKey,
    required Map<String, dynamic> body,
    Function(StreamResponse)? onMessage,
    Function(MessageEndResponse)? onMessageEnd,
    Function(ErrorResponse)? onError,
    Function(WorkflowStartedResponse)? onWorkflowStarted,
    Function(WorkflowFinishedResponse)? onWorkflowFinished,
    Function(NodeStartedResponse)? onNodeStarted,
    Function(NodeFinishedResponse)? onNodeFinished,
  }) async* {
    final client = http.Client();
    try {
      final request = http.Request('POST', Uri.parse('$baseUrl/$endpoint'));
      request.headers['Content-Type'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $apiKey';
      request.body = jsonEncode(body);

      final response = await client.send(request);
      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        final errorResponse = ErrorResponse(
          status: response.statusCode,
          code: 'http_error',
          message: 'HTTP错误: ${response.statusCode} - $errorBody',
        );
        if (onError != null) onError(errorResponse);
        yield errorResponse;
        return;
      }

      // 优化的SSE流处理：使用自定义解析器，立即处理每个数据块
      StringBuffer buffer = StringBuffer();
      
      await for (var chunk in response.stream.transform(utf8.decoder)) {
        buffer.write(chunk);
        var content = buffer.toString();
        
        // 处理所有完整的SSE消息（以\n\n分隔）
        while (content.contains('\n\n')) {
          final index = content.indexOf('\n\n');
          final message = content.substring(0, index);
          content = content.substring(index + 2);
          buffer.clear();
          buffer.write(content);
          
          // 解析并处理单个SSE消息
          final lines = message.split('\n');
          for (var line in lines) {
            if (line.trim().isEmpty) continue;
            
            if (line.startsWith('data:')) {
              final jsonContent = line.substring(5).trim();
              if (jsonContent.isEmpty) continue;
              
              try {
                final data = jsonDecode(jsonContent);
                final response = _parseStreamResponse(
                  data,
                  onMessage: onMessage,
                  onMessageEnd: onMessageEnd,
                  onError: onError,
                  onWorkflowStarted: onWorkflowStarted,
                  onWorkflowFinished: onWorkflowFinished,
                  onNodeStarted: onNodeStarted,
                  onNodeFinished: onNodeFinished,
                );
                
                if (response != null) {
                  yield response;
                }
              } catch (e) {
                debugPrint('解析JSON时出错: $e, 内容: $jsonContent');
                final errorResponse = ErrorResponse(
                  status: 400,
                  code: 'parse_error',
                  message: '解析响应时出错: $e',
                );
                if (onError != null) onError(errorResponse);
                yield errorResponse;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Stream请求出错: $e');
      final errorResponse = ErrorResponse(
        status: 500,
        code: 'stream_error',
        message: '流处理时出错: $e',
      );
      if (onError != null) onError(errorResponse);
      yield errorResponse;
    } finally {
      client.close();
    }
  }

  /// 解析流式响应数据
  StreamResponse? _parseStreamResponse(
    Map<String, dynamic> data, {
    Function(StreamResponse)? onMessage,
    Function(MessageEndResponse)? onMessageEnd,
    Function(ErrorResponse)? onError,
    Function(WorkflowStartedResponse)? onWorkflowStarted,
    Function(WorkflowFinishedResponse)? onWorkflowFinished,
    Function(NodeStartedResponse)? onNodeStarted,
    Function(NodeFinishedResponse)? onNodeFinished,
  }) {
    final eventType = data['event'] as String?;
    
    switch (eventType) {
      case 'message':
        final messageResponse = MessageResponse.fromJson(data);
        onMessage?.call(messageResponse);
        return messageResponse;
        
      case 'message_end':
        final messageEndResponse = MessageEndResponse.fromJson(data);
        onMessageEnd?.call(messageEndResponse);
        return messageEndResponse;
        
      case 'error':
        final errorResponse = ErrorResponse.fromJson(data);
        onError?.call(errorResponse);
        return errorResponse;
        
      case 'workflow_started':
        final workflowStartedResponse = WorkflowStartedResponse.fromJson(data);
        onWorkflowStarted?.call(workflowStartedResponse);
        return workflowStartedResponse;
        
      case 'workflow_finished':
        final workflowFinishedResponse = WorkflowFinishedResponse.fromJson(data);
        onWorkflowFinished?.call(workflowFinishedResponse);
        return workflowFinishedResponse;
        
      case 'node_started':
        final nodeStartedResponse = NodeStartedResponse.fromJson(data);
        onNodeStarted?.call(nodeStartedResponse);
        return nodeStartedResponse;
        
      case 'node_finished':
        final nodeFinishedResponse = NodeFinishedResponse.fromJson(data);
        onNodeFinished?.call(nodeFinishedResponse);
        return nodeFinishedResponse;
        
      default:
        return StreamResponse(event: eventType ?? 'unknown');
    }
  }

  /// 停止响应
  Future<bool> stopResponse({
    required String taskId,
    required String userId,
    required String apiKey,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat-messages/$taskId/stop'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'user': userId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('停止响应时出错: $e');
      return false;
    }
  }
} 