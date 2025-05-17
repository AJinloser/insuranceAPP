import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dify_models.dart';
import '../services/chat_service.dart';
import '../widgets/ai_welcome_view.dart';
import '../widgets/chat_message_item.dart';

/// 会话详情页面
/// 显示与AI助手的对话内容
class ConversationPage extends StatefulWidget {
  final String? conversationId;
  final String? initialQuestion;

  const ConversationPage({
    Key? key,
    this.conversationId,
    this.initialQuestion,
  }) : super(key: key);

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConversation();
    });
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  // 加载会话
  Future<void> _loadConversation() async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      debugPrint('===> ConversationPage: 开始加载会话');
      
      // 如果当前选中的模块没有parameters，先加载parameters
      if (chatService.selectedModule != null && 
          chatService.selectedModule!.parameters == null) {
        debugPrint('===> ConversationPage: 加载模块参数');
        await chatService.loadParametersForModule(chatService.selectedModule!);
      }
      
      if (widget.conversationId != null) {
        // 查找会话
        final conversation = chatService.conversations.firstWhere(
          (c) => c.id == widget.conversationId,
          orElse: () => throw Exception('会话不存在'),
        );
        
        // 加载会话详情
        await chatService.loadConversation(conversation);
      }
      
      // 如果有初始问题，在页面加载完成后自动发送
      if (widget.initialQuestion != null && widget.initialQuestion!.isNotEmpty) {
        // 使用微延迟确保UI已经完成渲染
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _messageController.text = widget.initialQuestion!;
            _sendMessage();
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载会话失败: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 创建新会话
  Future<void> _createNewConversation() async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await chatService.createNewConversation();
      
      // 导航到首页（而不是直接刷新当前页面）
      if (mounted) {
        Navigator.pushReplacementNamed(
          context, 
          '/home',
          arguments: {'conversationId': chatService.currentConversation?.id}
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('创建会话失败: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // 发送消息
  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    _messageController.clear();
    
    final chatService = Provider.of<ChatService>(context, listen: false);
    await chatService.sendMessageStream(message);
    
    // 滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  // 停止响应
  void _stopResponse() {
    final chatService = Provider.of<ChatService>(context, listen: false);
    chatService.stopResponse();
  }
  
  // 消息反馈
  void _sendFeedback(String messageId, String? rating) {
    final chatService = Provider.of<ChatService>(context, listen: false);
    chatService.sendFeedback(messageId, rating);
  }
  
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            // 导航到菜单页面
            Navigator.pushNamed(context, '/menu');
          },
        ),
        title: Consumer<ChatService>(
          builder: (context, chatService, child) {
            final conversation = chatService.currentConversation;
            return Text(
              conversation?.name ?? '新对话',
              style: const TextStyle(color: Colors.white),
            );
          },
        ),
        actions: [
          // 右侧新建对话按钮
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _createNewConversation,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _buildBody(),
    );
  }
  
  Widget _buildBody() {
    return Column(
      children: [
        // 消息列表
        Expanded(
          child: _buildMessageList(),
        ),
        
        // 输入框
        _buildInputArea(),
      ],
    );
  }
  
  Widget _buildMessageList() {
    return Consumer<ChatService>(
      builder: (context, chatService, child) {
        final messages = chatService.messages;
        final suggestedQuestions = chatService.suggestedQuestions;
        
        if (messages.isEmpty) {
          return _buildWelcomeView(chatService);
        }
        
        // 将每条消息拆分为用户问题和AI回答两个独立项
        // 说明：在DifyAPI返回的历史消息中，一个message对象同时包含query(用户问题)和answer(AI回答)
        // 但在实时发送的消息中，用户消息和AI回答是分开的两个message对象
        // 为了统一显示效果，这里将历史消息也拆分为两个独立的消息项显示
        List<Widget> messageWidgets = [];
        
        for (int index = 0; index < messages.length; index++) {
          final message = messages[index];
          final isLastMessage = index == 0;
          
          // 如果同时有问题和回答，创建两个独立的消息项
          if (message.query != null && message.query!.isNotEmpty && 
              message.answer != null && message.answer!.isNotEmpty) {
            
            // 由于ListView是reverse: true，所以需要先添加AI回答消息，再添加用户问题消息
            // 这样在显示时，用户问题会在上面，AI回答会在下面
            
            // AI回复消息，需要正确传递feedback状态
            messageWidgets.add(
              ChatMessageItem(
                message: ChatMessage(
                  id: message.id,
                  conversationId: message.conversationId,
                  query: null, // 确保问题为空，这样ChatMessageItem会将其识别为AI消息
                  answer: message.answer,
                  messageFiles: message.messageFiles,
                  feedback: message.feedback, // 保留原始消息的feedback状态
                  retrieverResources: message.retrieverResources,
                  createdAt: message.createdAt,
                ),
                isLastMessage: isLastMessage,
                isResponding: chatService.isSending && isLastMessage,
                onFeedback: _sendFeedback,
              ),
            );
            
            // 如果是最后一条消息且有建议问题，显示建议问题
            if (isLastMessage && !chatService.isSending && suggestedQuestions.isNotEmpty) {
              messageWidgets.add(_buildSuggestedQuestions(suggestedQuestions));
            }
            
            // 用户问题消息
            messageWidgets.add(
              ChatMessageItem(
                message: ChatMessage(
                  id: "${message.id}_user",
                  conversationId: message.conversationId,
                  query: message.query,
                  answer: null, // 确保答案为空，这样ChatMessageItem会将其识别为用户消息
                  createdAt: message.createdAt,
                ),
                isLastMessage: false,
                isResponding: false,
                onFeedback: _sendFeedback,
              ),
            );
          } else {
            // 如果只有问题或只有回答，直接添加原始消息
            // 这适用于实时发送的消息，比如用户刚发送的问题或AI正在生成的回答
            messageWidgets.add(
              ChatMessageItem(
                message: message,
                isLastMessage: isLastMessage,
                isResponding: chatService.isSending && isLastMessage,
                onFeedback: _sendFeedback,
              ),
            );
            
            // 如果是最后一条AI回复消息且不是正在发送状态，显示建议问题
            if (isLastMessage && message.answer != null && message.answer!.isNotEmpty && 
                !chatService.isSending && suggestedQuestions.isNotEmpty) {
              messageWidgets.add(_buildSuggestedQuestions(suggestedQuestions));
            }
          }
        }
        
        return ListView(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.all(16.0),
          children: messageWidgets,
        );
      },
    );
  }
  
  Widget _buildWelcomeView(ChatService chatService) {
    // 如果没有选中模块，显示默认欢迎视图
    if (chatService.selectedModule == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.smart_toy_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              '请选择一个AI模块开始对话',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    final selectedModule = chatService.selectedModule!;
    final parameters = selectedModule.parameters;
    final appInfo = selectedModule.appInfo;
    
    // 如果参数和应用信息都不可用，显示加载中
    if (parameters == null || appInfo == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            const Text('加载AI模块信息...'),
          ],
        ),
      );
    }
    
    // 使用AIWelcomeView组件展示AI模块欢迎界面
    return AIWelcomeView(
      moduleName: appInfo.name,
      parameters: parameters,
      onSubmit: (formData) async {
        // 如果包含question字段，直接发送问题
        if (formData.containsKey('question')) {
          _messageController.text = formData['question']!;
          await _sendMessage();
          return;
        }
        
        // 否则，拼接所有表单数据为一条消息发送
        final message = formData.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join('\n');
        
        if (message.isNotEmpty) {
          _messageController.text = message;
          await _sendMessage();
        }
      },
    );
  }
  
  Widget _buildInputArea() {
    return Consumer<ChatService>(
      builder: (context, chatService, child) {
        final isSending = chatService.isSending;
        final primaryColor = Theme.of(context).primaryColor;
        
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(13),
                blurRadius: 5,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            children: [
              // 输入框
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: '输入消息...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.withAlpha(26),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  enabled: !isSending,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 发送/停止按钮
              isSending
                  ? IconButton(
                      onPressed: _stopResponse,
                      icon: const Icon(Icons.stop_circle),
                      color: Colors.red,
                    )
                  : IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send),
                      color: primaryColor,
                    ),
            ],
          ),
        );
      },
    );
  }
  
  // 构建建议问题UI
  Widget _buildSuggestedQuestions(List<String> questions) {
    final primaryColor = Theme.of(context).primaryColor;
    final lightPurple = const Color(0xFFF8F5FF);
    
    return Container(
      padding: const EdgeInsets.only(left: 60, top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
            child: Text(
              '你可能想问：',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: questions.map((question) {
              return InkWell(
                onTap: () {
                  _messageController.text = question;
                  _sendMessage();
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: lightPurple,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    question,
                    style: TextStyle(
                      fontSize: 13,
                      color: primaryColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
} 