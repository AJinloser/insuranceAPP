import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:html' as html;

import 'api_service.dart';
import 'dify_service.dart';
import '../models/dify_models.dart';

/// 开发者服务类
/// 负责管理开发者选项和密码验证
class DeveloperService with ChangeNotifier {
  static final DeveloperService _instance = DeveloperService._internal();
  factory DeveloperService() => _instance;
  DeveloperService._internal();

  bool _isDeveloperMode = false;
  bool _isAuthenticated = false;
  
  // 会话分析相关
  List<AdminUserInfo> _users = [];
  List<ConversationAnalysis> _conversations = [];
  bool _isLoading = false;
  String? _error;

  /// 是否处于开发者模式
  bool get isDeveloperMode => _isDeveloperMode;

  /// 是否已通过开发者认证
  bool get isAuthenticated => _isAuthenticated;
  
  /// 用户列表
  List<AdminUserInfo> get users => _users;
  
  /// 会话分析列表
  List<ConversationAnalysis> get conversations => _conversations;
  
  /// 是否正在加载
  bool get isLoading => _isLoading;
  
  /// 错误信息
  String? get error => _error;

  /// 验证开发者密码
  /// [password] 输入的密码
  /// 返回验证结果
  Future<bool> verifyPassword(String password) async {
    try {
      // 从环境变量获取管理员密钥
      final adminKey = dotenv.env['ADMIN_KEY'];
      
      if (adminKey == null || adminKey.isEmpty) {
        debugPrint('开发者服务: ADMIN_KEY未配置');
        return false;
      }

      // 验证密码
      final isValid = password == adminKey;
      
      if (isValid) {
        _isAuthenticated = true;
        _isDeveloperMode = true;
        debugPrint('开发者服务: 密码验证成功');
        notifyListeners();
      } else {
        debugPrint('开发者服务: 密码验证失败');
      }
      
      return isValid;
    } catch (e) {
      debugPrint('开发者服务: 密码验证异常 - $e');
      return false;
    }
  }

  /// 退出开发者模式
  void exitDeveloperMode() {
    _isDeveloperMode = false;
    _isAuthenticated = false;
    debugPrint('开发者服务: 退出开发者模式');
    notifyListeners();
  }

  /// 重置认证状态
  void resetAuthentication() {
    _isAuthenticated = false;
    notifyListeners();
  }

