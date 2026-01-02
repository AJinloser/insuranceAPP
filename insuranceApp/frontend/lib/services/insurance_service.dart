import 'package:flutter/foundation.dart';
import '../models/insurance_product.dart';
import 'api_service.dart';
import '../utils/product_type_mapper.dart';

/// 保险产品搜索响应模型
class InsuranceSearchResponse {
  final int code;
  final String message;
  final int pages;
  final List<InsuranceProduct> products;

  InsuranceSearchResponse({
    required this.code,
    required this.message,
    required this.pages,
    required this.products,
  });

  factory InsuranceSearchResponse.fromJson(Map<String, dynamic> json) {
    return InsuranceSearchResponse(
      code: json['code'] ?? 0,
      message: json['message'] ?? '',
      pages: json['pages'] ?? 0,
      products: (json['products'] as List?)
          ?.map((item) => InsuranceProduct.fromJson(item))
          .toList() ?? [],
    );
  }
}

/// 保险产品服务类
class InsuranceService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<String> _productTypes = [];
  List<Map<String, dynamic>> _productFields = [];
  List<InsuranceProduct> _products = [];
  Map<String, dynamic> _productInfo = {};
  
  bool _isLoading = false;
  String? _error;
  
  // 搜索参数
  String _currentProductType = '';
  int _currentPage = 1;
  int _limit = 10;
  String _sortBy = '';
  String _sortOrder = 'desc';
  Map<String, dynamic> _searchParams = {};

  // Getters
  List<String> get productTypes => _productTypes;
  List<Map<String, dynamic>> get productFields => _productFields;
  List<InsuranceProduct> get products => _products;
  Map<String, dynamic> get productInfo => _productInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentProductType => _currentProductType;
  int get currentPage => _currentPage;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;
  
  /// 获取产品类型的中文名称列表
  List<String> get productTypeChineseNames => 
      ProductTypeMapper.getAllChineseNames(_productTypes);
  
  /// 获取当前产品类型的中文名称
  String get currentProductTypeChineseName => 
      ProductTypeMapper.toChineseName(_currentProductType);

  /// 获取保险产品类型列表
  Future<void> getProductTypes() async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.get('/insurance_products/product_types');
      
      if (response.data['code'] == 200) {
        _productTypes = List<String>.from(response.data['product_types'] ?? []);
        
        // 如果当前没有选择产品类型且有可用类型，选择第一个
        if (_currentProductType.isEmpty && _productTypes.isNotEmpty) {
          _currentProductType = _productTypes.first;
        }
      } else {
        _setError(response.data['message'] ?? '获取产品类型失败');
      }
    } catch (e) {
      _setError('网络错误: $e');
      debugPrint('获取保险产品类型失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 获取保险产品类型对应字段
  Future<void> getProductFields(String productType) async {
    if (productType.isEmpty) return;

    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.get(
        '/insurance_products/product_fields',
        queryParameters: {'product_type': productType},
      );
      
      if (response.data['code'] == 200) {
        _productFields = List<Map<String, dynamic>>.from(
          response.data['fields'] ?? []
        );
      } else {
        _setError(response.data['message'] ?? '获取产品字段失败');
        _productFields = [];
      }
    } catch (e) {
      
      _setError('网络错误: $e');
      _productFields = [];
      debugPrint('获取保险产品字段失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 搜索保险产品
  Future<int> searchProducts({
    required String productType,
    int page = 1,
    int limit = 10,
    String? sortBy,
    String sortOrder = 'desc',
    Map<String, dynamic>? searchParams,
  }) async {
    _setLoading(true);
    _setError(null);

    // 更新当前搜索参数
    _currentProductType = productType;
    _currentPage = page;
    _limit = limit;
    _sortBy = sortBy ?? '';
    _sortOrder = sortOrder;
    _searchParams = searchParams ?? {};

    try {
      final queryParams = {
        'product_type': productType,
        'page': page,
        'limit': limit,
        'sort_order': sortOrder,
        ...(_searchParams),
      };
      
      // 只有当sortBy不为空时才添加
      if (sortBy != null && sortBy.isNotEmpty) {
        queryParams['sort_by'] = sortBy;
      }

      final response = await _apiService.get(
        '/insurance_products/search',
        queryParameters: queryParams,
      );
      
      if (response.data['code'] == 200) {
        final searchResponse = InsuranceSearchResponse.fromJson(response.data);
        _products = searchResponse.products;
        _setLoading(false);
        return searchResponse.pages;
      } else {
        _setError(response.data['message'] ?? '搜索失败');
        _products = [];
        _setLoading(false);
        return 0;
      }
    } catch (e) {
      _setError('网络错误: $e');
      _products = [];
      debugPrint('搜索保险产品失败: $e');
      _setLoading(false);
      return 0;
    }
  }

  /// 获取具体保险产品信息
  Future<void> getProductInfo({
    required int productId,
    required String productType,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.get(
        '/insurance_products/product_info',
        queryParameters: {
          'product_id': productId,
          'product_type': productType,
        },
      );
      
      if (response.data['code'] == 200) {
        _productInfo = Map<String, dynamic>.from(response.data);
        _productInfo.remove('code');
        _productInfo.remove('message');
      } else {
        _setError(response.data['message'] ?? '获取产品信息失败');
        _productInfo = {};
      }
    } catch (e) {
      _setError('网络错误: $e');
      _productInfo = {};
      debugPrint('获取保险产品信息失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 切换产品类型
  Future<int> switchProductType(String productType) async {
    if (productType == _currentProductType) return 0;
    
    // 清空当前搜索参数
    _searchParams.clear();
    
    // 重置排序（避免使用不存在的字段）
    _sortBy = '';
    _sortOrder = 'desc';
    
    // 获取新类型的字段
    await getProductFields(productType);
    
    // 搜索新类型的产品
    return await searchProducts(
      productType: productType,
      page: 1,
      limit: _limit,
      sortBy: null,
      sortOrder: 'desc',
    );
  }

  /// 重置搜索条件
  Future<int> resetSearch() async {
    _searchParams.clear();
    _sortBy = '';
    _sortOrder = 'desc';
    return await searchProducts(
      productType: _currentProductType,
      page: 1,
      limit: _limit,
      sortBy: null,
      sortOrder: 'desc',
    );
  }

  /// 更新搜索参数并搜索
  Future<int> updateSearchParams(Map<String, dynamic> params) async {
    _searchParams.addAll(params);
    return await searchProducts(
      productType: _currentProductType,
      page: 1,
      limit: _limit,
      sortBy: _sortBy.isEmpty ? null : _sortBy,
      searchParams: _searchParams,
    );
  }

  /// 切换页码
  Future<int> changePage(int page) async {
    return await searchProducts(
      productType: _currentProductType,
      page: page,
      limit: _limit,
      sortBy: _sortBy.isEmpty ? null : _sortBy,
      searchParams: _searchParams,
    );
  }

  /// 更改排序方式
  Future<int> changeSortBy(String? sortBy, {String sortOrder = 'desc'}) async {
    return await searchProducts(
      productType: _currentProductType,
      page: 1,
      limit: _limit,
      sortBy: sortBy,
      sortOrder: sortOrder,
      searchParams: _searchParams,
    );
  }
  
  /// 获取数值类型字段列表（用于排序和筛选）
  List<Map<String, dynamic>> getNumericFields() {
    return _productFields
        .where((field) {
          final type = field['type'].toString().toLowerCase();
          return type == 'numeric' || 
                 type == 'integer' ||
                 type == 'double' ||
                 type == 'real' ||
                 type == 'decimal' ||
                 type == 'float' ||
                 type.contains('numeric') ||
                 type.contains('int') ||
                 type.contains('decimal');
        })
        .toList();
  }
  
  /// 获取布尔类型字段列表（用于筛选）
  List<Map<String, dynamic>> getBooleanFields() {
    return _productFields
        .where((field) => 
            field['type'] == 'boolean' ||
            field['type'].toString().contains('bool'))
        .toList();
  }
  
  /// 获取文本类型字段列表（用于搜索）
  List<Map<String, dynamic>> getTextFields() {
    return _productFields
        .where((field) => 
            field['type'] == 'text' || 
            field['type'] == 'character varying' ||
            field['type'].toString().contains('varchar') ||
            field['type'].toString().contains('text'))
        .toList();
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