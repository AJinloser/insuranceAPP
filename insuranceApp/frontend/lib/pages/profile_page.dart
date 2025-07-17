import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user_info.dart';
import '../services/user_info_service.dart';
import '../services/auth_service.dart';
import 'profile_edit_page.dart';
import 'privacy_policy_page.dart';
import 'help_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userInfoService = Provider.of<UserInfoService>(context, listen: false);
      userInfoService.fetchUserInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('个人中心'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
            tooltip: '退出登录',
          ),
        ],
      ),
      body: Consumer<UserInfoService>(
        builder: (context, userInfoService, child) {
          if (userInfoService.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (userInfoService.error != null) {
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
                    userInfoService.error!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => userInfoService.fetchUserInfo(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          final userInfo = userInfoService.userInfo ?? UserInfo.empty();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildUserInfoCard(context, userInfo),
                const SizedBox(height: 24),
                _buildActionButtons(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserInfoCard(BuildContext context, UserInfo userInfo) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToEditPage(context, userInfo),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.person,
                      size: 32,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '个人信息',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '点击查看和编辑您的个人信息',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
              _buildInfoSection('基本信息', [
                _buildInfoItem('年龄', userInfo.basicInfo.age ?? '未设置'),
                _buildInfoItem('城市', userInfo.basicInfo.city ?? '未设置'),
                _buildInfoItem('性别', userInfo.basicInfo.gender ?? '未设置'),
              ]),
              const SizedBox(height: 16),
              _buildInfoSection('财务信息', [
                _buildInfoItem('职业', userInfo.financialInfo.occupation ?? '未设置'),
                _buildInfoItem('收入', userInfo.financialInfo.income ?? '未设置'),
                _buildInfoItem('支出', userInfo.financialInfo.expenses ?? '未设置'),
              ]),
              const SizedBox(height: 16),
              _buildInfoSection('家庭信息', [
                _buildInfoItem('家庭成员', '${userInfo.familyInfo.familyMembers.length}人'),
              ]),
              const SizedBox(height: 16),
              _buildInfoSection('目标信息', [
                _buildInfoItem('目标数量', '${userInfo.goalInfo.goals.length}个'),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> items) {
    return Column(
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
        const SizedBox(height: 8),
        ...items,
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(
              Icons.settings,
              color: Theme.of(context).primaryColor,
            ),
            title: const Text('设置'),
            subtitle: const Text('应用设置和偏好'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('设置功能敬请期待')),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(
              Icons.help_outline,
              color: Theme.of(context).primaryColor,
            ),
            title: const Text('帮助与反馈'),
            subtitle: const Text('获取帮助或提供反馈'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpPage(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(
              Icons.privacy_tip_outlined,
              color: Theme.of(context).primaryColor,
            ),
            title: const Text('隐私政策'),
            subtitle: const Text('了解我们如何保护您的隐私'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyPage(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _navigateToEditPage(BuildContext context, UserInfo userInfo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditPage(userInfo: userInfo),
      ),
    ).then((_) {
      // 从编辑页面返回后刷新数据
      final userInfoService = Provider.of<UserInfoService>(context, listen: false);
      userInfoService.fetchUserInfo();
    });
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('退出登录'),
          content: const Text('确定要退出登录吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // 关闭对话框
                
                // 执行退出登录
                final authService = Provider.of<AuthService>(context, listen: false);
                await authService.logout();
                
                // 手动清理导航栈并跳转到登录页面
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false, // 清除所有路由
                  );
                }
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
} 