  /// 获取所有用户列表
  Future<void> fetchUsers() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final apiService = ApiService();
      final response = await apiService.get('/admin/users');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200) {
          final List<dynamic> usersData = data['users'];
          _users = usersData.map((json) => AdminUserInfo.fromJson(json)).toList();
          debugPrint('开发者服务: 获取用户列表成功，共${_users.length}个用户');
        } else {
          _error = data['message'] ?? '获取用户列表失败';
        }
      } else {
        _error = '获取用户列表失败';
      }
    } catch (e) {
      _error = '获取用户列表失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 分析会话数据
  Future<void> analyzeConversations({
    List<String>? selectedUserIds,
    List<String>? selectedAppKeys,
    DateTime? startTime,
    DateTime? endTime,
    String? keyword,
    String? feedback,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      debugPrint('开发者服务: 开始会话分析 - 用户: ${selectedUserIds?.length ?? '全部'}, 应用: ${selectedAppKeys?.length ?? '全部'}');

      final difyService = DifyService();
      final List<ConversationAnalysis> analysisResults = [];

      // 从后端API获取AI模块列表
      List<String> aiModules = [];
      
      try {
        final apiService = ApiService();
        final response = await apiService.get('/ai_modules');
        
        if (response.statusCode == 200) {
          final data = response.data;
          if (data['code'] == 200) {
            final apiKeysList = List<String>.from(data['ai_modules']);
            aiModules = apiKeysList;
          }
        }
      } catch (e) {
        // 静默处理错误
      }
      
      for (final user in _users) {
        // 如果指定了用户ID列表，只处理列表中的用户（null表示处理所有用户）
        if (selectedUserIds != null && !selectedUserIds.contains(user.userId)) {
          continue;
        }

        for (final apiKey in aiModules) {
          // 如果指定了应用Key列表，只处理列表中的应用（null表示处理所有应用）
          if (selectedAppKeys != null && !selectedAppKeys.contains(apiKey)) {
            continue;
          }

          try {
            // 设置API密钥
            difyService.setApiKey(apiKey);
            
            // 获取应用信息
            final appInfo = await difyService.getAppInfo();
            
            // 获取用户的会话列表
            final conversations = await difyService.getConversations(
              userId: user.userId,
              limit: 100, // 获取更多会话
            );

            for (final conversation in conversations) {
              // 时间筛选（null表示不限制时间范围）
              final conversationUpdatedAt = DateTime.fromMillisecondsSinceEpoch(conversation.updatedAt * 1000);
              
              if (startTime != null && conversationUpdatedAt.isBefore(startTime)) {
                continue;
              }
              if (endTime != null && conversationUpdatedAt.isAfter(endTime)) {
                continue;
              }

              // 获取会话消息进行关键词和反馈筛选
              final messages = await difyService.getMessages(
                conversationId: conversation.id,
                userId: user.userId,
                limit: 100,
              );

              // 关键词筛选（null或空字符串表示不筛选关键词）
              if (keyword != null && keyword.isNotEmpty) {
                bool hasKeyword = false;
                for (final message in messages) {
                  if ((message.query?.toLowerCase().contains(keyword.toLowerCase()) ?? false) ||
                      (message.answer?.toLowerCase().contains(keyword.toLowerCase()) ?? false)) {
                    hasKeyword = true;
                    break;
                  }
                }
                if (!hasKeyword) {
                  continue;
                }
              }

              // 反馈筛选（null或'全部'表示不筛选反馈）
              if (feedback != null && feedback != '全部') {
                bool hasFeedback = false;
                for (final message in messages) {
                  if (message.feedback != null) {
                    if (feedback == '点赞' && message.feedback!.rating == 'like') {
                      hasFeedback = true;
                      break;
                    } else if (feedback == '点踩' && message.feedback!.rating == 'dislike') {
                      hasFeedback = true;
                      break;
                    }
                  }
                }
                if (!hasFeedback) {
                  continue;
                }
              }

              // 统计反馈数量
              int likeCount = 0;
              int dislikeCount = 0;
              for (final message in messages) {
                if (message.feedback != null) {
                  if (message.feedback!.rating == 'like') {
                    likeCount++;
                  } else if (message.feedback!.rating == 'dislike') {
                    dislikeCount++;
                  }
                }
              }

              // 创建会话分析结果，保存消息数据
              final analysis = ConversationAnalysis(
                conversationId: conversation.id,
                conversationName: conversation.name,
                userId: user.userId,
                userAccount: user.account,
                appName: appInfo.name,
                appKey: apiKey,
                createdAt: DateTime.fromMillisecondsSinceEpoch(conversation.createdAt * 1000),
                updatedAt: DateTime.fromMillisecondsSinceEpoch(conversation.updatedAt * 1000),
                messageCount: messages.length,
                likeCount: likeCount,
                dislikeCount: dislikeCount,
                messages: messages, // 保存消息数据
              );

              analysisResults.add(analysis);
            }
          } catch (e) {
            // 继续处理其他用户和应用
          }
        }
      }

      _conversations = analysisResults;
      debugPrint('开发者服务: 会话分析完成，共${_conversations.length}个会话');
    } catch (e) {
      _error = '会话分析失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 清空分析结果
  void clearAnalysis() {
    _conversations.clear();
    _error = null;
    notifyListeners();
  }

  /// 导出对话数据
  Future<void> exportConversations({
    Map<String, dynamic>? filterParams,
    Function(int)? onProgress,
  }) async {
    try {
      if (_conversations.isEmpty) {
        throw Exception('没有可导出的会话数据');
      }

      // 按用户分组会话
      final Map<String, List<ConversationAnalysis>> userConversations = {};
      for (final conversation in _conversations) {
        if (!userConversations.containsKey(conversation.userAccount)) {
          userConversations[conversation.userAccount] = [];
        }
        userConversations[conversation.userAccount]!.add(conversation);
      }

      if (kIsWeb) {
        // Web环境：直接在内存中处理文件
        await _exportForWeb(userConversations, filterParams, onProgress);
      } else {
        // 移动端：使用文件系统
        await _exportForMobile(userConversations, filterParams, onProgress);
      }
    } catch (e) {
      rethrow;
    }
  }


  /// 生成CSV内容（使用保存的消息数据）
  String _generateCsvContent(List<ConversationAnalysis> conversations) {
    final StringBuffer csvBuffer = StringBuffer();
    
    // CSV头部 - 使用UTF-8 BOM确保中文正确显示
    csvBuffer.write('\uFEFF'); // UTF-8 BOM
    csvBuffer.writeln('conversation_id,app_key,app_name,username,query,answer,created_at,feedback');

    for (final conversation in conversations) {
      // 为每条消息生成CSV行
      for (final message in conversation.messages) {
        final conversationId = _escapeCsvField(conversation.conversationId);
        final appKey = _escapeCsvField(conversation.appKey);
        final appName = _escapeCsvField(conversation.appName);
        final username = _escapeCsvField(conversation.userAccount);
        final query = _escapeCsvField(message.query ?? '');
        final answer = _escapeCsvField(message.answer ?? '');
        final createdAt = _escapeCsvField(
          DateTime.fromMillisecondsSinceEpoch(message.createdAt * 1000).toIso8601String()
        );
        final feedback = _escapeCsvField(message.feedback?.rating ?? '');

        csvBuffer.writeln('$conversationId,$appKey,$appName,$username,$query,$answer,$createdAt,$feedback');
      }
    }

    return csvBuffer.toString();
  }

  /// 转义CSV字段
  String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// 创建ZIP文件
  Future<void> _createZipFile(List<File> csvFiles, File zipFile) async {
    final archive = Archive();
    
    for (final csvFile in csvFiles) {
      final fileData = await csvFile.readAsBytes();
      final archiveFile = ArchiveFile(
        csvFile.path.split('/').last, // 只保留文件名
        fileData.length,
        fileData,
      );
      archive.addFile(archiveFile);
    }

    final zipData = ZipEncoder().encode(archive);
    if (zipData != null) {
      await zipFile.writeAsBytes(zipData);
    }
  }

  /// Web环境导出
  Future<void> _exportForWeb(
    Map<String, List<ConversationAnalysis>> userConversations,
    Map<String, dynamic>? filterParams,
    Function(int)? onProgress,
  ) async {
    final List<Map<String, String>> csvFiles = [];
    int totalUsers = userConversations.length;
    int processedUsers = 0;

    // 为每个用户生成CSV内容
    for (final entry in userConversations.entries) {
      final username = entry.key;
      final conversations = entry.value;
      

      // 生成文件名
      final startTime = filterParams?['startTime'] as DateTime?;
      final endTime = filterParams?['endTime'] as DateTime?;
      final startTimeStr = startTime != null ? 
        '${startTime.year}${startTime.month.toString().padLeft(2, '0')}${startTime.day.toString().padLeft(2, '0')}' : 
        'all';
      final endTimeStr = endTime != null ? 
        '${endTime.year}${endTime.month.toString().padLeft(2, '0')}${endTime.day.toString().padLeft(2, '0')}' : 
        'all';
      
      final fileName = '$username-$startTimeStr-$endTimeStr.csv';

      // 生成CSV内容 - 使用保存的消息数据
      final csvContent = _generateCsvContent(conversations);
      csvFiles.add({
        'name': fileName,
        'content': csvContent,
      });

      processedUsers++;
      final progress = (processedUsers / totalUsers * 100).round();
      onProgress?.call(progress);
      
    }

    // 创建ZIP文件
    await _createZipForWeb(csvFiles);
  }

  /// 移动端导出
  Future<void> _exportForMobile(
    Map<String, List<ConversationAnalysis>> userConversations,
    Map<String, dynamic>? filterParams,
    Function(int)? onProgress,
  ) async {
    // 创建临时目录
    final tempDir = await getTemporaryDirectory();
    final exportDir = Directory('${tempDir.path}/conversation_export');
    if (await exportDir.exists()) {
      await exportDir.delete(recursive: true);
    }
    await exportDir.create();

    final List<File> csvFiles = [];
    int totalUsers = userConversations.length;
    int processedUsers = 0;

    // 为每个用户生成CSV文件
    for (final entry in userConversations.entries) {
      final username = entry.key;
      final conversations = entry.value;
      

      // 生成文件名
      final startTime = filterParams?['startTime'] as DateTime?;
      final endTime = filterParams?['endTime'] as DateTime?;
      final startTimeStr = startTime != null ? 
        '${startTime.year}${startTime.month.toString().padLeft(2, '0')}${startTime.day.toString().padLeft(2, '0')}' : 
        'all';
      final endTimeStr = endTime != null ? 
        '${endTime.year}${endTime.month.toString().padLeft(2, '0')}${endTime.day.toString().padLeft(2, '0')}' : 
        'all';
      
      final fileName = '$username-$startTimeStr-$endTimeStr.csv';
      final csvFile = File('${exportDir.path}/$fileName');

      // 生成CSV内容 - 使用保存的消息数据
      final csvContent = _generateCsvContent(conversations);
      await csvFile.writeAsString(csvContent, encoding: utf8);
      csvFiles.add(csvFile);

      processedUsers++;
      final progress = (processedUsers / totalUsers * 100).round();
      onProgress?.call(progress);
      
      debugPrint('开发者服务: 用户 $username 的CSV文件已生成: $fileName');
    }

    // 创建ZIP文件
    final zipFile = File('${exportDir.path}/conversations_export.zip');
    await _createZipFile(csvFiles, zipFile);

    // 下载ZIP文件
    await _downloadFile(zipFile);

    // 清理临时文件
    await exportDir.delete(recursive: true);
  }

  /// 为Web环境创建ZIP文件
  Future<void> _createZipForWeb(List<Map<String, String>> csvFiles) async {
    final archive = Archive();
    
    for (final csvFile in csvFiles) {
      // 确保使用UTF-8编码
      final fileData = utf8.encode(csvFile['content']!);
      final archiveFile = ArchiveFile(
        csvFile['name']!,
        fileData.length,
        fileData,
      );
      archive.addFile(archiveFile);
    }

    final zipData = ZipEncoder().encode(archive);
    if (zipData != null) {
      // 直接下载ZIP文件
      final blob = html.Blob([zipData], 'application/zip');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', 'conversations_export.zip')
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  /// 下载文件
  Future<void> _downloadFile(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final fileName = file.path.split('/').last;
      
      // 在Web环境中，使用浏览器下载
      if (kIsWeb) {
        // 导入dart:html用于Web环境
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        // 在移动端，使用file_picker保存文件
        final result = await FilePicker.platform.saveFile(
          dialogTitle: '保存对话数据',
          fileName: fileName,
        );
        
        if (result != null) {
          // 将文件复制到用户选择的位置
          final targetFile = File(result);
          await targetFile.writeAsBytes(bytes);
        } else {
          throw Exception('用户取消了文件保存');
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}

/// 管理员用户信息模型
class AdminUserInfo {
  final String userId;
  final String account;
  final String? experimentId;
  final String? groupCode;

  AdminUserInfo({
    required this.userId,
    required this.account,
    this.experimentId,
    this.groupCode,
  });

  factory AdminUserInfo.fromJson(Map<String, dynamic> json) {
    return AdminUserInfo(
      userId: json['user_id'] ?? '',
      account: json['account'] ?? '',
      experimentId: json['experiment_id'],
      groupCode: json['group_code'],
    );
  }
}

/// 会话分析模型
class ConversationAnalysis {
  final String conversationId;
  final String conversationName;
  final String userId;
  final String userAccount;
  final String appName;
  final String appKey;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messageCount;
  final int likeCount;
  final int dislikeCount;
  final List<ChatMessage> messages; // 添加消息数据

  ConversationAnalysis({
    required this.conversationId,
    required this.conversationName,
    required this.userId,
    required this.userAccount,
    required this.appName,
    required this.appKey,
    required this.createdAt,
    required this.updatedAt,
    required this.messageCount,
    required this.likeCount,
    required this.dislikeCount,
    required this.messages, // 添加消息数据
  });
}
