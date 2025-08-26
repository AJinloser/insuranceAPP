import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/dify_models.dart';
import '../services/chat_service.dart';
import '../services/settings_service.dart';
import '../services/comparison_chat_service.dart';
import '../services/insurance_chat_service.dart';
import '../services/analysis_chat_service.dart';
import '../widgets/ai_module_card.dart';
import '../widgets/ai_welcome_view.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import 'menu_page.dart';
import 'conversation_page.dart';

/// 默认聊天页面
/// 智能助手模块的初始页面，包含AI模块选择、欢迎语和输入框
class DefaultChatPage extends StatefulWidget {
  final Function(String conversationId, String initialQuestion)? onStartConversation;
  
  const DefaultChatPage({
    Key? key,
    this.onStartConversation,
  }) : super(key: key);

  @override
  State<DefaultChatPage> createState() => _DefaultChatPageState();
}

class _DefaultChatPageState extends State<DefaultChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = true;
  AIModule? _selectedModule;

  // 主题色定义，与其他页面保持一致
  final Color _primaryColor = const Color(0xFF6A1B9A); // 紫色主题

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 初始化页面
  Future<void> _initializePage() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      
      // 确保AI模块已加载
      if (chatService.aiModules.isEmpty) {
        await chatService.init();
      }
      
      // 如果有选中的模块，保持选中状态
      if (chatService.selectedModule != null) {
        _selectedModule = chatService.selectedModule;
        
        // 加载模块参数（如果还没有加载）
        if (_selectedModule!.parameters == null) {
          await chatService.loadParametersForModule(_selectedModule!);
        }
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
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 选择AI模块
  Future<void> _selectModule(AIModule module) async {
    if (_selectedModule?.apiKey == module.apiKey) return;

    setState(() {
      _selectedModule = module;
    });

    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      
      // 切换模块
      await chatService.selectAIModule(module);
      
      // 加载模块参数
      if (module.parameters == null) {
        await chatService.loadParametersForModule(module);
      }
      
      // 更新UI
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('===> DefaultChatPage: 选择模块失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('切换模块失败: $e')),
        );
      }
    }
  }

  /// 发送消息
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    if (_selectedModule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择一个AI模块')),
      );
      return;
    }

    // 清空输入框
    _messageController.clear();

    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      
      // 确保选中了正确的模块
      if (chatService.selectedModule?.apiKey != _selectedModule!.apiKey) {
        await chatService.selectAIModule(_selectedModule!);
      }
      
      // 创建新会话（重置会话状态）
      await chatService.createNewConversation();

      // 对于新会话，不传递conversationId，只传递initialQuestion
      // 会话ID将在发送第一条消息时由Dify API返回
      if (mounted && widget.onStartConversation != null) {
        widget.onStartConversation!('', message); // 传递空字符串表示新会话
      }
    } catch (e) {
      debugPrint('===> DefaultChatPage: 发送消息失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送失败: $e')),
        );
        // 如果发送失败，恢复输入框内容
        _messageController.text = message;
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
    return Column(
      children: [
        // 主要内容区域
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo
                _buildLogo(),
                const SizedBox(height: 20),
                
                // 欢迎语
                _buildWelcomeMessage(),
                const SizedBox(height: 24),
                
                // AI模块选择
                _buildModuleSelection(),
                const SizedBox(height: 20),
                
                // 选中模块的详细信息
                _buildSelectedModuleInfo(),
              ],
            ),
          ),
        ),
        
        // 底部输入区域
        _buildInputArea(),
      ],
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

  /// 构建欢迎消息
  Widget _buildWelcomeMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.shade200),
      ),
      child: Column(
        children: [
          Icon(
            Icons.waving_hand,
            color: _primaryColor,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            '欢迎来到 Skysail 平台！',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '您可以选择下列的AI智能助手进行交流，或者点击左上角的菜单按钮继续您之前的对话！',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建AI模块选择
  Widget _buildModuleSelection() {
    return Consumer2<ChatService, SettingsService>(
      builder: (context, chatService, settingsService, child) {
        if (chatService.aiModules.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.grey[400],
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  '暂无可用的AI模块',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        // 根据功能开关过滤AI模块
        final filteredModules = _getFilteredModules(chatService.aiModules, settingsService);

        if (filteredModules.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.settings,
                  color: Colors.grey[400],
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  '当前功能开关已关闭',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '请在菜单中开启相关功能',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'AI智能助手',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filteredModules.length,
                itemBuilder: (context, index) {
                  final module = filteredModules[index];
                  final isSelected = _selectedModule?.apiKey == module.apiKey;
                  
                  return AIModuleCard(
                    module: module,
                    isSelected: isSelected,
                    onTap: () => _selectModule(module),
                  );
                },
              ),
            ),
          ],
        );
      },
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

  /// 构建选中模块的详细信息
  Widget _buildSelectedModuleInfo() {
    if (_selectedModule == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(
              Icons.touch_app,
              color: Colors.grey[400],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              '请选择一个AI助手开始对话',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final parameters = _selectedModule!.parameters;
    final appInfo = _selectedModule!.appInfo;

    if (parameters == null || appInfo == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircularProgressIndicator(color: _primaryColor),
            const SizedBox(height: 12),
            const Text('加载AI模块信息...'),
          ],
        ),
      );
    }

    // 使用AIWelcomeView组件展示模块信息
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: AIWelcomeView(
        moduleName: appInfo.name,
        parameters: parameters,
        onSubmit: (formData) async {
          // 处理表单提交
          if (formData.containsKey('question')) {
            _messageController.text = formData['question']!;
            await _sendMessage();
            return;
          }
          
          // 拼接表单数据为消息
          final message = formData.entries
              .map((entry) => '${entry.key}: ${entry.value}')
              .join('\n');
          
          if (message.isNotEmpty) {
            _messageController.text = message;
            await _sendMessage();
          }
        },
      ),
    );
  }

  /// 构建输入区域
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 输入框
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: '请输入您的问题...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: _primaryColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 12),
            
            // 发送按钮
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 