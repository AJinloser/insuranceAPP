import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
// import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
// import 'package:flutter/widgets.dart';

import '../models/dify_models.dart';
import 'dify_service.dart';
import 'api_service.dart';
import 'auth_service.dart';
import '../utils/constants.dart';
import '../models/stream_models.dart';
import 'stream_service.dart';

/// 聊天服务类
/// 管理聊天相关状态和操作
class ChatService with ChangeNotifier {
  final DifyService _difyService = DifyService();
  final ApiService _apiService = ApiService();
  final StreamService _streamService = StreamService();
  
  // 移除随机生成的用户ID
  late String _userId;
  
  List<AIModule> _aiModules = [];
  AIModule? _selectedModule;
  List<Conversation> _conversations = [];
  Conversation? _currentConversation;
  List<ChatMessage> _messages = [];
  List<String> _suggestedQuestions = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _currentTaskId;
  String _currentAnswer = '';
  bool _isInitialized = false;
  
  // Getters
  List<AIModule> get aiModules => _aiModules;
  AIModule? get selectedModule => _selectedModule;
  List<Conversation> get conversations => _conversations;
  Conversation? get currentConversation => _currentConversation;
  List<ChatMessage> get messages => _messages;
  List<String> get suggestedQuestions => _suggestedQuestions;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String get userId => _userId;
  bool get isInitialized => _isInitialized;
  
  // 单例模式
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  
  ChatService._internal() {
    // 初始化时设置一个临时ID，后续会被更新
    _userId = const Uuid().v4();
  }
  
  /// 初始化
  Future<void> init() async {
    if (_isInitialized) return; // 防止重复初始化
    
    debugPrint('===> 开始初始化ChatService');
    // 从AuthService或API服务获取真实的用户ID
    await _initUserId();
    await _loadAIModules();
    
    if (_aiModules.isNotEmpty) {
      // 只选择模块，不加载会话列表，提高加载速度
      await selectAIModule(_aiModules.first, shouldLoadConversations: false);
    }
    
    _isInitialized = true;
    debugPrint('===> ChatService初始化完成');
  }
  
  /// 设置用户ID（由AuthService调用）
  void setUserId(String? id) {
    if (id != null && id.isNotEmpty && id != _userId) {
      _userId = id;
      debugPrint('===> 通过AuthService更新用户ID: $_userId');
      
      // 如果已初始化且已选择了AI模块，需要重新加载会话
      if (_isInitialized && _selectedModule != null) {
        loadConversations();
      }
    }
  }
  
  /// 初始化用户ID
  Future<void> _initUserId() async {
    try {
      // 从API服务获取用户ID
      final storedUserId = await _apiService.getUserId();
      
      if (storedUserId != null) {
        _userId = storedUserId;
        debugPrint('===> 使用已存储的用户ID: $_userId');
      } else {
        // 如果没有存储的用户ID，使用AuthService中的用户ID
        final authService = AuthService();
        final authUserId = authService.userId;
        
        if (authUserId != null) {
          _userId = authUserId;
          debugPrint('===> 使用AuthService中的用户ID: $_userId');
        } else {
          // 如果AuthService中也没有用户ID，使用一个临时ID
          // 这种情况应该很少发生，因为通常用户需要先登录
          _userId = const Uuid().v4();
          debugPrint('===> 警告: 无法获取真实用户ID，使用临时ID: $_userId');
        }
      }
    } catch (e) {
      // 出错时使用临时ID
      _userId = const Uuid().v4();
      debugPrint('===> 获取用户ID出错: $e，使用临时ID: $_userId');
    }
  }
  
