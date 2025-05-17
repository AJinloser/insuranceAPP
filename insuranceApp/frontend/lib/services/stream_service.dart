import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/stream_models.dart';

/// 流式服务类，用于处理Dify API的SSE（Server-Sent Events）流式响应
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

      // 将字节流转换为字符串流
      final stream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (var line in stream) {
        if (line.trim().isEmpty) continue;
        
        if (line.startsWith('data:')) {
          final jsonContent = line.substring(5).trim();
          try {
            final data = jsonDecode(jsonContent);
            final eventType = data['event'] as String?;
            
            // 根据事件类型创建不同的响应对象
            if (eventType == 'message') {
              final messageResponse = MessageResponse.fromJson(data);
              if (onMessage != null) onMessage(messageResponse);
              yield messageResponse;
            } else if (eventType == 'message_end') {
              final messageEndResponse = MessageEndResponse.fromJson(data);
              if (onMessageEnd != null) onMessageEnd(messageEndResponse);
              yield messageEndResponse;
            } else if (eventType == 'error') {
              final errorResponse = ErrorResponse.fromJson(data);
              if (onError != null) onError(errorResponse);
              yield errorResponse;
            } else if (eventType == 'workflow_started') {
              final workflowStartedResponse = WorkflowStartedResponse.fromJson(data);
              if (onWorkflowStarted != null) onWorkflowStarted(workflowStartedResponse);
              yield workflowStartedResponse;
            } else if (eventType == 'workflow_finished') {
              final workflowFinishedResponse = WorkflowFinishedResponse.fromJson(data);
              if (onWorkflowFinished != null) onWorkflowFinished(workflowFinishedResponse);
              yield workflowFinishedResponse;
            } else if (eventType == 'node_started') {
              final nodeStartedResponse = NodeStartedResponse.fromJson(data);
              if (onNodeStarted != null) onNodeStarted(nodeStartedResponse);
              yield nodeStartedResponse;
            } else if (eventType == 'node_finished') {
              final nodeFinishedResponse = NodeFinishedResponse.fromJson(data);
              if (onNodeFinished != null) onNodeFinished(nodeFinishedResponse);
              yield nodeFinishedResponse;
            } else {
              yield StreamResponse(event: eventType ?? 'unknown');
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