import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/insurance_product.dart';
import 'api_service.dart';
import 'insurance_service.dart';

/// 保单项目模型
class InsuranceListItem {
  final int productId;
  final String productType;
  InsuranceProduct? productDetail; // 保险产品详细信息

  InsuranceListItem({
    required this.productId,
    required this.productType,
    this.productDetail,
  });

  factory InsuranceListItem.fromJson(Map<String, dynamic> json) {
    return InsuranceListItem(
      productId: json['product_id'] ?? 0,
      productType: json['product_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_type': productType,
    };
  }
}

/// 保单服务类
class InsuranceListService extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final InsuranceService _insuranceService = InsuranceService();
  
  List<InsuranceListItem> _insuranceList = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<InsuranceListItem> get insuranceList => _insuranceList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 设置错误信息
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// 获取用户保单信息
  Future<void> getUserInsuranceList(String userId) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.get(
        '/insurance_list/get',
        queryParameters: {'user_id': userId},
      );
      
      if (response.data['code'] == 200) {
        final List<dynamic> insuranceListData = response.data['insurance_list'] ?? [];
        _insuranceList = insuranceListData
            .map((item) => InsuranceListItem.fromJson(item))
            .toList();
        
        // 获取每个保险产品的详细信息
        await _loadProductDetails();
      } else {
        _setError(response.data['message'] ?? '获取保单信息失败');
        _insuranceList = [];
      }
    } catch (e) {
      _setError('网络错误: $e');
      _insuranceList = [];
      debugPrint('获取用户保单信息失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 加载保险产品详细信息
  Future<void> _loadProductDetails() async {
    for (int i = 0; i < _insuranceList.length; i++) {
      try {
        debugPrint('开始加载产品详情: ${_insuranceList[i].productId} (${_insuranceList[i].productType})');
        
        await _insuranceService.getProductInfo(
          productId: _insuranceList[i].productId,
          productType: _insuranceList[i].productType,
        );
        
        if (_insuranceService.productInfo.isNotEmpty) {
          // 创建InsuranceProduct对象
          final productInfo = _insuranceService.productInfo;
          
          debugPrint('产品信息原始数据: $productInfo');
          
          _insuranceList[i].productDetail = InsuranceProduct(
            productId: _insuranceList[i].productId,
            productName: productInfo['product_name'],
            companyName: productInfo['company_name'],
            insuranceType: _insuranceList[i].productType,
            premium: productInfo['premium'],
            totalScore: _parseToDouble(productInfo['total_score']),
            // 根据不同产品类型设置其他字段
            coverageAmount: productInfo['coverage_amount'],
            coveragePeriod: productInfo['coverage_period']?.toString(),
            productType: _insuranceList[i].productType,
            coverageContent: productInfo['coverage_content'],
            additionalData: Map<String, dynamic>.from(productInfo),
          );
          
          debugPrint('成功创建产品详情: ${_insuranceList[i].productDetail?.productName}');
        } else {
          debugPrint('产品信息为空: ${_insuranceList[i].productId}');
        }
      } catch (e, stackTrace) {
        debugPrint('获取产品详情失败 (${_insuranceList[i].productId}): $e');
        debugPrint('错误堆栈: $stackTrace');
        
        // 即使获取详情失败，也创建一个基本的产品对象
        _insuranceList[i].productDetail = InsuranceProduct(
          productId: _insuranceList[i].productId,
          productName: '产品ID: ${_insuranceList[i].productId}',
          companyName: '未知',
          insuranceType: _insuranceList[i].productType,
          productType: _insuranceList[i].productType,
        );
      }
    }
    notifyListeners();
  }

  /// 安全地将值转换为double
  double? _parseToDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        debugPrint('无法解析double值: $value');
        return null;
      }
    }
    return null;
  }

  /// 添加保险产品到保单
  Future<bool> addInsuranceToList({
    required String userId,
    required int productId,
    required String productType,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.post(
        '/insurance_list/add',
        data: {
          'user_id': userId,
          'product_id': productId,
          'product_type': productType,
        },
      );
      
      if (response.data['code'] == 200) {
        // 重新获取保单信息
        await getUserInsuranceList(userId);
        return true;
      } else {
        _setError(response.data['message'] ?? '添加保险产品失败');
        return false;
      }
    } catch (e) {
      _setError('网络错误: $e');
      debugPrint('添加保险产品到保单失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 更新用户保单信息
  Future<bool> updateInsuranceList({
    required String userId,
    required List<InsuranceListItem> newInsuranceList,
  }) async {
    _setLoading(true);
    _setError(null);

    try {
      final response = await _apiService.post(
        '/insurance_list/update',
        data: {
          'user_id': userId,
          'insurance_list': newInsuranceList.map((item) => item.toJson()).toList(),
        },
      );
      
      if (response.data['code'] == 200) {
        // 更新本地保单信息
        _insuranceList = newInsuranceList;
        await _loadProductDetails();
        return true;
      } else {
        _setError(response.data['message'] ?? '更新保单信息失败');
        return false;
      }
    } catch (e) {
      _setError('网络错误: $e');
      debugPrint('更新用户保单信息失败: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 删除选中的保险产品
  Future<bool> deleteSelectedInsurance({
    required String userId,
    required List<int> selectedIndices,
  }) async {
    // 创建新的保单列表，移除选中的项目
    List<InsuranceListItem> newList = [];
    for (int i = 0; i < _insuranceList.length; i++) {
      if (!selectedIndices.contains(i)) {
        newList.add(_insuranceList[i]);
      }
    }

    // 更新保单
    return await updateInsuranceList(
      userId: userId,
      newInsuranceList: newList,
    );
  }

  /// 清空错误信息
  void clearError() {
    _setError(null);
  }
} 