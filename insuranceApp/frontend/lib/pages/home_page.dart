import 'package:flutter/material.dart';

import 'conversation_page.dart';
import 'insurance_page.dart';
import 'profile_page.dart';
import 'planning_page.dart';
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

class _HomePageState extends State<HomePage> {
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

  /// 更新页面列表
  void _updatePages() {
    _pages = [
      ConversationPage(
        conversationId: _currentConversationId,
        initialQuestion: _currentInitialQuestion,
        productInfo: _currentProductInfo,
        onInitialQuestionSent: _clearInitialData, // 添加回调
      ), // 智能助手页面（对话页面）
      const InsurancePage(), // 保险页面
      const PlanningPage(), // 财务规划页面
      const ProfilePage(), // 个人中心页面
    ];
  }

  /// 清除初始数据，防止重复发送
  void _clearInitialData() {
    setState(() {
      _currentInitialQuestion = null;
      _currentProductInfo = null;
      _updatePages();
    });
  }

  // 切换导航项
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
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