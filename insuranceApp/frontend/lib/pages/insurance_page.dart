import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/insurance_product.dart';
import '../services/insurance_service.dart';
import '../services/comparison_chat_service.dart';
import '../widgets/insurance_product_card.dart';
import 'product_detail_page.dart';
import 'user_insurance_list_page.dart';

class InsurancePage extends StatefulWidget {
  const InsurancePage({Key? key}) : super(key: key);

  @override
  State<InsurancePage> createState() => _InsurancePageState();
}

class _InsurancePageState extends State<InsurancePage> with TickerProviderStateMixin {
  late TabController _tabController;
  late InsuranceService _insuranceService;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int _totalPages = 0;
  bool _showFilterDialog = false;
  Map<String, dynamic> _currentFilters = {};

  // 产品对比相关状态
  final List<ComparisonProduct> _comparisonProducts = [];
  static const int _maxComparisonProducts = 2;

  @override
  void initState() {
    super.initState();
    _insuranceService = InsuranceService();
    _tabController = TabController(length: 0, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _insuranceService.getProductTypes();
    if (_insuranceService.productTypes.isNotEmpty) {
      // 重新创建TabController
      _tabController.dispose();
      _tabController = TabController(
        length: _insuranceService.productTypes.length,
        vsync: this,
      );
      
      // 监听tab切换
      _tabController.addListener(_handleTabSelection);
      
      // 加载第一个类型的产品
      await _loadProducts();
    }
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging) {
      final selectedType = _insuranceService.productTypes[_tabController.index];
      _switchProductType(selectedType);
    }
  }

  Future<void> _loadProducts() async {
    if (_insuranceService.currentProductType.isNotEmpty) {
      final pages = await _insuranceService.searchProducts(
        productType: _insuranceService.currentProductType,
      );
      setState(() {
        _totalPages = pages;
      });
    }
  }

  Future<void> _switchProductType(String productType) async {
    _currentFilters.clear();
    _searchController.clear();
    
    final pages = await _insuranceService.switchProductType(productType);
    setState(() {
      _totalPages = pages;
    });
  }

  Future<void> _search() async {
    final searchParams = Map<String, dynamic>.from(_currentFilters);
    
    if (_searchController.text.isNotEmpty) {
      searchParams['product_name'] = _searchController.text;
    }
    
    final pages = await _insuranceService.updateSearchParams(searchParams);
    setState(() {
      _totalPages = pages;
    });
  }

  Future<void> _resetSearch() async {
    _searchController.clear();
    _currentFilters.clear();
    
    final pages = await _insuranceService.resetSearch();
    setState(() {
      _totalPages = pages;
    });
  }

