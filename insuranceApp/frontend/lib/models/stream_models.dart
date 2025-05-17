// part 'stream_models.g.dart';

/// 基础流响应类
class StreamResponse {
  final String event;
  final String? taskId;
  
  StreamResponse({
    required this.event,
    this.taskId,
  });
}

/// 消息响应
class MessageResponse extends StreamResponse {
  final String messageId;
  final String conversationId;
  final String answer;
  final int createdAt;
  
  MessageResponse({
    required String event,
    String? taskId,
    required this.messageId,
    required this.conversationId,
    required this.answer,
    required this.createdAt,
  }) : super(event: event, taskId: taskId);
  
  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    return MessageResponse(
      event: json['event'] as String,
      taskId: json['task_id'] as String?,
      messageId: (json['id'] ?? json['message_id']) as String,
      conversationId: json['conversation_id'] as String,
      answer: json['answer'] as String,
      createdAt: json['created_at'] as int,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'event': event,
    'task_id': taskId,
    'message_id': messageId,
    'conversation_id': conversationId,
    'answer': answer,
    'created_at': createdAt,
  };
}

/// 消息文件响应
class MessageFileResponse extends StreamResponse {
  final String id;
  final String type;
  final String belongsTo;
  final String url;
  final String conversationId;
  
  MessageFileResponse({
    required String event,
    String? taskId,
    required this.id,
    required this.type,
    required this.belongsTo,
    required this.url,
    required this.conversationId,
  }) : super(event: event, taskId: taskId);
  
  factory MessageFileResponse.fromJson(Map<String, dynamic> json) {
    return MessageFileResponse(
      event: json['event'] as String,
      taskId: json['task_id'] as String?,
      id: json['id'] as String,
      type: json['type'] as String,
      belongsTo: json['belongs_to'] as String,
      url: json['url'] as String,
      conversationId: json['conversation_id'] as String,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'event': event,
    'task_id': taskId,
    'id': id,
    'type': type,
    'belongs_to': belongsTo,
    'url': url,
    'conversation_id': conversationId,
  };
}

/// 消息结束响应
class MessageEndResponse extends StreamResponse {
  final String messageId;
  final String conversationId;
  final Map<String, dynamic> metadata;
  
  MessageEndResponse({
    required String event,
    String? taskId,
    required this.messageId,
    required this.conversationId,
    required this.metadata,
  }) : super(event: event, taskId: taskId);
  
  factory MessageEndResponse.fromJson(Map<String, dynamic> json) {
    return MessageEndResponse(
      event: json['event'] as String,
      taskId: json['task_id'] as String?,
      messageId: (json['id'] ?? json['message_id']) as String,
      conversationId: json['conversation_id'] as String,
      metadata: json['metadata'] as Map<String, dynamic>,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'event': event,
    'task_id': taskId,
    'message_id': messageId,
    'conversation_id': conversationId,
    'metadata': metadata,
  };
}

/// 错误响应
class ErrorResponse extends StreamResponse {
  final int status;
  final String code;
  final String message;
  
  ErrorResponse({
    String event = 'error',
    String? taskId,
    required this.status,
    required this.code,
    required this.message,
  }) : super(event: event, taskId: taskId);
  
  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    return ErrorResponse(
      event: 'error',
      taskId: json['task_id'] as String?,
      status: json['status'] as int,
      code: json['code'] as String,
      message: json['message'] as String,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'event': event,
    'task_id': taskId,
    'status': status,
    'code': code,
    'message': message,
  };
}

/// 工作流开始响应
class WorkflowStartedResponse extends StreamResponse {
  final String workflowRunId;
  final Map<String, dynamic> data;
  
  WorkflowStartedResponse({
    required String event,
    String? taskId,
    required this.workflowRunId,
    required this.data,
  }) : super(event: event, taskId: taskId);
  
  factory WorkflowStartedResponse.fromJson(Map<String, dynamic> json) {
    return WorkflowStartedResponse(
      event: json['event'] as String,
      taskId: json['task_id'] as String?,
      workflowRunId: json['workflow_run_id'] as String,
      data: json['data'] as Map<String, dynamic>,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'event': event,
    'task_id': taskId,
    'workflow_run_id': workflowRunId,
    'data': data,
  };
}

/// 工作流完成响应
class WorkflowFinishedResponse extends StreamResponse {
  final String workflowRunId;
  final Map<String, dynamic> data;
  
  WorkflowFinishedResponse({
    required String event,
    String? taskId,
    required this.workflowRunId,
    required this.data,
  }) : super(event: event, taskId: taskId);
  
  factory WorkflowFinishedResponse.fromJson(Map<String, dynamic> json) {
    return WorkflowFinishedResponse(
      event: json['event'] as String,
      taskId: json['task_id'] as String?,
      workflowRunId: json['workflow_run_id'] as String,
      data: json['data'] as Map<String, dynamic>,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'event': event,
    'task_id': taskId,
    'workflow_run_id': workflowRunId,
    'data': data,
  };
}

/// 节点开始响应
class NodeStartedResponse extends StreamResponse {
  final String workflowRunId;
  final Map<String, dynamic> data;
  
  NodeStartedResponse({
    required String event,
    String? taskId,
    required this.workflowRunId,
    required this.data,
  }) : super(event: event, taskId: taskId);
  
  factory NodeStartedResponse.fromJson(Map<String, dynamic> json) {
    return NodeStartedResponse(
      event: json['event'] as String,
      taskId: json['task_id'] as String?,
      workflowRunId: json['workflow_run_id'] as String,
      data: json['data'] as Map<String, dynamic>,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'event': event,
    'task_id': taskId,
    'workflow_run_id': workflowRunId,
    'data': data,
  };
}

/// 节点完成响应
class NodeFinishedResponse extends StreamResponse {
  final String workflowRunId;
  final Map<String, dynamic> data;
  
  NodeFinishedResponse({
    required String event,
    String? taskId,
    required this.workflowRunId,
    required this.data,
  }) : super(event: event, taskId: taskId);
  
  factory NodeFinishedResponse.fromJson(Map<String, dynamic> json) {
    return NodeFinishedResponse(
      event: json['event'] as String,
      taskId: json['task_id'] as String?,
      workflowRunId: json['workflow_run_id'] as String,
      data: json['data'] as Map<String, dynamic>,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'event': event,
    'task_id': taskId,
    'workflow_run_id': workflowRunId,
    'data': data,
  };
} 