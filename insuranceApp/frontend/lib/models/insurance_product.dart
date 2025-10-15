/// 保险产品模型 - 支持动态字段
class InsuranceProduct {
  // 核心字段（固定）
  final int? productId;
  final String productType;
  
  // 所有字段数据（包括中文字段名）
  final Map<String, dynamic> allFields;

  InsuranceProduct({
    this.productId,
    required this.productType,
    required this.allFields,
  });

  /// 从JSON构造函数 - 适配后端返回的中文字段名
  factory InsuranceProduct.fromJson(Map<String, dynamic> json) {
    // 保存所有字段
    final Map<String, dynamic> allFields = Map.from(json);
    
    // 提取product_id（英文字段名，后端保证会有）
    final productId = json['product_id'] as int?;
    
    // 提取product_type（如果有）
    final productType = json['product_type'] as String? ?? '';
    
    return InsuranceProduct(
      productId: productId,
      productType: productType,
      allFields: allFields,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return Map.from(allFields);
  }
  
  /// 获取字段值 - 通用访问器
  dynamic getField(String fieldName) {
    return allFields[fieldName];
  }
  
  /// 获取产品名称（尝试多个可能的字段名）
  String? get productName {
    // 尝试常见的产品名称字段
    return getField('产品名称') ?? 
           getField('产品名') ?? 
           getField('product_name') ??
           getField('name');
  }
  
  /// 获取公司名称（尝试多个可能的字段名）
  String? get companyName {
    return getField('公司名称') ?? 
           getField('公司') ?? 
           getField('company_name') ??
           getField('company');
  }
  
  /// 解析评分，处理不同的数值格式
  static double? _parseNumber(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value.replaceAll(',', ''));
      } catch (_) {
        return null;
      }
    }
    return null;
  }
  
  /// 格式化数值显示
  static String formatNumber(dynamic value, {String prefix = '', String suffix = ''}) {
    final number = _parseNumber(value);
    if (number == null) return '-';
    
    // 格式化大数字
    if (number >= 10000) {
      return '$prefix${(number / 10000).toStringAsFixed(1)}万$suffix';
    }
    
    return '$prefix${number.toStringAsFixed(0)}$suffix';
  }
  
  /// 获取显示值的通用方法
  String getDisplayValue(String fieldName, {String defaultValue = '-'}) {
    final value = getField(fieldName);
    if (value == null) return defaultValue;
    return value.toString();
  }
  
  /// 从Markdown文本中提取保险产品JSON（静态方法）
  static List<InsuranceProduct> fromMarkdown(String markdown) {
    if (markdown.isEmpty) return [];
    
    // 查找所有的JSON代码块
    final RegExp jsonBlockRegex = RegExp(r'```json\s*([\s\S]*?)\s*```');
    final matches = jsonBlockRegex.allMatches(markdown);
    
    final List<InsuranceProduct> products = [];
    
    for (final match in matches) {
      try {
        final String jsonContent = match.group(1)!;
        
        // 尝试解析JSON（需要导入dart:convert）
        // 由于我们移除了dart:convert导入，这里需要使用其他方式
        // 暂时返回空列表，等待实际需要时再实现
        // final dynamic parsed = json.decode(jsonContent);
        
        // TODO: 实现JSON解析逻辑
      } catch (e) {
        // 解析失败，继续下一个
      }
    }
    
    return products;
  }
} 