import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import '../models/dify_models.dart';
import '../utils/product_type_mapper.dart';
import '../services/chat_service.dart';
import '../services/insurance_service.dart';
import '../services/insurance_list_service.dart';

/// 保单分析聊天服务
/// 用于处理用户保单分析功能
class AnalysisChatService {
  /// 从环境变量获取保单分析聊天API Key
  String? get analysisChatApiKey {
    final key = dotenv.env['CHAT_WITH_INSURANCE_LIST_KEY'];
    debugPrint('===> AnalysisChatService: 获取保单分析API Key: ${key?.isNotEmpty == true ? '已配置' : '未配置'}');
    return key;
  }

  /// 查找保单分析AI模块
  AIModule? findAnalysisChatModule(BuildContext context) {
    debugPrint('===> AnalysisChatService: 开始查找保单分析AI模块');
    
    final chatService = Provider.of<ChatService>(context, listen: false);
    final apiKey = analysisChatApiKey;
    
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('===> AnalysisChatService: 保单分析API Key未配置');
      return null;
    }
    
    // 在AI模块列表中查找匹配的模块
    final modules = chatService.aiModules;
    for (final module in modules) {
      if (module.apiKey == apiKey) {
        debugPrint('===> AnalysisChatService: 找到匹配的AI模块: ${module.appInfo?.name}');
        return module;
      }
    }
    
    debugPrint('===> AnalysisChatService: 未找到匹配的AI模块');
    return null;
  }

  /// 启动保单分析对话
  Future<void> startAnalysisChat(BuildContext context, String userId) async {
    debugPrint('===> AnalysisChatService: 开始启动保单分析对话');
    
    try {
      // 1. 查找保单分析AI模块
      final module = findAnalysisChatModule(context);
      if (module == null) {
        _showErrorDialog(context, '未找到保单分析AI模块，请检查配置');
        return;
      }
      
      // 2. 切换到对应的AI模块
      final chatService = Provider.of<ChatService>(context, listen: false);
      await chatService.selectAIModule(module);
      debugPrint('===> AnalysisChatService: 成功切换到AI模块: ${module.appInfo?.name}');
      
      // 3. 获取用户保单信息
      final insuranceListService = Provider.of<InsuranceListService>(context, listen: false);
      final insuranceService = Provider.of<InsuranceService>(context, listen: false);
      
      // 确保保单列表已加载
      if (insuranceListService.insuranceList.isEmpty) {
        await insuranceListService.getUserInsuranceList(userId);
      }
      
      if (insuranceListService.insuranceList.isEmpty) {
        _showErrorDialog(context, '您还没有保单，请先添加保险产品');
        return;
      }
      
      // 4. 获取所有保险产品的详细信息
      final productInfoList = <String>[];
      for (final item in insuranceListService.insuranceList) {
        try {
          await insuranceService.getProductInfo(
            productId: item.productId,
            productType: item.productType,
          );
          
          final productInfo = insuranceService.productInfo;
          if (productInfo.isNotEmpty) {
            final formattedInfo = _formatProductInfo(productInfo, item.productType);
            productInfoList.add(formattedInfo);
          }
        } catch (e) {
          debugPrint('===> AnalysisChatService: 获取产品信息失败: $e');
          // 继续处理其他产品，不因为单个产品失败而中断整个流程
        }
      }
      
      if (productInfoList.isEmpty) {
        _showErrorDialog(context, '获取保单信息失败，请重试');
        return;
      }
      
      // 5. 格式化所有保单信息
      final allProductInfo = _formatAllProductsInfo(productInfoList);
      debugPrint('===> AnalysisChatService: 保单信息格式化完成，总长度: ${allProductInfo.length}');
      
      // 6. 创建新对话
      await chatService.createNewConversation();
      final conversationId = chatService.currentConversation?.id;
      
      debugPrint('===> AnalysisChatService: 创建新对话成功，ID: $conversationId');
      
      // 7. 跳转到对话页面
      const initialQuestion = '你好，我想分析保单';
      
      final routeArgs = {
        'conversationId': conversationId,
        'initialQuestion': initialQuestion,
        'productInfo': allProductInfo,
      };
      
      debugPrint('===> AnalysisChatService: 准备跳转到对话页面');
      
      // 延迟确保Dialog完全关闭
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 跳转到首页的对话标签页，而不是独立的对话页面
      Navigator.pushNamed(
        context,
        '/home',
        arguments: {
          'conversationId': routeArgs['conversationId'],
          'initialTabIndex': 0, // 对话页面的索引
          'initialQuestion': routeArgs['initialQuestion'],
          'productInfo': routeArgs['productInfo'],
        },
      );
      
    } catch (e) {
      debugPrint('===> AnalysisChatService: 启动保单分析对话失败: $e');
      _showErrorDialog(context, '启动保单分析对话失败: $e');
    }
  }

  /// 格式化单个产品信息
  String _formatProductInfo(Map<String, dynamic> productInfo, String productType) {
    final buffer = StringBuffer();
    
    // 添加产品类型
    buffer.writeln('产品类型: ${ProductTypeMapper.toChineseName(productType)}');
    
    // 添加基本信息
    if (productInfo['product_name'] != null) {
      buffer.writeln('产品名称: ${productInfo['product_name']}');
    }
    if (productInfo['company_name'] != null) {
      buffer.writeln('保险公司: ${productInfo['company_name']}');
    }
    if (productInfo['premium'] != null) {
      buffer.writeln('保费: ${productInfo['premium']}');
    }
    if (productInfo['total_score'] != null) {
      buffer.writeln('总评分: ${productInfo['total_score']}');
    }
    
    // 添加其他相关信息（根据不同产品类型可能有不同字段）
    productInfo.forEach((key, value) {
      if (key != 'product_name' && key != 'company_name' && 
          key != 'premium' && key != 'total_score' && 
          value != null && value.toString().isNotEmpty) {
        buffer.writeln('$key: $value');
      }
    });
    
    return buffer.toString();
  }

  /// 格式化所有保单信息
  String _formatAllProductsInfo(List<String> productInfoList) {
    final buffer = StringBuffer();
    
    buffer.writeln('用户保单信息汇总：');
    buffer.writeln('====================');
    buffer.writeln('总计保单数量: ${productInfoList.length}');
    buffer.writeln('');
    
    for (int i = 0; i < productInfoList.length; i++) {
      buffer.writeln('保单 ${i + 1}:');
      buffer.writeln('-------------------');
      buffer.writeln(productInfoList[i]);
      buffer.writeln('');
    }
    
    return buffer.toString();
  }

  /// 显示错误对话框
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

