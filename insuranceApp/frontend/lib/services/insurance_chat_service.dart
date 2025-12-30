import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import '../models/dify_models.dart';
import '../utils/product_type_mapper.dart';
import 'chat_service.dart';
import 'insurance_service.dart';

/// 保险产品对话服务
/// 专门处理与保险产品相关的对话功能
class InsuranceChatService {
  
  /// 获取保险产品对话的API密钥
  static String? get insuranceChatApiKey {
    return dotenv.env['CHAT_WITH_INSURANCE_KEY'];
  }
  
  /// 查找保险产品对话对应的AI模块
  static AIModule? findInsuranceChatModule(List<AIModule> modules) {
    final targetApiKey = insuranceChatApiKey;
    
    if (targetApiKey == null || targetApiKey.isEmpty) {
      debugPrint('===> InsuranceChatService: 未找到CHAT_WITH_INSURANCE_KEY配置');
      return null;
    }
    
    // 查找匹配的AI模块
    for (final module in modules) {
      if (module.apiKey == targetApiKey) {
        debugPrint('===> InsuranceChatService: 找到匹配的AI模块 - ${module.appInfo?.name}');
        return module;
      }
    }
    
    debugPrint('===> InsuranceChatService: 未找到匹配的AI模块，目标API Key: ${targetApiKey.substring(0, 5)}...');
    return null;
  }
  
  /// 启动与保险产品的对话
  /// 
  /// [context] - 上下文，用于获取服务和导航
  /// [productId] - 保险产品ID
  /// [productType] - 保险产品类型
  /// [productName] - 保险产品名称（用于显示）
  /// 
  /// 返回Map包含路由参数，如果失败返回null
  static Future<Map<String, dynamic>?> startInsuranceChat(
    BuildContext context, {
    required String productId,
    required String productType,
    String? productName,
  }) async {
    debugPrint('===> InsuranceChatService: 开始启动保险产品对话');
    debugPrint('===> 产品ID: $productId, 产品类型: $productType, 产品名称: $productName');
    
    try {
      // 获取聊天服务
      // debugPrint('===> InsuranceChatService: 开始获取聊天服务');
      final chatService = Provider.of<ChatService>(context, listen: false);
      // debugPrint('===> InsuranceChatService: 聊天服务获取成功');
      
      // 查找保险产品对话模块
      // debugPrint('===> InsuranceChatService: 开始查找AI模块');
      final targetModule = findInsuranceChatModule(chatService.aiModules);
      
      if (targetModule == null) {
        // debugPrint('===> InsuranceChatService: 未找到目标模块');
        throw Exception('未找到保险产品对话模块');
      }
      
      // debugPrint('===> InsuranceChatService: 找到目标模块，开始切换');
      // 切换到保险产品对话模块
      await chatService.selectAIModule(targetModule);
      // debugPrint('===> InsuranceChatService: 模块切换完成');
      
      // 获取保险产品详细信息
      // debugPrint('===> InsuranceChatService: 开始获取产品信息');
      final productInfo = await _getProductInfo(context, productId, productType);
      
      if (productInfo == null) {
        // debugPrint('===> InsuranceChatService: 产品信息获取失败');
        throw Exception('无法获取保险产品信息');
      }
      // debugPrint('===> InsuranceChatService: 产品信息获取成功');
      
      // 创建新对话
      // debugPrint('===> InsuranceChatService: 开始创建新对话');
      await chatService.createNewConversation();
      // debugPrint('===> InsuranceChatService: 新对话创建完成');
      
      // 构造初始消息
      final initialQuery = "你好，我想了解这个保险产品";
      final productInfoText = _formatProductInfo(productInfo, productType);
      
      // debugPrint('===> InsuranceChatService: 准备返回路由参数');
      // debugPrint('===> 初始问题: $initialQuery');
      // debugPrint('===> 产品信息长度: ${productInfoText.length}');
      // debugPrint('===> 当前对话ID: ${chatService.currentConversation?.id}');
      
      // 返回路由参数，让调用者进行跳转
      return {
        'conversationId': chatService.currentConversation?.id,
        'initialQuestion': initialQuery,
        'productInfo': productInfoText,
      };
      
    } catch (e) {
      debugPrint('===> InsuranceChatService: 启动对话失败: $e');
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
      debugPrint('===> InsuranceChatService: 获取产品信息失败: $e');
      return null;
    }
  }
  
  /// 格式化保险产品信息为文本
  static String _formatProductInfo(Map<String, dynamic> productInfo, String productType) {
    final buffer = StringBuffer();
    
    // 添加产品类型
    buffer.writeln('保险产品类型: ${ProductTypeMapper.toChineseName(productType)}');
    
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