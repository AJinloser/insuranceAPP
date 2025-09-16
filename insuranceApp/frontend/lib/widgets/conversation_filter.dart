import 'package:flutter/material.dart';

import '../services/developer_service.dart';
import '../services/api_service.dart';
import '../services/dify_service.dart';
import '../models/dify_models.dart';

/// 会话筛选器组件
class ConversationFilter extends StatefulWidget {
  final List<AdminUserInfo> users;
  final Function({
    List<String>? selectedUserIds,
    List<String>? selectedAppKeys,
    DateTime? startTime,
    DateTime? endTime,
    String? keyword,
    String? feedback,
  }) onFilterChanged;

  const ConversationFilter({
    Key? key,
    required this.users,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  State<ConversationFilter> createState() => _ConversationFilterState();
}

class _ConversationFilterState extends State<ConversationFilter> {
  List<String> _selectedUserIds = []; // 改为多选
  List<String> _selectedAppKeys = []; // 改为多选
  DateTime? _startTime;
  DateTime? _endTime;
  final TextEditingController _keywordController = TextEditingController();
  String _selectedFeedback = '全部';

  List<String> _appKeys = [];
  List<AppInfo> _appInfos = [];

  @override
  void initState() {
    super.initState();
    _loadAppKeys();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  void _loadAppKeys() {
    // 从后端API获取AI模块列表
    _loadAppKeysFromBackend();
  }
  
  Future<void> _loadAppKeysFromBackend() async {
    try {
      final apiService = ApiService();
      final response = await apiService.get('/ai_modules');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['code'] == 200) {
          final apiKeysList = List<String>.from(data['ai_modules']);
          _appKeys = apiKeysList;
          _appInfos = [];
          
          // 获取每个API key对应的应用信息
          final difyService = DifyService();
          for (final apiKey in apiKeysList) {
            try {
              difyService.setApiKey(apiKey);
              final appInfo = await difyService.getAppInfo();
              _appInfos.add(appInfo);
            } catch (e) {
              // 如果获取应用信息失败，使用默认名称
              _appInfos.add(AppInfo(
                name: '应用 ${apiKey.substring(0, 8)}...',
                description: '无法获取应用信息',
                tags: [],
              ));
            }
          }
        } else {
          _appKeys = [];
          _appInfos = [];
        }
      } else {
        _appKeys = [];
        _appInfos = [];
      }
    } catch (e) {
      _appKeys = [];
      _appInfos = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.filter_list,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  '筛选条件',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 第一行：用户账户和应用
            Row(
              children: [
                Expanded(
                  child: _buildUserDropdown(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAppDropdown(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 第二行：时间范围
            Row(
              children: [
                Expanded(
                  child: _buildDatePicker(
                    label: '起始时间',
                    date: _startTime,
                    onDateSelected: (date) {
                      setState(() {
                        _startTime = date;
                      });
                      _notifyFilterChanged();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDatePicker(
                    label: '终止时间',
                    date: _endTime,
                    onDateSelected: (date) {
                      setState(() {
                        _endTime = date;
                      });
                      _notifyFilterChanged();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 第三行：关键词和反馈
            Row(
              children: [
                Expanded(
                  child: _buildKeywordField(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFeedbackDropdown(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear),
                    label: const Text('清空筛选'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _applyFilters,
                    icon: const Icon(Icons.search),
                    label: const Text('开始分析'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
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

  Widget _buildUserDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '用户账户',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _showUserMultiSelectDialog(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedUserIds.isEmpty 
                        ? '选择用户' 
                        : _selectedUserIds.length == 1
                            ? widget.users.firstWhere((u) => u.userId == _selectedUserIds.first).account
                            : '已选择${_selectedUserIds.length}个用户',
                    style: TextStyle(
                      color: _selectedUserIds.isEmpty ? Colors.grey[600] : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAppDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '应用',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () => _showAppMultiSelectDialog(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedAppKeys.isEmpty 
                        ? '选择应用' 
                        : _selectedAppKeys.length == 1
                            ? _getAppName(_selectedAppKeys.first)
                            : '已选择${_selectedAppKeys.length}个应用',
                    style: TextStyle(
                      color: _selectedAppKeys.isEmpty ? Colors.grey[600] : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? date,
    required Function(DateTime?) onDateSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final selectedDate = await showDatePicker(
              context: context,
              initialDate: date ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
            );
            onDateSelected(selectedDate);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null
                        ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
                        : '选择日期',
                    style: TextStyle(
                      color: date != null ? Colors.black87 : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeywordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '关键词',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _keywordController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: '输入关键词进行模糊匹配',
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onChanged: (_) => _notifyFilterChanged(),
        ),
      ],
    );
  }

  Widget _buildFeedbackDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '反馈',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: _selectedFeedback,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          isExpanded: true, // 修复溢出问题
          items: const [
            DropdownMenuItem<String>(
              value: '全部',
              child: Text('全部'),
            ),
            DropdownMenuItem<String>(
              value: '点赞',
              child: Text('点赞'),
            ),
            DropdownMenuItem<String>(
              value: '点踩',
              child: Text('点踩'),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _selectedFeedback = value ?? '全部';
            });
            _notifyFilterChanged();
          },
        ),
      ],
    );
  }

  /// 获取应用名称
  String _getAppName(String apiKey) {
    final index = _appKeys.indexOf(apiKey);
    if (index >= 0 && index < _appInfos.length) {
      return _appInfos[index].name;
    }
    return '应用 $apiKey';
  }

  /// 显示用户多选对话框
  void _showUserMultiSelectDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('选择用户'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.users.length,
                  itemBuilder: (context, index) {
                    final user = widget.users[index];
                    final isSelected = _selectedUserIds.contains(user.userId);
                    return CheckboxListTile(
                      title: Text(user.account),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            _selectedUserIds.add(user.userId);
                          } else {
                            _selectedUserIds.remove(user.userId);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      _selectedUserIds.clear();
                    });
                  },
                  child: const Text('清空'),
                ),
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      _selectedUserIds = widget.users.map((u) => u.userId).toList();
                    });
                  },
                  child: const Text('全选'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {});
                    _notifyFilterChanged();
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// 显示应用多选对话框
  void _showAppMultiSelectDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('选择应用'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _appKeys.length,
                  itemBuilder: (context, index) {
                    final apiKey = _appKeys[index];
                    final appName = _getAppName(apiKey);
                    final isSelected = _selectedAppKeys.contains(apiKey);
                    return CheckboxListTile(
                      title: Text(appName),
                      subtitle: Text('API Key: ${apiKey.substring(0, 10)}...'),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            _selectedAppKeys.add(apiKey);
                          } else {
                            _selectedAppKeys.remove(apiKey);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      _selectedAppKeys.clear();
                    });
                  },
                  child: const Text('清空'),
                ),
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      _selectedAppKeys = List.from(_appKeys);
                    });
                  },
                  child: const Text('全选'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {});
                    _notifyFilterChanged();
                  },
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _notifyFilterChanged() {
    final keyword = _keywordController.text.trim().isEmpty ? null : _keywordController.text.trim();
    final feedback = _selectedFeedback == '全部' ? null : _selectedFeedback;
    
    widget.onFilterChanged(
      selectedUserIds: _selectedUserIds.isEmpty ? null : _selectedUserIds,
      selectedAppKeys: _selectedAppKeys.isEmpty ? null : _selectedAppKeys,
      startTime: _startTime,
      endTime: _endTime,
      keyword: keyword,
      feedback: feedback,
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedUserIds.clear();
      _selectedAppKeys.clear();
      _startTime = null;
      _endTime = null;
      _keywordController.clear();
      _selectedFeedback = '全部';
    });
    _notifyFilterChanged();
  }

  void _applyFilters() {
    _notifyFilterChanged();
  }
}