  /// 加载AI模块
  Future<void> _loadAIModules() async {
    _setLoading(true);
    debugPrint('===> 开始加载AI模块...');
    try {
      // 直接从后端API获取AI模块列表
      // 不再使用SharedPreferences中缓存的模块列表
      await _loadAIModulesFromBackend();
    } catch (e) {
      debugPrint('===> 加载AI模块时出错: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 从后端API加载AI模块列表
  Future<void> _loadAIModulesFromBackend() async {
    debugPrint('===> 从后端API加载AI模块列表');
    try {
      final token = await _apiService.getToken();
      
      final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api/v1';
      debugPrint('===> 后端API基础URL: $baseUrl');
      
      final dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      
      final response = await dio.get('/ai_modules');
      debugPrint('===> 从后端获取的AI模块响应: ${response.data}');
      
      if (response.data['code'] == 200) {
        final apiKeysList = List<String>.from(response.data['ai_modules']);
        debugPrint('===> 从后端获取的API密钥列表: $apiKeysList');
        
        _aiModules = [];
        
        for (int i = 0; i < apiKeysList.length; i++) {
          final apiKey = apiKeysList[i];
          
          _difyService.setApiKey(apiKey);
          try {
            // 仅获取应用信息，不获取parameters以提高加载速度
            final appInfo = await _difyService.getAppInfo();
            
            _aiModules.add(AIModule(
              apiKey: apiKey,
              appInfo: appInfo,
              parameters: null, // 初始化时不加载parameters
            ));
            
            debugPrint('===> 成功添加后端AI模块 #$i: ${appInfo.name}');
          } catch (e) {
            debugPrint('===> 加载后端AI模块失败 #$i: API密钥=$apiKey, 错误: $e');
          }
        }
        
        // 不再将模块密钥持久化到SharedPreferences
      } else {
        debugPrint('===> 从后端加载AI模块失败: ${response.data['message']}');
      }
    } catch (e) {
      debugPrint('===> 从后端加载AI模块时出错: $e');
    }
  }
  
  /// 添加AI模块
  Future<bool> addAIModule(String apiKey) async {
    _setLoading(true);
    try {
      _difyService.setApiKey(apiKey);
      final appInfo = await _difyService.getAppInfo();
      
      final newModule = AIModule(
        apiKey: apiKey,
        appInfo: appInfo,
        parameters: null, // 稍后按需加载
      );
      
      _aiModules.add(newModule);
      
      // 不再保存到SharedPreferences
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding AI module: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  /// 加载模块参数
  Future<void> loadParametersForModule(AIModule module) async {
    if (module.parameters != null) return;
    
    try {
      final parameters = await getAIModuleParameters(module.apiKey);
      if (parameters != null) {
        module.parameters = parameters;
        notifyListeners();
      }
    } catch (e) {
      print('加载模块参数失败: $e');
    }
  }
  
  /// 选择AI模块
  Future<void> selectAIModule(AIModule module, {bool shouldLoadConversations = false}) async {
    final bool isSameModule = _selectedModule?.apiKey == module.apiKey;
    if (isSameModule && shouldLoadConversations == false) return;
    
    _setLoading(true);
    try {
      _selectedModule = module;
      _difyService.setApiKey(module.apiKey);
      
      // 重置当前会话状态
      _currentConversation = null;
      _messages = [];
      _suggestedQuestions = [];
      
      // 只有在明确需要时才加载会话列表（例如进入菜单页面时）
      if (shouldLoadConversations) {
        await loadConversations();
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error selecting AI module: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 加载会话列表
  Future<void> loadConversations() async {
    if (_selectedModule == null) return;
    
    _setLoading(true);
    debugPrint('===> 开始加载会话列表，用户ID: $_userId');
    try {
      _conversations = await _difyService.getConversations(
        userId: _userId,
      );
      debugPrint('===> 加载到${_conversations.length}个会话');
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 创建新会话
  Future<void> createNewConversation() async {
    _currentConversation = null;
    _messages = [];
    
    // 确保已加载parameters
    if (_selectedModule != null && _selectedModule!.parameters == null) {
      await loadParametersForModule(_selectedModule!);
    }
    
    _suggestedQuestions = _selectedModule?.parameters?.suggestedQuestions ?? [];
    notifyListeners();
  }
  
  /// 加载会话
  Future<void> loadConversation(Conversation conversation) async {
    _setLoading(true);
    try {
      _currentConversation = conversation;
      
      // 确保已加载parameters
      if (_selectedModule != null && _selectedModule!.parameters == null) {
        await loadParametersForModule(_selectedModule!);
      }
      
      await loadMessages();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading conversation: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 加载消息历史
  Future<void> loadMessages() async {
    if (_currentConversation == null) {
      _messages = [];
      return;
    }
    
    _setLoading(true);
    try {
      _messages = await _difyService.getMessages(
        conversationId: _currentConversation!.id,
        userId: _userId,
      );
      
      // 对获取到的历史消息进行反转，使其按照时间顺序（从旧到新）排列
      // 因为DifyAPI返回的历史消息是倒序的（最新的在前面）
      _messages = _messages.reversed.toList();
      
      for (var message in _messages) {
        debugPrint('===> 加载消息历史: ${message.query}');
      }
      for (var message in _messages) {
        debugPrint('===> 加载消息历史: ${message.answer}');
        // 打印反馈信息，便于调试
        if (message.feedback != null) {
          debugPrint('===> 消息反馈状态: ${message.id}, rating=${message.feedback?.rating}');
        }
      }
      
      // 确保已加载parameters再检查建议问题开关
      if (_selectedModule != null && _selectedModule!.parameters == null) {
        await loadParametersForModule(_selectedModule!);
      }
      
      // 加载最后一条消息的建议问题
      if (_messages.isNotEmpty && 
          _selectedModule?.parameters?.suggestedQuestionsAfterAnswer?.enabled == true) {
        await loadSuggestedQuestions(_messages.last.id);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading messages: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// 加载建议问题
  Future<void> loadSuggestedQuestions(String messageId) async {
    try {
      _suggestedQuestions = await _difyService.getSuggestedQuestions(
        messageId: messageId,
        userId: _userId,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading suggested questions: $e');
    }
  }
  
  /// 发送消息（使用流式响应）
  Future<void> sendMessageStream(String message) async {
    if (_userId.isEmpty) {
      await _initUserId();
    }

    if (selectedModule == null) {
      throw Exception('请先选择AI模块');
    }
    
    // 确保参数已加载
    if (selectedModule!.parameters == null) {
      await loadParametersForModule(selectedModule!);
    }

    try {
      _isSending = true;
      _currentAnswer = ''; // 清空之前的累积回复
      notifyListeners();

      // 创建临时ID以更好地标识消息
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      
      // 先添加用户消息
      final userMessage = ChatMessage(
        id: tempId,
        conversationId: _currentConversation?.id ?? tempId, // 为新对话时使用临时ID
        query: message,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      _messages.insert(0, userMessage);
      notifyListeners();

      // 创建AI回复的临时消息
      final aiMessage = ChatMessage(
        id: 'temp_ai_${DateTime.now().millisecondsSinceEpoch}',
        conversationId: _currentConversation?.id ?? tempId, // 为新对话时使用临时ID
        answer: '',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      );
      _messages.insert(0, aiMessage);
      notifyListeners();

      // 创建聊天请求 - 对于新对话，不传conversationId
      final requestBody = {
        'inputs': {},
        'query': message,
        'response_mode': 'streaming',
        'user': _userId,
        'conversation_id': _currentConversation?.id, // 为null时DifyAPI会自动创建新对话
      };

      debugPrint('===> 发送聊天请求：${jsonEncode(requestBody)}');
      debugPrint('===> 聊天API KEY: ${selectedModule!.apiKey.substring(0, 5)}...');

      // 使用StreamService发送流式请求
      final streamSubscription = _streamService.createSSERequest(
        endpoint: 'chat-messages',
        apiKey: selectedModule!.apiKey,
        body: requestBody,
        onMessage: (response) {
          if (response is MessageResponse) {
            // 更新任务ID
            _currentTaskId = response.taskId;
            
            // 累积回复
            _currentAnswer += response.answer;
            
            // 如果是新会话，获取服务器返回的conversation_id
            if (_currentConversation == null) {
              final conversationId = response.conversationId;
              // 创建新会话对象
              _currentConversation = Conversation(
                id: conversationId,
                name: '新对话',
                status: 'normal',
                createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
                updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              );
            }
            
            // 更新临时消息
            final index = _messages.indexWhere((msg) => msg.id == aiMessage.id);
            if (index != -1) {
              _messages[index] = ChatMessage(
                id: aiMessage.id,
                conversationId: _currentConversation?.id ?? aiMessage.conversationId,
                answer: _currentAnswer,
                createdAt: aiMessage.createdAt,
              );
              notifyListeners(); // 实时更新UI，保持流式效果
            }
          }
        },
        onMessageEnd: (response) {
          debugPrint('===> 消息结束: ${response.messageId}');
          
          // 更新最终消息
          final index = _messages.indexWhere((msg) => msg.id == aiMessage.id);
          if (index != -1) {
            _messages[index] = ChatMessage(
              id: response.messageId,
              conversationId: response.conversationId,
              answer: _currentAnswer,
              createdAt: aiMessage.createdAt,
              retrieverResources: _parseRetrieverResources(response.metadata),
            );
            notifyListeners();
          }
          
          _currentTaskId = null;
          
          // 如果是新会话，获取服务器返回的conversation_id
          if (_currentConversation == null && response.conversationId.isNotEmpty) {
            // 创建新会话对象
            _currentConversation = Conversation(
              id: response.conversationId,
              name: '新对话',
              status: 'normal',
              createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              updatedAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            );
            
            // 加载会话列表
            loadConversations();
          }
          
          // 如果开启了建议问题，则加载建议问题
          if (_selectedModule?.parameters?.suggestedQuestionsAfterAnswer?.enabled == true) {
            loadSuggestedQuestions(response.messageId);
          }
        },
        onError: (errorResponse) {
          debugPrint('===> 流错误: ${errorResponse.message}');
          
          // 更新临时消息为错误信息
          final index = _messages.indexWhere((msg) => msg.id == aiMessage.id);
          if (index != -1) {
            _messages[index] = ChatMessage(
              id: aiMessage.id,
              conversationId: aiMessage.conversationId,
              answer: '错误: ${errorResponse.message}',
              createdAt: aiMessage.createdAt,
            );
            notifyListeners();
          }
        },
      ).listen((event) {
        // 流事件已在各个回调中处理
      });

      // 等待流处理完成
      await streamSubscription.asFuture();
      await streamSubscription.cancel();

    } catch (e) {
      debugPrint('发送消息错误: $e');
      
      // 确保在错误情况下也更新UI
      final index = _messages.indexWhere((msg) => msg.id.startsWith('temp_ai_'));
      if (index != -1) {
        _messages[index] = ChatMessage(
          id: _messages[index].id,
          conversationId: _messages[index].conversationId,
          answer: '发送消息时出错: $e',
          createdAt: _messages[index].createdAt,
        );
        notifyListeners();
      }
      
      rethrow;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }
  
  /// 从消息元数据中解析引用资源
  List<RetrieverResource>? _parseRetrieverResources(Map<String, dynamic> metadata) {
    try {
      if (metadata.containsKey('retriever_resources')) {
        final resourcesJson = metadata['retriever_resources'] as List<dynamic>;
        return resourcesJson.map((json) {
          return RetrieverResource(
            position: json['position'] as int,
            datasetId: json['dataset_id'] as String,
            datasetName: json['dataset_name'] as String,
            documentId: json['document_id'] as String,
            documentName: json['document_name'] as String,
            segmentId: json['segment_id'] as String,
            score: json['score'] as double,
            content: json['content'] as String,
          );
        }).toList();
      }
    } catch (e) {
      debugPrint('解析引用资源出错: $e');
    }
    return null;
  }
  
  /// 停止响应
  Future<void> stopResponse() async {
    if (_currentTaskId == null || selectedModule == null) return;

    try {
      final result = await _streamService.stopResponse(
        taskId: _currentTaskId!,
        userId: _userId,
        apiKey: selectedModule!.apiKey,
      );
      
      if (result) {
        debugPrint('===> 停止响应成功');
      } else {
        debugPrint('===> 停止响应失败');
      }
      
      _currentTaskId = null;
    } catch (e) {
      debugPrint('停止响应出错: $e');
    }
  }
  
  /// 消息反馈（点赞/点踩）
  Future<void> sendFeedback(String messageId, String? rating) async {
    try {
      await _difyService.sendFeedback(
        messageId: messageId,
        userId: _userId,
        rating: rating,
      );
      
      // 更新本地消息的反馈状态
      final index = _messages.indexWhere((m) => m.id == messageId);
      if (index != -1) {
        final message = _messages[index];
        _messages[index] = ChatMessage(
          id: message.id,
          conversationId: message.conversationId,
          inputs: message.inputs,
          query: message.query,
          answer: message.answer,
          messageFiles: message.messageFiles,
          feedback: MessageFeedback(rating: rating),
          retrieverResources: message.retrieverResources,
          createdAt: message.createdAt,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error sending feedback: $e');
    }
  }
  
  /// 删除会话
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _difyService.deleteConversation(
        conversationId: conversationId,
        userId: _userId,
      );
      
      // 从本地列表中移除
      _conversations.removeWhere((c) => c.id == conversationId);
      
      // 如果删除的是当前会话，则重置当前会话
      if (_currentConversation?.id == conversationId) {
        _currentConversation = null;
        _messages = [];
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting conversation: $e');
    }
  }
  
  /// 重命名会话
  Future<void> renameConversation(String conversationId, String? name, {bool autoGenerate = false}) async {
    try {
      final updatedConversation = await _difyService.renameConversation(
        conversationId: conversationId,
        userId: _userId,
        name: name,
        autoGenerate: autoGenerate,
      );
      
      // 更新本地会话
      final index = _conversations.indexWhere((c) => c.id == conversationId);
      if (index != -1) {
        _conversations[index] = updatedConversation;
      }
      
      // 如果是当前会话，则更新当前会话
      if (_currentConversation?.id == conversationId) {
        _currentConversation = updatedConversation;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error renaming conversation: $e');
    }
  }
  
  /// 上传文件
  Future<UploadedFile?> uploadFile(File file) async {
    try {
      return await _difyService.uploadFile(
        file: file,
        userId: _userId,
      );
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }
  
  /// 语音转文字
  Future<String> audioToText(File audioFile) async {
    try {
      return await _difyService.audioToText(
        audioFile: audioFile,
        userId: _userId,
      );
    } catch (e) {
      debugPrint('Error converting audio to text: $e');
      return '';
    }
  }
  
  /// 文字转语音
  Future<Uint8List?> textToAudio({String? messageId, String? text}) async {
    try {
      return await _difyService.textToAudio(
        messageId: messageId,
        text: text,
        userId: _userId,
      );
    } catch (e) {
      debugPrint('Error converting text to audio: $e');
      return null;
    }
  }
  
  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  /// 重新加载用户ID
  Future<void> reloadUserId() async {
    await _initUserId();
    debugPrint('===> 重新加载用户ID完成: $_userId');
    
    // 如果已选择了AI模块，需要重新加载会话
    if (_selectedModule != null) {
      await loadConversations();
    }
  }

  // 获取AI模块的参数
  Future<AppParameters?> getAIModuleParameters(String apiKey) async {
    try {
      final response = await http.get(
        Uri.parse('${Constants.difyApiBaseUrl}/parameters'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        return AppParameters.fromJson(jsonData);
      } else {
        print('获取AI模块参数失败: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('获取AI模块参数异常: $e');
      return null;
    }
  }

  // 获取当前模块的推荐问题列表
  List<String> get moduleQuestions {
    if (selectedModule?.parameters?.suggestedQuestions != null) {
      return selectedModule!.parameters!.suggestedQuestions!;
    }
    return [];
  }
} 