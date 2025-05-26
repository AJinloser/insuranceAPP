import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'insurance_product.g.dart';

/// 保险产品基本信息模型
@JsonSerializable()
class InsuranceProduct {
  final int? productId;
  final String? productName;
  final String? companyName;
  final String? insuranceType;
  final dynamic premium;
  final double? totalScore;
  final dynamic coverageAmount;
  final String? coveragePeriod;
  final dynamic coverageContent;
  final String? productType;
  final Map<String, dynamic>? additionalData;

  InsuranceProduct({
    this.productId,
    this.productName,
    this.companyName,
    this.insuranceType,
    this.premium,
    this.totalScore,
    this.coverageAmount,
    this.coveragePeriod,
    this.coverageContent,
    this.productType,
    this.additionalData,
  });

  /// 从JSON构造函数
  factory InsuranceProduct.fromJson(Map<String, dynamic> json) {
    // 提取已知字段
    final Map<String, dynamic> additionalData = Map.from(json);
    
    // 标准化字段名
    final normalizedJson = _normalizeFieldNames(json);
    
    // 移除基本字段，保留额外数据
    final basicFields = [
      'product_id', 'productId',
      'product_name', 'productName',
      'company_name', 'companyName',
      'insurance_type', 'insuranceType',
      'premium',
      'total_score', 'totalScore',
      'coverage_amount', 'coverageAmount',
      'coverage_period', 'coveragePeriod',
      'coverage_content', 'coverageContent',
      'product_type', 'productType',
      // 中文字段名
      '产品名', '公司', '保费', '保额', '重点', '一句话概括',
    ];
    
    basicFields.forEach((field) => additionalData.remove(field));
    
    return InsuranceProduct(
      productId: normalizedJson['productId'],
      productName: normalizedJson['productName'],
      companyName: normalizedJson['companyName'],
      insuranceType: normalizedJson['insuranceType'],
      premium: normalizedJson['premium'],
      totalScore: _parseScore(normalizedJson['totalScore']),
      coverageAmount: normalizedJson['coverageAmount'],
      coveragePeriod: normalizedJson['coveragePeriod'],
      coverageContent: normalizedJson['coverageContent'],
      productType: normalizedJson['productType'],
      additionalData: additionalData,
    );
  }

  /// 标准化字段名，处理不同格式的JSON
  static Map<String, dynamic> _normalizeFieldNames(Map<String, dynamic> json) {
    final result = <String, dynamic>{};
    
    // 复制原始数据
    result.addAll(json);
    
    // 标准化字段映射
    final fieldMappings = {
      // 标准英文字段映射
      'product_id': 'productId',
      'product_name': 'productName',
      'company_name': 'companyName',
      'insurance_type': 'insuranceType',
      'coverage_amount': 'coverageAmount',
      'coverage_period': 'coveragePeriod',
      'coverage_content': 'coverageContent',
      'product_type': 'productType',
      'total_score': 'totalScore',
      
      // 中文字段映射
      '产品名': 'productName',
      '公司': 'companyName',
      '保费': 'premium',
      '保额': 'coverageAmount',
      '重点': 'coverageContent',
      '一句话概括': 'description',
      
      // 其他可能的映射
      'name': 'productName',
      'company': 'companyName',
      'price': 'premium',
      'amount': 'coverageAmount',
      'coverage': 'coverageContent',
      'description': 'description',
    };
    
    // 应用映射
    fieldMappings.forEach((originalKey, normalizedKey) {
      if (json.containsKey(originalKey)) {
        result[normalizedKey] = json[originalKey];
      }
    });
    
    // 特殊处理：重点字段作为保障内容
    if (json.containsKey('重点') && json['重点'] is Map) {
      result['coverageContent'] = json['重点'];
    }
    
    // 调试输出
    print('标准化后的保险产品数据: $result');
    
    return result;
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'product_id': productId,
      'product_name': productName,
      'company_name': companyName,
      'insurance_type': insuranceType,
      'premium': premium,
      'total_score': totalScore,
      'coverage_amount': coverageAmount,
      'coverage_period': coveragePeriod,
      'coverage_content': coverageContent,
      'product_type': productType,
    };
    
