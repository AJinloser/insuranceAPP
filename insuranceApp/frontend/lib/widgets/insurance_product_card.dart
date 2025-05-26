import 'package:flutter/material.dart';
import '../models/insurance_product.dart';

/// 保险产品卡片组件
class InsuranceProductCard extends StatelessWidget {
  final InsuranceProduct product;
  final VoidCallback? onViewDetails;
  
  const InsuranceProductCard({
    Key? key,
    required this.product,
    this.onViewDetails,
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
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.getPremiumDisplay(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
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
                  
                  const Spacer(),
                  
                  // 评分
                  if (product.totalScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.getScoreDisplay(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(width: 12),
                  
                  // 查看详情按钮
                  ElevatedButton(
                    onPressed: onViewDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('查看详情'),
                  ),
                ],
              ),
            ],
          ),
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
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) => _buildTag(context, tag)).toList(),
    );
  }
  
  /// 构建单个标签
  Widget _buildTag(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getTagColor(text).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getTagColor(text).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: _getTagColor(text),
        ),
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
  
  const InsuranceProductCardList({
    Key? key,
    required this.products,
    this.onProductSelected,
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
        );
      },
    );
  }
} 