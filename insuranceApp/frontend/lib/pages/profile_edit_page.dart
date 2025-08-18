import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_info.dart';
import '../services/user_info_service.dart';

class ProfileEditPage extends StatefulWidget {
  final UserInfo userInfo;

  const ProfileEditPage({Key? key, required this.userInfo}) : super(key: key);

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  late UserInfo _editedUserInfo;
  bool _isLoading = false;

  // 基本信息控制器
  late TextEditingController _ageController;
  late TextEditingController _cityController;
  late TextEditingController _genderController;
  late TextEditingController _healthStatusController;

  // 财务信息控制器
  late TextEditingController _occupationController;
  late TextEditingController _incomeController;
  late TextEditingController _expensesController;
  late TextEditingController _assetsController;
  late TextEditingController _liabilitiesController;
  late TextEditingController _currentAssetsController;

  // 风险信息控制器
  late TextEditingController _riskAversionController;

  // 退休信息控制器
  late TextEditingController _retirementAgeController;
  late TextEditingController _retirementIncomeController;

  // 保险信息控制器
  late TextEditingController _socialMedicalInsuranceController;
  late TextEditingController _socialEndowmentInsuranceController;
  late TextEditingController _businessInsuranceController;

  // 家庭成员控制器列表
  List<List<TextEditingController>> _familyMemberControllers = [];

  // 目标控制器列表
  List<TextEditingController> _goalControllers = [];

  // 其他信息控制器列表 (键值对)
  List<List<TextEditingController>> _otherInfoControllers = [];

  @override
  void initState() {
    super.initState();
    _editedUserInfo = widget.userInfo.copyWith();
    _initializeControllers();
  }

  void _initializeControllers() {
    // 基本信息
    _ageController = TextEditingController(text: _editedUserInfo.basicInfo.age ?? '');
    _cityController = TextEditingController(text: _editedUserInfo.basicInfo.city ?? '');
    _genderController = TextEditingController(text: _editedUserInfo.basicInfo.gender ?? '');
    _healthStatusController = TextEditingController(text: _editedUserInfo.basicInfo.healthStatus ?? '');

    // 财务信息
    _occupationController = TextEditingController(text: _editedUserInfo.financialInfo.occupation ?? '');
    _incomeController = TextEditingController(text: _editedUserInfo.financialInfo.income ?? '');
    _expensesController = TextEditingController(text: _editedUserInfo.financialInfo.expenses ?? '');
    _assetsController = TextEditingController(text: _editedUserInfo.financialInfo.assets ?? '');
    _liabilitiesController = TextEditingController(text: _editedUserInfo.financialInfo.liabilities ?? '');
    _currentAssetsController = TextEditingController(text: _editedUserInfo.financialInfo.currentAssets ?? '');

    // 风险信息
    _riskAversionController = TextEditingController(text: _editedUserInfo.riskInfo.riskAversion ?? '');

    // 退休信息
    _retirementAgeController = TextEditingController(text: _editedUserInfo.retirementInfo.retirementAge ?? '');
    _retirementIncomeController = TextEditingController(text: _editedUserInfo.retirementInfo.retirementIncome ?? '');

    // 保险信息
    _socialMedicalInsuranceController = TextEditingController(text: _editedUserInfo.insuranceInfo.socialMedicalInsurance ?? '');
    _socialEndowmentInsuranceController = TextEditingController(text: _editedUserInfo.insuranceInfo.socialEndowmentInsurance ?? '');
    _businessInsuranceController = TextEditingController(text: _editedUserInfo.insuranceInfo.businessInsurance ?? '');

    // 初始化家庭成员控制器
    _initializeFamilyMemberControllers();

    // 初始化目标控制器
    _initializeGoalControllers();

    // 初始化其他信息控制器
    _initializeOtherInfoControllers();
  }

  void _initializeFamilyMemberControllers() {
    _familyMemberControllers.clear();
    for (final member in _editedUserInfo.familyInfo.familyMembers) {
      _familyMemberControllers.add([
        TextEditingController(text: member.relation ?? ''), // 关系
        TextEditingController(text: member.age ?? ''),      // 年龄
        TextEditingController(text: member.occupation ?? ''), // 职业
        TextEditingController(text: member.income ?? ''),   // 收入
      ]);
    }
  }

  void _initializeGoalControllers() {
    _goalControllers.clear();
    for (final goal in _editedUserInfo.goalInfo.goals) {
      _goalControllers.add(
        TextEditingController(text: goal.goalDetails ?? ''),
      );
    }
  }

  void _initializeOtherInfoControllers() {
    _otherInfoControllers.clear();
    _editedUserInfo.otherInfo.forEach((key, value) {
      _otherInfoControllers.add([
        TextEditingController(text: key), // 键
        TextEditingController(text: value?.toString() ?? ''), // 值
      ]);
    });
  }

