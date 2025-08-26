import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dify_models.dart';
import '../services/chat_service.dart';
import '../services/settings_service.dart';
import '../widgets/ai_module_card.dart';
import '../widgets/conversation_item.dart';

/// 菜单页面
/// 包含AI模块选择、会话列表和设置选项，右上角有返回按钮
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
    // 初始化聊天服务和设置服务
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initServices();
    });
  }
  
  // 初始化服务
  Future<void> _initServices() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 初始化设置服务
      final settingsService = SettingsService();
      await settingsService.init();
      
      // 初始化聊天服务
      await _initChatService();
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
  
  // 初始化聊天服务
  Future<void> _initChatService() async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    
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
        SnackBar(content: Text('初始化聊天服务失败: $e')),
      );
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
                height: size.height * 0.35, // 减少高度为设置区域留空间
                child: _buildConversationsSection(chatService),
              ),
              
              SizedBox(height: verticalPadding * 1.0),
              
              // 设置区域
              _buildSectionTitle('设置', Icons.settings_outlined),
              SizedBox(height: verticalPadding * 0.4),
              _buildSettingsSection(),
              
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
  
  // 构建设置区域
  Widget _buildSettingsSection() {
    return Consumer<SettingsService>(
      builder: (context, settingsService, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                '智能功能开关',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 保险产品JSON检测开关
                    SwitchListTile(
                      title: const Text(
                        '保险产品检测',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: const Text(
                        '自动检测AI回答中的保险产品信息',
                        style: TextStyle(fontSize: 14),
                      ),
                      value: settingsService.insuranceJsonDetectionEnabled,
                      onChanged: (value) {
                        settingsService.setInsuranceJsonDetectionEnabled(value);
                      },
                      activeColor: Theme.of(context).primaryColor,
                    ),

                    const Divider(height: 1),

                    // 目标检测开关
                    SwitchListTile(
                      title: const Text(
                        '目标建议检测',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: const Text(
                        '自动检测AI回答中的目标建议信息',
                        style: TextStyle(fontSize: 14),
                      ),
                      value: settingsService.goalJsonDetectionEnabled,
                      onChanged: (value) {
                        settingsService.setGoalJsonDetectionEnabled(value);
                      },
                      activeColor: Theme.of(context).primaryColor,
                    ),

                    const Divider(height: 1),

                    // 产品对比功能开关
                    SwitchListTile(
                      title: const Text(
                        '产品对比功能',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: const Text(
                        '启用保险产品对比功能',
                        style: TextStyle(fontSize: 14),
                      ),
                      value: settingsService.productComparisonEnabled,
                      onChanged: (value) {
                        settingsService.setProductComparisonEnabled(value);
                      },
                      activeColor: Theme.of(context).primaryColor,
                    ),

                    const Divider(height: 1),

                    // 产品对话功能开关
                    SwitchListTile(
                      title: const Text(
                        '产品对话功能',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: const Text(
                        '启用与保险产品对话功能',
                        style: TextStyle(fontSize: 14),
                      ),
                      value: settingsService.productChatEnabled,
                      onChanged: (value) {
                        settingsService.setProductChatEnabled(value);
                      },
                      activeColor: Theme.of(context).primaryColor,
                    ),

                    const Divider(height: 1),

                    // 保单分析功能开关
                    SwitchListTile(
                      title: const Text(
                        '保单分析功能',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: const Text(
                        '启用保单分析对话功能',
                        style: TextStyle(fontSize: 14),
                      ),
                      value: settingsService.insuranceAnalysisEnabled,
                      onChanged: (value) {
                        settingsService.setInsuranceAnalysisEnabled(value);
                      },
                      activeColor: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  // 构建设置项
  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _primaryColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: _primaryColor,
        ),
      ],
    );
  }
  
  // 构建重命名对话框
  Widget _buildRenameDialog(Conversation conversation) {
    final controller = TextEditingController(text: conversation.name);
    
    return AlertDialog(
      title: const Text('重命名对话'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          hintText: '输入新的对话名称',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () async {
            final newName = controller.text.trim();
            if (newName.isNotEmpty) {
              Navigator.pop(context);
              final chatService = Provider.of<ChatService>(context, listen: false);
              await chatService.renameConversation(conversation.id, newName);
            }
          },
          child: const Text('确定'),
        ),
      ],
    );
  }
} 