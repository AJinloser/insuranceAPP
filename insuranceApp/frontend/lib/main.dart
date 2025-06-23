import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'pages/conversation_page.dart';
import 'pages/home_page.dart';
import 'pages/menu_page.dart';
import 'pages/profile_setup_page.dart';
import 'pages/user_insurance_list_page.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'services/insurance_service.dart';
import 'services/insurance_list_service.dart';
import 'services/user_info_service.dart';

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
  
  // 初始化保险服务
  final insuranceService = InsuranceService();
  
  // 初始化保单服务
  final insuranceListService = InsuranceListService();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: chatService),
        ChangeNotifierProvider.value(value: insuranceService),
        ChangeNotifierProvider.value(value: insuranceListService),
        ChangeNotifierProxyProvider<AuthService, UserInfoService>(
          create: (context) => UserInfoService(authService),
          update: (context, auth, previous) => previous ?? UserInfoService(auth),
        ),
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
        primaryColor: const Color(0xFF8E6FF7),
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF8E6FF7),
          secondary: const Color(0xFF8E6FF7),
          surface: Colors.white,
          background: const Color(0xFFF8F5FF),
        ),
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF8E6FF7),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(
            color: Colors.white,
          ),
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
          final initialTabIndex = args?['initialTabIndex'] as int?;
          
          return MaterialPageRoute(
            builder: (context) => HomePage(
              conversationId: conversationId,
              initialTabIndex: initialTabIndex,
            ),
          );
        }
        
        // 处理菜单页面路由
        if (settings.name == '/menu') {
          return MaterialPageRoute(
            builder: (context) => const MenuPage(),
          );
        }
        
        // 处理个人信息初始化页面路由
        if (settings.name == '/profile-setup') {
          return MaterialPageRoute(
            builder: (context) => const ProfileSetupPage(),
          );
        }
        
        // 处理用户保单页面路由
        if (settings.name == '/user-insurance-list') {
          return MaterialPageRoute(
            builder: (context) => const UserInsuranceListPage(),
          );
        }
        
        return null;
      },
      home: Consumer<AuthService>(
        builder: (context, authService, child) {
          debugPrint('===> MaterialApp: AuthStatus = ${authService.authStatus}, isNewUser = ${authService.isNewUser}, shouldShowProfile = ${authService.shouldShowProfile}');
          
          switch (authService.authStatus) {
            case AuthStatus.authenticated:
              // 如果是新注册的用户，显示个人信息初始化页面
              if (authService.isNewUser) {
                debugPrint('===> MaterialApp: 显示个人信息初始化页面');
                return const ProfileSetupPage();
              }
              // 如果应该显示个人中心，则显示个人中心标签页
              if (authService.shouldShowProfile) {
                debugPrint('===> MaterialApp: 显示个人中心页面');
                // 重置标志，避免重复显示
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  authService.resetShowProfile();
                });
                return const HomePage(initialTabIndex: 3); // 3对应个人中心标签页
              }
              // 否则显示主页
              debugPrint('===> MaterialApp: 显示主页');
              return const HomePage();
            case AuthStatus.unauthenticated:
            case AuthStatus.unknown:
              debugPrint('===> MaterialApp: 显示登录页面');
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