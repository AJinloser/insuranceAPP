import 'package:flutter/material.dart';
import '../models/insurance_product.dart';

/// 保险产品卡片组件
class InsuranceProductCard extends StatelessWidget {
  final InsuranceProduct product;
  final VoidCallback? onViewDetails;
  final VoidCallback? onAddToComparison;
  
  const InsuranceProductCard({
    Key? key,
    required this.product,
    this.onViewDetails,
    this.onAddToComparison,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: GestureDetector(
        onTap: () {
          debugPrint('===> 产品卡片被点击: ${product.productName}');
          if (onViewDetails != null) {
            onViewDetails!();
          }
        },
        onLongPress: () {
          debugPrint('===> 产品卡片被长按: ${product.productName}');
          _showMobileMenu(context);
        },
        behavior: HitTestBehavior.translucent,
        child: Container(
          padding: const EdgeInsets.all(16),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行：产品名称 + 热门标签
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.productName ?? '未知产品',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if ((product.totalScore ?? 0) >= 80)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '热门',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 4),
              
              // 公司名称 + 保险类型
              Text(
                '${product.companyName ?? ''} ${product.insuranceType != null ? '· ${product.insuranceType}' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              // 一句话概括（如果有）
              if (product.getDescription() != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    product.getDescription()!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              
              const SizedBox(height: 12),
              
              // 保障标签或重点内容
              _buildHighlights(context),
              
              const SizedBox(height: 16),
              
              // 底部信息：保费 + 评分 + 查看详情按钮
              Row(
                children: [
                  // 保费
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.getPremiumDisplay(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '起/年',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 评分
                  if (product.totalScore != null)
                    Flexible(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              product.getScoreDisplay(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // 查看详情按钮 - 使用GestureDetector防止冲突
                  Flexible(
                    child: GestureDetector(
                      onTap: () {
                        // 防止事件冲突，直接调用
                        debugPrint('===> 详情按钮被点击');
                        if (onViewDetails != null) {
                          onViewDetails!();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '详情',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// 显示移动端友好的长按菜单
  void _showMobileMenu(BuildContext context) {
    // 给用户一个触觉反馈，表示长按被识别
    // HapticFeedback.lightImpact(); // 可以添加触觉反馈

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部指示条
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 产品名称
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                product.productName ?? '未知产品',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // 菜单选项
            ListTile(
              leading: Icon(
                Icons.compare_arrows,
                color: Colors.blue[600],
                size: 24,
              ),
              title: const Text(
                '进行对比',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: const Text(
                '添加到产品对比列表',
                style: TextStyle(fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(context);
                if (onAddToComparison != null) {
                  onAddToComparison!();
                }
              },
            ),
            
            const Divider(height: 1),
            
            ListTile(
              leading: Icon(
                Icons.visibility,
                color: Colors.green[600],
                size: 24,
              ),
              title: const Text(
                '查看详情',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: const Text(
                '查看完整产品信息',
                style: TextStyle(fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(context);
                if (onViewDetails != null) {
                  onViewDetails!();
                }
              },
            ),
            
            const SizedBox(height: 10),
            
            // 取消按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: Colors.grey[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    '取消',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            
            // 底部安全区域
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
  
  /// 构建保障标签或重点内容
  Widget _buildHighlights(BuildContext context) {
    // 先尝试获取保障重点内容
    final highlights = product.getCoverageHighlights();
    if (highlights.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: highlights.map((highlight) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              highlight,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )
        ).toList(),
      );
    }
    
    // 如果没有重点内容，则显示标签
    return _buildTags(context);
  }
  
  /// 构建保障标签
  Widget _buildTags(BuildContext context) {
    // 从产品信息中提取保障内容
    final List<String> tags = _extractTags();
    
    // 限制标签数量，避免过多标签导致布局问题
    final displayTags = tags.take(3).toList();
    
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: displayTags.map((tag) => _buildTag(context, tag)).toList(),
    );
  }
  
  /// 构建单个标签
  Widget _buildTag(BuildContext context, String text) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 80), // 限制标签最大宽度
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: _getTagColor(text).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getTagColor(text).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: _getTagColor(text),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
  
  /// 根据标签内容获取颜色
  Color _getTagColor(String tag) {
    final String normalizedTag = tag.trim().split(':').first.trim();
    
    switch (normalizedTag) {
      case '重疾':
        return Colors.red.shade700;
      case '轻症':
        return Colors.orange.shade700;
      case '身故':
        return Colors.purple.shade700;
      case '医疗':
        return Colors.blue.shade700;
      case '意外':
        return Colors.green.shade700;
      case '保障':
        return Colors.blue.shade700;
      case '理赔':
        return Colors.orange.shade700;
      case '增值':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
  
  /// 从产品信息中提取标签
  List<String> _extractTags() {
    final List<String> tags = [];
    
    // 首先检查是否有保障重点
    final highlights = product.getCoverageHighlights();
    if (highlights.isNotEmpty) {
      // 提取重点内容中的关键词作为标签
      for (final highlight in highlights) {
        final parts = highlight.split(':');
        if (parts.length > 1) {
          final tagName = parts[0].trim();
          tags.add(tagName);
        }
      }
      if (tags.isNotEmpty) {
        return tags;
      }
    }
    
    // 如果没有重点内容，使用默认的标签提取逻辑
    if (product.insuranceType != null) {
      if (product.insuranceType!.contains('重疾')) {
        tags.add('重疾');
      }
      if (product.insuranceType!.contains('医疗')) {
        tags.add('医疗');
      }
      if (product.insuranceType!.contains('意外')) {
        tags.add('意外');
      }
      if (product.insuranceType!.contains('寿险')) {
        tags.add('身故');
      }
    }
    
    // 从产品名称中提取关键词
    if (product.productName != null) {
      final String name = product.productName!.toLowerCase();
      if (name.contains('意外')) tags.add('意外');
      if (name.contains('医疗')) tags.add('医疗');
      if (name.contains('重疾') || name.contains('重大疾病')) tags.add('重疾');
      if (name.contains('教育') || name.contains('少儿')) tags.add('教育');
      if (name.contains('养老')) tags.add('养老');
    }
    
    // 从保障内容中提取更多标签
    if (product.coverageContent is Map<String, dynamic>) {
      final coverage = product.coverageContent as Map<String, dynamic>;
      
      // 检查是否有轻症保障
      if (coverage.toString().contains('轻症')) {
        tags.add('轻症');
      }
    }
    
    // 如果没有提取到标签，添加默认标签
    if (tags.isEmpty) {
      tags.addAll(['身故', '保障']);
    }
    
    return tags;
  }
}

/// 保险产品卡片列表组件
class InsuranceProductCardList extends StatelessWidget {
  final List<InsuranceProduct> products;
  final Function(InsuranceProduct)? onProductSelected;
  final Function(InsuranceProduct)? onProductAddToComparison;
  
  const InsuranceProductCardList({
    Key? key,
    required this.products,
    this.onProductSelected,
    this.onProductAddToComparison,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(
        child: Text('没有找到保险产品'),
      );
    }
    
    return ListView.builder(
      itemCount: products.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        final product = products[index];
        return InsuranceProductCard(
          product: product,
          onViewDetails: () {
            if (onProductSelected != null) {
              onProductSelected!(product);
            }
          },
          onAddToComparison: () {
            if (onProductAddToComparison != null) {
              onProductAddToComparison!(product);
            }
          },
        );
      },
    );
  }
} 