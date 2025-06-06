import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/dify_models.dart';
import '../models/insurance_product.dart';
import 'insurance_product_card.dart';
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI头像
          if (!isUserMessage)
            Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12.0),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha(26),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.smart_toy_outlined,
                size: 24,
                color: primaryColor,
              ),
            ),
          
          // 消息内容
          Expanded(
            child: Column(
              crossAxisAlignment: isUserMessage 
                ? CrossAxisAlignment.end 
                : CrossAxisAlignment.start,
              children: [
                // 消息气泡
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: isUserMessage
                        ? primaryColor
                        : Colors.grey.withAlpha(26),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: isUserMessage 
                    ? SelectableText(
                        message.query!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          height: 1.5,
                        ),
                      ) 
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // AI正在回复的动画
                          if (isResponding && isLastMessage && (message.answer == null || message.answer!.isEmpty))
                            _buildLoadingAnimation()
                          else
                            _buildMessageContent(context, message.answer ?? ''),
                            
                          // 显示文件（图片等）
                          if (message.messageFiles != null && message.messageFiles!.isNotEmpty)
                            _buildMessageFiles(message.messageFiles!),
                            
                          // 引用和归属信息
                          if (message.retrieverResources != null && message.retrieverResources!.isNotEmpty)
                            _buildRetrieverResources(message.retrieverResources!),
                        ],
                      ),
                ),
                
                // 反馈按钮（仅AI消息）
                if (!isUserMessage && onFeedback != null && !message.id.startsWith('temp_'))
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 点赞
                        IconButton(
                          icon: Icon(
                            message.feedback?.rating == 'like'
                                ? Icons.thumb_up
                                : Icons.thumb_up_outlined,
                            size: 18,
                          ),
                          onPressed: () => onFeedback!(
                            message.id,
                            message.feedback?.rating == 'like' ? null : 'like',
                          ),
                          color: message.feedback?.rating == 'like'
                              ? primaryColor
                              : null,
                        ),
                        
                        // 点踩
                        IconButton(
                          icon: Icon(
                            message.feedback?.rating == 'dislike'
                                ? Icons.thumb_down
                                : Icons.thumb_down_outlined,
                            size: 18,
                          ),
                          onPressed: () => onFeedback!(
                            message.id,
                            message.feedback?.rating == 'dislike' ? null : 'dislike',
                          ),
                          color: message.feedback?.rating == 'dislike'
                              ? Colors.red
                              : null,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // 用户头像
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
  
  /// 构建消息内容，支持保险产品卡片渲染
  Widget _buildMessageContent(BuildContext context, String answer) {
    print('解析聊天消息: ${answer.length > 100 ? answer.substring(0, 100) + '...' : answer}');
    
    // 检测是否包含JSON代码块
    final RegExp jsonBlockRegex = RegExp(r'```json\s*([\s\S]*?)\s*```');
    final matches = jsonBlockRegex.allMatches(answer);
    
    if (matches.isNotEmpty) {
      // 尝试解析保险产品
      final products = InsuranceProduct.fromMarkdown(answer);
      print('识别到${products.length}个保险产品');
      
      if (products.isNotEmpty) {
        // 处理消息中的文本内容，移除JSON代码块
        String textContent = answer;
        for (final match in matches) {
          textContent = textContent.replaceRange(
            match.start, 
            match.end, 
            ''
          );
        }
        
        // 移除多余的空行
        textContent = textContent.replaceAll(RegExp(r'\n{3,}'), '\n\n');
        
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
            
            // 显示保险产品卡片
            InsuranceProductCardList(
              products: products,
              onProductSelected: onProductSelected,
            ),
          ],
        );
      }
    } else {
      // 如果没有找到标准的JSON代码块，尝试检测可能的非标准格式JSON
      try {
        // 检查是否包含类似JSON的内容（在方括号或大括号中的内容）
        final RegExp bracketContentRegex = RegExp(r'\[\s*\{[\s\S]*?\}\s*\]|\{\s*"[\s\S]*?\}\s*');
        final bracketMatches = bracketContentRegex.allMatches(answer);
        
        if (bracketMatches.isNotEmpty) {
          for (final match in bracketMatches) {
            final content = match.group(0)!;
            try {
              // 尝试解析内容为JSON
              final dynamic parsed = json.decode(content);
              if (parsed != null) {
                print('检测到可能的JSON内容: ${content.substring(0, min(100, content.length))}...');
                
                // 构造带有JSON代码块的Markdown
                final jsonMarkdown = '```json\n$content\n```';
                final products = InsuranceProduct.fromMarkdown(jsonMarkdown);
                
                if (products.isNotEmpty) {
                  print('成功解析出${products.length}个保险产品');
                  
                  // 处理消息中的文本内容，移除JSON内容
                  String textContent = answer;
                  textContent = textContent.replaceRange(match.start, match.end, '');
                  
                  // 移除多余的空行
                  textContent = textContent.replaceAll(RegExp(r'\n{3,}'), '\n\n');
                  
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
                      
                      // 显示保险产品卡片
                      InsuranceProductCardList(
                        products: products,
                        onProductSelected: onProductSelected,
                      ),
                    ],
                  );
                }
              }
            } catch (e) {
              print('尝试解析可能的JSON内容失败: $e');
            }
          }
        }
      } catch (e) {
        print('检测非标准格式JSON时出错: $e');
      }
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

  /// 构建消息文件（图片等）
  Widget _buildMessageFiles(List<MessageFile> files) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: files.map((file) {
          if (file.type == 'image') {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                file.url,
                width: 200,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 200,
                    height: 150,
                    color: Colors.grey.withAlpha(51),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    height: 150,
                    color: Colors.grey.withAlpha(51),
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.red),
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        }).toList(),
      ),
    );
  }

  /// 构建引用和归属信息
  Widget _buildRetrieverResources(List<RetrieverResource> resources) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(26),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '引用来源',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          ...resources.map((resource) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              '${resource.position}. ${resource.documentName} - ${resource.datasetName}',
              style: const TextStyle(fontSize: 12),
            ),
          )),
        ],
      ),
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
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    Future.delayed(Duration(milliseconds: widget.delayInMilliseconds), () {
      if (mounted) {
        _controller.forward();
      }
    });

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
            color: Colors.grey.withAlpha(128 + ((_animation.value * 0.5) * 127).round()),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
} 