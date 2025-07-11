import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('帮助与反馈'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 16),
            _buildGettingStartedCard(),
            const SizedBox(height: 16),
            _buildMainFeaturesCard(),
            const SizedBox(height: 16),
            _buildSmartAssistantCard(),
            const SizedBox(height: 16),
            _buildInsuranceServiceCard(),
            const SizedBox(height: 16),
            _buildFinancialPlanningCard(),
            const SizedBox(height: 16),
            _buildProfileCenterCard(),
            const SizedBox(height: 16),
            _buildFooterCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.purple.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.waving_hand, size: 32, color: Colors.orange.shade600),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '欢迎使用 Skysail',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '您好，这里是skysail开发小组给予您的使用指南，旨在介绍说明本应用的基本情况和使用流程，希望能对您有所帮助。',
              style: TextStyle(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGettingStartedCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rocket_launch, color: Colors.green.shade600, size: 28),
                const SizedBox(width: 12),
                const Text(
                  '开始使用',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '首先，您可以通过注册账号的方式开始使用本应用，注册账号后需要填写一些基础的信息，然后便可使用该账号进行登录和使用本应用。',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.red.shade600, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '注意：我们会保护您的信息，不会向任何第三方应用出售、转让、展示您的信息！',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
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

  Widget _buildMainFeaturesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard, color: Colors.purple.shade600, size: 28),
                const SizedBox(width: 12),
                const Text(
                  '四大主要页面模块',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
                children: [
                  const TextSpan(text: '本应用分为四个主要页面模块：'),
                  TextSpan(text: '智能助手', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade700)),
                  const TextSpan(text: '、'),
                  TextSpan(text: '保险服务', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                  const TextSpan(text: '、'),
                  TextSpan(text: '财务规划', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                  const TextSpan(text: '、'),
                  TextSpan(text: '个人中心', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple.shade700)),
                  const TextSpan(text: '，你可以通过'),
                  TextSpan(text: '点击页面底部的导航栏', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade600)),
                  const TextSpan(text: '进行切换。'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildFeatureItem(Icons.smart_toy, '智能助手', 'AI聊天助手，提供专业建议', Colors.blue),
            _buildFeatureItem(Icons.shield, '保险服务', '查看保险产品，管理保单', Colors.orange),
            _buildFeatureItem(Icons.trending_up, '财务规划', '设定目标，规划未来', Colors.green),
            _buildFeatureItem(Icons.person, '个人中心', '管理个人信息和设置', Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartAssistantCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.smart_toy, color: Colors.blue.shade600, size: 28),
                const SizedBox(width: 12),
                const Text(
                  '智能助手页面',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '在智能助手页面，你可以和我们开发的AI智能助手聊天，它可以介绍保险的基本知识、并根据您的财务状况为您进行规划，并通过文字、图表等多种方式协助说明，力求让您理解。当你想要中止聊天时，您也可以点击输入框右侧的中止按钮。',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 16),
            _buildLocationFeature(
              '左上角菜单按钮',
              '您可以点击左上角的菜单按钮，进入菜单页面。在菜单页面中，你可以选择功能侧重各有不同的AI进行聊天，也可以查看您之前与不同AI对话的历史对话，点击后可以继续您之前的聊天。',
              Icons.menu,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildLocationFeature(
              '右上角新建对话按钮',
              '您也可以点击右上角的加号按钮，新建对话重新开始聊天。',
              Icons.add,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildLocationFeature(
              '输入框右侧中止按钮',
              '当你想要中止聊天时，可以点击输入框右侧的中止按钮。',
              Icons.stop,
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsuranceServiceCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield, color: Colors.orange.shade600, size: 28),
                const SizedBox(width: 12),
                const Text(
                  '保险服务页面',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '在保险服务页面，您可以查看我们数据库中拥有的各种保险产品，点击后可以进入保险产品详情页面，了解关于该保险产品保费、保障条款等各种详细信息。',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 15, color: Colors.black87),
                      children: [
                        const TextSpan(text: '目前保险产品主要分为'),
                        TextSpan(text: '年金险，重疾险，定期寿险，定额终身寿险，意外险，百万医疗险及中端医疗险', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                        const TextSpan(text: '，您可以'),
                        TextSpan(text: '点击上方的导航栏', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade600)),
                        const TextSpan(text: '进行切换。'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      '年金险', '重疾险', '定期寿险', '定额终身寿险',
                      '意外险', '百万医疗险及中端医疗险'
                    ].map((type) => Chip(
                      label: Text(type, style: const TextStyle(fontSize: 12)),
                      backgroundColor: Colors.white,
                    )).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailedFeature(
              '搜索和筛选功能',
              '您也可以通过保险服务页面中的搜索框通过保险产品的名称进行搜索，或点击重置按钮重置为初始状态（展示所有保险产品）',
              Icons.search,
            ),
            const SizedBox(height: 12),
            _buildDetailedFeature(
              '保险产品详情页面操作',
              '您可以在保险产品详情页面的底部，点击加入保单按钮，将该保险产品加入您的保单，也可以点击"与保险产品对话"按钮，通过我们开发的AI助手，了解关于这个保险产品的各个方面。',
              Icons.info,
            ),
            const SizedBox(height: 12),
            _buildDetailedFeature(
              '产品对比功能',
              '您可以长按保险产品卡片，将之加入对比模块中，选择好两个对比的保险产品后，您可以点击对比按钮，通过与我们开发的AI助手聊天的方式了解这两个保险产品之间的异同。',
              Icons.compare_arrows,
            ),
            const SizedBox(height: 12),
            _buildDetailedFeature(
              '我的保单管理',
              '您可以点击保险服务页面底部的保单卡片，进入保单页面，查看您的保单目前拥有的保险产品，也可以点击底部的保单分析按钮，与AI助手聊天，了解您目前保单的涵盖范围，缺陷和优化方向。',
              Icons.list_alt,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialPlanningCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green.shade600, size: 28),
                const SizedBox(width: 12),
                const Text(
                  '财务规划页面',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '在财务规划页面，该页面旨在帮助您更好的设定、分解目标，完成看似遥不可及的财务规划未来。',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 16),
            _buildPlanningSection(
              '目标管理',
              '您可以点击添加目标按钮，添加您目前想要实现的大目标。点击目标后，您可以进入目标管理页面。在这里，您可以添加子目标，子目标旨在帮助您分解困难的大目标。您也可以添加子任务，子任务旨在帮助您在目标分解为可执行的小任务（比如今天存100块钱等）。',
              Icons.flag,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildPlanningSection(
              '日程管理',
              '您可以点击上方的导航栏中的日程，切换到日程页面，日程页面可以选择日期，展示您不同日期需要执行的任务，预计完成的子目标和大目标，帮助您进行时间上的规划。',
              Icons.calendar_today,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildPlanningSection(
              '数据规划',
              '您也可以点击规划，切换到规划页面，规划页面可以通过饼状图、折线图等易于理解的方式为您展示您的目标分配情况和任务完成情况，帮助您更好的了解您目前的状况和离未来的距离。',
              Icons.analytics,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCenterCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Colors.purple.shade600, size: 28),
                const SizedBox(width: 12),
                const Text(
                  '个人中心页面',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailedFeature(
              '个人信息管理',
              '在个人中心页面，您可以点击个人信息卡片，进入个人信息修改页面，修改您的各项信息。',
              Icons.edit,
            ),
            const SizedBox(height: 12),
            _buildDetailedFeature(
              '帮助与反馈',
              '也可以点击帮助与反馈，查看这篇使用流程教程（我们会及时更新），帮助您更好地使用这个应用。',
              Icons.help,
            ),
            const SizedBox(height: 12),
            _buildDetailedFeature(
              '隐私政策',
              '也可以点击隐私政策，了解详细的隐私条款。',
              Icons.privacy_tip,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.green.shade50, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.favorite, color: Colors.red.shade400, size: 32),
            const SizedBox(height: 12),
            const Text(
              '希望能对您有所帮助，祝您使用愉快！',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  description,
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
    );
  }

  Widget _buildLocationFeature(String location, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedFeature(String title, String description, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.orange.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanningSection(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 