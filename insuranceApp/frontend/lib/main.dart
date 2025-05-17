import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'pages/conversation_page.dart';
import 'pages/home_page.dart';
import 'pages/menu_page.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 加载环境变量文件
  try {
    await dotenv.load(fileName: ".env");
    debugPrint("===> 成功加载.env文件");
  } catch (e) {
    debugPrint("===> 加载.env文件失败: $e");
  }
  
  // 初始化认证服务
  final authService = AuthService();
  await authService.init();
  
  // 初始化聊天服务
  final chatService = ChatService();
  try {
    // 提前初始化ChatService，确保在页面加载前AI模块已经准备好
    await chatService.init();
    debugPrint("===> ChatService初始化成功");
  } catch (e) {
    debugPrint("===> ChatService初始化失败: $e");
  }
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: chatService),
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
      title: '保险咨询APP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        primaryColor: const Color(0xFF6A1B9A),
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF6A1B9A),
          secondary: const Color(0xFF8E24AA),
          surface: Colors.white,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        // 处理对话页面路由
        if (settings.name == '/conversation') {
          final args = settings.arguments as Map<String, dynamic>?;
          final conversationId = args?['conversationId'] as String?;
          final initialQuestion = args?['initialQuestion'] as String?;
          
          return MaterialPageRoute(
            builder: (context) => ConversationPage(
              conversationId: conversationId,
              initialQuestion: initialQuestion,
            ),
          );
        }
        
        // 处理首页路由，传递会话ID
        if (settings.name == '/home') {
          final args = settings.arguments as Map<String, dynamic>?;
          final conversationId = args?['conversationId'] as String?;
          
          return MaterialPageRoute(
            builder: (context) => HomePage(
              conversationId: conversationId,
            ),
          );
        }
        
        // 处理菜单页面路由
        if (settings.name == '/menu') {
          return MaterialPageRoute(
            builder: (context) => const MenuPage(),
          );
        }
        
        return null;
      },
      home: Consumer<AuthService>(
        builder: (context, authService, child) {
          switch (authService.authStatus) {
            case AuthStatus.authenticated:
              // 登录成功后跳转到首页（带导航栏的主页）
              return const HomePage();
            case AuthStatus.unauthenticated:
            case AuthStatus.unknown:
              return const LoginScreen();
          }
        },
      ),
      routes: {
        // 其他路由...
      },
    );
  }
} 