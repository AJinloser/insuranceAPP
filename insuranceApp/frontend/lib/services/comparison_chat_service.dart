import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import '../models/dify_models.dart';
import '../models/insurance_product.dart';
import 'chat_service.dart';
import 'insurance_service.dart';

/// 产品对比聊天服务
/// 专门处理保险产品对比相关的对话功能
class ComparisonChatService {
  
  /// 获取产品对比的API密钥
  static String? get comparisonChatApiKey {
    return dotenv.env['CHAT_COMPARE_KEY'];
  }
  
  /// 查找产品对比对应的AI模块
  static AIModule? findComparisonChatModule(List<AIModule> modules) {
    final targetApiKey = comparisonChatApiKey;
    
    if (targetApiKey == null || targetApiKey.isEmpty) {
      debugPrint('===> ComparisonChatService: 未找到CHAT_COMPARE_KEY配置');
      return null;
    }
    
    // 查找匹配的AI模块
    for (final module in modules) {
      if (module.apiKey == targetApiKey) {
        debugPrint('===> ComparisonChatService: 找到匹配的AI模块 - ${module.appInfo?.name}');
        return module;
      }
    }
    
    debugPrint('===> ComparisonChatService: 未找到匹配的AI模块，目标API Key: ${targetApiKey.substring(0, 5)}...');
    return null;
  }
  
  /// 启动产品对比对话
  /// 
  /// [context] - 上下文，用于获取服务和导航
  /// [products] - 要对比的产品列表（应该包含productId和productType）
  /// 
  /// 返回Map包含路由参数，如果失败返回null
  static Future<Map<String, dynamic>?> startComparisonChat(
    BuildContext context, {
    required List<ComparisonProduct> products,
  }) async {
    debugPrint('===> ComparisonChatService: 开始启动产品对比对话');
    debugPrint('===> 产品数量: ${products.length}');
    
    // 验证产品数量
    if (products.length != 2) {
      debugPrint('===> ComparisonChatService: 产品数量不正确，需要2个产品');
      throw Exception('请选择2个产品进行对比');
    }
    
    try {
      // 获取聊天服务
      final chatService = Provider.of<ChatService>(context, listen: false);
      
      // 查找产品对比模块
      final targetModule = findComparisonChatModule(chatService.aiModules);
      
      if (targetModule == null) {
        throw Exception('未找到产品对比模块');
      }
      
      // 切换到产品对比模块
      await chatService.selectAIModule(targetModule);
      
      // 获取两个产品的详细信息
      final productInfos = <Map<String, dynamic>>[];
      
      for (final product in products) {
        final productInfo = await _getProductInfo(
          context, 
          product.productId, 
          product.productType
        );
        
        if (productInfo == null) {
          throw Exception('无法获取产品信息: ${product.productName}');
        }
        
        productInfos.add(productInfo);
      }
      
      // 创建新对话
      await chatService.createNewConversation();
      
      // 构造初始消息
      final initialQuery = "你好，我想对比这两个保险产品";
      final comparisonInfo = _formatComparisonInfo(productInfos, products);
      
      debugPrint('===> ComparisonChatService: 对比信息长度: ${comparisonInfo.length}');
      
      // 返回路由参数，让调用者进行跳转
      return {
        'conversationId': chatService.currentConversation?.id,
        'initialQuestion': initialQuery,
        'productInfo': comparisonInfo,
      };
      
    } catch (e) {
      debugPrint('===> ComparisonChatService: 启动对话失败: $e');
      return null;
    }
  }
  
  /// 获取保险产品详细信息
  static Future<Map<String, dynamic>?> _getProductInfo(
    BuildContext context,
    String productId,
    String productType,
  ) async {
    try {
      final insuranceService = Provider.of<InsuranceService>(context, listen: false);
      
      // 将String类型的productId转换为int类型
      final productIdInt = int.tryParse(productId);
      if (productIdInt == null) {
        throw Exception('无效的产品ID: $productId');
      }
      
      // 调用保险产品信息API
      await insuranceService.getProductInfo(
        productId: productIdInt,
        productType: productType,
      );
      
      return insuranceService.productInfo;
      
    } catch (e) {
      debugPrint('===> ComparisonChatService: 获取产品信息失败: $e');
      return null;
    }
  }
  
  /// 格式化产品对比信息为文本
  static String _formatComparisonInfo(
    List<Map<String, dynamic>> productInfos, 
    List<ComparisonProduct> products
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln('=== 产品对比信息 ===');
    buffer.writeln('');
    
    for (int i = 0; i < productInfos.length; i++) {
      final productInfo = productInfos[i];
      final product = products[i];
      
      buffer.writeln('产品${i + 1}：');
      buffer.writeln('产品名称: ${product.productName}');
      buffer.writeln('产品类型: ${product.productType}');
      buffer.writeln('');
      
      // 遍历产品信息并格式化
      for (final entry in productInfo.entries) {
        final key = entry.key;
        final value = entry.value;
        
        // 跳过系统字段
        if (key == 'code' || key == 'message') {
          continue;
        }
        
        // 格式化字段名
        final formattedKey = _formatFieldName(key);
        
        // 格式化值
        final formattedValue = _formatValue(value);
        
        if (formattedValue.isNotEmpty) {
          buffer.writeln('$formattedKey: $formattedValue');
        }
      }
      
      buffer.writeln('');
      buffer.writeln('---');
      buffer.writeln('');
    }
    
    return buffer.toString();
  }
  
  /// 格式化字段名为中文
  static String _formatFieldName(String fieldName) {
    final Map<String, String> fieldMap = {
      'product_id': '产品ID',
      'product_name': '产品名称',
      'company_name': '保险公司',
      'insurance_type': '保险类型',
      'premium': '保费',
      'coverage_amount': '保额',
      'coverage_period': '保障期限',
      'coverage_content': '保障内容',
      'critical_illness': '重疾保障',
      'mild_illness': '轻症保障',
      'moderate_illness': '中症保障',
      'death_benefit': '身故保障',
      'medical_coverage': '医疗保障',
      'deductible': '免赔额',
      'reimbursement_ratio': '报销比例',
      'hospital_limitation': '医院限制',
      'value_added_services': '增值服务',
      'accident_death': '意外身故',
      'accident_disability': '意外伤残',
      'accident_medical': '意外医疗',
      'hospitalization_allowance': '住院津贴',
      'total_disability': '全残保障',
      'cash_value': '现金价值',
      'premium_waiver': '保费豁免',
      'other_benefits': '其他保障',
      'other_terms': '其他条款',
      'total_score': '总评分',
    };
    
    return fieldMap[fieldName] ?? fieldName;
  }
  
  /// 格式化值为字符串
  static String _formatValue(dynamic value) {
    if (value == null) return '';
    
    if (value is String) {
      return value;
    } else if (value is Map) {
      return value.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join(', ');
    } else if (value is List) {
      return value.map((item) => item.toString()).join(', ');
    } else {
      return value.toString();
    }
  }
}

/// 用于对比的产品信息
class ComparisonProduct {
  final String productId;
  final String productType;
  final String productName;
  
  ComparisonProduct({
    required this.productId,
    required this.productType,
    required this.productName,
  });
  
  /// 从InsuranceProduct创建ComparisonProduct
  factory ComparisonProduct.fromInsuranceProduct(
    InsuranceProduct product, 
    String productType
  ) {
    return ComparisonProduct(
      productId: product.productId?.toString() ?? '',
      productType: productType,
      productName: product.productName ?? '未知产品',
    );
  }
} 