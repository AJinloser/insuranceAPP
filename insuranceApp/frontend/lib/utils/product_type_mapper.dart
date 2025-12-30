/// 保险产品类型映射工具类
class ProductTypeMapper {
  // 英文到中文的映射
  static const Map<String, String> _typeMap = {
    'term_life': '定期寿险',
    'non_annuity': '非年金',
    'annuity': '年金',
    'medical': '医疗保险',
    'critical_illness': '重疾险',
  };

  // 中文到英文的映射（用于反向查找）
  static const Map<String, String> _reverseTypeMap = {
    '定期寿险': 'term_life',
    '非年金': 'non_annuity',
    '年金': 'annuity',
    '医疗保险': 'medical',
    '重疾险': 'critical_illness',
  };

  /// 将英文类型转换为中文显示
  static String toChineseName(String englishType) {
    return _typeMap[englishType] ?? englishType;
  }

  /// 将中文类型转换为英文类型（API使用）
  static String toEnglishType(String chineseName) {
    return _reverseTypeMap[chineseName] ?? chineseName;
  }

  /// 获取所有中文类型名称列表
  static List<String> getAllChineseNames(List<String> englishTypes) {
    return englishTypes.map((type) => toChineseName(type)).toList();
  }

  /// 判断是否为有效的产品类型
  static bool isValidType(String type) {
    return _typeMap.containsKey(type) || _reverseTypeMap.containsKey(type);
  }
}

