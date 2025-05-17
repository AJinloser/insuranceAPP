import 'package:json_annotation/json_annotation.dart';

part 'dify_models.g.dart';

/// Dify API 模型类
/// 基于DifyAPI.md文档实现

// 应用信息模型
@JsonSerializable()
class AppInfo {
  final String name;
  final String description;
  final List<String> tags;

  AppInfo({
    required this.name,
    required this.description,
    required this.tags,
  });

  factory AppInfo.fromJson(Map<String, dynamic> json) => _$AppInfoFromJson(json);
  Map<String, dynamic> toJson() => _$AppInfoToJson(this);
}

// 文本输入配置
@JsonSerializable()
class TextInputConfig {
  final String label;
  final String variable;
  final bool required;
  final int? maxLength;
  @JsonKey(name: 'default')
  final String? defaultValue;

  TextInputConfig({
    required this.label,
    required this.variable,
    required this.required,
    this.maxLength,
    this.defaultValue,
  });

  factory TextInputConfig.fromJson(Map<String, dynamic> json) => _$TextInputConfigFromJson(json);
  Map<String, dynamic> toJson() => _$TextInputConfigToJson(this);
}

// 段落输入配置
@JsonSerializable()
class ParagraphConfig {
  final String label;
  final String variable;
  final bool required;
  @JsonKey(name: 'default')
  final String? defaultValue;

  ParagraphConfig({
    required this.label,
    required this.variable,
    required this.required,
    this.defaultValue,
  });

  factory ParagraphConfig.fromJson(Map<String, dynamic> json) => _$ParagraphConfigFromJson(json);
  Map<String, dynamic> toJson() => _$ParagraphConfigToJson(this);
}

// 选择输入配置
@JsonSerializable()
class SelectConfig {
  final String label;
  final String variable;
  final bool required;
  @JsonKey(name: 'default')
  final String? defaultValue;
  final List<String>? options;

  SelectConfig({
    required this.label,
    required this.variable,
    required this.required,
    this.defaultValue,
    this.options,
  });

  factory SelectConfig.fromJson(Map<String, dynamic> json) => _$SelectConfigFromJson(json);
  Map<String, dynamic> toJson() => _$SelectConfigToJson(this);
}

// 表单项
@JsonSerializable()
class FormItem {
  @JsonKey(name: 'text-input')
  final TextInputConfig? textInput;
  
  final ParagraphConfig? paragraph;
  
  final SelectConfig? select;

  FormItem({
    this.textInput,
    this.paragraph,
    this.select,
  });

  factory FormItem.fromJson(Map<String, dynamic> json) => _$FormItemFromJson(json);
  Map<String, dynamic> toJson() => _$FormItemToJson(this);
}

// 应用参数模型
@JsonSerializable()
class AppParameters {
  @JsonKey(name: 'opening_statement')
  final String? openingStatement;
  
  @JsonKey(name: 'suggested_questions')
  final List<String>? suggestedQuestions;
  
  @JsonKey(name: 'suggested_questions_after_answer')
  final SuggestedQuestionsAfterAnswer? suggestedQuestionsAfterAnswer;
  
  @JsonKey(name: 'speech_to_text')
  final FeatureConfig? speechToText;
  
  @JsonKey(name: 'retriever_resource')
  final FeatureConfig? retrieverResource;
  
  @JsonKey(name: 'annotation_reply')
  final FeatureConfig? annotationReply;
  
  @JsonKey(name: 'user_input_form')
  final List<FormItem>? userInputForm;
  
  @JsonKey(name: 'file_upload')
  final FileUploadConfig? fileUpload;
  
  @JsonKey(name: 'system_parameters')
  final SystemParameters? systemParameters;

  AppParameters({
    this.openingStatement,
    this.suggestedQuestions,
    this.suggestedQuestionsAfterAnswer,
    this.speechToText,
    this.retrieverResource,
    this.annotationReply,
    this.userInputForm,
    this.fileUpload,
    this.systemParameters,
  });

