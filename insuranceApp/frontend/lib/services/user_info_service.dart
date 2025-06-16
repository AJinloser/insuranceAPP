import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/user_info.dart';
import 'auth_service.dart';

class UserInfoService extends ChangeNotifier {
  UserInfo? _userInfo;
  bool _isLoading = false;
  String? _error;

  UserInfo? get userInfo => _userInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final AuthService _authService;

  UserInfoService(this._authService);

  String get _baseUrl {
    final backendUrl = dotenv.env['BACKEND_URL'] ?? 'http://localhost:8000';
    return '$backendUrl/api/v1';
  }

  Map<String, String> get _headers {
    return {
      'Content-Type': 'application/json',
    };
  }

  Future<void> fetchUserInfo() async {
    final userId = _authService.userId;
    if (userId == null) {
      _error = '用户未登录';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('===> 获取用户信息，user_id: $userId');
      
      final requestBody = json.encode({
        'user_id': userId,
      });
      
      debugPrint('===> 请求体: $requestBody');
      debugPrint('===> 请求URL: $_baseUrl/user_info/get');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/user_info/get'),
        headers: _headers,
        body: requestBody,
      );

      debugPrint('===> 响应状态码: ${response.statusCode}');
      debugPrint('===> 响应体: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final apiResponse = UserInfoApiResponse.fromJson(responseData);
        
        if (apiResponse.code == 200 && apiResponse.userInfo != null) {
          _userInfo = apiResponse.userInfo;
          _error = null;
          debugPrint('===> 用户信息获取成功');
        } else {
          _error = apiResponse.message;
          debugPrint('===> API返回错误: ${apiResponse.message}');
        }
      } else if (response.statusCode == 404) {
        _error = '用户不存在';
        debugPrint('===> 用户不存在错误');
      } else {
        _error = '获取用户信息失败: ${response.statusCode}';
        debugPrint('===> HTTP错误: ${response.statusCode}, body: ${response.body}');
      }
    } catch (e) {
      _error = '网络错误: $e';
      debugPrint('获取用户信息错误: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUserInfo(UserInfo userInfo) async {
    final userId = _authService.userId;
    if (userId == null) {
      _error = '用户未登录';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('===> 更新用户信息，user_id: $userId');
      
      final userInfoWithId = userInfo.copyWith(userId: userId);
      final requestBody = json.encode(userInfoWithId.toJson());
      
      debugPrint('===> 更新请求体: $requestBody');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/user_info'),
        headers: _headers,
        body: requestBody,
      );

      debugPrint('===> 更新响应状态码: ${response.statusCode}');
      debugPrint('===> 更新响应体: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['code'] == 200) {
          _userInfo = userInfo;
          _error = null;
          notifyListeners();
          debugPrint('===> 用户信息更新成功');
          return true;
        } else {
          _error = responseData['message'] ?? '更新失败';
          debugPrint('===> 更新API返回错误: ${responseData['message']}');
        }
      } else if (response.statusCode == 404) {
        _error = '用户不存在';
        debugPrint('===> 更新时用户不存在错误');
      } else {
        _error = '更新用户信息失败: ${response.statusCode}';
        debugPrint('===> 更新HTTP错误: ${response.statusCode}, body: ${response.body}');
      }
    } catch (e) {
      _error = '网络错误: $e';
      debugPrint('更新用户信息错误: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    return false;
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void reset() {
    _userInfo = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
} 