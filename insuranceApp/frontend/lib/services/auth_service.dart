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
  bool _isNewUser = false;
  bool _shouldShowProfile = false;

  AuthStatus get authStatus => _authStatus;
  String? get userId => _userId;
  bool get isPersistent => _isPersistent;
  bool get isNewUser => _isNewUser;
  bool get shouldShowProfile => _shouldShowProfile;

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
      debugPrint('===> AuthService: 开始登录流程');
      final response = await _apiService.login(account, password);
      _userId = response.userId;
      _authStatus = AuthStatus.authenticated;
      _isNewUser = false; // 登录用户不是新用户
      _shouldShowProfile = false; // 重置显示个人中心标志
      debugPrint('===> AuthService: 登录成功');
      notifyListeners();
      
      // 通知ChatService更新用户ID
      await _updateChatServiceUserId();
      
      return true;
    } catch (e) {
      _authStatus = AuthStatus.unauthenticated;
      _isNewUser = false;
      _shouldShowProfile = false;
      debugPrint('===> AuthService: 登录失败 - $e');
      notifyListeners();
      rethrow;
    }
  }

  // 注册
  Future<bool> register(String account, String password) async {
    try {
      debugPrint('===> AuthService: 开始注册流程');
      final response = await _apiService.register(account, password);
      _userId = response.userId;
      _authStatus = AuthStatus.authenticated;
      _isNewUser = true; // 设置为新用户
      _shouldShowProfile = false; // 重置显示个人中心标志
      debugPrint('===> AuthService: 注册成功，设置为新用户状态');
      notifyListeners();
      
      // 通知ChatService更新用户ID
      await _updateChatServiceUserId();
      
      return true;
    } catch (e) {
      _authStatus = AuthStatus.unauthenticated;
      _isNewUser = false;
      _shouldShowProfile = false;
      debugPrint('===> AuthService: 注册失败 - $e');
      notifyListeners();
      rethrow;
    }
  }

  // 重置密码
  Future<bool> resetPassword(String account, String newPassword) async {
    try {
      debugPrint('===> AuthService: 开始重置密码流程');
      final response = await _apiService.resetPassword(account, newPassword);
      _userId = response.userId;
      _authStatus = AuthStatus.authenticated;
      _isNewUser = false; // 重置密码的用户不是新用户
      _shouldShowProfile = false; // 重置显示个人中心标志
      debugPrint('===> AuthService: 重置密码成功');
      notifyListeners();
      
      // 通知ChatService更新用户ID
      await _updateChatServiceUserId();
      
      return true;
    } catch (e) {
      debugPrint('===> AuthService: 重置密码失败 - $e');
      rethrow;
    }
  }

  // 登出
  Future<void> logout() async {
    debugPrint('===> AuthService: 开始登出流程');
    await _apiService.logout();
    _userId = null;
    _authStatus = AuthStatus.unauthenticated;
    _isNewUser = false; // 重置新用户标志
    _shouldShowProfile = false; // 重置显示个人中心标志
    debugPrint('===> AuthService: 登出成功');
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

  // 完成新用户设置
  void completeNewUserSetup() {
    debugPrint('===> AuthService: 完成新用户设置，重置新用户标志并设置显示个人中心');
    _isNewUser = false;
    _shouldShowProfile = true;
    notifyListeners();
  }

  // 重置显示个人中心标志
  void resetShowProfile() {
    debugPrint('===> AuthService: 重置显示个人中心标志');
    _shouldShowProfile = false;
    notifyListeners();
  }
} 