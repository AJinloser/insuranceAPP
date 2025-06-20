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
    if (_currentPage < 2) {
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

  // 提交表单
  Future<void> _submitForm() async {
    setState(() {
      _isLoading = true;
    });

    print('===> ProfileSetupPage: 开始提交个人信息');
    print('===> ProfileSetupPage: 目标详情内容: "${_goalDetailsController.text}"');

    try {
      // 构建UserInfo对象
      final userInfo = UserInfo(
        basicInfo: BasicInfo(
          age: _ageController.text.isEmpty ? null : _ageController.text,
          city: _cityController.text.isEmpty ? null : _cityController.text,
          gender: _genderController.text.isEmpty ? null : _genderController.text,
        ),
        financialInfo: FinancialInfo(
          occupation: _occupationController.text.isEmpty ? null : _occupationController.text,
          income: _incomeController.text.isEmpty ? null : _incomeController.text,
          expenses: _expensesController.text.isEmpty ? null : _expensesController.text,
          assets: _assetsController.text.isEmpty ? null : _assetsController.text,
          liabilities: _liabilitiesController.text.isEmpty ? null : _liabilitiesController.text,
        ),
        riskInfo: RiskInfo(),
        retirementInfo: RetirementInfo(),
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
        print('===> ProfileSetupPage: 个人信息提交成功');
        
        // 标记新用户设置完成
        final authService = Provider.of<AuthService>(context, listen: false);
        authService.completeNewUserSetup();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('个人信息初始化成功'),
            backgroundColor: Colors.green,
          ),
        );
        
        print('===> ProfileSetupPage: 个人信息初始化完成，AuthService将处理页面切换');
        // 不需要手动导航，AuthService状态变化会自动触发页面切换到HomePage
      } else if (mounted) {
        print('===> ProfileSetupPage: 个人信息提交失败');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userInfoService.error ?? '初始化失败'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('===> ProfileSetupPage: 提交异常: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('初始化失败: $e'),
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
                        _buildBasicInfoPage(),
                        _buildFinancialInfoPage(),
                        _buildGoalInfoPage(),
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
      children: List.generate(3, (index) {
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

  // 底部按钮
  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          // 上一页按钮
          if (_currentPage > 0)
            Expanded(
              child: CustomButton(
                text: '上一页',
                onPressed: _previousPage,
                backgroundColor: Colors.grey[400],
                isFullWidth: true,
              ),
            ),
          
          if (_currentPage > 0) const SizedBox(width: 16),

          // 下一页/提交按钮
          Expanded(
            child: CustomButton(
              text: _currentPage == 2 ? '完成设置' : '下一页',
              onPressed: _currentPage == 2 ? _submitForm : _nextPage,
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