  factory AppParameters.fromJson(Map<String, dynamic> json) => _$AppParametersFromJson(json);
  Map<String, dynamic> toJson() => _$AppParametersToJson(this);
}

@JsonSerializable()
class SuggestedQuestionsAfterAnswer {
  final bool enabled;

  SuggestedQuestionsAfterAnswer({
    required this.enabled,
  });

  factory SuggestedQuestionsAfterAnswer.fromJson(Map<String, dynamic> json) => 
      _$SuggestedQuestionsAfterAnswerFromJson(json);
  Map<String, dynamic> toJson() => _$SuggestedQuestionsAfterAnswerToJson(this);
}

@JsonSerializable()
class FeatureConfig {
  final bool enabled;

  FeatureConfig({
    required this.enabled,
  });

  factory FeatureConfig.fromJson(Map<String, dynamic> json) => _$FeatureConfigFromJson(json);
  Map<String, dynamic> toJson() => _$FeatureConfigToJson(this);
}

@JsonSerializable()
class FileUploadConfig {
  final ImageConfig? image;

  FileUploadConfig({
    this.image,
  });

  factory FileUploadConfig.fromJson(Map<String, dynamic> json) => _$FileUploadConfigFromJson(json);
  Map<String, dynamic> toJson() => _$FileUploadConfigToJson(this);
}

@JsonSerializable()
class ImageConfig {
  final bool enabled;
  
  @JsonKey(name: 'number_limits')
  final int numberLimits;
  
  @JsonKey(name: 'transfer_methods')
  final List<String> transferMethods;

  ImageConfig({
    required this.enabled,
    required this.numberLimits,
    required this.transferMethods,
  });

  factory ImageConfig.fromJson(Map<String, dynamic> json) => _$ImageConfigFromJson(json);
  Map<String, dynamic> toJson() => _$ImageConfigToJson(this);
}

@JsonSerializable()
class SystemParameters {
  @JsonKey(name: 'file_size_limit')
  final int fileSizeLimit;
  
  @JsonKey(name: 'image_file_size_limit')
  final int imageFileSizeLimit;
  
  @JsonKey(name: 'audio_file_size_limit')
  final int audioFileSizeLimit;
  
  @JsonKey(name: 'video_file_size_limit')
  final int videoFileSizeLimit;

  SystemParameters({
    required this.fileSizeLimit,
    required this.imageFileSizeLimit,
    required this.audioFileSizeLimit,
    required this.videoFileSizeLimit,
  });

  factory SystemParameters.fromJson(Map<String, dynamic> json) => _$SystemParametersFromJson(json);
  Map<String, dynamic> toJson() => _$SystemParametersToJson(this);
}

// 聊天消息模型
@JsonSerializable()
class ChatMessage {
  final String id;
  
  @JsonKey(name: 'conversation_id')
  final String conversationId;
  
  final Map<String, dynamic>? inputs;
  final String? query;
  final String? answer;
  
  @JsonKey(name: 'message_files')
  final List<MessageFile>? messageFiles;
  
  final MessageFeedback? feedback;
  
  @JsonKey(name: 'retriever_resources')
  final List<RetrieverResource>? retrieverResources;
  
  @JsonKey(name: 'created_at')
  final int createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    this.inputs,
    this.query,
    this.answer,
    this.messageFiles,
    this.feedback,
    this.retrieverResources,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}

@JsonSerializable()
class MessageFile {
  final String id;
  final String type;
  final String url;
  
  @JsonKey(name: 'belongs_to')
  final String belongsTo;

  MessageFile({
    required this.id,
    required this.type,
    required this.url,
    required this.belongsTo,
  });

  factory MessageFile.fromJson(Map<String, dynamic> json) => _$MessageFileFromJson(json);
  Map<String, dynamic> toJson() => _$MessageFileToJson(this);
}

