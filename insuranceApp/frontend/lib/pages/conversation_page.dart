import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/dify_models.dart';
import '../models/insurance_product.dart';
import '../services/chat_service.dart';
import '../widgets/ai_welcome_view.dart';
import '../widgets/chat_message_item.dart';

/// 会话详情页面
/// 显示与AI助手的对话内容
class ConversationPage extends StatefulWidget {
  final String? conversationId;
  final String? initialQuestion;
  final String? productInfo;
  final VoidCallback? onInitialQuestionSent;
  final VoidCallback? onNewConversation; // 新增回调
  final Function(String conversationId)? onConversationCreated; // 新增：会话创建回调

  const ConversationPage({
    Key? key,
    this.conversationId,
    this.initialQuestion,
    this.productInfo,
    this.onInitialQuestionSent,
    this.onNewConversation,
    this.onConversationCreated,
  }) : super(key: key);

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _hasProductInfo = false;
  bool _hasInitialQuestionSent = false; // 跟踪是否已经发送过初始问题
  
  @override
  void initState() {
    super.initState();
    debugPrint('===> ConversationPage: initState开始');
    debugPrint('===> ConversationPage: conversationId=${widget.conversationId}');
    debugPrint('===> ConversationPage: initialQuestion=${widget.initialQuestion}');
    debugPrint('===> ConversationPage: productInfo长度=${widget.productInfo?.length ?? 0}');
    
    _hasProductInfo = widget.productInfo != null && widget.productInfo!.isNotEmpty;
    
    // 如果有产品信息，打印调试信息
    if (_hasProductInfo) {
      debugPrint('===> ConversationPage: 收到产品信息，长度: ${widget.productInfo!.length}');
    }
    
    debugPrint('===> ConversationPage: 准备执行_loadConversation');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('===> ConversationPage: PostFrameCallback触发，开始加载会话');
      _loadConversation();
    });
  }
  
  @override
  void dispose() {
    // 当页面销毁时，自动终止正在进行的对话响应
    final chatService = Provider.of<ChatService>(context, listen: false);
    if (chatService.isSending) {
      chatService.stopResponse();
    }
    
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
      
      // 只有在conversationId不为空时才查找已有会话
      if (widget.conversationId != null && widget.conversationId!.isNotEmpty) {
        debugPrint('===> ConversationPage: 加载已有会话: ${widget.conversationId}');
        
        // 查找会话
        final conversation = chatService.conversations.firstWhere(
          (c) => c.id == widget.conversationId,
          orElse: () => throw Exception('会话不存在'),
        );
        
        // 加载会话详情
        await chatService.loadConversation(conversation);
      } else {
        debugPrint('===> ConversationPage: 新会话模式，等待用户发送消息');
        // 对于新会话，不需要预先创建会话，让sendMessage方法处理
        // 只需要确保已加载模块参数
        if (chatService.selectedModule?.parameters == null) {
          await chatService.loadParametersForModule(chatService.selectedModule!);
        }
        
        // 对于新会话，ChatService会在发送第一条消息时自动处理会话创建
        // 这里不需要手动设置建议问题，ChatService会处理
      }
      
      // 如果有初始问题，在页面加载完成后自动发送
      if (widget.initialQuestion != null && widget.initialQuestion!.isNotEmpty && !_hasInitialQuestionSent) {
        // 使用微延迟确保UI已经完成渲染
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _messageController.text = widget.initialQuestion!;
            _sendMessage();
          }
        });
      }
    } catch (e) {
      debugPrint('===> ConversationPage: 加载会话失败: $e');
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
      
      if (mounted) {
        // 如果有回调函数，使用回调重置到默认聊天页面（tab内导航）
        if (widget.onNewConversation != null) {
          widget.onNewConversation!();
        } else {
          // 否则使用原来的导航逻辑（独立页面导航）
          Navigator.pushReplacementNamed(
            context, 
            '/home',
            arguments: {'conversationId': chatService.currentConversation?.id}
          );
        }
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
    
    // 检查是否是初始问题，如果是则标记为已发送
    final isInitialQuestion = message == widget.initialQuestion;
    if (isInitialQuestion) {
      _hasInitialQuestionSent = true;
      // 通知HomePage清除初始数据
      if (widget.onInitialQuestionSent != null) {
        widget.onInitialQuestionSent!();
      }
    }

    _messageController.clear();
    
    final chatService = Provider.of<ChatService>(context, listen: false);
    
    // 记录发送前的会话状态
    final hadConversationBefore = chatService.currentConversation != null;
    final conversationIdBefore = chatService.currentConversation?.id;
    
    try {
      // 如果有产品信息且是首次发送消息，则包含产品信息
      if (_hasProductInfo && isInitialQuestion) {
        debugPrint('===> ConversationPage: 发送包含产品信息的消息');
        await chatService.sendMessageStreamWithInputs(
          message,
          inputs: {'text': widget.productInfo!},
        );
        // 标记产品信息已使用，后续消息不再包含
        _hasProductInfo = false;
      } else {
        await chatService.sendMessageStream(message);
      }
      
      // 检查会话状态变化，使用多次检查确保捕获到变化
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        
        final currentConversation = chatService.currentConversation;
        if (currentConversation != null) {
          final currentConversationId = currentConversation.id;
          
          // 如果之前没有会话或会话ID发生了变化，说明创建了新会话
          if ((!hadConversationBefore || conversationIdBefore != currentConversationId)) {
            debugPrint('===> ConversationPage: 检测到会话创建/变化: $currentConversationId');
            
            // 通知HomePage更新conversationId
            if (widget.onConversationCreated != null) {
              widget.onConversationCreated!(currentConversationId);
            }
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('===> ConversationPage: 发送消息失败: $e');
      // 处理发送失败的情况
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送消息失败: $e')),
      );
    }
    
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
  
  // 处理保险产品选择
  void _handleProductSelected(InsuranceProduct product) {
    print('保险产品被选中: ${product.productName}');
    
    // 暂时只是打印信息，后续会跳转到产品详情页
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('您选择了: ${product.productName}'),
        action: SnackBarAction(
          label: '查看详情',
          onPressed: () {
            // TODO: 跳转到产品详情页
            print('准备跳转到产品详情页，产品ID: ${product.productId}');
          },
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      appBar: AppBar(
        // 让AppBar自动处理leading按钮，如果可以pop则显示返回按钮，否则显示自定义菜单按钮
        leading: Navigator.canPop(context) 
            ? null // 使用系统默认的返回按钮
            : IconButton(
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
          // 简化的空状态显示，不再显示完整的欢迎视图
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '开始新的对话',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '在下方输入框输入您的问题',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
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
                onProductSelected: _handleProductSelected,
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
                onProductSelected: _handleProductSelected,
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