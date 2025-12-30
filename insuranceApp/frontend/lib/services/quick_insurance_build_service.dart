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

      // 为每个完整产品名称在所有类型中搜索
      for (final productName in productNames) {
        debugPrint('搜索产品: $productName');
        
        for (final productType in productTypes) {
          try {
            // 使用完整产品名称搜索
            await _insuranceService.searchProducts(
              productType: productType,
              searchParams: {'product_name': productName},
            );

            // 查找精确匹配的产品
            final matchingProducts = _insuranceService.products.where((product) {
              return _isExactProductMatch(product.productName ?? '', productName);
            }).toList();

            debugPrint('在 $productType 中搜索 "$productName" 找到 ${matchingProducts.length} 个产品');

            // 添加匹配的产品
            for (final product in matchingProducts) {
              // 避免重复添加
              if (!matches.any((m) => m.product.productId == product.productId)) {
                matches.add(InsuranceProductMatch(
                  product: product,
                  productType: productType,
                  originalName: productName,
                ));
                debugPrint('添加匹配产品: ${product.productName}');
              }
            }

            // 如果找到匹配，跳出当前产品类型的搜索
            if (matchingProducts.isNotEmpty) break;
            
          } catch (e) {
            debugPrint('搜索产品 "$productName" 在 $productType 中失败: $e');
          }
        }
        
        // 限制结果数量
        if (matches.length >= 5) break;
      }

      _recommendedProducts = matches.take(5).toList();
      debugPrint('最终找到 ${_recommendedProducts.length} 个匹配的产品');

    } catch (e) {
      debugPrint('解析和搜索产品失败: $e');
    }
  }
  
  /// 精确产品匹配判断
  bool _isExactProductMatch(String dbProductName, String searchProductName) {
    if (dbProductName.isEmpty || searchProductName.isEmpty) return false;
    
    // 去除空格和符号进行比较
    final cleanDbName = _normalizeProductName(dbProductName);
    final cleanSearchName = _normalizeProductName(searchProductName);
    
    // 完全匹配
    if (cleanDbName == cleanSearchName) return true;
    
    // 包含关系匹配（任一方包含另一方）
    if (cleanDbName.contains(cleanSearchName) || cleanSearchName.contains(cleanDbName)) {
      return true;
    }
    
    return false;
  }
  
  /// 标准化产品名称用于匹配
  String _normalizeProductName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '') // 移除所有空格
        .replaceAll(RegExp(r'[–—\-]'), '') // 移除各种连字符
        .replaceAll(RegExp(r'[·•]'), '') // 移除分隔符
        .trim();
  }

  /// 从AI响应中提取保险产品名称
  List<String> _extractProductNames(String response) {
    final productNames = <String>[];
    
    // 专门从包含"产品名"列的表格中提取产品名称
    final lines = response.split('\n');
    int? productNameColumnIndex;
    bool inTargetTable = false;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // 跳过空行
      if (line.isEmpty) continue;
      
      // 检查是否是表格行（包含|）
      if (!line.contains('|')) {
        // 不是表格行，重置状态
        inTargetTable = false;
        productNameColumnIndex = null;
        continue;
      }
      
      // 分割表格列
      final columns = line.split('|').map((col) => col.trim()).toList();
      
      // 移除首尾空白列
      while (columns.isNotEmpty && columns.first.isEmpty) {
        columns.removeAt(0);
      }
      while (columns.isNotEmpty && columns.last.isEmpty) {
        columns.removeLast();
      }
      
      // 检查是否是包含"产品名"的表头行
      if (columns.any((col) => col.contains('产品名'))) {
        productNameColumnIndex = columns.indexWhere((col) => col.contains('产品名'));
        inTargetTable = true;
        debugPrint('找到产品名列，位置: $productNameColumnIndex');
        continue;
      }
      
      // 检查是否是分隔线（包含---）
      if (line.contains('---') || line.contains('--')) {
        continue;
      }
      
      // 如果在目标表格中且有产品名列索引，提取对应列的内容
      if (inTargetTable && productNameColumnIndex != null && productNameColumnIndex < columns.length) {
        final cellContent = columns[productNameColumnIndex].trim();
        
        if (cellContent.isNotEmpty && 
            cellContent != '产品名' && // 排除表头
            !cellContent.contains('---') && // 排除分隔线
            (cellContent.contains('保') || cellContent.contains('险'))) {
          final cleanName = _cleanProductName(cellContent);
          if (cleanName.isNotEmpty && !productNames.contains(cleanName)) {
            productNames.add(cleanName);
            debugPrint('从产品名列提取到产品: $cleanName');
          }
        }
      }
    }

    // 如果没有从产品名列提取到内容，使用备用方法
    if (productNames.isEmpty) {
      debugPrint('未从产品名列找到产品，使用备用提取方法');
      _extractFromQuotesAndStructures(response, productNames);
    }
    
    debugPrint('最终提取到的产品名称: $productNames');
    return productNames.take(10).toList(); // 限制数量
  }
  
  /// 从引号和结构化文本中提取产品名称（备用方法）
  void _extractFromQuotesAndStructures(String response, List<String> productNames) {
    // 从引号中提取产品名称（中文引号、书名号、英文引号）
    final quotePatterns = [
      RegExp(r'「([^」]+(?:保险|险|保))」', caseSensitive: false), // 「产品名」
      RegExp(r'《([^》]+(?:保险|险|保))》', caseSensitive: false), // 《产品名》
      RegExp(r'"([^"]+(?:保险|险|保))"', caseSensitive: false),   // "产品名"
      RegExp(r'『([^』]+(?:保险|险|保))』', caseSensitive: false), // 『产品名』
    ];
    
    for (final pattern in quotePatterns) {
      final matches = pattern.allMatches(response);
      for (final match in matches) {
        final productName = match.group(1)?.trim();
        if (productName != null && productName.isNotEmpty) {
          final cleanName = _cleanProductName(productName);
          if (cleanName.isNotEmpty && !productNames.contains(cleanName)) {
            productNames.add(cleanName);
            debugPrint('引号提取到产品: $cleanName');
          }
        }
      }
    }
    
    // 从结构化文本中提取（相关产品、可了解产品等）
    final structuredPatterns = [
      RegExp(r'最优推荐[：:]\s*([^，。\n]+(?:保险|险|保))', caseSensitive: false),
      RegExp(r'可投保产品[：:]\s*([^，。\n]+(?:保险|险|保))', caseSensitive: false),
      RegExp(r'推荐产品[：:]\s*([^，。\n]+(?:保险|险|保))', caseSensitive: false),
    ];
    
    for (final pattern in structuredPatterns) {
      final matches = pattern.allMatches(response);
      for (final match in matches) {
        final productName = match.group(1)?.trim();
        if (productName != null && productName.isNotEmpty) {
          final cleanName = _cleanProductName(productName);
          if (cleanName.isNotEmpty && !productNames.contains(cleanName)) {
            productNames.add(cleanName);
            debugPrint('结构化提取到产品: $cleanName');
          }
        }
      }
    }
  }

  /// 清理产品名称
  String _cleanProductName(String name) {
    // 移除常见的前缀和后缀，但保留产品名称中的重要信息
    String cleanName = name
        .replaceAll(RegExp(r'^[•\-\*\s]+'), '') // 移除开头的列表符号
        .replaceAll(RegExp(r'^[：:]\s*'), '') // 移除开头的冒号
        .replaceAll(RegExp(r'[|｜]'), '') // 移除表格分隔符
        .trim();
    
    // 移除公司名称前缀（如果存在）
    final companyPrefixes = ['众安保险', '平安健康', '平安财险', '人保财险', '太平洋保险', '中国人寿', '新华保险', '泰康保险'];
    for (final prefix in companyPrefixes) {
      if (cleanName.startsWith(prefix)) {
        cleanName = cleanName.substring(prefix.length).trim();
        break;
      }
    }
    
    // 移除一些无用的词汇，但保留括号内容（因为可能是产品版本信息）
    cleanName = cleanName
        .replaceAll(RegExp(r'^(产品|保险产品)[：:]?\s*'), '') // 移除"产品："前缀
        .replaceAll(RegExp(r'\s+(产品|保险)$'), '') // 移除末尾的"产品"
        .trim();
    
    // 如果名称太短或包含无意义内容，则过滤掉
    if (cleanName.length < 3 || 
        cleanName.length > 50 ||
        cleanName.contains('可投保') ||
        cleanName.contains('适配性') ||
        cleanName.contains('判断') ||
        cleanName.contains('用户') ||
        cleanName.contains('适合') ||
        cleanName.startsWith('**') ||
        cleanName.contains('款可以') ||
        RegExp(r'^\d+\s*\*').hasMatch(cleanName)) {
      return '';
    }
    
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