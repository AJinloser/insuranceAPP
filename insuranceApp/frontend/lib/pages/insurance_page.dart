import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/insurance_product.dart';
import '../services/insurance_service.dart';
import '../widgets/insurance_product_card.dart';
import 'product_detail_page.dart';

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
              IconButton(
                onPressed: () => _showFilterBottomSheet(),
                icon: Stack(
                  children: [
                    const Icon(Icons.filter_list),
                    if (_currentFilters.isNotEmpty)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.grey[100],
                  foregroundColor: Colors.grey[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // 操作按钮行
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
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('重置'),
                ),
              ),
              const SizedBox(width: 12),
              // 排序按钮
              _buildSortButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<String>(
      onSelected: _changeSortBy,
      itemBuilder: (context) {
        return [
          const PopupMenuItem(
            value: 'total_score',
            child: Text('评分排序'),
          ),
          const PopupMenuItem(
            value: 'premium',
            child: Text('保费排序'),
          ),
          const PopupMenuItem(
            value: 'company_name',
            child: Text('公司排序'),
          ),
        ];
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sort, size: 18, color: Colors.grey[700]),
            const SizedBox(width: 4),
            Text(
              '排序',
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
          ],
        ),
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
            );
          },
        ),
        
        // 分页器
        if (_totalPages > 1) _buildPagination(),
      ],
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