import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_info.dart';
import '../services/user_info_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({Key? key}) : super(key: key);

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  // 定义颜色主题
  final Color _primaryColor = const Color(0xFF6A1B9A); // 紫色主题
  final Color _backgroundColor = Colors.white;
  final Color _cardColor = Colors.white;

  // 基本信息控制器
  final _ageController = TextEditingController();
  final _cityController = TextEditingController();
  final _genderController = TextEditingController();

  // 财务信息控制器
  final _occupationController = TextEditingController();
  final _incomeController = TextEditingController();
  final _expensesController = TextEditingController();
  final _assetsController = TextEditingController();
  final _liabilitiesController = TextEditingController();

  // 目标信息控制器
  final _goalDetailsController = TextEditingController();

  // 保险信息状态变量
  String? _hasMedicalInsurance; // 是否有社会医疗保险：是/否
  String? _medicalInsuranceType; // 社会医疗保险类型：城镇职工/城乡居民/公费医疗
  String? _hasEndowmentInsurance; // 是否有社会养老保险：是/否
  String? _endowmentInsuranceType; // 社会养老保险类型：城镇职工/城乡居民
  String? _hasBusinessInsurance; // 是否有商业保险：是/否

  // 模块信息配置
  final List<ModuleInfo> _modules = [
    ModuleInfo(
      title: '智能助手',
      description: 'AI保险顾问，为您答疑解惑',
      icon: Icons.chat_bubble_outline,
      color: Color(0xFF4CAF50),
      tabIndex: 0,
    ),
    ModuleInfo(
      title: '保险知识',
      description: '浏览和比较保险产品',
      icon: Icons.shield_outlined,
      color: Color(0xFF2196F3),
      tabIndex: 1,
    ),
    ModuleInfo(
      title: '财务规划',
      description: '制定和管理财务目标',
      icon: Icons.trending_up,
      color: Color(0xFFFF9800),
      tabIndex: 2,
    ),
    ModuleInfo(
      title: '个人中心',
      description: '管理个人信息和设置',
      icon: Icons.person_outline,
      color: Color(0xFF9C27B0),
      tabIndex: 3,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    _cityController.dispose();
    _genderController.dispose();
    _occupationController.dispose();
    _incomeController.dispose();
    _expensesController.dispose();
    _assetsController.dispose();
    _liabilitiesController.dispose();
    _goalDetailsController.dispose();
    super.dispose();
  }

  // 下一页
  void _nextPage() {
    if (_currentPage < 5) { // 修改最大页面数为6页（索引0-5）
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // 上一页
  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // 跳过设置
  Future<void> _skipSetup() async {
    setState(() {
      _isLoading = true;
    });

    print('===> ProfileSetupPage: 用户选择跳过个人信息设置');

    try {
      // 构建空的UserInfo对象
      final userInfo = UserInfo(
        basicInfo: BasicInfo(
          age: null,
          city: null,
          gender: null,
          healthStatus: null,
        ),
        financialInfo: FinancialInfo(
          occupation: null,
          income: null,
          expenses: null,
          assets: null,
          liabilities: null,
          currentAssets: null,
        ),
        riskInfo: RiskInfo(),
        retirementInfo: RetirementInfo(),
        insuranceInfo: InsuranceInfo(
          socialMedicalInsurance: null,
          socialEndowmentInsurance: null,
          businessInsurance: null,
        ),
        familyInfo: FamilyInfo(familyMembers: []),
        goalInfo: GoalInfo(goals: []),
        otherInfo: {},
      );

      final userInfoService = Provider.of<UserInfoService>(context, listen: false);
      final success = await userInfoService.updateUserInfo(userInfo);

      if (success && mounted) {
        print('===> ProfileSetupPage: 跳过设置成功，跳转到欢迎页面');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已跳过个人信息设置'),
            backgroundColor: Colors.orange,
          ),
        );
        
        // 跳转到欢迎页面
        _pageController.animateToPage(
          5, // 直接跳转到第6页（索引5）
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else if (mounted) {
        print('===> ProfileSetupPage: 跳过设置失败');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userInfoService.error ?? '跳过设置失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('===> ProfileSetupPage: 跳过设置异常: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('跳过设置失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 提交表单
  Future<void> _submitForm() async {
    setState(() {
      _isLoading = true;
    });

    print('===> ProfileSetupPage: 开始提交个人信息');
    print('===> ProfileSetupPage: 目标详情内容: "${_goalDetailsController.text}"');

    try {
      // 构建保险信息
      String? medicalInsurance;
      String? endowmentInsurance;
      String? businessInsurance;

      // 处理社会医疗保险
      if (_hasMedicalInsurance == '否') {
        medicalInsurance = '无';
      } else if (_hasMedicalInsurance == '是' && _medicalInsuranceType != null) {
        medicalInsurance = _medicalInsuranceType;
      }

      // 处理社会养老保险
      if (_hasEndowmentInsurance == '否') {
        endowmentInsurance = '无';
      } else if (_hasEndowmentInsurance == '是' && _endowmentInsuranceType != null) {
        endowmentInsurance = _endowmentInsuranceType;
      }

      // 处理商业保险
      if (_hasBusinessInsurance == '否') {
        businessInsurance = '无';
      } else if (_hasBusinessInsurance == '是') {
        businessInsurance = '有';
      }

      // 构建UserInfo对象
      final userInfo = UserInfo(
        basicInfo: BasicInfo(
          age: _ageController.text.isEmpty ? null : _ageController.text,
          city: _cityController.text.isEmpty ? null : _cityController.text,
          gender: _genderController.text.isEmpty ? null : _genderController.text,
          healthStatus: null,
        ),
        financialInfo: FinancialInfo(
          occupation: _occupationController.text.isEmpty ? null : _occupationController.text,
          income: _incomeController.text.isEmpty ? null : _incomeController.text,
          expenses: _expensesController.text.isEmpty ? null : _expensesController.text,
          assets: _assetsController.text.isEmpty ? null : _assetsController.text,
          liabilities: _liabilitiesController.text.isEmpty ? null : _liabilitiesController.text,
          currentAssets: null,
        ),
        riskInfo: RiskInfo(),
        retirementInfo: RetirementInfo(),
        insuranceInfo: InsuranceInfo(
          socialMedicalInsurance: medicalInsurance,
          socialEndowmentInsurance: endowmentInsurance,
          businessInsurance: businessInsurance,
        ),
        familyInfo: FamilyInfo(familyMembers: []),
        goalInfo: GoalInfo(
          goals: _goalDetailsController.text.isEmpty 
              ? [] 
              : [Goal(goalDetails: _goalDetailsController.text)],
        ),
        otherInfo: {},
      );

      final userInfoService = Provider.of<UserInfoService>(context, listen: false);
      final success = await userInfoService.updateUserInfo(userInfo);

      if (success && mounted) {
        print('===> ProfileSetupPage: 个人信息提交成功，跳转到欢迎页面');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('个人信息保存成功'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 跳转到欢迎页面
        _nextPage();
      } else if (mounted) {
        print('===> ProfileSetupPage: 个人信息提交失败');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userInfoService.error ?? '保存失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('===> ProfileSetupPage: 提交异常: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 跳转到指定模块
  void _navigateToModule(int tabIndex) {
    print('===> ProfileSetupPage: 用户选择进入模块: $tabIndex');
    
    // 标记新用户设置完成
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.completeNewUserSetup();
    
    // 导航到首页指定tab
    Navigator.of(context).pushReplacementNamed(
      '/home',
      arguments: {'initialTabIndex': tabIndex},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              width: MediaQuery.of(context).size.width > 600 
                  ? 500 
                  : MediaQuery.of(context).size.width * 0.9,
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 100,
              ),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withAlpha(77),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Logo
                  Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 20),
                    child: Image.asset(
                      'assets/logo/logo-site.png',
                      height: 80,
                    ),
                  ),

                  // 页面指示器
                  _buildPageIndicator(),
                  const SizedBox(height: 20),

                  // 表单内容
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.5,
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      children: [
                        _buildPrivacyPolicyPage(),
                        _buildBasicInfoPage(),
                        _buildFinancialInfoPage(),
                        _buildGoalInfoPage(),
                        _buildInsuranceInfoPage(), // 新增保险信息页面
                        _buildWelcomePage(), // 欢迎页面移到最后
                      ],
                    ),
                  ),

                  // 底部按钮
                  _buildBottomButtons(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 页面指示器
  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) { // 修改页面数量为6
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index <= _currentPage ? _primaryColor : Colors.grey[300],
          ),
        );
      }),
    );
  }

  // 隐私政策页面
  Widget _buildPrivacyPolicyPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '隐私与安全',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.security, color: _primaryColor, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      '您的信息安全',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildPrivacyPolicySection(
                  '信息用途',
                  '• 个性化保险产品推荐\n• 财务规划建议与分析\n• 风险评估与管理\n• 产品匹配与优化',
                ),
                const SizedBox(height: 12),
                _buildPrivacyPolicySection(
                  '保密承诺',
                  '• 严格遵守《个人信息保护法》\n• 绝不向第三方出售或泄露您的信息\n• 您可随时查看、修改或删除个人信息',
                ),
                const SizedBox(height: 12),
                _buildPrivacyPolicySection(
                  '平台担保',
                  '• 7×24小时安全监控\n• 专业合规团队审核\n• 完善的数据备份机制',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified_user, color: Colors.green.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '我们承诺：所有信息均为可选填写，您可以选择跳过或稍后填写，这不会影响您使用我们的服务。',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green.shade700,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 隐私政策部分构建器
  Widget _buildPrivacyPolicySection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            height: 1.4,
          ),
        ),
      ],
    );
  }

  // 基本信息页面
  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '基本信息',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '欢迎来到skysail，请您提供一些您的基本信息如年龄和性别，这能帮助我们更好地了解您来为您提供服务，如您担心隐私泄露，也可以不进行填写',
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          CustomTextField(
            label: '年龄',
            controller: _ageController,
            prefixIcon: Icons.cake,
            keyboardType: TextInputType.number,
            hintText: '请输入您的实际年龄，例如：35岁',
          ),
          CustomTextField(
            label: '性别',
            controller: _genderController,
            prefixIcon: Icons.person,
            hintText: '请输入您的性别，例如：男/女/其他',
          ),
          CustomTextField(
            label: '城市',
            controller: _cityController,
            prefixIcon: Icons.location_city,
            hintText: '请输入您当前居住的城市，例如：上海',
          ),
        ],
      ),
    );
  }

  // 财务信息页面
  Widget _buildFinancialInfoPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '财务信息',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '请您提供一些您的财务信息，您可以回忆您的工作状况、生活支出和目前拥有的资产和负债，进行填写，这能帮助我们更好地了解您的财务状况',
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          CustomTextField(
            label: '职业',
            controller: _occupationController,
            prefixIcon: Icons.work,
            hintText: '请输入您的职业，例如：软件工程师、教师等',
          ),
          CustomTextField(
            label: '收入',
            controller: _incomeController,
            prefixIcon: Icons.attach_money,
            hintText: '可按格式填写，例如：10000元/月或120000元/年',
          ),
          CustomTextField(
            label: '支出',
            controller: _expensesController,
            prefixIcon: Icons.money_off,
            hintText: '请填写您的月均支出，例如：5000元/月',
          ),
          CustomTextField(
            label: '资产',
            controller: _assetsController,
            prefixIcon: Icons.account_balance,
            hintText: '请填写您的主要资产及价值，例如：房产200万、车20万等',
          ),
          CustomTextField(
            label: '负债',
            controller: _liabilitiesController,
            prefixIcon: Icons.credit_card,
            hintText: '请填写您的负债情况，例如：房贷100万、车贷10万等',
          ),
        ],
      ),
    );
  }

  // 目标信息页面
  Widget _buildGoalInfoPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '目标信息',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '您目前最关心的问题是什么？最想要达成的目标是什么？例如：存下100万元提前退休，或是为养老做准备，您可以填写这部分信息，我们能够根据您的目标为您提供更加个性化的服务',
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _goalDetailsController,
            maxLines: 6,
            style: const TextStyle(fontSize: 16.0),
            decoration: const InputDecoration(
              labelText: '目标详情',
              hintText: '请描述您的财务目标，例如：5年内购买一套200万的房产、为子女准备100万教育金、计划60岁退休后每月有15000元收入等',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  // 保险信息页面
  Widget _buildInsuranceInfoPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '保险信息',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '请您提供一些您的保险信息，包括您目前拥有的社会医疗保险、社会养老保险和商业保险，这能帮助我们更好地了解您的保险状况，为您推荐合适的保险产品。',
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          
          // 社会医疗保险问题
          _buildInsuranceQuestion(
            '您是否参加了社会医疗保险？',
            _hasMedicalInsurance,
            (value) => setState(() {
              _hasMedicalInsurance = value;
              if (value == '否') _medicalInsuranceType = null;
            }),
          ),
          
          // 社会医疗保险类型追问
          if (_hasMedicalInsurance == '是') ...[
            const SizedBox(height: 16),
            _buildInsuranceTypeQuestion(
              '您的社会医疗保险类型是什么？',
              _medicalInsuranceType,
              ['城镇职工', '城乡居民', '公费医疗'],
              (value) => setState(() => _medicalInsuranceType = value),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // 社会养老保险问题
          _buildInsuranceQuestion(
            '您是否参加了社会养老保险？',
            _hasEndowmentInsurance,
            (value) => setState(() {
              _hasEndowmentInsurance = value;
              if (value == '否') _endowmentInsuranceType = null;
            }),
          ),
          
          // 社会养老保险类型追问
          if (_hasEndowmentInsurance == '是') ...[
            const SizedBox(height: 16),
            _buildInsuranceTypeQuestion(
              '您的社会养老保险类型是什么？',
              _endowmentInsuranceType,
              ['城镇职工', '城乡居民'],
              (value) => setState(() => _endowmentInsuranceType = value),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // 商业保险问题
          _buildInsuranceQuestion(
            '您是否购买了商业保险？',
            _hasBusinessInsurance,
            (value) => setState(() => _hasBusinessInsurance = value),
          ),
        ],
      ),
    );
  }

  // 构建保险是否问题的组件
  Widget _buildInsuranceQuestion(String question, String? currentValue, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('是'),
                value: '是',
                groupValue: currentValue,
                onChanged: onChanged,
                visualDensity: VisualDensity.compact,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('否'),
                value: '否',
                groupValue: currentValue,
                onChanged: onChanged,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 构建保险类型选择的组件
  Widget _buildInsuranceTypeQuestion(String question, String? currentValue, List<String> options, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question,
          style: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        ...options.map((option) => RadioListTile<String>(
          title: Text(option),
          value: option,
          groupValue: currentValue,
          onChanged: onChanged,
          visualDensity: VisualDensity.compact,
        )).toList(),
      ],
    );
  }

  // 欢迎页面
  Widget _buildWelcomePage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 欢迎标题
          Text(
            '欢迎使用 Skysail',
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          // 欢迎语
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.purple.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.celebration,
                  color: _primaryColor,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  '设置完成！您可以从以下模块开始探索',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '如有困惑，可进入个人中心的帮助与反馈查看使用教程',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // 模块卡片网格
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: _modules.length,
            itemBuilder: (context, index) {
              return _ModuleCard(
                moduleInfo: _modules[index],
                onTap: () => _navigateToModule(_modules[index].tabIndex),
              );
            },
          ),
        ],
      ),
    );
  }

  // 底部按钮
  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          // 隐私政策页面的跳过按钮
          if (_currentPage == 0)
            Expanded(
              child: CustomButton(
                text: '跳过设置',
                onPressed: _skipSetup,
                backgroundColor: Colors.grey[400],
                isLoading: _isLoading,
                isFullWidth: true,
              ),
            ),
          
          // 上一页按钮
          if (_currentPage > 0 && _currentPage < 5) // 欢迎页面不显示上一页按钮
            Expanded(
              child: CustomButton(
                text: '上一页',
                onPressed: _previousPage,
                backgroundColor: Colors.grey[400],
                isFullWidth: true,
              ),
            ),
          
          if ((_currentPage > 0 && _currentPage < 5) || _currentPage == 0) const SizedBox(width: 16),

          // 下一页/提交按钮 (欢迎页面不显示此按钮)
          if (_currentPage < 5)
            Expanded(
              child: CustomButton(
                text: _currentPage == 4 ? '完成设置' : '下一页',
                onPressed: _currentPage == 4 ? _submitForm : _nextPage,
                isLoading: _isLoading,
                backgroundColor: _primaryColor,
                isFullWidth: true,
              ),
            ),
        ],
      ),
    );
  }
}

// 模块信息数据类
class ModuleInfo {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final int tabIndex;

  const ModuleInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.tabIndex,
  });
}

// 模块卡片组件
class _ModuleCard extends StatelessWidget {
  final ModuleInfo moduleInfo;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.moduleInfo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: moduleInfo.color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: moduleInfo.color.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图标
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: moduleInfo.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                moduleInfo.icon,
                color: moduleInfo.color,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            
            // 标题
            Text(
              moduleInfo.title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            
            // 描述
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                moduleInfo.description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 