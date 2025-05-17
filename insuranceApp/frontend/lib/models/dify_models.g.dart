// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dify_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppInfo _$AppInfoFromJson(Map<String, dynamic> json) => AppInfo(
      name: json['name'] as String,
      description: json['description'] as String,
      tags: (json['tags'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$AppInfoToJson(AppInfo instance) => <String, dynamic>{
      'name': instance.name,
      'description': instance.description,
      'tags': instance.tags,
    };

TextInputConfig _$TextInputConfigFromJson(Map<String, dynamic> json) =>
    TextInputConfig(
      label: json['label'] as String,
      variable: json['variable'] as String,
      required: json['required'] as bool,
      maxLength: (json['maxLength'] as num?)?.toInt(),
      defaultValue: json['default'] as String?,
    );

Map<String, dynamic> _$TextInputConfigToJson(TextInputConfig instance) =>
    <String, dynamic>{
      'label': instance.label,
      'variable': instance.variable,
      'required': instance.required,
      'maxLength': instance.maxLength,
      'default': instance.defaultValue,
    };

ParagraphConfig _$ParagraphConfigFromJson(Map<String, dynamic> json) =>
    ParagraphConfig(
      label: json['label'] as String,
      variable: json['variable'] as String,
      required: json['required'] as bool,
      defaultValue: json['default'] as String?,
    );

Map<String, dynamic> _$ParagraphConfigToJson(ParagraphConfig instance) =>
    <String, dynamic>{
      'label': instance.label,
      'variable': instance.variable,
      'required': instance.required,
      'default': instance.defaultValue,
    };

SelectConfig _$SelectConfigFromJson(Map<String, dynamic> json) => SelectConfig(
      label: json['label'] as String,
      variable: json['variable'] as String,
      required: json['required'] as bool,
      defaultValue: json['default'] as String?,
      options:
          (json['options'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$SelectConfigToJson(SelectConfig instance) =>
    <String, dynamic>{
      'label': instance.label,
      'variable': instance.variable,
      'required': instance.required,
      'default': instance.defaultValue,
      'options': instance.options,
    };

FormItem _$FormItemFromJson(Map<String, dynamic> json) => FormItem(
      textInput: json['text-input'] == null
          ? null
          : TextInputConfig.fromJson(
              json['text-input'] as Map<String, dynamic>),
      paragraph: json['paragraph'] == null
          ? null
          : ParagraphConfig.fromJson(json['paragraph'] as Map<String, dynamic>),
      select: json['select'] == null
          ? null
          : SelectConfig.fromJson(json['select'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FormItemToJson(FormItem instance) => <String, dynamic>{
      'text-input': instance.textInput,
      'paragraph': instance.paragraph,
      'select': instance.select,
    };

AppParameters _$AppParametersFromJson(Map<String, dynamic> json) =>
    AppParameters(
      openingStatement: json['opening_statement'] as String?,
      suggestedQuestions: (json['suggested_questions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      suggestedQuestionsAfterAnswer: json['suggested_questions_after_answer'] ==
              null
          ? null
          : SuggestedQuestionsAfterAnswer.fromJson(
              json['suggested_questions_after_answer'] as Map<String, dynamic>),
      speechToText: json['speech_to_text'] == null
          ? null
          : FeatureConfig.fromJson(
              json['speech_to_text'] as Map<String, dynamic>),
      retrieverResource: json['retriever_resource'] == null
          ? null
          : FeatureConfig.fromJson(
              json['retriever_resource'] as Map<String, dynamic>),
      annotationReply: json['annotation_reply'] == null
          ? null
          : FeatureConfig.fromJson(
              json['annotation_reply'] as Map<String, dynamic>),
      userInputForm: (json['user_input_form'] as List<dynamic>?)
          ?.map((e) => FormItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      fileUpload: json['file_upload'] == null
          ? null
          : FileUploadConfig.fromJson(
              json['file_upload'] as Map<String, dynamic>),
      systemParameters: json['system_parameters'] == null
          ? null
          : SystemParameters.fromJson(
              json['system_parameters'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$AppParametersToJson(AppParameters instance) =>
    <String, dynamic>{
      'opening_statement': instance.openingStatement,
      'suggested_questions': instance.suggestedQuestions,
      'suggested_questions_after_answer':
          instance.suggestedQuestionsAfterAnswer,
      'speech_to_text': instance.speechToText,
      'retriever_resource': instance.retrieverResource,
      'annotation_reply': instance.annotationReply,
      'user_input_form': instance.userInputForm,
      'file_upload': instance.fileUpload,
      'system_parameters': instance.systemParameters,
    };

SuggestedQuestionsAfterAnswer _$SuggestedQuestionsAfterAnswerFromJson(
        Map<String, dynamic> json) =>
    SuggestedQuestionsAfterAnswer(
      enabled: json['enabled'] as bool,
    );

Map<String, dynamic> _$SuggestedQuestionsAfterAnswerToJson(
        SuggestedQuestionsAfterAnswer instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
    };

FeatureConfig _$FeatureConfigFromJson(Map<String, dynamic> json) =>
    FeatureConfig(
      enabled: json['enabled'] as bool,
    );

Map<String, dynamic> _$FeatureConfigToJson(FeatureConfig instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
    };

FileUploadConfig _$FileUploadConfigFromJson(Map<String, dynamic> json) =>
    FileUploadConfig(
      image: json['image'] == null
          ? null
          : ImageConfig.fromJson(json['image'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FileUploadConfigToJson(FileUploadConfig instance) =>
    <String, dynamic>{
      'image': instance.image,
    };

ImageConfig _$ImageConfigFromJson(Map<String, dynamic> json) => ImageConfig(
      enabled: json['enabled'] as bool,
      numberLimits: (json['number_limits'] as num).toInt(),
      transferMethods: (json['transfer_methods'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ImageConfigToJson(ImageConfig instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'number_limits': instance.numberLimits,
      'transfer_methods': instance.transferMethods,
    };

SystemParameters _$SystemParametersFromJson(Map<String, dynamic> json) =>
    SystemParameters(
      fileSizeLimit: (json['file_size_limit'] as num).toInt(),
      imageFileSizeLimit: (json['image_file_size_limit'] as num).toInt(),
      audioFileSizeLimit: (json['audio_file_size_limit'] as num).toInt(),
      videoFileSizeLimit: (json['video_file_size_limit'] as num).toInt(),
    );

Map<String, dynamic> _$SystemParametersToJson(SystemParameters instance) =>
    <String, dynamic>{
      'file_size_limit': instance.fileSizeLimit,
      'image_file_size_limit': instance.imageFileSizeLimit,
      'audio_file_size_limit': instance.audioFileSizeLimit,
      'video_file_size_limit': instance.videoFileSizeLimit,
    };

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      inputs: json['inputs'] as Map<String, dynamic>?,
      query: json['query'] as String?,
      answer: json['answer'] as String?,
      messageFiles: (json['message_files'] as List<dynamic>?)
          ?.map((e) => MessageFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      feedback: json['feedback'] == null
          ? null
          : MessageFeedback.fromJson(json['feedback'] as Map<String, dynamic>),
      retrieverResources: (json['retriever_resources'] as List<dynamic>?)
          ?.map((e) => RetrieverResource.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: (json['created_at'] as num).toInt(),
    );

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversation_id': instance.conversationId,
      'inputs': instance.inputs,
      'query': instance.query,
      'answer': instance.answer,
      'message_files': instance.messageFiles,
      'feedback': instance.feedback,
      'retriever_resources': instance.retrieverResources,
      'created_at': instance.createdAt,
    };

MessageFile _$MessageFileFromJson(Map<String, dynamic> json) => MessageFile(
      id: json['id'] as String,
      type: json['type'] as String,
      url: json['url'] as String,
      belongsTo: json['belongs_to'] as String,
    );

Map<String, dynamic> _$MessageFileToJson(MessageFile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'url': instance.url,
      'belongs_to': instance.belongsTo,
    };

MessageFeedback _$MessageFeedbackFromJson(Map<String, dynamic> json) =>
    MessageFeedback(
      rating: json['rating'] as String?,
    );

Map<String, dynamic> _$MessageFeedbackToJson(MessageFeedback instance) =>
    <String, dynamic>{
      'rating': instance.rating,
    };

RetrieverResource _$RetrieverResourceFromJson(Map<String, dynamic> json) =>
    RetrieverResource(
      position: (json['position'] as num).toInt(),
      datasetId: json['dataset_id'] as String,
      datasetName: json['dataset_name'] as String,
      documentId: json['document_id'] as String,
      documentName: json['document_name'] as String,
      segmentId: json['segment_id'] as String,
      score: (json['score'] as num).toDouble(),
      content: json['content'] as String,
    );

Map<String, dynamic> _$RetrieverResourceToJson(RetrieverResource instance) =>
    <String, dynamic>{
      'position': instance.position,
      'dataset_id': instance.datasetId,
      'dataset_name': instance.datasetName,
      'document_id': instance.documentId,
      'document_name': instance.documentName,
      'segment_id': instance.segmentId,
      'score': instance.score,
      'content': instance.content,
    };

Conversation _$ConversationFromJson(Map<String, dynamic> json) => Conversation(
      id: json['id'] as String,
      name: json['name'] as String,
      inputs: json['inputs'] as Map<String, dynamic>?,
      status: json['status'] as String,
      introduction: json['introduction'] as String?,
      createdAt: (json['created_at'] as num).toInt(),
      updatedAt: (json['updated_at'] as num).toInt(),
    );

Map<String, dynamic> _$ConversationToJson(Conversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'inputs': instance.inputs,
      'status': instance.status,
      'introduction': instance.introduction,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

ChatRequest _$ChatRequestFromJson(Map<String, dynamic> json) => ChatRequest(
      query: json['query'] as String,
      inputs: json['inputs'] as Map<String, dynamic>?,
      responseMode: json['response_mode'] as String,
      user: json['user'] as String,
      conversationId: json['conversation_id'] as String?,
      files: (json['files'] as List<dynamic>?)
          ?.map((e) => FileItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      autoGenerateName: json['auto_generate_name'] as bool?,
    );

Map<String, dynamic> _$ChatRequestToJson(ChatRequest instance) =>
    <String, dynamic>{
      'query': instance.query,
      'inputs': instance.inputs,
      'response_mode': instance.responseMode,
      'user': instance.user,
      'conversation_id': instance.conversationId,
      'files': instance.files,
      'auto_generate_name': instance.autoGenerateName,
    };

FileItem _$FileItemFromJson(Map<String, dynamic> json) => FileItem(
      type: json['type'] as String,
      transferMethod: json['transfer_method'] as String,
      url: json['url'] as String?,
      uploadFileId: json['upload_file_id'] as String?,
    );

Map<String, dynamic> _$FileItemToJson(FileItem instance) => <String, dynamic>{
      'type': instance.type,
      'transfer_method': instance.transferMethod,
      'url': instance.url,
      'upload_file_id': instance.uploadFileId,
    };

UploadedFile _$UploadedFileFromJson(Map<String, dynamic> json) => UploadedFile(
      id: json['id'] as String,
      name: json['name'] as String,
      size: (json['size'] as num).toInt(),
      extension: json['extension'] as String,
      mimeType: json['mime_type'] as String,
      createdBy: json['created_by'] as String,
      createdAt: (json['created_at'] as num).toInt(),
    );

Map<String, dynamic> _$UploadedFileToJson(UploadedFile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'size': instance.size,
      'extension': instance.extension,
      'mime_type': instance.mimeType,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt,
    };