  @override
  void dispose() {
    // 基本信息控制器
    _ageController.dispose();
    _cityController.dispose();
    _genderController.dispose();
    _healthStatusController.dispose();
    
    // 财务信息控制器
    _occupationController.dispose();
    _incomeController.dispose();
    _expensesController.dispose();
    _assetsController.dispose();
    _liabilitiesController.dispose();
    _currentAssetsController.dispose();
    
    // 风险信息控制器
    _riskAversionController.dispose();
    
    // 退休信息控制器
    _retirementAgeController.dispose();
    _retirementIncomeController.dispose();

    // 保险信息控制器
    _socialMedicalInsuranceController.dispose();
    _socialEndowmentInsuranceController.dispose();
    _businessInsuranceController.dispose();

    // 家庭成员控制器
    for (final controllers in _familyMemberControllers) {
      for (final controller in controllers) {
        controller.dispose();
      }
    }

    // 目标控制器
    for (final controller in _goalControllers) {
      controller.dispose();
    }

    // 其他信息控制器
    for (final controllers in _otherInfoControllers) {
      for (final controller in controllers) {
        controller.dispose();
      }
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('编辑个人信息'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildBasicInfoSection(),
              const SizedBox(height: 20),
              _buildFinancialInfoSection(),
              const SizedBox(height: 20),
              _buildRiskInfoSection(),
              const SizedBox(height: 20),
              _buildRetirementInfoSection(),
              const SizedBox(height: 20),
              _buildInsuranceInfoSection(),
              const SizedBox(height: 20),
              _buildFamilyInfoSection(),
              const SizedBox(height: 20),
              _buildGoalInfoSection(),
              const SizedBox(height: 20),
              _buildOtherInfoSection(),
              const SizedBox(height: 32),
              _buildSaveButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '基本信息',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField('年龄', _ageController, Icons.cake),
            const SizedBox(height: 12),
            _buildTextField('城市', _cityController, Icons.location_city),
            const SizedBox(height: 12),
            _buildTextField('性别', _genderController, Icons.person),
            const SizedBox(height: 12),
            _buildTextField('健康状况', _healthStatusController, Icons.health_and_safety),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '财务信息',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField('职业', _occupationController, Icons.work),
            const SizedBox(height: 12),
            _buildTextField('收入', _incomeController, Icons.attach_money),
            const SizedBox(height: 12),
            _buildTextField('支出', _expensesController, Icons.money_off),
            const SizedBox(height: 12),
            _buildTextField('资产', _assetsController, Icons.account_balance),
            const SizedBox(height: 12),
            _buildTextField('负债', _liabilitiesController, Icons.credit_card),
            const SizedBox(height: 12),
            _buildTextField('流动资产', _currentAssetsController, Icons.account_balance_wallet),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '风险信息',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField('风险厌恶程度', _riskAversionController, Icons.trending_up),
          ],
        ),
      ),
    );
  }

  Widget _buildRetirementInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '退休信息',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField('退休年龄', _retirementAgeController, Icons.elderly),
            const SizedBox(height: 12),
            _buildTextField('退休收入', _retirementIncomeController, Icons.savings),
          ],
        ),
      ),
    );
  }

  Widget _buildInsuranceInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '保险信息',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField('社会医疗保险', _socialMedicalInsuranceController, Icons.medical_services),
            const SizedBox(height: 12),
            _buildTextField('社会养老保险', _socialEndowmentInsuranceController, Icons.handshake),
            const SizedBox(height: 12),
            _buildTextField('商业保险', _businessInsuranceController, Icons.business_center),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '家庭信息',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _addFamilyMember,
                  icon: const Icon(Icons.add_circle),
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_familyMemberControllers.isEmpty)
              const Center(
                child: Text(
                  '暂无家庭成员\n点击右上角添加按钮添加家庭成员',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...List.generate(_familyMemberControllers.length, (index) {
                return _buildFamilyMemberCard(index);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyMemberCard(int index) {
    final controllers = _familyMemberControllers[index];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '家庭成员 ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  onPressed: () => _removeFamilyMember(index),
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controllers[0], // 关系
                    decoration: const InputDecoration(
                      labelText: '关系',
                      border: OutlineInputBorder(),
                      isDense: true,
                      hintText: '例如：配偶、子女、父母等',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: controllers[1], // 年龄
                    decoration: const InputDecoration(
                      labelText: '年龄',
                      border: OutlineInputBorder(),
                      isDense: true,
                      hintText: '请输入实际年龄',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: controllers[2], // 职业
                    decoration: const InputDecoration(
                      labelText: '职业',
                      border: OutlineInputBorder(),
                      isDense: true,
                      hintText: '例如：学生、教师等',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: controllers[3], // 收入
                    decoration: const InputDecoration(
                      labelText: '收入',
                      border: OutlineInputBorder(),
                      isDense: true,
                      hintText: '例如：8000元/月',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '目标信息',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _addGoal,
                  icon: const Icon(Icons.add_circle),
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_goalControllers.isEmpty)
              const Center(
                child: Text(
                  '暂无目标\n点击右上角添加按钮添加目标',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...List.generate(_goalControllers.length, (index) {
                return _buildGoalCard(index);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '目标 ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  onPressed: () => _removeGoal(index),
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _goalControllers[index],
              decoration: const InputDecoration(
                labelText: '目标详情',
                border: OutlineInputBorder(),
                isDense: true,
                hintText: '请描述您的财务目标，例如：5年内购买一套200万的房产、为子女准备100万教育金、计划60岁退休后每月有15000元收入等',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '其他信息',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _addOtherInfo,
                  icon: const Icon(Icons.add_circle),
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_otherInfoControllers.isEmpty)
              const Center(
                child: Text(
                  '暂无其他信息\n点击右上角添加按钮添加自定义信息',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...List.generate(_otherInfoControllers.length, (index) {
                return _buildOtherInfoCard(index);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherInfoCard(int index) {
    final controllers = _otherInfoControllers[index];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '信息项 ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                IconButton(
                  onPressed: () => _removeOtherInfo(index),
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: controllers[0], // 键
                    decoration: const InputDecoration(
                      labelText: '字段名称',
                      border: OutlineInputBorder(),
                      isDense: true,
                      hintText: '例如：爱好、健康状况、保险需求等',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: controllers[1], // 值
                    decoration: const InputDecoration(
                      labelText: '字段内容',
                      border: OutlineInputBorder(),
                      isDense: true,
                      hintText: '请填写具体内容，例如：旅游、高血压家族史、希望有一份重疾保障等',
                      hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    String hintText = '';
    
    // 根据不同的标签提供不同的提示信息
    switch(label) {
      // 基本信息
      case '年龄':
        hintText = '请输入您的实际年龄，例如：35岁';
        break;
      case '城市':
        hintText = '请输入您当前居住的城市，例如：上海';
        break;
      case '性别':
        hintText = '请输入您的性别，例如：男/女/其他';
        break;
      case '健康状况':
        hintText = '请填写您的健康状况，例如：良好、一般、较差';
        break;
        
      // 财务信息
      case '职业':
        hintText = '请输入您的职业，例如：软件工程师、教师等';
        break;
      case '收入':
        hintText = '可按格式填写，例如：10000元/月或120000元/年';
        break;
      case '支出':
        hintText = '请填写您的月均支出，例如：5000元/月';
        break;
      case '资产':
        hintText = '请填写您的主要资产及价值，例如：房产200万、车20万等，也可以给出具体房产的位置或车的品牌，能够帮助我们更好地了解您的资产情况';
        break;
      case '负债':
        hintText = '请填写您的负债情况，例如：房贷100万、车贷10万等，也可以给出具体缴纳的期限等有用信息。';
        break;
      case '当前资产':
        hintText = '请填写您当前的净资产，例如：100万';
        break;
        
      // 风险信息
      case '风险厌恶程度':
        hintText = '请填写您的风险厌恶程度，例如：高/中/低，高代表非常厌恶风险';
        break;
        
      // 退休信息
      case '退休年龄':
        hintText = '请填写您计划的退休年龄，例如：60岁';
        break;
      case '退休收入':
        hintText = '请填写您期望的退休月收入，例如：8000元/月';
        break;
        
      // 保险信息
      case '社会医疗保险':
        hintText = '请填写您的社会医疗保险情况，例如：已缴费5年、城镇职工医保等';
        break;
      case '社会养老保险':
        hintText = '请填写您的社会养老保险情况，例如：已缴费10年、城镇职工养老保险等';
        break;
      case '商业保险':
        hintText = '请填写您已购买的商业保险，例如：重疾险50万、意外险100万等';
        break;
    }
    
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        isDense: true,
        hintText: hintText,
        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveUserInfo,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                '保存',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  void _addFamilyMember() {
    setState(() {
      _editedUserInfo.familyInfo.familyMembers.add(FamilyMember());
      _familyMemberControllers.add([
        TextEditingController(), // 关系
        TextEditingController(), // 年龄
        TextEditingController(), // 职业
        TextEditingController(), // 收入
      ]);
    });
  }

  void _removeFamilyMember(int index) {
    setState(() {
      _editedUserInfo.familyInfo.familyMembers.removeAt(index);
      // 释放控制器
      for (final controller in _familyMemberControllers[index]) {
        controller.dispose();
      }
      _familyMemberControllers.removeAt(index);
    });
  }

  void _addGoal() {
    setState(() {
      _editedUserInfo.goalInfo.goals.add(Goal());
      _goalControllers.add(TextEditingController());
    });
  }

  void _removeGoal(int index) {
    setState(() {
      _editedUserInfo.goalInfo.goals.removeAt(index);
      _goalControllers[index].dispose();
      _goalControllers.removeAt(index);
    });
  }

  void _addOtherInfo() {
    setState(() {
      _otherInfoControllers.add([
        TextEditingController(), // 键
        TextEditingController(), // 值
      ]);
    });
  }

  void _removeOtherInfo(int index) {
    setState(() {
      // 释放控制器
      for (final controller in _otherInfoControllers[index]) {
        controller.dispose();
      }
      _otherInfoControllers.removeAt(index);
    });
  }

  void _saveUserInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 更新编辑后的用户信息
    _updateUserInfoFromControllers();

    final userInfoService = Provider.of<UserInfoService>(context, listen: false);
    final success = await userInfoService.updateUserInfo(_editedUserInfo);

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('个人信息更新成功'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userInfoService.error ?? '更新失败'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateUserInfoFromControllers() {
    // 从控制器收集家庭成员数据
    final familyMembers = <FamilyMember>[];
    for (int i = 0; i < _familyMemberControllers.length; i++) {
      final controllers = _familyMemberControllers[i];
      familyMembers.add(FamilyMember(
        relation: controllers[0].text.isEmpty ? null : controllers[0].text,
        age: controllers[1].text.isEmpty ? null : controllers[1].text,
        occupation: controllers[2].text.isEmpty ? null : controllers[2].text,
        income: controllers[3].text.isEmpty ? null : controllers[3].text,
      ));
    }

    // 从控制器收集目标数据
    final goals = <Goal>[];
    for (int i = 0; i < _goalControllers.length; i++) {
      goals.add(Goal(
        goalDetails: _goalControllers[i].text.isEmpty ? null : _goalControllers[i].text,
      ));
    }

    // 从控制器收集其他信息数据
    final otherInfo = <String, dynamic>{};
    for (int i = 0; i < _otherInfoControllers.length; i++) {
      final controllers = _otherInfoControllers[i];
      final key = controllers[0].text.trim();
      final value = controllers[1].text.trim();
      
      // 只有当键不为空时才添加到map中
      if (key.isNotEmpty) {
        otherInfo[key] = value.isEmpty ? null : value;
      }
    }

    // 更新基本信息
    _editedUserInfo = _editedUserInfo.copyWith(
      basicInfo: _editedUserInfo.basicInfo.copyWith(
        age: _ageController.text.isEmpty ? null : _ageController.text,
        city: _cityController.text.isEmpty ? null : _cityController.text,
        gender: _genderController.text.isEmpty ? null : _genderController.text,
        healthStatus: _healthStatusController.text.isEmpty ? null : _healthStatusController.text,
      ),
      financialInfo: _editedUserInfo.financialInfo.copyWith(
        occupation: _occupationController.text.isEmpty ? null : _occupationController.text,
        income: _incomeController.text.isEmpty ? null : _incomeController.text,
        expenses: _expensesController.text.isEmpty ? null : _expensesController.text,
        assets: _assetsController.text.isEmpty ? null : _assetsController.text,
        liabilities: _liabilitiesController.text.isEmpty ? null : _liabilitiesController.text,
        currentAssets: _currentAssetsController.text.isEmpty ? null : _currentAssetsController.text,
      ),
      riskInfo: _editedUserInfo.riskInfo.copyWith(
        riskAversion: _riskAversionController.text.isEmpty ? null : _riskAversionController.text,
      ),
      retirementInfo: _editedUserInfo.retirementInfo.copyWith(
        retirementAge: _retirementAgeController.text.isEmpty ? null : _retirementAgeController.text,
        retirementIncome: _retirementIncomeController.text.isEmpty ? null : _retirementIncomeController.text,
      ),
      insuranceInfo: _editedUserInfo.insuranceInfo.copyWith(
        socialMedicalInsurance: _socialMedicalInsuranceController.text.isEmpty ? null : _socialMedicalInsuranceController.text,
        socialEndowmentInsurance: _socialEndowmentInsuranceController.text.isEmpty ? null : _socialEndowmentInsuranceController.text,
        businessInsurance: _businessInsuranceController.text.isEmpty ? null : _businessInsuranceController.text,
      ),
      familyInfo: _editedUserInfo.familyInfo.copyWith(
        familyMembers: familyMembers,
      ),
      goalInfo: _editedUserInfo.goalInfo.copyWith(
        goals: goals,
      ),
      otherInfo: otherInfo,
    );
  }
} 