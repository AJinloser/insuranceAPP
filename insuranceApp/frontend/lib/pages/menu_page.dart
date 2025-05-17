import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dify_models.dart';
import '../services/chat_service.dart';
import '../widgets/ai_module_card.dart';
import '../widgets/conversation_item.dart';

/// 菜单页面
/// 包含AI模块选择和会话列表，右上角有返回按钮
class MenuPage extends StatefulWidget {
  const MenuPage({Key? key}) : super(key: key);

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  // 当前选中的AI模块
  AIModule? _selectedModule;
  // 是否加载中
  bool _isLoading = true;
  // 是否已加载会话列表
  bool _hasLoadedConversations = false;
  
  // 主题色定义，与登录页面统一
  final Color _primaryColor = const Color(0xFF6A1B9A); // 紫色主题
  final Color _backgroundColor = Colors.white; // 白色背景
  // final Color _cardColor = Colors.white; // 白色卡片
  // final Color _lightPurple = const Color(0xFFEDE7F6); // 浅紫色背景
  
  @override
  void initState() {
    super.initState();
    // 初始化聊天服务
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initChatService();
    });
  }
  
  // 初始化聊天服务
  Future<void> _initChatService() async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 已初始化ChatService
      if (chatService.isInitialized) {
        _selectedModule = chatService.selectedModule;
        
        // 在菜单页面加载会话列表，无论是否已经加载过，确保列表是最新的
        if (_selectedModule != null) {
          debugPrint('===> MenuPage: 加载会话列表');
          await chatService.loadConversations();
          _hasLoadedConversations = true;
        }
      } else {
        // 首次初始化
        debugPrint('===> MenuPage: 首次初始化ChatService');
        await chatService.init();
        
        // ChatService初始化完成后更新状态
        _selectedModule = chatService.selectedModule;
        
        // 在菜单页面显式加载会话列表
        if (_selectedModule != null) {
          debugPrint('===> MenuPage: 首次初始化后加载会话列表');
          await chatService.loadConversations();
          _hasLoadedConversations = true;
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('初始化失败: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 选择会话
  void _selectConversation(String conversationId) {
    // 跳转到首页（第一个标签是对话页面）
    Navigator.pushReplacementNamed(
      context, 
      '/home',
      arguments: {'conversationId': conversationId}
    );
  }
  
  // 选择AI模块
  void _selectAIModule(AIModule module) async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    final bool isSameModule = _selectedModule?.apiKey == module.apiKey;
    
    setState(() {
      _isLoading = true;
      _selectedModule = module;
    });
    
    try {
      // 选择AI模块，并始终加载该模块的会话列表（菜单页面始终需要显示会话列表）
      // 即使是同一个模块，也重新加载一次会话列表，确保数据是最新的
      await chatService.selectAIModule(module, shouldLoadConversations: true);
      _hasLoadedConversations = true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择AI模块失败: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '菜单',
          style: TextStyle(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        actions: [
          // 添加返回按钮
          IconButton(
            icon: const Icon(Icons.arrow_forward, size: 22),
            onPressed: () {
              // 返回首页
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
          : _buildBody(),
    );
  }
  
  Widget _buildBody() {
    final chatService = Provider.of<ChatService>(context);
    final size = MediaQuery.of(context).size;
    final double verticalPadding = size.height * 0.02; // 根据屏幕高度调整垂直间距
    
    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, verticalPadding * 0.5, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // AI模块选择区域
              _buildSectionTitle('AI 助手', Icons.smart_toy_outlined),
              SizedBox(height: verticalPadding * 0.4),
              _buildAIModulesSection(chatService),
              
              SizedBox(height: verticalPadding * 1.0),
              
              // 历史会话区域
              _buildSectionTitle('历史对话', Icons.history_outlined),
              SizedBox(height: verticalPadding * 0.4),
              SizedBox(
                height: size.height * 0.5, // 增加高度，因为没有常见问题部分
                child: _buildConversationsSection(chatService),
              ),
              
              SizedBox(height: verticalPadding),
            ],
          ),
        ),
      ),
    );
  }
  
  // 构建区域标题
  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Icon(icon, color: _primaryColor, size: 22),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500, // 中等粗细
              color: _primaryColor,
            ),
          ),
        ],
      ),
    );
  }
  
  // 构建AI模块选择区域
  Widget _buildAIModulesSection(ChatService chatService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            '选择你需要的AI助手类型',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.grey[700],
            ),
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: chatService.aiModules.length,
            itemBuilder: (context, index) {
              final module = chatService.aiModules[index];
              return AIModuleCard(
                module: module,
                isSelected: _selectedModule?.apiKey == module.apiKey,
                onTap: () => _selectAIModule(module),
              );
            },
          ),
        ),
      ],
    );
  }
  
  // 构建历史会话区域
  Widget _buildConversationsSection(ChatService chatService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            '继续之前的对话',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: chatService.conversations.isEmpty
              ? Container(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 42,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '暂无会话，返回对话页面新建对话',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: chatService.conversations.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey[100],
                  ),
                  itemBuilder: (context, index) {
                    final conversation = chatService.conversations[index];
                    return ConversationItem(
                      conversation: conversation,
                      onTap: () => _selectConversation(conversation.id),
                      onDelete: () => chatService.deleteConversation(conversation.id),
                      onRename: () => showDialog(
                        context: context,
                        builder: (context) => _buildRenameDialog(conversation),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
  
  // 构建重命名对话框
  Widget _buildRenameDialog(Conversation conversation) {
    final TextEditingController controller = TextEditingController(text: conversation.name);
    final primaryColor = const Color(0xFF8E6FF7); // 更新为设计稿中的紫色
    final lightPurple = const Color(0xFFF8F5FF); // 更新为设计稿中的浅紫色
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // 更圆的对话框
      ),
      title: Text(
        '重命名会话',
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w500,
          fontSize: 17,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: '输入新的会话名称',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: primaryColor,
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            style: const TextStyle(fontSize: 14),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 15,
                color: primaryColor,
              ),
              const SizedBox(width: 6),
              Text(
                '或自动生成名称',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.white,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[600],
          ),
          child: Text(
            '取消',
            style: TextStyle(
              fontSize: 14,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            final chatService = Provider.of<ChatService>(context, listen: false);
            chatService.renameConversation(
              conversation.id,
              controller.text,
            );
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
          ),
          child: Text(
            '确认',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            final chatService = Provider.of<ChatService>(context, listen: false);
            chatService.renameConversation(
              conversation.id,
              null,
              autoGenerate: true,
            );
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(
            foregroundColor: primaryColor,
          ),
          child: Text(
            '自动生成',
            style: TextStyle(
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
} 