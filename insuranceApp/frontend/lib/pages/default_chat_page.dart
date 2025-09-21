import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/dify_models.dart';
import '../services/chat_service.dart';
import '../services/settings_service.dart';
import '../services/comparison_chat_service.dart';
import '../services/insurance_chat_service.dart';
import 'menu_page.dart';
import 'conversation_page.dart';

/// 默认聊天页面
/// 智能助手模块的选择页面，展示可用的AI助手
class DefaultChatPage extends StatefulWidget {
  final Function(AIModule module)? onModuleSelected;
  
  const DefaultChatPage({
    Key? key,
    this.onModuleSelected,
  }) : super(key: key);

  @override
  State<DefaultChatPage> createState() => _DefaultChatPageState();
}

class _DefaultChatPageState extends State<DefaultChatPage> {
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = true;

  // 主题色定义，与其他页面保持一致
  final Color _primaryColor = const Color(0xFF6A1B9A); // 紫色主题

  @override
  void initState() {
    super.initState();
    debugPrint('===> DefaultChatPage: initState called');
    _initializePage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 初始化页面
  Future<void> _initializePage() async {
    debugPrint('===> DefaultChatPage: _initializePage start');
    
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      debugPrint('===> DefaultChatPage: ChatService obtained, modules count: ${chatService.aiModules.length}');
      
      // 确保AI模块已加载
      if (chatService.aiModules.isEmpty) {
        debugPrint('===> DefaultChatPage: AI modules empty, initializing...');
        await chatService.init();
        debugPrint('===> DefaultChatPage: AI modules initialized, count: ${chatService.aiModules.length}');
      } else {
        debugPrint('===> DefaultChatPage: AI modules already loaded');
      }
    } catch (e) {
      debugPrint('===> DefaultChatPage: 初始化失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('初始化失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        debugPrint('===> DefaultChatPage: Setting _isLoading = false');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 选择AI模块并进入对话
  Future<void> _selectModule(AIModule module) async {
    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      
      // 切换模块
      await chatService.selectAIModule(module);
      
      // 加载模块参数
      if (module.parameters == null) {
        await chatService.loadParametersForModule(module);
      }
      
      // 创建新会话
      await chatService.createNewConversation();
      
      // 通知上级组件模块被选中，或直接导航
      if (widget.onModuleSelected != null) {
        widget.onModuleSelected!(module);
      } else {
        // 如果没有回调，直接导航到对话页面
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ConversationPage(),
          ),
        );
      }
    } catch (e) {
      debugPrint('===> DefaultChatPage: 选择模块失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择模块失败: $e')),
        );
      }
    }
  }


  /// 跳转到菜单页面
  void _navigateToMenu() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MenuPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('===> DefaultChatPage: build called, _isLoading: $_isLoading');
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: _primaryColor),
          onPressed: _navigateToMenu,
        ),
        title: Text(
          '智能助手',
          style: TextStyle(
            color: _primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: _primaryColor),
            )
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Center(child: _buildLogo()),
          const SizedBox(height: 24),
          
          // 引导性内容
          _buildGuidanceContent(),
          const SizedBox(height: 32),
          
          // AI模块选择标题
          _buildSectionTitle(),
          const SizedBox(height: 16),
          
          // AI模块列表（纵向）
          _buildModuleList(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// 构建Logo
  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Image.asset(
        'assets/logo/logo-site.png',
        height: 80,
        fit: BoxFit.contain,
      ),
    );
  }

  /// 构建引导性内容
  Widget _buildGuidanceContent() {
    return Column(
      children: [
        // 欢迎信息卡片
        _buildWelcomeCard(),
      ],
    );
  }

  /// 构建欢迎信息卡片
  Widget _buildWelcomeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _primaryColor,
              _primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.waving_hand,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '欢迎来到 Skysail 智能助手',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '为您提供专业的保险咨询和个性化的财务规划建议',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }





  /// 构建章节标题
  Widget _buildSectionTitle() {
    return Text(
      '选择AI智能助手',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.grey[800],
      ),
    );
  }

  /// 构建AI模块列表（纵向）
  Widget _buildModuleList() {
    return Consumer2<ChatService, SettingsService>(
      builder: (context, chatService, settingsService, child) {
        if (chatService.aiModules.isEmpty) {
          return _buildEmptyState(
            Icons.info_outline,
            '暂无可用的AI模块',
            '请稍后重试或联系管理员',
          );
        }

        // 根据功能开关过滤AI模块
        final filteredModules = _getFilteredModules(chatService.aiModules, settingsService);

        if (filteredModules.isEmpty) {
          return _buildEmptyState(
            Icons.settings,
            '当前功能开关已关闭',
            '请在菜单中开启相关功能',
          );
        }

        return Column(
          children: filteredModules.map((module) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: _buildVerticalModuleCard(module),
            );
          }).toList(),
        );
      },
    );
  }

  /// 构建空状态显示
  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.grey[400],
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建纵向AI模块卡片
  Widget _buildVerticalModuleCard(AIModule module) {
    if (module.appInfo == null) {
      return _buildLoadingModuleCard();
    }

    return InkWell(
      onTap: () => _selectModule(module),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 左侧图标区域
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.smart_toy_outlined,
                color: _primaryColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            
            // 中间内容区域
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    module.appInfo!.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    module.appInfo!.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (module.appInfo!.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: module.appInfo!.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 12,
                              color: _primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            
            // 右侧箭头
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建加载中的模块卡片
  Widget _buildLoadingModuleCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 18,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 根据功能开关过滤AI模块
  List<AIModule> _getFilteredModules(List<AIModule> modules, SettingsService settingsService) {
    final List<AIModule> filteredModules = [];
    
    for (final module in modules) {
      bool shouldInclude = true;
      
      // 检查是否是产品对比模块
      if (module.apiKey == ComparisonChatService.comparisonChatApiKey) {
        shouldInclude = settingsService.productComparisonEnabled;
      }
      // 检查是否是产品对话模块
      else if (module.apiKey == InsuranceChatService.insuranceChatApiKey) {
        shouldInclude = settingsService.productChatEnabled;
      }
      // 检查是否是保单分析模块
      else if (module.apiKey == dotenv.env['CHAT_WITH_INSURANCE_LIST_KEY']) {
        shouldInclude = settingsService.insuranceAnalysisEnabled;
      }
      
      if (shouldInclude) {
        filteredModules.add(module);
      }
    }
    
    return filteredModules;
  }

} 