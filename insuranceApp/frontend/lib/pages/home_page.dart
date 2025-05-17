import 'package:flutter/material.dart';

import 'conversation_page.dart';
import '../widgets/coming_soon_page.dart';
// import './menu_page.dart';

class HomePage extends StatefulWidget {
  final String? conversationId;
  
  const HomePage({Key? key, this.conversationId}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  
  // 统一颜色方案
  final Color _primaryColor = const Color(0xFF6A1B9A); // 紫色主题
  final Color _backgroundColor = Colors.white; // 白色背景
  
  // 页面列表
  late final List<Widget> _pages;
  
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
    
    // 初始化页面列表，并传递conversationId给ConversationPage
    _pages = [
      ConversationPage(conversationId: widget.conversationId), // 智能助手页面（对话页面）
      const ComingSoonPage(title: '保险页面'),
      const ComingSoonPage(title: '财务规划页面'),
      const ComingSoonPage(title: '个人中心页面'),
    ];
  }

  // 切换导航项
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 所有平台统一使用底部导航栏
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: _primaryColor,
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