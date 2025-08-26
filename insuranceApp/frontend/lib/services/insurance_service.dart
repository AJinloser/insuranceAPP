import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/insurance_product.dart';
import 'api_service.dart';
import '../utils/error_logger.dart';

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
  String _sortBy = 'total_score';
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
      // 记录获取保险产品类型错误
      await logInsuranceError(
        message: '获取保险产品类型失败: $e',
        serviceName: 'InsuranceService',
        apiEndpoint: '/insurance_products/product_types',
        stackTrace: e.toString(),
      );
      
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
      // 记录获取保险产品字段错误
      await logInsuranceError(
        message: '获取保险产品字段失败: $e',
        serviceName: 'InsuranceService',
        apiEndpoint: '/insurance_products/product_fields',
        productType: productType,
        stackTrace: e.toString(),
      );
      
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
    String sortBy = 'total_score',
    Map<String, dynamic>? searchParams,
  }) async {
    _setLoading(true);
    _setError(null);

    // 更新当前搜索参数
    _currentProductType = productType;
    _currentPage = page;
    _limit = limit;
    _sortBy = sortBy;
    _searchParams = searchParams ?? {};

    try {
      final queryParams = {
        'product_type': productType,
        'page': page,
        'limit': limit,
        'sort_by': sortBy,
        ...(_searchParams),
      };

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
    
    // 获取新类型的字段
    await getProductFields(productType);
    
    // 搜索新类型的产品
    return await searchProducts(
      productType: productType,
      page: 1,
      limit: _limit,
      sortBy: _sortBy,
    );
  }

  /// 重置搜索条件
  Future<int> resetSearch() async {
    _searchParams.clear();
    return await searchProducts(
      productType: _currentProductType,
      page: 1,
      limit: _limit,
      sortBy: 'total_score',
    );
  }

  /// 更新搜索参数并搜索
  Future<int> updateSearchParams(Map<String, dynamic> params) async {
    _searchParams.addAll(params);
    return await searchProducts(
      productType: _currentProductType,
      page: 1,
      limit: _limit,
      sortBy: _sortBy,
      searchParams: _searchParams,
    );
  }

  /// 切换页码
  Future<int> changePage(int page) async {
    return await searchProducts(
      productType: _currentProductType,
      page: page,
      limit: _limit,
      sortBy: _sortBy,
      searchParams: _searchParams,
    );
  }

  /// 更改排序方式
  Future<int> changeSortBy(String sortBy) async {
    return await searchProducts(
      productType: _currentProductType,
      page: 1,
      limit: _limit,
      sortBy: sortBy,
      searchParams: _searchParams,
    );
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