    if (additionalData != null) {
      data.addAll(additionalData!);
    }
    
    return data;
  }
  
  /// 从Markdown JSON内容提取保险产品
  static List<InsuranceProduct> fromMarkdown(String markdown) {
    // 查找所有的JSON代码块
    final RegExp jsonBlockRegex = RegExp(r'```json\s*([\s\S]*?)\s*```');
    final matches = jsonBlockRegex.allMatches(markdown);
    
    final List<InsuranceProduct> products = [];
    
    for (final match in matches) {
      try {
        final String jsonContent = match.group(1)!;
        print('解析保险产品JSON: $jsonContent');
        
        // 尝试解析JSON
        final dynamic parsed = json.decode(jsonContent);
        
        if (parsed is List) {
          // 处理JSON数组
          for (final item in parsed) {
            if (item is Map<String, dynamic>) {
              products.add(InsuranceProduct.fromJson(item));
            }
          }
        } else if (parsed is Map<String, dynamic>) {
          // 处理单个JSON对象
          products.add(InsuranceProduct.fromJson(parsed));
        }
      } catch (e) {
        print('解析保险产品JSON失败: $e');
      }
    }
    
    return products;
  }
  
  /// 解析评分，处理不同的数值格式
  static double? _parseScore(dynamic score) {
    if (score == null) return null;
    if (score is double) return score;
    if (score is int) return score.toDouble();
    if (score is String) {
      try {
        return double.parse(score);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
  
  /// 获取保费的字符串表示
  String getPremiumDisplay() {
    if (premium == null) return '询价';
    
    if (premium is Map<String, dynamic>) {
      if (premium.containsKey('amount')) {
        final amount = premium['amount'];
        final unit = premium['unit'] ?? 'CNY';
        return '¥ ${amount.toString()} ${unit != 'CNY' ? unit : ''}';
      }
    }
    
    return '¥ ${premium.toString()}';
  }
  
  /// 获取保额的字符串表示
  String getCoverageAmountDisplay() {
    if (coverageAmount == null) return '详询';
    
    if (coverageAmount is Map<String, dynamic>) {
      if (coverageAmount.containsKey('amount')) {
        final amount = coverageAmount['amount'];
        final unit = coverageAmount['unit'] ?? 'CNY';
        return '¥ ${amount.toString()} ${unit != 'CNY' ? unit : ''}';
      }
    }
    
    return '¥ ${coverageAmount.toString()}';
  }
  
  /// 获取格式化的评分
  String getScoreDisplay() {
    if (totalScore == null) return '-';
    return totalScore!.toStringAsFixed(1);
  }
  
  /// 获取产品描述
  String? getDescription() {
    // 先检查additionalData中是否有description或一句话概括
    if (additionalData != null) {
      if (additionalData!.containsKey('description')) {
        return additionalData!['description'] as String?;
      }
      if (additionalData!.containsKey('一句话概括')) {
        return additionalData!['一句话概括'] as String?;
      }
    }
    return null;
  }
  
  /// 获取保障内容的摘要
  List<String> getCoverageHighlights() {
    final List<String> highlights = [];
    
    // 处理coverageContent
    if (coverageContent != null) {
      if (coverageContent is Map<String, dynamic>) {
        // 处理新格式中的重点字段
        if (coverageContent.containsKey('保障范围')) {
          highlights.add('保障: ${coverageContent['保障范围']}');
        }
        if (coverageContent.containsKey('理赔服务')) {
          highlights.add('理赔: ${coverageContent['理赔服务']}');
        }
        if (coverageContent.containsKey('增值服务')) {
          highlights.add('增值: ${coverageContent['增值服务']}');
        }
      } else if (coverageContent is String) {
        highlights.add(coverageContent);
      }
    }
    
    // 如果没有提取到任何内容，返回空列表
    return highlights;
  }
} 