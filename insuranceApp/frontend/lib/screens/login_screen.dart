import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/developer_service.dart';
import '../utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../pages/developer_page.dart';

enum LoginMode { login, register, resetPassword }

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _developerPasswordController = TextEditingController();

  bool _isLoading = false;
  // 实验模式：移除自动登录选项
  // bool _isPersistent = false;  // 已禁用
  bool _isPasswordVisible = false;
  bool _hasError = false;
  LoginMode _mode = LoginMode.login;

  // 定义颜色
  final Color _primaryColor = const Color(0xFF6A1B9A); // 紫色主题
  final Color _backgroundColor = Colors.white; // 白色背景
  final Color _cardColor = Colors.white; // 白色卡片

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _developerPasswordController.dispose();
    super.dispose();
  }

  // 切换模式（登录/注册/忘记密码）
  void _switchMode(LoginMode mode) {
    setState(() {
      _mode = mode;
      _hasError = false;
      _isPasswordVisible = false;
    });
  }

  // 表单提交
  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      print('===> 开始表单提交，模式: $_mode');

      final authService = Provider.of<AuthService>(context, listen: false);
      try {
        bool success = false;

        switch (_mode) {
          case LoginMode.login:
            print('===> 执行登录操作');
            success = await authService.login(
              _accountController.text,
              _passwordController.text,
            );
            // 实验模式：不再保存持久化登录状态
            // if (success) {
            //   await authService.setPersistent(_isPersistent);
            // }
            break;
          case LoginMode.register:
            print('===> 执行注册操作');
            success = await authService.register(
              _accountController.text,
              _passwordController.text,
            );
            print('===> 注册结果: $success');
            break;
          case LoginMode.resetPassword:
            print('===> 执行重置密码操作');
            success = await authService.resetPassword(
              _accountController.text,
              _passwordController.text,
            );
            break;
        }

        if (success && mounted) {
          print('===> 操作成功，AuthService状态已更新，将自动处理页面导航');
          // AuthService状态变化会自动触发MaterialApp中的Consumer重新构建
          // 不需要手动导航
        } else {
          print('===> 操作失败或组件已销毁');
        }
      } catch (e) {
        print('===> 操作异常: $e');
        setState(() {
          _hasError = true;
        });
        Fluttertoast.showToast(
          msg: _getErrorMessage(e.toString()),
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  // 错误信息处理
  String _getErrorMessage(String error) {
    if (error.contains('401')) {
      return '账号或密码错误';
    } else if (error.contains('400') && _mode == LoginMode.register) {
      return '该账号已被注册';
    } else if (error.contains('404') && _mode == LoginMode.resetPassword) {
      return '用户不存在';
    }
    return '操作失败，请稍后重试';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              width: MediaQuery.of(context).size.width > 600 
                  ? 500 
                  : MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(77),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo
                    Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 30),
                      child: Image.asset(
                        'assets/logo/logo-site.png',
                        height: 100,
                      ),
                    ),

                    // 标题
                    Text(
                      _getTitleText(),
                      style: TextStyle(
                        fontSize: 28.0,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(height: 30.0),

                    // 账号输入框
                    CustomTextField(
                      label: '账号',
                      controller: _accountController,
                      prefixIcon: Icons.person,
                      validator: Validators.validateAccount,
                      isError: _hasError && _mode == LoginMode.login,
                      keyboardType: TextInputType.text,
                    ),

                    // 密码输入框
                    CustomTextField(
                      label: _mode == LoginMode.resetPassword ? '新密码' : '密码',
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      prefixIcon: Icons.lock,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: _primaryColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      validator: Validators.validatePassword,
                      isError: _hasError && _mode == LoginMode.login,
                    ),

                    // 确认密码输入框（仅在注册模式下显示）
                    if (_mode == LoginMode.register)
                      CustomTextField(
                        label: '确认密码',
                        controller: _confirmPasswordController,
                        obscureText: !_isPasswordVisible,
                        prefixIcon: Icons.lock,
                        validator: (value) => Validators.validateConfirmPassword(
                          value,
                          _passwordController.text,
                        ),
                      ),

                    // 实验模式：移除"记住密码"选项，只保留忘记密码链接
                    if (_mode == LoginMode.login)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _switchMode(LoginMode.resetPassword),
                              child: Text(
                                '忘记密码?',
                                style: TextStyle(
                                  color: _primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 30.0),

                    // 提交按钮
                    CustomButton(
                      text: _getButtonText(),
                      onPressed: _submitForm,
                      isLoading: _isLoading,
                      backgroundColor: _primaryColor,
                    ),

                    const SizedBox(height: 24.0),

                    // 底部切换选项
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _mode == LoginMode.login
                              ? '没有账号?'
                              : _mode == LoginMode.register
                                  ? '已有账号?'
                                  : '记起密码?',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        TextButton(
                          onPressed: () => _switchMode(
                            _mode == LoginMode.login
                                ? LoginMode.register
                                : LoginMode.login,
                          ),
                          child: Text(
                            _mode == LoginMode.login
                                ? '立即注册'
                                : _mode == LoginMode.register
                                    ? '立即登录'
                                    : '立即登录',
                            style: TextStyle(
                              color: _primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    
                    // 开发者入口（隐蔽）
                    Center(
                      child: TextButton(
                        onPressed: _showDeveloperPasswordDialog,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                        child: Text(
                          '开发者',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 获取标题文本
  String _getTitleText() {
    switch (_mode) {
      case LoginMode.login:
        return '欢迎登录';
      case LoginMode.register:
        return '创建账号';
      case LoginMode.resetPassword:
        return '重置密码';
    }
  }

  // 获取按钮文本
  String _getButtonText() {
    switch (_mode) {
      case LoginMode.login:
        return '登录';
      case LoginMode.register:
        return '注册';
      case LoginMode.resetPassword:
        return '重置密码';
    }
  }

  // 显示开发者密码验证对话框
  void _showDeveloperPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('开发者验证'),
          content: TextField(
            controller: _developerPasswordController,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '请输入开发者密码',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
            onSubmitted: (_) => _verifyDeveloperPassword(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _developerPasswordController.clear();
                Navigator.of(context).pop();
              },
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: _verifyDeveloperPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  // 验证开发者密码
  void _verifyDeveloperPassword() async {
    final developerService = Provider.of<DeveloperService>(
      context,
      listen: false,
    );
    
    final isValid = await developerService.verifyPassword(
      _developerPasswordController.text,
    );
    
    if (isValid && mounted) {
      _developerPasswordController.clear();
      Navigator.of(context).pop(); // 关闭对话框
      // 直接导航到开发者页面
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const DeveloperPage(),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('密码错误'),
          backgroundColor: Colors.red,
        ),
      );
      _developerPasswordController.clear();
    }
  }
} 