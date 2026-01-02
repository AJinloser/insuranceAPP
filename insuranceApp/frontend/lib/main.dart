import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'pages/conversation_page.dart';
import 'pages/home_page.dart';
import 'pages/menu_page.dart';
import 'pages/profile_setup_page.dart';
import 'pages/user_insurance_list_page.dart';
import 'pages/pre_survey_page.dart';
import 'pages/declaration_page.dart';
import 'pages/post_survey_page.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'services/insurance_service.dart';
import 'services/insurance_list_service.dart';
import 'services/user_info_service.dart';
import 'services/goal_service.dart';
import 'services/settings_service.dart';
import 'services/developer_service.dart';
import 'services/experiment_service.dart';

// 全局RouteObserver
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

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
  
  // 初始化目标服务
  final goalService = GoalService();
  
  // 初始化设置服务
  final settingsService = SettingsService();
  try {
    await settingsService.init();
    debugPrint("===> SettingsService初始化成功");
  } catch (e) {
    debugPrint("===> SettingsService初始化失败: $e");
  }
  
  // 初始化开发者服务
  final developerService = DeveloperService();
  
  // 初始化实验服务
  final experimentService = ExperimentService();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authService),
        ChangeNotifierProvider.value(value: chatService),
        ChangeNotifierProvider.value(value: insuranceService),
        ChangeNotifierProvider.value(value: insuranceListService),
        ChangeNotifierProvider.value(value: goalService),
        ChangeNotifierProvider.value(value: settingsService),
        ChangeNotifierProvider.value(value: developerService),
        ChangeNotifierProvider.value(value: experimentService),
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
      title: '保险规划助手',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver], // 添加RouteObserver
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        primaryColor: const Color(0xFF6A1B9A),
        fontFamily: 'PingFang SC',
        useMaterial3: true,
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
          debugPrint('===> Router: 收到对话页面路由请求');
          final args = settings.arguments as Map<String, dynamic>?;
          final conversationId = args?['conversationId'] as String?;
          final initialQuestion = args?['initialQuestion'] as String?;
          final productInfo = args?['productInfo'] as String?;
          
          debugPrint('===> Router: 路由参数 - conversationId: $conversationId');
          debugPrint('===> Router: 路由参数 - initialQuestion: $initialQuestion');
          debugPrint('===> Router: 路由参数 - productInfo长度: ${productInfo?.length ?? 0}');
          
          return MaterialPageRoute(
            builder: (context) {
              debugPrint('===> Router: 正在构建ConversationPage');
              return ConversationPage(
                conversationId: conversationId,
                initialQuestion: initialQuestion,
                productInfo: productInfo,
              );
            },
          );
        }
        
        // 处理首页路由，传递会话ID
        if (settings.name == '/home') {
          final args = settings.arguments as Map<String, dynamic>?;
          final conversationId = args?['conversationId'] as String?;
          final initialTabIndex = args?['initialTabIndex'] as int?;
          final initialQuestion = args?['initialQuestion'] as String?;
          final productInfo = args?['productInfo'] as String?;
          
          return MaterialPageRoute(
            builder: (context) => HomePage(
              conversationId: conversationId,
              initialTabIndex: initialTabIndex,
              initialQuestion: initialQuestion,
              productInfo: productInfo,
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
        
        // 实验流程路由
        if (settings.name == '/pre-survey') {
          return MaterialPageRoute(
            builder: (context) => const PreSurveyPage(),
          );
        }
        
        if (settings.name == '/declaration') {
          return MaterialPageRoute(
            builder: (context) => const DeclarationPage(),
          );
        }
        
        if (settings.name == '/experiment-conversation') {
          return MaterialPageRoute(
            builder: (context) => const ConversationPage(isExperimentMode: true),
          );
        }
        
        if (settings.name == '/post-survey') {
          return MaterialPageRoute(
            builder: (context) => const PostSurveyPage(),
          );
        }
        
        return null;
      },
      home: Consumer2<AuthService, ExperimentService>(
        builder: (context, authService, experimentService, child) {
          debugPrint('===> MaterialApp home: builder被调用');
          debugPrint('===> MaterialApp home: AuthStatus = ${authService.authStatus}, isNewUser = ${authService.isNewUser}, shouldShowProfile = ${authService.shouldShowProfile}');
          
          switch (authService.authStatus) {
            case AuthStatus.authenticated:
              debugPrint('===> MaterialApp home: 状态=authenticated');
              // 如果是新注册的用户,进入实验流程
              if (authService.isNewUser) {
                debugPrint('===> MaterialApp home: 新用户,加载实验信息');
                // 加载实验信息
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  await experimentService.getExperimentInfo(authService.userId!);
                  if (context.mounted) {
                    // 跳转到测前问卷页面
                    Navigator.of(context).pushReplacementNamed('/pre-survey');
                  }
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              
              // 对于已有用户,检查实验进度
              if (authService.userId != null) {
                debugPrint('===> MaterialApp home: 已有用户，userId=${authService.userId}');
                // 加载实验信息
                WidgetsBinding.instance.addPostFrameCallback((_) async {
                  final info = await experimentService.getExperimentInfo(authService.userId!);
                  if (info != null && context.mounted) {
                    debugPrint('===> MaterialApp home: 实验进度 - 测前:${info.completedPreSurvey}, 声明:${info.completedDeclaration}, 对话:${info.completedConversation}, 测后:${info.completedPostSurvey}');
                    
                    // 根据实验进度跳转到对应页面
                    if (!info.completedPreSurvey) {
                      debugPrint('===> MaterialApp home: 跳转到测前问卷');
                      Navigator.of(context).pushReplacementNamed('/pre-survey');
                    } else if (!info.completedDeclaration) {
                      debugPrint('===> MaterialApp home: 跳转到声明页面');
                      Navigator.of(context).pushReplacementNamed('/declaration');
                    } else if (!info.completedConversation) {
                      debugPrint('===> MaterialApp home: 跳转到实验对话');
                      Navigator.of(context).pushReplacementNamed('/experiment-conversation');
                    } else if (!info.completedPostSurvey) {
                      debugPrint('===> MaterialApp home: 跳转到测后问卷');
                      Navigator.of(context).pushReplacementNamed('/post-survey');
                    } else {
                      // 如果全部完成，允许用户继续使用实验对话页面
                      debugPrint('===> MaterialApp home: 实验已全部完成，进入对话页面');
                      Navigator.of(context).pushReplacementNamed('/experiment-conversation');
                    }
                  }
                });
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              
              // 默认显示加载中
              debugPrint('===> MaterialApp home: authenticated但userId为null，显示加载中');
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
              
            case AuthStatus.unauthenticated:
              debugPrint('===> MaterialApp home: 状态=unauthenticated，显示登录页面');
              return const LoginScreen();
            case AuthStatus.unknown:
              debugPrint('===> MaterialApp home: 状态=unknown，显示登录页面');
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