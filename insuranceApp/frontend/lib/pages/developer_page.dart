import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/developer_service.dart';
import '../widgets/conversation_filter.dart';
import '../widgets/conversation_analysis_card.dart';

/// 开发者页面
/// 提供会话分析和用户管理功能
class DeveloperPage extends StatefulWidget {
  const DeveloperPage({Key? key}) : super(key: key);

  @override
  State<DeveloperPage> createState() => _DeveloperPageState();
}

class _DeveloperPageState extends State<DeveloperPage> {
  // 保存当前的筛选参数
  Map<String, dynamic>? _currentFilterParams;

  @override
  void initState() {
    super.initState();
    
    // 初始化时获取用户列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final developerService = Provider.of<DeveloperService>(context, listen: false);
      developerService.fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('开发者选项'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<DeveloperService>(
            builder: (context, developerService, child) {
              return IconButton(
                icon: const Icon(Icons.exit_to_app),
                onPressed: () => _showExitDialog(context, developerService),
                tooltip: '退出开发者模式',
              );
            },
          ),
        ],
      ),
      body: Consumer<DeveloperService>(
        builder: (context, developerService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 筛选器
                ConversationFilter(
                  users: developerService.users,
                  onFilterChanged: ({
                    List<String>? selectedUserIds,
                    List<String>? selectedAppKeys,
                    DateTime? startTime,
                    DateTime? endTime,
                    String? keyword,
                    String? feedback,
                  }) {
                    // 保存筛选参数到页面状态
                    _currentFilterParams = {
                      'selectedUserIds': selectedUserIds,
                      'selectedAppKeys': selectedAppKeys,
                      'startTime': startTime,
                      'endTime': endTime,
                      'keyword': keyword,
                      'feedback': feedback,
                    };
                  },
                ),
                const SizedBox(height: 16),
                
                // 分析按钮
                Center(
                  child: ElevatedButton.icon(
                    onPressed: developerService.isLoading ? null : () => _startAnalysis(developerService),
                    icon: developerService.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.analytics),
                    label: Text(developerService.isLoading ? '分析中...' : '开始分析'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // 导出按钮
                Center(
                  child: ElevatedButton.icon(
                    onPressed: developerService.conversations.isEmpty ? null : () => _exportConversations(developerService),
                    icon: const Icon(Icons.download),
                    label: const Text('导出数据'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 错误信息
                if (developerService.error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            developerService.error!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // 会话列表
                if (developerService.conversations.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.list,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '会话分析结果 (${developerService.conversations.length}个)',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // 会话卡片列表
                  ...developerService.conversations.map((analysis) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ConversationAnalysisCard(analysis: analysis),
                  )),
                ] else if (!developerService.isLoading && developerService.users.isNotEmpty) ...[
                  // 空状态
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '暂无会话数据',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '请设置筛选条件并点击"开始分析"',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _startAnalysis(DeveloperService developerService) {
    // 使用保存的筛选参数执行分析
    if (_currentFilterParams != null) {
      developerService.analyzeConversations(
        selectedUserIds: _currentFilterParams!['selectedUserIds'],
        selectedAppKeys: _currentFilterParams!['selectedAppKeys'],
        startTime: _currentFilterParams!['startTime'],
        endTime: _currentFilterParams!['endTime'],
        keyword: _currentFilterParams!['keyword'],
        feedback: _currentFilterParams!['feedback'],
      );
    } else {
      // 如果没有筛选参数，使用默认值（全部）
      developerService.analyzeConversations();
    }
  }

  /// 导出对话数据
  Future<void> _exportConversations(DeveloperService developerService) async {
    try {
      // 显示加载对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('正在导出数据...'),
              ],
            ),
          );
        },
      );
      
      // 调用开发者服务的导出功能
      await developerService.exportConversations(
        filterParams: _currentFilterParams,
        onProgress: (progress) {
          // 可以在这里显示进度，但暂时不输出到控制台
        },
      );
      
      // 关闭加载对话框
      Navigator.of(context).pop();
      
      // 显示成功消息
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('数据导出成功！'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      // 关闭加载对话框
      Navigator.of(context).pop();
      
      // 显示错误消息
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('导出失败: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 显示退出确认对话框
  void _showExitDialog(BuildContext context, DeveloperService developerService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('退出开发者模式'),
          content: const Text('确定要退出开发者模式吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 关闭对话框
                developerService.exitDeveloperMode();
                Navigator.of(context).pop(); // 返回上一页
              },
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }
}
