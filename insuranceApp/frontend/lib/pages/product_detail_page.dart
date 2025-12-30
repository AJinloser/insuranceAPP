import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/insurance_product.dart';
import '../services/insurance_service.dart';
import '../services/insurance_list_service.dart';
import '../services/insurance_chat_service.dart';
import '../services/settings_service.dart';
import '../services/auth_service.dart';
import '../utils/product_type_mapper.dart';
import 'user_insurance_list_page.dart';

class ProductDetailPage extends StatefulWidget {
  final InsuranceProduct product;
  final String productType;

  const ProductDetailPage({
    Key? key,
    required this.product,
    required this.productType,
  }) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late InsuranceService _insuranceService;
  bool _isLoading = true;
  Map<String, dynamic> _detailInfo = {};

  @override
  void initState() {
    super.initState();
    _insuranceService = InsuranceService();
    _loadProductDetail();
  }

  Future<void> _loadProductDetail() async {
    if (widget.product.productId != null) {
      await _insuranceService.getProductInfo(
        productId: widget.product.productId!,
        productType: widget.productType,
      );
      setState(() {
        _detailInfo = _insuranceService.productInfo;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _insuranceService,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(widget.product.productName ?? '产品详情'),
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 产品基本信息卡片
                    _buildBasicInfoCard(),
                    
                    const SizedBox(height: 16),
                    
                    // 产品详细信息
                    _buildDetailedInfo(),
                    
                    const SizedBox(height: 24),
                    
                    // 添加保单按钮
                    _buildAddToListButton(),
                    
                    const SizedBox(height: 16),
                    
                    // 与保险产品对话按钮（根据功能开关显示）
                    Consumer<SettingsService>(
                      builder: (context, settingsService, child) {
                        if (settingsService.productChatEnabled) {
                          return _buildChatWithProductButton();
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    
                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 产品名称
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.productName ?? '未知产品',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.product.companyName ?? ''} · ${ProductTypeMapper.toChineseName(widget.productType)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildDetailedInfo() {
    if (_detailInfo.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              '暂无详细信息',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '产品详情',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // 显示动态字段信息
        _buildDynamicFieldsDetails(),
      ],
    );
  }
  
  /// 构建动态字段详情
  Widget _buildDynamicFieldsDetails() {
    // 过滤掉不需要显示的字段
    final filteredInfo = Map<String, dynamic>.from(_detailInfo);
    filteredInfo.removeWhere((key, value) => 
      key == 'code' || 
      key == 'message' || 
      key == 'product_id' ||
      key == 'product_type' ||
      value == null ||
      value.toString().isEmpty
    );
    
    if (filteredInfo.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text(
              '暂无详细信息',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: filteredInfo.entries
              .map((entry) => _buildDetailSection(entry.key, entry.value))
              .toList(),
        ),
      ),
    );
  }


  Widget _buildDetailSection(String title, dynamic content) {
    if (content == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              _formatContent(content),
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }


  String _formatContent(dynamic content) {
    if (content == null) return '';
    
    if (content is String) {
      return content;
    } else if (content is Map) {
      return content.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join('\n');
    } else if (content is List) {
      return content.map((item) => '• $item').join('\n');
    } else if (content is num) {
      // 格式化数字
      return InsuranceProduct.formatNumber(content);
    } else if (content is bool) {
      return content ? '是' : '否';
    } else {
      return content.toString();
    }
  }

  Widget _buildAddToListButton() {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _addToInsuranceList,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle_outline,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              '添加到我的保单',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 添加保险产品到用户保单
  Future<void> _addToInsuranceList() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先登录'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (widget.product.productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('产品信息错误'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 创建保单服务实例
    final insuranceListService = InsuranceListService();
    
    // 显示加载指示器
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final success = await insuranceListService.addInsuranceToList(
        userId: userId,
        productId: widget.product.productId!,
        productType: widget.productType,
      );

      // 关闭加载指示器
      Navigator.of(context).pop();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('成功添加到保单'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: '查看保单',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserInsuranceListPage(),
                  ),
                );
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(insuranceListService.error ?? '添加失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // 关闭加载指示器
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('添加失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildChatWithProductButton() {
    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _startChat,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chat,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              '与保险产品对话',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 启动与保险产品的对话
  Future<void> _startChat() async {
    debugPrint('===> ProductDetailPage: _startChat开始');
    
    if (widget.product.productId == null) {
      debugPrint('===> ProductDetailPage: 产品ID为空');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('产品信息错误'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    debugPrint('===> ProductDetailPage: 产品ID验证通过，显示加载指示器');
    // 显示加载指示器
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      debugPrint('===> ProductDetailPage: 准备调用InsuranceChatService.startInsuranceChat');
      final routeArgs = await InsuranceChatService.startInsuranceChat(
        context,
        productId: widget.product.productId!.toString(),
        productType: widget.productType,
        productName: widget.product.productName,
      );

      debugPrint('===> ProductDetailPage: InsuranceChatService.startInsuranceChat返回结果: ${routeArgs != null}');

      // 关闭加载指示器
      debugPrint('===> ProductDetailPage: 关闭加载指示器');
      Navigator.of(context).pop();

      if (routeArgs == null) {
        debugPrint('===> ProductDetailPage: 启动对话失败，显示错误提示');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('启动对话失败，请稍后重试'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        debugPrint('===> ProductDetailPage: 启动对话成功，准备跳转到对话页面');
        debugPrint('===> ProductDetailPage: 路由参数: $routeArgs');
        
        // 延迟确保Dialog完全关闭
        await Future.delayed(const Duration(milliseconds: 100));
        
        // 跳转到首页的对话标签页，而不是独立的对话页面
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
      }
    } catch (e) {
      debugPrint('===> ProductDetailPage: 发生异常: $e');
      // 关闭加载指示器
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('启动对话失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} 