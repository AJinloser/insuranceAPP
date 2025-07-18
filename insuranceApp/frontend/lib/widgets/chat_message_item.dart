import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';
import '../models/dify_models.dart';
import '../models/insurance_product.dart';
import '../models/goal_suggestion.dart';
import '../services/settings_service.dart';
import '../services/goal_suggestion_service.dart';
import '../widgets/insurance_product_card.dart';
import '../widgets/goal_suggestion_card.dart';
import 'dart:convert';
import 'dart:math' show min;

/// 聊天消息项组件
class ChatMessageItem extends StatelessWidget {
  final ChatMessage message;
  final bool isLastMessage;
  final bool isResponding;
  final Function(String, String?)? onFeedback;
  final Function(InsuranceProduct)? onProductSelected;

  const ChatMessageItem({
    Key? key,
    required this.message,
    this.isLastMessage = false,
    this.isResponding = false,
    this.onFeedback,
    this.onProductSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUserMessage = message.query != null;
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUserMessage)
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12.0),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.smart_toy,
                size: 24,
                color: primaryColor,
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: 
                  isUserMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // 消息气泡
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: isUserMessage ? primaryColor : Colors.grey.withAlpha(25),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isUserMessage) ...[
                        // 用户消息
                        Text(
                          message.query!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                      ] else ...[
                        // AI消息
                        if (message.answer != null)
                          _buildMessageContent(context, message.answer!),
                        
                        // 加载动画
                        if (isResponding && isLastMessage)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: _buildLoadingAnimation(),
                          ),
                      ],
                    ],
                  ),
                ),
                
                // 消息操作按钮（仅AI消息）
                if (!isUserMessage && message.answer != null && message.answer!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        _buildActionButton(
                          icon: Icons.thumb_up_outlined,
                          onPressed: () => onFeedback?.call(message.id, 'like'),
                        ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          icon: Icons.thumb_down_outlined,
                          onPressed: () => onFeedback?.call(message.id, 'dislike'),
                        ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          icon: Icons.volume_up_outlined,
                          onPressed: () {
                            // TODO: 实现语音播放
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (isUserMessage)
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(left: 12.0),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(51),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.person,
                size: 24,
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }
  
  /// 构建消息内容，支持保险产品卡片和目标建议卡片渲染
  Widget _buildMessageContent(BuildContext context, String answer) {
    
    return Consumer<SettingsService>(
      builder: (context, settingsService, child) {
        // 只在流式输出完全结束后才解析JSON内容
        // isResponding为true表示还在接收流式数据，此时不应该解析
        final shouldParseJsonContent = !isResponding;
        
        // 存储处理后的内容
        String textContent = answer;
        List<Widget> additionalWidgets = [];
        
        if (shouldParseJsonContent) {
          debugPrint('开始解析完整消息内容 (长度: ${answer.length})');
          
          // 处理目标建议 - 使用简化后的检测逻辑
          if (settingsService.goalJsonDetectionEnabled) {
            final goalSuggestions = GoalSuggestionSet.fromMarkdown(answer);
            if (goalSuggestions.isNotEmpty) {
              debugPrint('识别到${goalSuggestions.length}个目标建议集合');
              additionalWidgets.add(
                GoalSuggestionCardList(
                  suggestionSets: goalSuggestions,
                  onAccept: (suggestionSet) => _handleGoalSuggestionAccept(context, suggestionSet),
                  onReject: (suggestionSet) => _handleGoalSuggestionReject(context, suggestionSet),
                )
              );
            }
          }
          
          // 处理保险产品
          if (settingsService.insuranceJsonDetectionEnabled) {
            final products = InsuranceProduct.fromMarkdown(answer);
            if (products.isNotEmpty) {
              debugPrint('识别到${products.length}个保险产品');
              additionalWidgets.add(
                InsuranceProductCardList(
                  products: products,
                  onProductSelected: onProductSelected,
                )
              );
            }
          }
          
          // 如果找到了内容，清理文本中的JSON内容
          if (additionalWidgets.isNotEmpty) {
            // 移除完整的JSON格式内容
            textContent = textContent.replaceAll(RegExp(r'\{\s*"answer"\s*:\s*\{.*?\}\s*\}'), '');
            
            // 移除JSON代码块
            textContent = textContent.replaceAll(RegExp(r'```json\s*[\s\S]*?\s*```'), '');
            
            // 移除多余的空行
            textContent = textContent.replaceAll(RegExp(r'\n{3,}'), '\n\n');
          }
        }
        
        // 构建最终的内容
        if (additionalWidgets.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 显示文本内容，如果有的话
              if (textContent.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: MarkdownBody(
                    data: textContent,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: Colors.black87,
                      ),
                      code: TextStyle(
                        fontSize: 14,
                        backgroundColor: Colors.grey.withAlpha(51),
                        fontFamily: 'monospace',
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: Colors.grey.withAlpha(51),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              
              // 显示附加组件
              ...additionalWidgets,
            ],
          );
        }
        
        // 默认渲染为Markdown
        return MarkdownBody(
          data: answer,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.black87,
            ),
            code: TextStyle(
              fontSize: 14,
              backgroundColor: Colors.grey.withAlpha(51),
              fontFamily: 'monospace',
            ),
            codeblockDecoration: BoxDecoration(
              color: Colors.grey.withAlpha(51),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  /// 处理目标建议接受
  Future<void> _handleGoalSuggestionAccept(BuildContext context, GoalSuggestionSet suggestionSet) async {
    debugPrint('用户接受了目标建议');
    
    // 显示加载指示器
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
    
    try {
      final success = await GoalSuggestionService.acceptGoalSuggestion(context, suggestionSet);
      
      // 关闭加载指示器
      Navigator.of(context).pop();
      
      if (success) {
        // 标记为已接受
        final settingsService = Provider.of<SettingsService>(context, listen: false);
        await settingsService.markGoalSuggestionAccepted(suggestionSet.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('目标已成功添加到您的规划中'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('添加目标失败，请稍后重试'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // 关闭加载指示器
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('操作失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 处理目标建议拒绝
  void _handleGoalSuggestionReject(BuildContext context, GoalSuggestionSet suggestionSet) {
    debugPrint('用户拒绝了目标建议');
    
    GoalSuggestionService.rejectGoalSuggestion(suggestionSet);
    
    // 标记为已拒绝
    final settingsService = Provider.of<SettingsService>(context, listen: false);
    settingsService.markGoalSuggestionRejected(suggestionSet.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已忽略该目标建议'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  /// 构建加载动画
  Widget _buildLoadingAnimation() {
    return Row(
      children: [
        _buildDot(delay: 0),
        _buildDot(delay: 300),
        _buildDot(delay: 600),
      ],
    );
  }

  /// 构建单个动画点
  Widget _buildDot({required int delay}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: AnimatedDotsWidget(delayInMilliseconds: delay),
    );
  }

  /// 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(25),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  /// 构建消息文件（图片等）
  Widget _buildMessageFiles(List<dynamic> files) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: files.map((file) {
        if (file is Map<String, dynamic>) {
          final fileType = file['type'] as String?;
          final fileName = file['name'] as String?;
          final fileUrl = file['url'] as String?;
          
          if (fileType == 'image' && fileUrl != null) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  fileUrl,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 200,
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.error,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            );
          } else {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.insert_drive_file,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fileName ?? 'Unknown file',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        }
        return const SizedBox.shrink();
      }).toList(),
    );
  }
}

/// 动画点组件
class AnimatedDotsWidget extends StatefulWidget {
  final int delayInMilliseconds;

  const AnimatedDotsWidget({
    Key? key,
    required this.delayInMilliseconds,
  }) : super(key: key);

  @override
  State<AnimatedDotsWidget> createState() => _AnimatedDotsWidgetState();
}

class _AnimatedDotsWidgetState extends State<AnimatedDotsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    Future.delayed(Duration(milliseconds: widget.delayInMilliseconds), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[600]!.withOpacity(_animation.value),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
} 