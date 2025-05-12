class Validators {
  // 验证账号
  static String? validateAccount(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入账号';
    }
    if (value.length < 3) {
      return '账号长度不能少于3个字符';
    }
    return null;
  }

  // 验证密码
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入密码';
    }
    if (value.length < 6) {
      return '密码长度不能少于6个字符';
    }
    return null;
  }

  // 验证确认密码
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return '请确认密码';
    }
    if (value != password) {
      return '两次输入的密码不一致';
    }
    return null;
  }
} 