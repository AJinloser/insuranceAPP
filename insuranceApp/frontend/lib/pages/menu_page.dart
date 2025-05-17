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
  // 当前选中的会话ID
  String? _selectedConversationId;
  // 是否加载中
  bool _isLoading = true;
  // 是否已加载会话列表
  bool _hasLoadedConversations = false;
  
  // 主题色定义，与登录页面统一
  final Color _primaryColor = const Color(0xFF6A1B9A); // 紫色主题
  final Color _backgroundColor = Colors.white; // 白色背景
  final Color _cardColor = Colors.white; // 白色卡片
  final Color _lightPurple = const Color(0xFFEDE7F6); // 浅紫色背景
  
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
        
        // 如果尚未加载会话列表，手动加载一次
        if (!_hasLoadedConversations) {
          if (_selectedModule != null) {
            debugPrint('===> MenuPage: 初始化时加载会话列表');
            await chatService.loadConversations();
            _hasLoadedConversations = true;
          }
        }
        
        // 如果有会话，选择第一个
        if (chatService.conversations.isNotEmpty) {
          _selectedConversationId = chatService.conversations.first.id;
        }
      } else {
        // 首次初始化
        debugPrint('===> MenuPage: 首次初始化ChatService');
        await chatService.init();
        
        // ChatService初始化完成后更新状态
        _selectedModule = chatService.selectedModule;
        
        // 选择第一个会话
        if (chatService.conversations.isNotEmpty) {
          _selectedConversationId = chatService.conversations.first.id;
        }
        
        _hasLoadedConversations = true;
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
    setState(() {
      _selectedConversationId = conversationId;
    });
    
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
      _selectedConversationId = null;
    });
    
    try {
      // 选择AI模块并确保加载会话列表
      await chatService.selectAIModule(module, shouldLoadConversations: true);
      _hasLoadedConversations = true;
      
      // 如果有会话，选择第一个
      if (chatService.conversations.isNotEmpty) {
        setState(() {
          _selectedConversationId = chatService.conversations.first.id;
        });
      }
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
        title: Text(
          '菜单',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          // 添加返回按钮
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () {
              // 返回首页
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _primaryColor))
          : _buildBody(),
    );
  }
  
  Widget _buildBody() {
    final chatService = Provider.of<ChatService>(context);
    final size = MediaQuery.of(context).size;
    final double verticalPadding = size.height * 0.02; // 根据屏幕高度调整垂直间距
    
    return Container(
      color: _backgroundColor,
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, verticalPadding * 0.5, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // AI模块选择区域
              _buildSectionTitle('AI 助手', Icons.smart_toy),
              SizedBox(height: verticalPadding * 0.6),
              _buildAIModulesSection(chatService),
              
              SizedBox(height: verticalPadding * 1.2),
              
              // 历史会话区域
              _buildSectionTitle('历史对话', Icons.history),
              SizedBox(height: verticalPadding * 0.6),
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
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, color: _primaryColor, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
        ],
      ),
    );
  }
  
  // 构建AI模块选择区域
  Widget _buildAIModulesSection(ChatService chatService) {
    final size = MediaQuery.of(context).size;
    final cardWidth = size.width > 600 ? 200.0 : 180.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            '选择你需要的AI助手类型',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
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
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: AIModuleCard(
                  module: module,
                  isSelected: _selectedModule?.apiKey == module.apiKey,
                  onTap: () => _selectAIModule(module),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  // 构建历史会话区域
  Widget _buildConversationsSection(ChatService chatService) {
    final size = MediaQuery.of(context).size;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            '继续之前的对话',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
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
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '暂无会话，返回对话页面新建对话',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
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
                    color: Colors.grey[200],
                  ),
                  itemBuilder: (context, index) {
                    final conversation = chatService.conversations[index];
                    return ConversationItem(
                      conversation: conversation,
                      isSelected: conversation.id == _selectedConversationId,
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
    final primaryColor = const Color(0xFF6A1B9A); // 紫色主题
    final lightPurple = const Color(0xFFEDE7F6); // 浅紫色
    
    return AlertDialog(
      title: Text(
        '重命名会话',
        style: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: '输入新的会话名称',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: primaryColor,
                  width: 2,
                ),
              ),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 16,
                color: primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                '或自动生成名称',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            '取消',
            style: TextStyle(
              color: Colors.grey[700],
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
          child: Text(
            '确认',
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
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
          child: Text(
            '自动生成',
            style: TextStyle(
              color: primaryColor,
            ),
          ),
        ),
      ],
    );
  }
} 