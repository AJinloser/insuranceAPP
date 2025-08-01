import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/quick_insurance_build_service.dart';
import '../models/insurance_product.dart';
import '../widgets/insurance_product_card.dart';
import '../widgets/custom_markdown_body.dart';
import 'product_detail_page.dart';

class QuickInsuranceBuildPage extends StatefulWidget {
  const QuickInsuranceBuildPage({Key? key}) : super(key: key);

  @override
  State<QuickInsuranceBuildPage> createState() => _QuickInsuranceBuildPageState();
}

class _QuickInsuranceBuildPageState extends State<QuickInsuranceBuildPage> {
  final QuickInsuranceBuildService _buildService = QuickInsuranceBuildService();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startQuickBuild();
    });
  }

  /// 启动快速构筑流程
  Future<void> _startQuickBuild() async {
    try {
      await _buildService.generateQuickInsurancePlan();
    } catch (e) {
      debugPrint('快速构筑失败: $e');
    }
  }

  /// 查看产品详情
  void _showProductDetail(InsuranceProduct product, String productType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(
          product: product,
          productType: productType,
        ),
      ),
    );
  }

  /// 继续聊天
  Future<void> _continueChatting() async {
    try {
      final routeArgs = await _buildService.continueChat(context);
      
      if (routeArgs != null) {
        Navigator.pushNamed(
          context,
          '/home',
          arguments: {
            'conversationId': routeArgs['conversationId'],
            'initialTabIndex': 0, // 对话页面的索引
            'initialQuestion': routeArgs['initialQuestion'],
            'productInfo': routeArgs['productInfo'],
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('无法找到对应的AI模块，请稍后重试'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('继续聊天失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('继续聊天失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _buildService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _buildService,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('快速构筑保险方案'),
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        body: Consumer<QuickInsuranceBuildService>(
          builder: (context, service, child) {
            if (service.isLoading) {
              return _buildLoadingView();
            }

            if (service.error != null) {
              return _buildErrorView(service.error!);
            }

            if (service.aiResponse.isEmpty) {
              return _buildEmptyView();
            }

            return _buildResultView(service);
          },
        ),
      ),
    );
  }

  /// 构建加载视图
  Widget _buildLoadingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 48,
                color: Colors.green.shade700,
              ),
            ),
            
            const SizedBox(height: 24),
            
            const CircularProgressIndicator(),
            
            const SizedBox(height: 24),
            
            Text(
              'AI正在为您分析个人信息',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              '正在基于您的年龄、收入、风险偏好等信息\n为您量身定制保险方案...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建错误视图
  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            
            const SizedBox(height: 16),
            
            Text(
              '生成方案失败',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              error,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _startQuickBuild,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('重新生成'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建空视图
  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            
            const SizedBox(height: 16),
            
            Text(
              '暂无保险方案',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              '请点击重新生成按钮获取专属保险方案',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _startQuickBuild,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('生成保险方案'),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建结果视图
  Widget _buildResultView(QuickInsuranceBuildService service) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI建议卡片
          _buildAiRecommendationCard(service.aiResponse),
          
          const SizedBox(height: 16),
          
          // 推荐产品列表
          if (service.recommendedProducts.isNotEmpty) ...[
            _buildRecommendedProductsSection(service.recommendedProducts),
            const SizedBox(height: 16),
          ],
          
          // 继续聊天卡片
          _buildContinueChatCard(),
        ],
      ),
    );
  }

  /// 构建AI建议卡片
  Widget _buildAiRecommendationCard(String response) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.psychology,
                    color: Colors.green.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI专属建议',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.green.shade200,
                  width: 1,
                ),
              ),
              child: CustomMarkdownBody(
                data: response,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.grey[800],
                  ),
                  h1: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                    height: 1.3,
                  ),
                  h2: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                    height: 1.3,
                  ),
                  h3: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                    height: 1.3,
                  ),
                  strong: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                  em: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
                  code: TextStyle(
                    fontSize: 13,
                    backgroundColor: Colors.green.shade50,
                    color: Colors.green.shade800,
                    fontFamily: 'monospace',
                  ),
                  codeblockDecoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.green.shade200,
                      width: 1,
                    ),
                  ),
                  blockquote: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                  blockquoteDecoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(
                        color: Colors.green.shade400,
                        width: 4,
                      ),
                    ),
                  ),
                  listBullet: TextStyle(
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.bold,
                  ),
                  tableHead: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                  tableBody: TextStyle(
                    color: Colors.grey[800],
                  ),
                  tableBorder: TableBorder.all(
                    color: Colors.green.shade300,
                    width: 1,
                  ),
                  tableHeadAlign: TextAlign.center,
                  tableCellsPadding: const EdgeInsets.all(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建推荐产品部分
  Widget _buildRecommendedProductsSection(List<InsuranceProductMatch> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '推荐产品',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        
        const SizedBox(height: 12),
        
        Text(
          '根据您的个人信息，我们还为您筛选出以下优质保险产品：',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        
        const SizedBox(height: 16),
        
        ...products.map((productMatch) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: InsuranceProductCard(
            product: productMatch.product,
            onViewDetails: () => _showProductDetail(
              productMatch.product,
              productMatch.productType,
            ),
          ),
        )),
      ],
    );
  }

  /// 构建继续聊天卡片
  Widget _buildContinueChatCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.blue.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '需要进一步咨询？',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '如果您对当前方案想要进一步修改，可以和我们的AI继续聊天！',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade800,
                      height: 1.4,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _continueChatting,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        '继续与AI聊天',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 