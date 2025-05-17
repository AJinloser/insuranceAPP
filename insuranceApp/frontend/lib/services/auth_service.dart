import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// import '../models/user.dart';
import 'api_service.dart';
import 'chat_service.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class AuthService with ChangeNotifier {
  final ApiService _apiService = ApiService();
  AuthStatus _authStatus = AuthStatus.unknown;
  String? _userId;
  bool _isPersistent = false;

  AuthStatus get authStatus => _authStatus;
  String? get userId => _userId;
  bool get isPersistent => _isPersistent;

  // 单例模式
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal();

  // 初始化
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isPersistent = prefs.getBool('isPersistent') ?? false;
    
    if (_isPersistent) {
      final token = await _apiService.getToken();
      final userId = await _apiService.getUserId();
      
      if (token != null && userId != null) {
        _userId = userId;
        _authStatus = AuthStatus.authenticated;
      } else {
        _authStatus = AuthStatus.unauthenticated;
      }
    } else {
      _authStatus = AuthStatus.unauthenticated;
    }
    
    notifyListeners();
  }

  // 设置持久化
  Future<void> setPersistent(bool isPersistent) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPersistent', isPersistent);
    _isPersistent = isPersistent;
    notifyListeners();
  }

  // 登录
  Future<bool> login(String account, String password) async {
    try {
      final response = await _apiService.login(account, password);
      _userId = response.userId;
      _authStatus = AuthStatus.authenticated;
      notifyListeners();
      
      // 通知ChatService更新用户ID
      await _updateChatServiceUserId();
      
      return true;
    } catch (e) {
      _authStatus = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  // 注册
  Future<bool> register(String account, String password) async {
    try {
      final response = await _apiService.register(account, password);
      _userId = response.userId;
      _authStatus = AuthStatus.authenticated;
      notifyListeners();
      
      // 通知ChatService更新用户ID
      await _updateChatServiceUserId();
      
      return true;
    } catch (e) {
      _authStatus = AuthStatus.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  // 重置密码
  Future<bool> resetPassword(String account, String newPassword) async {
    try {
      final response = await _apiService.resetPassword(account, newPassword);
      _userId = response.userId;
      _authStatus = AuthStatus.authenticated;
      notifyListeners();
      
      // 通知ChatService更新用户ID
      await _updateChatServiceUserId();
      
      return true;
    } catch (e) {
      rethrow;
    }
  }

  // 登出
  Future<void> logout() async {
    await _apiService.logout();
    _userId = null;
    _authStatus = AuthStatus.unauthenticated;
    notifyListeners();
  }
  
  // 通知ChatService更新用户ID
  Future<void> _updateChatServiceUserId() async {
    try {
      final chatService = ChatService();
      // 如果ChatService已经初始化，则调用其初始化用户ID的方法
      if (chatService.isInitialized) {
        await chatService.reloadUserId();
      }
    } catch (e) {
      debugPrint('更新ChatService用户ID失败: $e');
    }
  }
} 