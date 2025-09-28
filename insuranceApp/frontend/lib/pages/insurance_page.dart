import 'package:flutter/material.dart';
import 'insurance_search_page.dart';
import 'user_insurance_list_page.dart';
import 'quick_insurance_build_page.dart'; // Added import for QuickInsuranceBuildPage

class InsurancePage extends StatelessWidget {
  const InsurancePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('保险知识'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 欢迎信息卡片
            _buildWelcomeCard(context),
            
            const SizedBox(height: 24),
            
            // 服务介绍
            _buildServiceIntroduction(context),
            
            const SizedBox(height: 24),
            
            // 主要功能卡片
            _buildMainFeatureCards(context),
          ],
        ),
      ),
    );
  }

  /// 构建欢迎信息卡片
  Widget _buildWelcomeCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
            ],
        ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '保险知识中心',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Text(
              '为您提供全面的保险产品搜索和保单管理服务',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建服务介绍
  Widget _buildServiceIntroduction(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '我们提供什么服务？',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
        ),
        ),
        
        const SizedBox(height: 16),
        
        // 功能介绍列表
        _buildFeatureListItem(
        context,
          icon: Icons.search,
          title: '智能搜索',
          description: '按类型搜索保险产品，支持多条件筛选和对比',
          color: Colors.blue,
          ),
        
        const SizedBox(height: 12),
        
        _buildFeatureListItem(
          context,
          icon: Icons.assignment,
          title: '保单管理',
          description: '管理您已添加的保险产品，支持分析和删除',
          color: Colors.green,
        ),
        
        const SizedBox(height: 12),
        
        _buildFeatureListItem(
          context,
          icon: Icons.compare_arrows,
          title: '产品对比',
          description: '选择多个保险产品进行智能对比分析',
          color: Colors.orange,
        ),
        
        const SizedBox(height: 12),
        
        _buildFeatureListItem(
          context,
          icon: Icons.chat_bubble_outline,
          title: 'AI咨询',
          description: '与AI助手对话，获取个性化保险建议',
          color: Colors.purple,
                    ),
      ],
    );
  }

  /// 构建功能列表项
  Widget _buildFeatureListItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
            child: Icon(
              icon,
              color: color,
              size: 24,
              ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                ),
              ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
              ),
          ),
        ],
      ),
    );
  }

  /// 构建主要功能卡片
  Widget _buildMainFeatureCards(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
          '选择您需要的服务',
              style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
              ),
            ),
        
        const SizedBox(height: 16),
        
        // 搜索保险产品卡片
        _buildSearchInsuranceCard(context),
        
        const SizedBox(height: 16),
        
        // 快速构筑卡片
        _buildQuickBuildCard(context),
        
        const SizedBox(height: 16),
        
        // 我的保单卡片
        _buildMyInsuranceCard(context),
      ],
    );
  }

  /// 构建搜索保险产品卡片
  Widget _buildSearchInsuranceCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const InsuranceSearchPage(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 图标和标题
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.search,
                      color: Colors.blue.shade700,
                      size: 32,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                        Text(
                          '搜索保险产品',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '浏览和搜索各种保险产品',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // 功能介绍
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
            Row(
              children: [
                Icon(
                          Icons.check_circle_outline,
                          color: Colors.blue.shade700,
                          size: 16,
                ),
                const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '按类型浏览：定期寿险、重疾险、医疗险等',
                  style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade800,
                            ),
                  ),
                ),
              ],
            ),
            
                    const SizedBox(height: 8),
            
            Row(
              children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.blue.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                Expanded(
                  child: Text(
                            '多条件筛选：保费、保额、公司等',
                    style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade800,
                    ),
                  ),
                ),
              ],
            ),
            
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.blue.shade700,
                          size: 16,
                  ),
                        const SizedBox(width: 8),
                        Expanded(
                child: Text(
                            '产品对比：最多同时对比2个产品',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade800,
                ),
              ),
            ),
          ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建快速构筑卡片
  Widget _buildQuickBuildCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const QuickInsuranceBuildPage(),
            ),
    );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 图标和标题
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: Colors.green.shade700,
                      size: 32,
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                          '快速构筑保险方案',
                          style: TextStyle(
                            fontSize: 20,
                  fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                          '基于您的个人信息智能推荐',
                style: TextStyle(
                            fontSize: 14,
                            color: Colors.green.shade600,
                ),
              ),
            ],
          ),
        ),
        
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // 功能介绍
              Container(
                padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.green.shade700,
                size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'AI分析：基于您的年龄、收入、风险偏好等信息',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green.shade800,
            ),
          ),
        ),
      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.green.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '智能推荐：为您量身定制的保险产品组合',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
        children: [
          Icon(
                          Icons.check_circle_outline,
                          color: Colors.green.shade700,
                          size: 16,
          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '专业建议：专业的保险规划方案和购买建议',
            style: TextStyle(
                              fontSize: 13,
                              color: Colors.green.shade800,
                            ),
                          ),
                        ),
                      ],
            ),
                  ],
                ),
          ),
        ],
          ),
        ),
      ),
    );
  }

  /// 构建我的保单卡片
  Widget _buildMyInsuranceCard(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 图标和标题
              Row(
                children: [
              Container(
                    padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.assignment,
                  color: Colors.purple.shade700,
                      size: 32,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '我的保单',
                      style: TextStyle(
                            fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                          '管理您已添加的保险产品',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.purple.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.purple.shade600,
                    size: 20,
              ),
            ],
          ),
              
              const SizedBox(height: 20),
          
              // 功能介绍
          Container(
                padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.purple.shade700,
                          size: 16,
            ),
                        const SizedBox(width: 8),
                        Expanded(
            child: Text(
                            '查看保单详情：查看已添加的保险产品信息',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.purple.shade800,
              ),
            ),
          ),
        ],
      ),
                    
                    const SizedBox(height: 8),
                    
            Row(
              children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.purple.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '保单管理：删除不需要的保险产品',
                  style: TextStyle(
                              fontSize: 13,
                              color: Colors.purple.shade800,
                            ),
                ),
                ),
              ],
            ),
            
                    const SizedBox(height: 8),
            
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: Colors.purple.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
            Expanded(
                    child: Text(
                            'AI分析：获取个性化的保单分析建议',
                      style: TextStyle(
                              fontSize: 13,
                              color: Colors.purple.shade800,
                      ),
                    ),
                        ),
                      ],
                  ),
                ],
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
} 