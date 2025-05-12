import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  final authService = AuthService();
  await authService.init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '保险应用',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Consumer<AuthService>(
        builder: (context, authService, child) {
          switch (authService.authStatus) {
            case AuthStatus.authenticated:
              // 登录成功后的主页（暂未实现）
              return const Scaffold(
                body: Center(
                  child: Text('登录成功！主页正在建设中...'),
                ),
              );
            case AuthStatus.unauthenticated:
            case AuthStatus.unknown:
            default:
              return const LoginScreen();
          }
        },
      ),
    );
  }
} 