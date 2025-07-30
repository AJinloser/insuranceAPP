import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/dify_service.dart';
import '../services/insurance_service.dart';
import '../services/chat_service.dart';
import '../models/insurance_product.dart';

/// 保险产品匹配结果
class InsuranceProductMatch {
  final InsuranceProduct product;
  final String productType;
  final String originalName;

  InsuranceProductMatch({
    required this.product,
    required this.productType,
    required this.originalName,
  });
}

/// 快速构筑保险方案服务
class QuickInsuranceBuildService extends ChangeNotifier {
  final DifyService _difyService = DifyService();
  final InsuranceService _insuranceService = InsuranceService();
  final ChatService _chatService = ChatService();
  
  bool _isLoading = false;
  String? _error;
  String _aiResponse = '';
  List<InsuranceProductMatch> _recommendedProducts = [];
  String? _conversationId;
  String? _quickInsuranceKey;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get aiResponse => _aiResponse;
  List<InsuranceProductMatch> get recommendedProducts => _recommendedProducts;

  /// 生成快速保险方案
  Future<void> generateQuickInsurancePlan() async {
    _setLoading(true);
    _setError(null);

    try {
      // 获取快速构筑API Key
      _quickInsuranceKey = dotenv.env['QUICK_INSURANCE_KEY'];
      if (_quickInsuranceKey == null || _quickInsuranceKey!.isEmpty) {
        throw Exception('未配置快速构筑AI模块密钥');
      }

      // 设置API Key
      _difyService.setApiKey(_quickInsuranceKey!);

      // 获取用户ID
      final userId = _chatService.userId;
      
      // 发送消息给AI
      final chatMessage = await _difyService.sendMessage(
        query: '请根据当前的个人信息为我进行保险方案的规划和推荐',
        userId: userId,
      );

      // 保存会话ID和AI响应
      _conversationId = chatMessage.conversationId;
      _aiResponse = chatMessage.answer ?? '';

      // 解析AI响应中的保险产品名称并搜索
      await _parseAndSearchProducts(_aiResponse);

    } catch (e) {
      debugPrint('生成保险方案失败: $e');
      _setError('生成保险方案失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 解析AI响应并搜索保险产品
  Future<void> _parseAndSearchProducts(String aiResponse) async {
    try {
      // 从AI响应中提取可能的保险产品名称
      final productNames = _extractProductNames(aiResponse);
      
      if (productNames.isEmpty) {
        debugPrint('未从AI响应中找到保险产品名称');
        return;
      }

      debugPrint('提取到的产品名称: $productNames');

      // 获取所有保险产品类型
      await _insuranceService.getProductTypes();
      final productTypes = _insuranceService.productTypes;

      List<InsuranceProductMatch> matches = [];

      // 为每个产品名称在所有类型中搜索
      for (final productName in productNames) {
        for (final productType in productTypes) {
          try {
            // 搜索产品
            await _insuranceService.searchProducts(
              productType: productType,
              searchParams: {'product_name': productName},
            );

            // 查找匹配的产品
            final matchingProducts = _insuranceService.products.where((product) {
              final pName = product.productName?.toLowerCase() ?? '';
              final searchName = productName.toLowerCase();
              return pName.contains(searchName) || searchName.contains(pName);
            }).toList();

            // 添加匹配的产品
            for (final product in matchingProducts) {
              matches.add(InsuranceProductMatch(
                product: product,
                productType: productType,
                originalName: productName,
              ));
            }

            // 限制结果数量
            if (matches.length >= 5) break;
          } catch (e) {
            debugPrint('搜索产品 $productName 在 $productType 中失败: $e');
          }
        }
        
        if (matches.length >= 5) break;
      }

      _recommendedProducts = matches.take(5).toList();
      debugPrint('找到 ${_recommendedProducts.length} 个匹配的产品');

    } catch (e) {
      debugPrint('解析和搜索产品失败: $e');
    }
  }

  /// 从AI响应中提取保险产品名称
  List<String> _extractProductNames(String response) {
    final productNames = <String>[];
    
    // 常见的保险产品关键词模式
    final patterns = [
      // 匹配表格中的产品名称（markdown格式）
      RegExp(r'\|[^|]*([^|]+(?:保险|险|保)(?:产品)?)[^|]*\|', caseSensitive: false),
      // 匹配列表中的产品名称
      RegExp(r'[•\-\*]\s*(.+?(?:保险|险|保)(?:产品)?)', caseSensitive: false),
      // 匹配带引号的产品名称
      RegExp(r'["""](.+?(?:保险|险|保)(?:产品)?)["""]', caseSensitive: false),
      // 匹配推荐或建议后的产品名称
      RegExp(r'(?:推荐|建议|选择)\s*(.+?(?:保险|险|保)(?:产品)?)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final matches = pattern.allMatches(response);
      for (final match in matches) {
        if (match.groupCount > 0) {
          final productName = match.group(1)?.trim();
          if (productName != null && productName.isNotEmpty) {
            // 清理产品名称
            final cleanName = _cleanProductName(productName);
            if (cleanName.isNotEmpty && !productNames.contains(cleanName)) {
              productNames.add(cleanName);
            }
          }
        }
      }
    }

    // 如果没有找到产品名称，尝试更宽泛的匹配
    if (productNames.isEmpty) {
      final fallbackPattern = RegExp(r'([^，。！？\n]{2,15}(?:保险|险|保))', caseSensitive: false);
      final matches = fallbackPattern.allMatches(response);
      for (final match in matches) {
        final productName = match.group(1)?.trim();
        if (productName != null && productName.isNotEmpty) {
          final cleanName = _cleanProductName(productName);
          if (cleanName.isNotEmpty && !productNames.contains(cleanName)) {
            productNames.add(cleanName);
          }
        }
      }
    }

    return productNames.take(10).toList(); // 限制数量
  }

  /// 清理产品名称
  String _cleanProductName(String name) {
    // 移除常见的前缀和后缀
    final cleanName = name
        .replaceAll(RegExp(r'^[•\-\*\s]+'), '') // 移除开头的列表符号
        .replaceAll(RegExp(r'[：:]\s*'), '') // 移除冒号
        .replaceAll(RegExp(r'\s*[（(].*?[）)]\s*'), '') // 移除括号内容
        .replaceAll(RegExp(r'[|｜]'), '') // 移除表格分隔符
        .trim();
    
    return cleanName;
  }

  /// 继续聊天
  Future<Map<String, dynamic>?> continueChat(BuildContext context) async {
    try {
      if (_quickInsuranceKey == null) {
        throw Exception('未找到快速构筑AI模块密钥');
      }

      // 等待ChatService初始化
      await _chatService.init();
      
      // 在AI模块列表中查找对应的模块
      final targetModule = _chatService.aiModules.firstWhere(
        (module) => module.apiKey == _quickInsuranceKey,
        orElse: () => throw Exception('未找到对应的AI模块'),
      );

      // 设置选中的模块并加载会话列表
      await _chatService.selectAIModule(targetModule, shouldLoadConversations: true);

      // 确保会话列表已加载
      await _chatService.loadConversations();

      // 验证会话是否存在于列表中
      if (_conversationId != null) {
        final conversationExists = _chatService.conversations
            .any((c) => c.id == _conversationId);
        
        if (!conversationExists) {
          debugPrint('警告: 会话 $_conversationId 不在ChatService的会话列表中');
          debugPrint('可用会话数量: ${_chatService.conversations.length}');
          
          // 如果会话不存在，尝试重新创建会话或直接创建新对话
          debugPrint('尝试创建新会话来继续对话');
          return {
            'conversationId': null, // 不传conversationId，让ConversationPage创建新会话
            'initialQuestion': '请继续我们刚才关于保险方案规划的对话',
            'productInfo': null,
          };
        }

        // 会话存在，可以安全地加载
        final conversation = _chatService.conversations.firstWhere(
          (c) => c.id == _conversationId,
        );
        await _chatService.loadConversation(conversation);
      }

      return {
        'conversationId': _conversationId,
        'initialQuestion': null,
        'productInfo': null,
      };
    } catch (e) {
      debugPrint('准备继续聊天失败: $e');
      return null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
} 