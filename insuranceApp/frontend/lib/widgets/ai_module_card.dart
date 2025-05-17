import 'package:flutter/material.dart';

import '../models/dify_models.dart';

/// AI模块卡片组件
/// 用于在聊天页面显示AI模块信息
class AIModuleCard extends StatelessWidget {
  final AIModule module;
  final bool isSelected;
  final VoidCallback onTap;
  final double width;

  const AIModuleCard({
    Key? key,
    required this.module,
    this.isSelected = false,
    required this.onTap,
    this.width = 180,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor; // #8E6FF7 紫色
    final lightPurple = const Color(0xFFF8F5FF); // 更新为设计稿中的浅紫色背景
    
    // 如果应用信息不可用，显示加载中
    if (module.appInfo == null) {
      return _buildLoadingCard(context);
    }
    
    // 标签列表
    final tags = module.appInfo!.tags;
    
    return Card(
      elevation: isSelected ? 2 : 0, // 减小阴影
      margin: const EdgeInsets.only(right: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // 更小的圆角
        side: BorderSide(
          color: isSelected ? primaryColor : Colors.grey.withAlpha(30),
          width: 1, // 统一边框宽度
        ),
      ),
      color: isSelected ? lightPurple : Colors.white, // 选中时使用浅紫色背景
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12), // 和外部边框一致
        child: Container(
          width: width,
          height: 140, // 固定高度防止溢出
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 模块标题和图标
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 图标 - 采用设计稿的样式
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.smart_toy_outlined, // 更新为机器人图标
                      size: 18,
                      color: isSelected ? primaryColor : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // 标题 - 使用SizedBox而不是Expanded
                  SizedBox(
                    width: width - 68, // 减去图标宽度(32)、间距(8)和内边距(2*12)
                    child: Text(
                      module.appInfo!.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500, // 中等粗细
                        color: isSelected ? primaryColor : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // 描述 - 使用SizedBox而不是Expanded
              SizedBox(
                height: 44, // 固定高度，大约2行文本
                child: Text(
                  module.appInfo!.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.4, // 行高稍微紧凑一点
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: 6),
              
              // 标签列表
              if (tags.isNotEmpty)
                SizedBox(
                  height: 20,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: tags.map((tag) => _buildTag(tag, primaryColor)).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 构建标签小组件
  Widget _buildTag(String tag, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.08), // 更淡的背景色
        borderRadius: BorderRadius.circular(10), // 圆角更大，接近胶囊形状
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400, // 正常粗细
          color: primaryColor,
        ),
      ),
    );
  }
  
  // 构建加载中的卡片
  Widget _buildLoadingCard(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.grey.withAlpha(30),
          width: 1,
        ),
      ),
      child: Container(
        width: width,
        height: 140,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3, // 更细的加载指示器
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
            const SizedBox(height: 12),
            Text(
              '加载中...',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 