@JsonSerializable()
class MessageFeedback {
  final String? rating;

  MessageFeedback({
    this.rating,
  });

  factory MessageFeedback.fromJson(Map<String, dynamic> json) => _$MessageFeedbackFromJson(json);
  Map<String, dynamic> toJson() => _$MessageFeedbackToJson(this);
}

@JsonSerializable()
class RetrieverResource {
  final int position;
  
  @JsonKey(name: 'dataset_id')
  final String datasetId;
  
  @JsonKey(name: 'dataset_name')
  final String datasetName;
  
  @JsonKey(name: 'document_id')
  final String documentId;
  
  @JsonKey(name: 'document_name')
  final String documentName;
  
  @JsonKey(name: 'segment_id')
  final String segmentId;
  
  final double score;
  final String content;

  RetrieverResource({
    required this.position,
    required this.datasetId,
    required this.datasetName,
    required this.documentId,
    required this.documentName,
    required this.segmentId,
    required this.score,
    required this.content,
  });

  factory RetrieverResource.fromJson(Map<String, dynamic> json) => _$RetrieverResourceFromJson(json);
  Map<String, dynamic> toJson() => _$RetrieverResourceToJson(this);
}

// 会话模型
@JsonSerializable()
class Conversation {
  final String id;
  final String name;
  final Map<String, dynamic>? inputs;
  final String status;
  final String? introduction;
  
  @JsonKey(name: 'created_at')
  final int createdAt;
  
  @JsonKey(name: 'updated_at')
  final int updatedAt;

