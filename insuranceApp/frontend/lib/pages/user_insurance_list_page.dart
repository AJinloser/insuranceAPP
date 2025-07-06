import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/insurance_list_service.dart';
import '../services/analysis_chat_service.dart';
import '../widgets/insurance_product_card.dart';
import 'product_detail_page.dart';

class UserInsuranceListPage extends StatefulWidget {
  const UserInsuranceListPage({Key? key}) : super(key: key);

  @override
  State<UserInsuranceListPage> createState() => _UserInsuranceListPageState();
}

class _UserInsuranceListPageState extends State<UserInsuranceListPage> {
  late InsuranceListService _insuranceListService;
  final AnalysisChatService _analysisChatService = AnalysisChatService();
  bool _isEditMode = false;
  Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _insuranceListService = InsuranceListService();
    _loadUserInsuranceList();
  }

  Future<void> _loadUserInsuranceList() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;
    if (userId != null) {
      await _insuranceListService.getUserInsuranceList(userId);
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      _selectedIndices.clear();
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  Future<void> _deleteSelectedItems() async {
    if (_selectedIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择要删除的保单')),
      );
      return;
    }

    // 显示确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除选中的 ${_selectedIndices.length} 个保险产品吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.userId;
      
      if (userId != null) {
        final success = await _insuranceListService.deleteSelectedInsurance(
          userId: userId,
          selectedIndices: _selectedIndices.toList(),
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除成功')),
          );
          setState(() {
            _isEditMode = false;
            _selectedIndices.clear();
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_insuranceListService.error ?? '删除失败'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showProductDetail(InsuranceListItem item) {
    if (item.productDetail != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailPage(
            product: item.productDetail!,
            productType: item.productType,
          ),
        ),
      );
    }
  }

  /// 启动保单分析
  Future<void> _startAnalysisChat() async {
    debugPrint('===> UserInsuranceListPage: 开始启动保单分析');
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.userId;
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('用户未登录，无法进行保单分析')),
      );
      return;
    }
    
    // 检查是否有保单
    if (_insuranceListService.insuranceList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('您还没有保单，请先添加保险产品')),
      );
      return;
    }
    
    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在启动保单分析...'),
              ],
            ),
          ),
        ),
      ),
    );
    
    try {
      await _analysisChatService.startAnalysisChat(context, userId);
      // 如果成功，对话框会自动关闭（因为页面跳转）
    } catch (e) {
      // 关闭加载对话框
      Navigator.of(context).pop();
      
      // 显示错误信息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('启动保单分析失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _insuranceListService,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('我的保单'),
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            Consumer<InsuranceListService>(
              builder: (context, service, child) {
                if (service.insuranceList.isEmpty) return const SizedBox();
                
                return TextButton(
                  onPressed: _toggleEditMode,
                  child: Text(
                    _isEditMode ? '完成' : '修改',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: Consumer<InsuranceListService>(
          builder: (context, service, child) {
            if (service.isLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (service.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      service.error!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadUserInsuranceList,
                      child: const Text('重试'),
                    ),
                  ],
                ),
              );
            }

            if (service.insuranceList.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无保单',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '去保险产品页面添加您感兴趣的保险产品吧',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: service.insuranceList.length,
                    itemBuilder: (context, index) {
                      final item = service.insuranceList[index];
                      final isSelected = _selectedIndices.contains(index);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: _buildInsuranceCard(item, index, isSelected),
                      );
                    },
                  ),
                ),
                
                // 保单分析按钮区域
                if (service.insuranceList.isNotEmpty && !_isEditMode)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _startAnalysisChat,
                          icon: const Icon(Icons.analytics_outlined),
                          label: const Text(
                            '保单分析',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // 修改模式下的底部操作栏
                if (_isEditMode)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '已选择 ${_selectedIndices.length} 项',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _selectedIndices.isEmpty ? null : _deleteSelectedItems,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(100, 36),
                          ),
                          child: const Text('删除'),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInsuranceCard(InsuranceListItem item, int index, bool isSelected) {
    final product = item.productDetail;
    
    return GestureDetector(
      onTap: _isEditMode 
        ? () => _toggleSelection(index)
        : () => _showProductDetail(item),
      child: Stack(
        children: [
          // 使用现有的InsuranceProductCard组件
          Container(
            decoration: _isEditMode && isSelected 
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).primaryColor, width: 2),
                )
              : null,
            child: product != null
              ? InsuranceProductCard(
                  product: product,
                  onViewDetails: _isEditMode 
                    ? () => _toggleSelection(index)
                    : () => _showProductDetail(item),
                )
              : _buildFallbackCard(item, isSelected),
          ),
          
          // 编辑模式下的选择框覆盖层
          if (_isEditMode)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Checkbox(
                  value: isSelected,
                  onChanged: (value) => _toggleSelection(index),
                  activeColor: Theme.of(context).primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 构建备用卡片（当产品详情加载失败时使用）
  Widget _buildFallbackCard(InsuranceListItem item, bool isSelected) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: _isEditMode && isSelected 
          ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
          : BorderSide.none,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 产品信息
            Text(
              '产品ID: ${item.productId}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '产品类型: ${item.productType}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '详情加载中...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 