  Future<void> _changePage(int page) async {
    final pages = await _insuranceService.changePage(page);
    setState(() {
      _totalPages = pages;
    });
    
    // 滚动到顶部
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _changeSortBy(String sortBy) async {
    final pages = await _insuranceService.changeSortBy(sortBy);
    setState(() {
      _totalPages = pages;
    });
  }

  void _showProductDetail(InsuranceProduct product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailPage(
          product: product,
          productType: _insuranceService.currentProductType,
        ),
      ),
    );
  }

  /// 添加产品到对比列表
  void _addToComparison(InsuranceProduct product) {
    debugPrint('===> InsurancePage: 添加产品到对比列表 - ${product.productName}');
    
    if (product.productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('产品信息错误'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final comparisonProduct = ComparisonProduct.fromInsuranceProduct(
      product, 
      _insuranceService.currentProductType
    );

    // 检查是否已经添加过
    if (_comparisonProducts.any((p) => p.productId == comparisonProduct.productId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('该产品已在对比列表中'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 检查是否达到最大数量
    if (_comparisonProducts.length >= _maxComparisonProducts) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('最多只能选择$_maxComparisonProducts个产品进行对比'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _comparisonProducts.add(comparisonProduct);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已添加「${product.productName}」到对比列表'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 从对比列表中移除产品
  void _removeFromComparison(int index) {
    debugPrint('===> InsurancePage: 从对比列表移除产品 - index: $index');
    
    if (index >= 0 && index < _comparisonProducts.length) {
      setState(() {
        _comparisonProducts.removeAt(index);
      });
    }
  }

  /// 启动产品对比
  Future<void> _startComparison() async {
    debugPrint('===> InsurancePage: 启动产品对比');
    
    if (_comparisonProducts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请选择2个产品进行对比'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 显示加载指示器
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final routeArgs = await ComparisonChatService.startComparisonChat(
        context,
        products: _comparisonProducts,
      );

      // 关闭加载指示器
      Navigator.of(context).pop();

      if (routeArgs == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('启动对比失败，请稍后重试'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // 成功启动对比，清空对比列表
        setState(() {
          _comparisonProducts.clear();
        });

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
      debugPrint('===> InsurancePage: 启动对比异常: $e');
      
      // 关闭加载指示器
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('启动对比失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _insuranceService,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('保险产品'),
          backgroundColor: Theme.of(context).primaryColor,
          elevation: 0,
          bottom: _insuranceService.productTypes.isNotEmpty
              ? TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: _insuranceService.productTypes
                      .map((type) => Tab(text: type))
                      .toList(),
                )
              : null,
        ),
        body: Consumer<InsuranceService>(
          builder: (context, service, child) {
            if (service.productTypes.isEmpty && service.isLoading) {
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
                      onPressed: _initializeData,
                      child: const Text('重试'),
                    ),
                  ],
                ),
              );
            }

            if (service.productTypes.isEmpty) {
              return const Center(
                child: Text('暂无保险产品类型'),
              );
            }

            return Column(
              children: [
                // 搜索栏
                _buildSearchBar(),
                
                // 产品列表
                Expanded(
                  child: _buildProductList(service),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 搜索输入框
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索产品名称',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 12),
              // 筛选按钮
              ElevatedButton(
                onPressed: _showFilterBottomSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Icon(Icons.filter_alt),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 搜索和重置按钮
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _search,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('搜索'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetSearch,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).primaryColor),
                    foregroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('重置'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(InsuranceService service) {
    if (service.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (service.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '没有找到相关产品',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '试试调整搜索条件或筛选条件',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        // 产品列表
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: service.products.length,
          itemBuilder: (context, index) {
            final product = service.products[index];
            return InsuranceProductCard(
              product: product,
              onViewDetails: () => _showProductDetail(product),
              onAddToComparison: () => _addToComparison(product),
            );
          },
        ),
        
        // 分页器
        if (_totalPages > 1) _buildPagination(),
        
        // 产品对比卡片
        _buildProductComparisonCard(),
        
        // "我的保单"卡片
        _buildMyInsuranceCard(),
      ],
    );
  }

  /// 构建产品对比卡片
  Widget _buildProductComparisonCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Row(
              children: [
                Icon(
                  Icons.compare_arrows,
                  color: Colors.indigo[600],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '产品对比',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[700],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 对比框
            Row(
              children: [
                // 第一个产品框
                Expanded(
                  child: _buildComparisonBox(0),
                ),
                
                const SizedBox(width: 16),
                
                // VS图标
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo[700],
                      fontSize: 12,
                    ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // 第二个产品框
                Expanded(
                  child: _buildComparisonBox(1),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 对比按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _comparisonProducts.length == 2 ? _startComparison : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _comparisonProducts.length == 2 
                      ? Colors.indigo[600] 
                      : Colors.grey[400],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  _comparisonProducts.length == 2 
                      ? '开始对比' 
                      : '请选择2个产品 (${_comparisonProducts.length}/2)',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建单个对比框
  Widget _buildComparisonBox(int index) {
    final hasProduct = index < _comparisonProducts.length;
    
    return Container(
      height: 100,
      decoration: BoxDecoration(
        border: Border.all(
          color: hasProduct ? Colors.indigo[300]! : Colors.grey[300]!,
          width: hasProduct ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: hasProduct ? Colors.indigo[50] : Colors.grey[50],
      ),
      child: hasProduct
          ? _buildProductInfo(index)
          : _buildEmptyBox(),
    );
  }

  /// 构建产品信息
  Widget _buildProductInfo(int index) {
    final product = _comparisonProducts[index];
    
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.productName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                product.productType,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        
        // 删除按钮
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeFromComparison(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.close,
                size: 16,
                color: Colors.red[600],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建空的对比框
  Widget _buildEmptyBox() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_circle_outline,
            size: 32,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 4),
          Text(
            '长按产品卡片\n选择"进行对比"',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建"我的保单"卡片
  Widget _buildMyInsuranceCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UserInsuranceListPage(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // 图标
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade200.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  Icons.assignment,
                  color: Colors.purple.shade700,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // 文字内容
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '我的保单',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '查看和管理您已添加的保险产品',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.purple.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 箭头
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.purple.shade600,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 上一页
          IconButton(
            onPressed: _insuranceService.currentPage > 1
                ? () => _changePage(_insuranceService.currentPage - 1)
                : null,
            icon: const Icon(Icons.chevron_left),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // 页码显示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              '${_insuranceService.currentPage} / $_totalPages',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // 下一页
          IconButton(
            onPressed: _insuranceService.currentPage < _totalPages
                ? () => _changePage(_insuranceService.currentPage + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              children: [
                const Text(
                  '筛选条件',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    _currentFilters.clear();
                    Navigator.pop(context);
                  },
                  child: const Text('清空'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _search();
                  },
                  child: const Text('确定'),
                ),
              ],
            ),
            
            const Divider(),
            
            // 筛选字段列表
            Expanded(
              child: ListView(
                children: [
                  // TODO: 基于productFields动态生成筛选表单
                  const Center(
                    child: Text(
                      '筛选功能开发中...',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
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