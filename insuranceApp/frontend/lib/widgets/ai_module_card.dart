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
    final primaryColor = Theme.of(context).primaryColor;
    final lightPurple = const Color(0xFFEDE7F6); // 浅紫色背景
    
    // 如果应用信息不可用，显示加载中
    if (module.appInfo == null) {
      return _buildLoadingCard(context);
    }
    
    // 标签列表
    final tags = module.appInfo!.tags ?? [];
    
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? primaryColor : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
                  // 图标
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : lightPurple,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.psychology_outlined,
                      size: 18,
                      color: isSelected ? Colors.white : primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // 标题 - 使用SizedBox而不是Expanded
                  SizedBox(
                    width: width - 68, // 减去图标宽度(32)、间距(8)和内边距(2*12)
                    child: Text(
                      module.appInfo!.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
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
                  module.appInfo!.description ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: 4),
              
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
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 9,
          color: primaryColor,
        ),
      ),
    );
  }
  
  // 构建加载中的卡片
  Widget _buildLoadingCard(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: width,
        height: 140,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 8),
            Text(
              '加载中...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 