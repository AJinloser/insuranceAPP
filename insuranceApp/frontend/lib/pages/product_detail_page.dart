import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/insurance_product.dart';
import '../services/insurance_service.dart';
import '../services/insurance_list_service.dart';
import '../services/auth_service.dart';
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
            // 产品名称和评分
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
                        '${widget.product.companyName ?? ''} · ${widget.productType}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.product.totalScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.product.getScoreDisplay(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 产品描述
            if (widget.product.getDescription() != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.product.getDescription()!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue.shade800,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // 保费和保额
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    title: '保费',
                    value: widget.product.getPremiumDisplay(),
                    subtitle: '起/年',
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInfoItem(
                    title: '保额',
                    value: widget.product.getCoverageAmountDisplay(),
                    subtitle: '最高',
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            
            // 保障期限
            if (widget.product.coveragePeriod != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _buildInfoItem(
                  title: '保障期限',
                  value: widget.product.coveragePeriod.toString(),
                  color: Colors.orange.shade700,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required String title,
    required String value,
    String? subtitle,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
      ],
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
        
        // 根据产品类型显示不同的详细信息
        if (widget.productType == '重疾险')
          _buildCriticalIllnessDetails()
        else if (widget.productType == '医疗险')
          _buildMedicalDetails()
        else if (widget.productType == '意外险')
          _buildAccidentDetails()
        else if (widget.productType == '寿险')
          _buildLifeInsuranceDetails()
        else
          _buildGenericDetails(),
      ],
    );
  }

  Widget _buildCriticalIllnessDetails() {
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
            _buildDetailSection('重疾保障', _detailInfo['critical_illness']),
            _buildDetailSection('轻症保障', _detailInfo['mild_illness']),
            _buildDetailSection('中症保障', _detailInfo['moderate_illness']),
            _buildDetailSection('身故保障', _detailInfo['death_benefit']),
            _buildDetailSection('其他保障', _detailInfo['other_benefits']),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalDetails() {
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
            _buildDetailSection('医疗保障', _detailInfo['medical_coverage']),
            _buildDetailSection('免赔额', _detailInfo['deductible']),
            _buildDetailSection('报销比例', _detailInfo['reimbursement_ratio']),
            _buildDetailSection('医院限制', _detailInfo['hospital_limitation']),
            _buildDetailSection('增值服务', _detailInfo['value_added_services']),
          ],
        ),
      ),
    );
  }

  Widget _buildAccidentDetails() {
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
            _buildDetailSection('意外身故', _detailInfo['accident_death']),
            _buildDetailSection('意外伤残', _detailInfo['accident_disability']),
            _buildDetailSection('意外医疗', _detailInfo['accident_medical']),
            _buildDetailSection('住院津贴', _detailInfo['hospitalization_allowance']),
            _buildDetailSection('其他保障', _detailInfo['other_benefits']),
          ],
        ),
      ),
    );
  }

  Widget _buildLifeInsuranceDetails() {
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
            _buildDetailSection('身故保障', _detailInfo['death_benefit']),
            _buildDetailSection('全残保障', _detailInfo['total_disability']),
            _buildDetailSection('现金价值', _detailInfo['cash_value']),
            _buildDetailSection('保费豁免', _detailInfo['premium_waiver']),
            _buildDetailSection('其他条款', _detailInfo['other_terms']),
          ],
        ),
      ),
    );
  }

  Widget _buildGenericDetails() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _detailInfo.entries
              .where((entry) => entry.key != 'code' && entry.key != 'message')
              .map((entry) => _buildDetailSection(
                    _formatFieldName(entry.key),
                    entry.value,
                  ))
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

  String _formatFieldName(String fieldName) {
    // 将字段名转换为中文显示
    final Map<String, String> fieldMap = {
      'product_name': '产品名称',
      'company_name': '保险公司',
      'insurance_type': '保险类型',
      'premium': '保费',
      'coverage_amount': '保额',
      'coverage_period': '保障期限',
      'coverage_content': '保障内容',
      'critical_illness': '重疾保障',
      'mild_illness': '轻症保障',
      'moderate_illness': '中症保障',
      'death_benefit': '身故保障',
      'medical_coverage': '医疗保障',
      'deductible': '免赔额',
      'reimbursement_ratio': '报销比例',
      'hospital_limitation': '医院限制',
      'value_added_services': '增值服务',
      'accident_death': '意外身故',
      'accident_disability': '意外伤残',
      'accident_medical': '意外医疗',
      'hospitalization_allowance': '住院津贴',
      'total_disability': '全残保障',
      'cash_value': '现金价值',
      'premium_waiver': '保费豁免',
      'other_benefits': '其他保障',
      'other_terms': '其他条款',
    };
    
    return fieldMap[fieldName] ?? fieldName;
  }

  String _formatContent(dynamic content) {
    if (content is String) {
      return content;
    } else if (content is Map) {
      return content.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join('\n');
    } else if (content is List) {
      return content.map((item) => '• $item').join('\n');
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
} 