/// 用户保单分析数据模型
class AnalysisData {
  final String userId;
  final List<AnalysisProduct> products;
  final DateTime analysisTime;

  AnalysisData({
    required this.userId,
    required this.products,
    required this.analysisTime,
  });

  /// 转换为格式化的文本信息
  String toFormattedText() {
    final buffer = StringBuffer();
    
    buffer.writeln('用户保单分析数据：');
    buffer.writeln('用户ID: $userId');
    buffer.writeln('分析时间: ${analysisTime.toIso8601String()}');
    buffer.writeln('保单总数: ${products.length}');
    buffer.writeln('');
    
    for (int i = 0; i < products.length; i++) {
      buffer.writeln('保单 ${i + 1}:');
      buffer.writeln(products[i].toFormattedText());
      buffer.writeln('');
    }
    
    return buffer.toString();
  }
}

/// 分析产品数据模型
class AnalysisProduct {
  final String productId;
  final String productType;
  final String productName;
  final String companyName;
  final Map<String, dynamic> details;

  AnalysisProduct({
    required this.productId,
    required this.productType,
    required this.productName,
    required this.companyName,
    required this.details,
  });

  /// 转换为格式化的文本信息
  String toFormattedText() {
    final buffer = StringBuffer();
    
    buffer.writeln('产品ID: $productId');
    buffer.writeln('产品类型: ${ProductTypeMapper.toChineseName(productType)}');
    buffer.writeln('产品名称: $productName');
    buffer.writeln('保险公司: $companyName');
    
    details.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        buffer.writeln('$key: $value');
      }
    });
    
    return buffer.toString();
  }
} 