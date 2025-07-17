import 'package:flutter/material.dart';

import 'conversation_page.dart';
import 'default_chat_page.dart';
import 'insurance_page.dart';
import 'profile_page.dart';
import 'planning_page.dart';
import '../main.dart'; // 导入RouteObserver
// import './menu_page.dart';

class HomePage extends StatefulWidget {
  final String? conversationId;
  final int? initialTabIndex;
  final String? initialQuestion;
  final String? productInfo;
  
  const HomePage({
    Key? key, 
    this.conversationId, 
    this.initialTabIndex,
    this.initialQuestion,
    this.productInfo,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with RouteAware {
  int _selectedIndex = 0;
  
  // 页面列表
  List<Widget> _pages = []; // 改为可变列表
  
  // 动态参数，用于支持清除
  String? _currentConversationId;
  String? _currentInitialQuestion;
  String? _currentProductInfo;
  
  // 标题列表
  final List<String> _titles = const [
    '智能助手',
    '保险服务',
    '财务规划',
    '个人中心',
  ];
  
  // 图标列表
  final List<IconData> _icons = const [
    Icons.chat_bubble_outline,
    Icons.shield_outlined,
    Icons.trending_up,
    Icons.person_outline,
  ];

  @override
  void initState() {
    super.initState();
    
    // 设置初始标签页索引
    _selectedIndex = widget.initialTabIndex ?? 0;
    
    // 初始化动态参数
    _currentConversationId = widget.conversationId;
    _currentInitialQuestion = widget.initialQuestion;
    _currentProductInfo = widget.productInfo;
    
    // 初始化页面列表
    _updatePages();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 订阅路由观察器
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    // 取消订阅路由观察器
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    // 当从其他页面返回时，清除对话相关参数，确保显示DefaultChatPage
    if (_selectedIndex == 0) { // 只有在智能助手tab时才清理
      setState(() {
        _currentConversationId = null;
        _currentInitialQuestion = null;
        _currentProductInfo = null;
        _updatePages();
      });
    }
  }

  /// 处理会话创建的回调
  void _handleConversationCreated(String conversationId) {
    debugPrint('===> HomePage: 会话创建回调 - conversationId: $conversationId');
    
    setState(() {
      _currentConversationId = conversationId;
      // 保留其他参数不变
      _updatePages();
    });
  }

  /// 更新页面列表
  void _updatePages() {
    _pages = [
      // 如果有对话相关参数（conversationId、initialQuestion或productInfo），显示ConversationPage
      // 否则显示DefaultChatPage
      (_currentConversationId != null || _currentInitialQuestion != null || _currentProductInfo != null)
          ? ConversationPage(
              conversationId: _currentConversationId,
              initialQuestion: _currentInitialQuestion,
              productInfo: _currentProductInfo,
              onInitialQuestionSent: _clearInitialData, // 添加回调
              onNewConversation: resetToDefaultChat, // 添加新对话回调
              onConversationCreated: _handleConversationCreated, // 添加会话创建回调
            )
          : DefaultChatPage(
              onStartConversation: _handleStartConversation, // 添加回调
            ),
      const InsurancePage(), // 保险页面
      const PlanningPage(), // 财务规划页面
      const ProfilePage(), // 个人中心页面
    ];
  }

  /// 处理开始对话的回调
  void _handleStartConversation(String conversationId, String initialQuestion) {
    debugPrint('===> HomePage: 开始对话回调 - conversationId: "$conversationId", initialQuestion: "$initialQuestion"');
    
    setState(() {
      // 对于新会话，conversationId可能为空，这是正常情况
      // 只有在有明确conversationId时才设置，否则保持为null表示新会话
      _currentConversationId = conversationId.isNotEmpty ? conversationId : null;
      _currentInitialQuestion = initialQuestion;
      
      debugPrint('===> HomePage: 更新状态 - _currentConversationId: $_currentConversationId, _currentInitialQuestion: $_currentInitialQuestion');
      
      _updatePages();
    });
  }

  /// 清除初始数据，防止重复发送
  void _clearInitialData() {
    setState(() {
      // 只有在有明确的conversationId时才清理initialQuestion
      // 这样可以确保在会话创建成功之前不会跳回默认页面
      if (_currentConversationId != null) {
        _currentInitialQuestion = null;
      }
      _currentProductInfo = null;
      // 保留_currentConversationId，这样用户继续停留在对话页面
      _updatePages();
    });
  }

  // 切换导航项
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      
      // 简化逻辑：当切换到智能助手tab时，总是重置到默认聊天页面
      // 这样可以避免各种状态不一致的问题
      if (index == 0) {
        _currentConversationId = null;
        _currentInitialQuestion = null;
        _currentProductInfo = null;
        _updatePages();
      }
    });
  }

  /// 重置到默认聊天页面
  void resetToDefaultChat() {
    setState(() {
      _currentConversationId = null;
      _currentInitialQuestion = null;
      _currentProductInfo = null;
      _updatePages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    
    // 所有平台统一使用底部导航栏
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 8,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        items: List.generate(
          _titles.length,
          (index) => BottomNavigationBarItem(
            icon: Icon(_icons[index]),
            label: _titles[index],
          ),
        ),
      ),
    );
  }
} 