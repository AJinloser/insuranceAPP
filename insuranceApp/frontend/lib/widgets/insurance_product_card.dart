import 'package:flutter/material.dart';
import '../models/insurance_product.dart';
import '../utils/product_type_mapper.dart';

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
                ],
              ),
              
              const SizedBox(height: 4),
              
                  // 公司名称 + 产品类型（中文）
              Text(
                '${product.companyName ?? ''}${product.productType.isNotEmpty ? ' · ${ProductTypeMapper.toChineseName(product.productType)}' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // 保障标签或重点内容
              _buildHighlights(context),
              
              const SizedBox(height: 16),
              
              // 底部信息：保费 + 评分 + 查看详情按钮
              Row(
                children: [
                  // 产品类型标签（中文）
                  Expanded(
                    flex: 2,
                    child: Text(
                      product.productType.isNotEmpty 
                          ? ProductTypeMapper.toChineseName(product.productType)
                          : '保险产品',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              child: Column(
                children: [
                  Text(
                    product.productName ?? '未知产品',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ProductTypeMapper.toChineseName(product.productType),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
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
    // 从产品字段中提取可显示的信息
    final List<String> highlights = [];
    
    // 尝试从常见字段提取信息
    final fields = product.allFields;
    
    // 限制最多显示3个要点
    int count = 0;
    for (var entry in fields.entries) {
      if (count >= 3) break;
      
      // 跳过product_id和product_type
      if (entry.key == 'product_id' || entry.key == 'product_type') continue;
      
      // 跳过基本信息字段
      if (entry.key.contains('产品名') || 
          entry.key.contains('公司') ||
          entry.key.contains('code') || 
          entry.key == 'message') continue;
      
      // 提取有用的信息
      if (entry.value != null && entry.value.toString().isNotEmpty) {
        String value = entry.value.toString();
        if (value.length > 20) {
          value = '${value.substring(0, 20)}...';
        }
        highlights.add('${entry.key}: $value');
        count++;
      }
    }
    
    if (highlights.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: highlights.map((highlight) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Text(
            highlight,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        )
      ).toList(),
    );
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