  Conversation({
    required this.id,
    required this.name,
    this.inputs,
    required this.status,
    this.introduction,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => _$ConversationFromJson(json);
  Map<String, dynamic> toJson() => _$ConversationToJson(this);
}

// 聊天请求模型
@JsonSerializable()
class ChatRequest {
  final String query;
  final Map<String, dynamic>? inputs;
  
  @JsonKey(name: 'response_mode')
  final String responseMode;
  
  final String user;
  
  @JsonKey(name: 'conversation_id')
  final String? conversationId;
  
  final List<FileItem>? files;
  
  @JsonKey(name: 'auto_generate_name')
  final bool? autoGenerateName;

  ChatRequest({
    required this.query,
    this.inputs,
    required this.responseMode,
    required this.user,
    this.conversationId,
    this.files,
    this.autoGenerateName,
  });

  factory ChatRequest.fromJson(Map<String, dynamic> json) => _$ChatRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ChatRequestToJson(this);
}

@JsonSerializable()
class FileItem {
  final String type;
  
  @JsonKey(name: 'transfer_method')
  final String transferMethod;
  
  final String? url;
  
  @JsonKey(name: 'upload_file_id')
  final String? uploadFileId;

  FileItem({
    required this.type,
    required this.transferMethod,
    this.url,
    this.uploadFileId,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) => _$FileItemFromJson(json);
  Map<String, dynamic> toJson() => _$FileItemToJson(this);
}

// 文件上传响应模型
@JsonSerializable()
class UploadedFile {
  final String id;
  final String name;
  final int size;
  final String extension;
  
  @JsonKey(name: 'mime_type')
  final String mimeType;
  
  @JsonKey(name: 'created_by')
  final String createdBy;
  
  @JsonKey(name: 'created_at')
  final int createdAt;

  UploadedFile({
    required this.id,
    required this.name,
    required this.size,
    required this.extension,
    required this.mimeType,
    required this.createdBy,
    required this.createdAt,
  });

  factory UploadedFile.fromJson(Map<String, dynamic> json) => _$UploadedFileFromJson(json);
  Map<String, dynamic> toJson() => _$UploadedFileToJson(this);
}

// 流式响应事件类型
enum StreamEventType {
  message,
  messageFile,
  messageEnd,
  ttsMessage,
  ttsMessageEnd,
  messageReplace,
  workflowStarted,
  nodeStarted,
  nodeFinished,
  workflowFinished,
  error,
  ping
}

// 流式响应基础模型
class StreamResponse {
  final StreamEventType event;
  final String? taskId;
  
  StreamResponse({
    required this.event,
    this.taskId,
  });
  
  factory StreamResponse.fromJson(Map<String, dynamic> json) {
    final eventStr = json['event'] as String;
    final StreamEventType eventType = _parseEventType(eventStr);
    
    switch (eventType) {
      case StreamEventType.message:
        return MessageStreamResponse.fromJson(json);
      case StreamEventType.messageEnd:
        return MessageEndStreamResponse.fromJson(json);
      case StreamEventType.error:
        return ErrorStreamResponse.fromJson(json);
      default:
        return StreamResponse(
          event: eventType,
          taskId: json['task_id'] as String?,
        );
    }
  }
  
  static StreamEventType _parseEventType(String eventStr) {
    switch (eventStr) {
      case 'message': return StreamEventType.message;
      case 'message_file': return StreamEventType.messageFile;
      case 'message_end': return StreamEventType.messageEnd;
      case 'tts_message': return StreamEventType.ttsMessage;
      case 'tts_message_end': return StreamEventType.ttsMessageEnd;
      case 'message_replace': return StreamEventType.messageReplace;
      case 'workflow_started': return StreamEventType.workflowStarted;
      case 'node_started': return StreamEventType.nodeStarted;
      case 'node_finished': return StreamEventType.nodeFinished;
      case 'workflow_finished': return StreamEventType.workflowFinished;
      case 'error': return StreamEventType.error;
      case 'ping': return StreamEventType.ping;
      default: return StreamEventType.message;
    }
  }
}

// 消息流式响应
class MessageStreamResponse extends StreamResponse {
  final String messageId;
  final String conversationId;
  final String answer;
  final int createdAt;
  
  MessageStreamResponse({
    required super.event,
    required super.taskId,
    required this.messageId,
    required this.conversationId,
    required this.answer,
    required this.createdAt,
  });
  
  factory MessageStreamResponse.fromJson(Map<String, dynamic> json) {
    return MessageStreamResponse(
      event: StreamEventType.message,
      taskId: json['task_id'] as String?,
      messageId: json['message_id'] ?? json['id'] as String,
      conversationId: json['conversation_id'] as String,
      answer: json['answer'] as String,
      createdAt: json['created_at'] as int,
    );
  }
}

// 消息结束流式响应
class MessageEndStreamResponse extends StreamResponse {
  final String messageId;
  final String conversationId;
  final Map<String, dynamic> metadata;
  
  MessageEndStreamResponse({
    required super.event,
    required super.taskId,
    required this.messageId,
    required this.conversationId,
    required this.metadata,
  });
  
  factory MessageEndStreamResponse.fromJson(Map<String, dynamic> json) {
    return MessageEndStreamResponse(
      event: StreamEventType.messageEnd,
      taskId: json['task_id'] as String?,
      messageId: json['message_id'] ?? json['id'] as String,
      conversationId: json['conversation_id'] as String,
      metadata: json['metadata'] as Map<String, dynamic>,
    );
  }
}

// 错误流式响应
class ErrorStreamResponse extends StreamResponse {
  final int status;
  final String code;
  final String message;
  
  ErrorStreamResponse({
    required super.event,
    required super.taskId,
    required this.status,
    required this.code,
    required this.message,
  });
  
  factory ErrorStreamResponse.fromJson(Map<String, dynamic> json) {
    return ErrorStreamResponse(
      event: StreamEventType.error,
      taskId: json['task_id'] as String?,
      status: json['status'] as int,
      code: json['code'] as String,
      message: json['message'] as String,
    );
  }
}

// AI模块模型
class AIModule {
  final String apiKey;
  final AppInfo? appInfo;
  AppParameters? parameters;
  
  AIModule({
    required this.apiKey,
    this.appInfo,
    this.parameters,
  });
} 