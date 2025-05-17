import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/dify_models.dart';

/// 会话列表项组件
/// 用于在聊天页面显示会话历史记录
class ConversationItem extends StatelessWidget {
  final Conversation conversation;
  final bool isSelected;
  final Function()? onTap;
  final Function()? onDelete;
  final Function()? onRename;

  const ConversationItem({
    Key? key,
    required this.conversation,
    this.isSelected = false,
    this.onTap,
    this.onDelete,
    this.onRename,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    
    // 转换时间戳为可读时间
    final DateTime createdAt = DateTime.fromMillisecondsSinceEpoch(
      conversation.createdAt * 1000,
    );
    final String timeAgo = timeago.format(createdAt, locale: 'zh');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white, // 始终使用白色背景，不再根据isSelected改变
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withAlpha(51), // 始终使用灰色边框，不再根据isSelected改变
          width: 1, // 统一边框宽度为1
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // 图标
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.chat_outlined,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // 会话信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 会话名称
                    Text(
                      conversation.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // 创建时间
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 操作按钮
              if (onRename != null)
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  onPressed: onRename,
                  tooltip: '重命名',
                  splashRadius: 20,
                ),
                
              if (onDelete != null)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  onPressed: onDelete,
                  tooltip: '删除',
                  splashRadius: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
} 