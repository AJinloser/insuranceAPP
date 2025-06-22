import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';

class ApiService {
  late Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // 单例模式
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  ApiService._internal() {
    // 获取IP地址 - 这里使用localhost的映射，适用于Web环境
    // 在实际部署时应根据环境配置正确的API地址
    String apiUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api/v1';
    
    // 如果是在Web环境中运行，确保使用正确的后端地址
    // 由于Flutter Web安全限制，前后端必须在同一域或配置CORS
    
    _dio = Dio(
      BaseOptions(
        baseUrl: apiUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 添加拦截器用于认证
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // 获取存储的令牌
          final token = await _secureStorage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          print('API错误: ${error.message}');
          return handler.next(error);
        },
      ),
    );
  }

  // 通用GET请求
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  // 通用POST请求
  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await _dio.post(path, data: data, queryParameters: queryParameters);
  }

  // 通用PUT请求
  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    return await _dio.put(path, data: data, queryParameters: queryParameters);
  }

  // 通用DELETE请求
  Future<Response> delete(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.delete(path, queryParameters: queryParameters);
  }

  // 登录
  Future<AuthResponse> login(String account, String password) async {
    try {
      final formData = FormData.fromMap({
        'username': account, // API需要username作为key
        'password': password,
      });
      
      final response = await _dio.post('/login', data: formData);
      final authResponse = AuthResponse.fromJson(response.data);
      
      // 保存令牌
      await _secureStorage.write(key: 'access_token', value: authResponse.accessToken);
      await _secureStorage.write(key: 'user_id', value: authResponse.userId);
      
      return authResponse;
    } catch (e) {
      print('登录失败: $e');
      rethrow;
    }
  }

  // 注册
  Future<AuthResponse> register(String account, String password) async {
    try {
      final response = await _dio.post(
        '/register',
        data: RegisterRequest(account: account, password: password).toJson(),
      );
      final authResponse = AuthResponse.fromJson(response.data);
      
      // 保存令牌
      await _secureStorage.write(key: 'access_token', value: authResponse.accessToken);
      await _secureStorage.write(key: 'user_id', value: authResponse.userId);
      
      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  // 重置密码
  Future<AuthResponse> resetPassword(String account, String newPassword) async {
    try {
      final response = await _dio.post(
        '/reset_password',
        data: ResetPasswordRequest(account: account, newPassword: newPassword).toJson(),
      );
      final authResponse = AuthResponse.fromJson(response.data);
      
      // 保存令牌
      await _secureStorage.write(key: 'access_token', value: authResponse.accessToken);
      await _secureStorage.write(key: 'user_id', value: authResponse.userId);
      
      return authResponse;
    } catch (e) {
      rethrow;
    }
  }

  // 登出
  Future<void> logout() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'user_id');
  }

  // 获取当前令牌
  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  // 获取当前用户ID
  Future<String?> getUserId() async {
    return await _secureStorage.read(key: 'user_id');
  }
} 