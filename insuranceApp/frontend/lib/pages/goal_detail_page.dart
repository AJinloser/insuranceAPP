import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/goal_service.dart';
import '../models/goal.dart';

class GoalDetailPage extends StatefulWidget {
  final String goalId;

  const GoalDetailPage({Key? key, required this.goalId}) : super(key: key);

  @override
  State<GoalDetailPage> createState() => _GoalDetailPageState();
}

class _GoalDetailPageState extends State<GoalDetailPage> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGoalDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGoalDetail() async {
    final goalService = Provider.of<GoalService>(context, listen: false);
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final success = await goalService.getGoalDetailInfo(context, widget.goalId);
      
      if (!success) {
        setState(() {
          _error = goalService.error ?? '加载失败';
        });
      }
    } catch (e) {
      setState(() {
        _error = '加载目标详情时出错: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('目标详情'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: '子目标'),
            Tab(text: '任务'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
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
              _error!,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadGoalDetail,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return Consumer<GoalService>(
      builder: (context, goalService, child) {
        final goal = goalService.currentGoal;
        
        if (goal == null) {
          return const Center(
            child: Text('目标不存在'),
          );
        }

        return Column(
          children: [
            _buildGoalHeader(goal),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSubGoalsTab(goal),
                  _buildSubTasksTab(goal),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGoalHeader(Goal goal) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.goalName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (goal.priority != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(goal.priority!).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    goal.priority!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getPriorityColor(goal.priority!),
                    ),
                  ),
                ),
            ],
          ),
          
          if (goal.goalDescription != null) ...[
            const SizedBox(height: 8),
            Text(
              goal.goalDescription!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.3,
              ),
            ),
          ],
          
          if (goal.targetAmount != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '目标金额',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '¥${_formatNumber(goal.targetAmount!)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '已完成',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '¥${_formatNumber(goal.completedAmount)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                if (goal.expectedCompletionTime != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '预计完成',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          goal.expectedCompletionTime!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '完成进度',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${(goal.progress * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: goal.progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  minHeight: 8,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubGoalsTab(Goal goal) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '子目标 (${goal.subGoals.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _addSubGoal(goal),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: goal.subGoals.isEmpty
              ? _buildEmptyState('还没有子目标', '添加子目标来分解你的大目标')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: goal.subGoals.length,
                  itemBuilder: (context, index) {
                    final subGoal = goal.subGoals[index];
                    return _buildSubGoalCard(goal, subGoal, index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSubTasksTab(Goal goal) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '任务 (${goal.subTaskCompletedNum}/${goal.subTaskNum})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _addSubTask(goal),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: goal.subTasks.isEmpty
              ? _buildEmptyState('还没有任务', '添加具体的执行任务')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: goal.subTasks.length,
                  itemBuilder: (context, index) {
                    final subTask = goal.subTasks[index];
                    return _buildSubTaskCard(goal, subTask, index);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubGoalCard(Goal goal, SubGoal subGoal, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Checkbox(
          value: subGoal.subGoalStatus,
          onChanged: (value) => _toggleSubGoalStatus(goal, index, value ?? false),
        ),
        title: Text(
          subGoal.subGoalName,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            decoration: subGoal.subGoalStatus ? TextDecoration.lineThrough : null,
            color: subGoal.subGoalStatus ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subGoal.subGoalDescription != null) ...[
              const SizedBox(height: 4),
              Text(
                subGoal.subGoalDescription!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                if (subGoal.subGoalAmount != null) ...[
                  Icon(Icons.attach_money, size: 16, color: Colors.grey[500]),
                  Text(
                    '¥${_formatNumber(subGoal.subGoalAmount!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (subGoal.subGoalCompletionTime != null) ...[
                  Icon(Icons.schedule, size: 16, color: Colors.grey[500]),
                  Text(
                    subGoal.subGoalCompletionTime!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editSubGoal(goal, index);
                break;
              case 'delete':
                _deleteSubGoal(goal, index);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('编辑'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('删除', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTaskCard(Goal goal, SubTask subTask, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Checkbox(
          value: subTask.subTaskStatus,
          onChanged: (value) => _toggleSubTaskStatus(goal, index, value ?? false),
        ),
        title: Text(
          subTask.subTaskName,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            decoration: subTask.subTaskStatus ? TextDecoration.lineThrough : null,
            color: subTask.subTaskStatus ? Colors.grey : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subTask.subTaskDescription != null) ...[
              const SizedBox(height: 4),
              Text(
                subTask.subTaskDescription!,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                if (subTask.subTaskAmount != null) ...[
                  Icon(Icons.attach_money, size: 16, color: Colors.grey[500]),
                  Text(
                    '¥${_formatNumber(subTask.subTaskAmount!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                if (subTask.subTaskCompletionTime != null) ...[
                  Icon(Icons.schedule, size: 16, color: Colors.grey[500]),
                  Text(
                    subTask.subTaskCompletionTime!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editSubTask(goal, index);
                break;
              case 'delete':
                _deleteSubTask(goal, index);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('编辑'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('删除', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case '高':
      case 'high':
        return Colors.red;
      case '中':
      case 'medium':
        return Colors.orange;
      case '低':
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatNumber(double number) {
    if (number >= 10000) {
      return '${(number / 10000).toStringAsFixed(1)}万';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    } else {
      return number.toStringAsFixed(0);
    }
  }

  // 切换子目标状态
  void _toggleSubGoalStatus(Goal goal, int index, bool status) async {
    final updatedSubGoals = List<SubGoal>.from(goal.subGoals);
    updatedSubGoals[index] = updatedSubGoals[index].copyWith(subGoalStatus: status);
    
    final goalService = Provider.of<GoalService>(context, listen: false);
    await goalService.updateSubGoals(context, goal.goalId, updatedSubGoals);
  }

  // 切换子任务状态
  void _toggleSubTaskStatus(Goal goal, int index, bool status) async {
    final updatedSubTasks = List<SubTask>.from(goal.subTasks);
    updatedSubTasks[index] = updatedSubTasks[index].copyWith(subTaskStatus: status);
    
    final goalService = Provider.of<GoalService>(context, listen: false);
    await goalService.updateSubTasks(context, goal.goalId, updatedSubTasks);
  }

  // 添加子目标
  void _addSubGoal(Goal goal) {
    _showSubGoalDialog(goal);
  }

  // 编辑子目标
  void _editSubGoal(Goal goal, int index) {
    _showSubGoalDialog(goal, subGoal: goal.subGoals[index], index: index);
  }

  // 删除子目标
  void _deleteSubGoal(Goal goal, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除子目标'),
        content: Text('确定要删除子目标"${goal.subGoals[index].subGoalName}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final updatedSubGoals = List<SubGoal>.from(goal.subGoals);
              updatedSubGoals.removeAt(index);
              
              final goalService = Provider.of<GoalService>(context, listen: false);
              await goalService.updateSubGoals(context, goal.goalId, updatedSubGoals);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // 添加子任务
  void _addSubTask(Goal goal) {
    _showSubTaskDialog(goal);
  }

  // 编辑子任务
  void _editSubTask(Goal goal, int index) {
    _showSubTaskDialog(goal, subTask: goal.subTasks[index], index: index);
  }

  // 删除子任务
  void _deleteSubTask(Goal goal, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除任务'),
        content: Text('确定要删除任务"${goal.subTasks[index].subTaskName}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final updatedSubTasks = List<SubTask>.from(goal.subTasks);
              updatedSubTasks.removeAt(index);
              
              final goalService = Provider.of<GoalService>(context, listen: false);
              await goalService.updateSubTasks(context, goal.goalId, updatedSubTasks);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  // 显示子目标编辑对话框
  void _showSubGoalDialog(Goal goal, {SubGoal? subGoal, int? index}) {
    final isEditing = subGoal != null;
    
    final nameController = TextEditingController(text: subGoal?.subGoalName ?? '');
    final descriptionController = TextEditingController(text: subGoal?.subGoalDescription ?? '');
    final amountController = TextEditingController(
      text: subGoal?.subGoalAmount != null ? subGoal!.subGoalAmount.toString() : '',
    );
    final completionTimeController = TextEditingController(text: subGoal?.subGoalCompletionTime ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? '编辑子目标' : '添加子目标'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '子目标名称 *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '子目标描述',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: '子目标金额',
                  border: OutlineInputBorder(),
                  prefixText: '¥ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: completionTimeController,
                decoration: const InputDecoration(
                  labelText: '预计完成时间',
                  border: OutlineInputBorder(),
                  hintText: 'YYYY-MM-DD',
                ),
                onTap: () => _selectDate(context, completionTimeController),
                readOnly: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => _saveSubGoal(
              goal,
              isEditing,
              index,
              nameController.text,
              descriptionController.text,
              amountController.text,
              completionTimeController.text,
              subGoal?.subGoalStatus ?? false,
            ),
            child: Text(isEditing ? '保存' : '添加'),
          ),
        ],
      ),
    );
  }

  // 显示子任务编辑对话框
  void _showSubTaskDialog(Goal goal, {SubTask? subTask, int? index}) {
    final isEditing = subTask != null;
    
    final nameController = TextEditingController(text: subTask?.subTaskName ?? '');
    final descriptionController = TextEditingController(text: subTask?.subTaskDescription ?? '');
    final amountController = TextEditingController(
      text: subTask?.subTaskAmount != null ? subTask!.subTaskAmount.toString() : '',
    );
    final completionTimeController = TextEditingController(text: subTask?.subTaskCompletionTime ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? '编辑任务' : '添加任务'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '任务名称 *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '任务描述',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: '任务金额',
                  border: OutlineInputBorder(),
                  prefixText: '¥ ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: completionTimeController,
                decoration: const InputDecoration(
                  labelText: '预计完成时间',
                  border: OutlineInputBorder(),
                  hintText: 'YYYY-MM-DD',
                ),
                onTap: () => _selectDate(context, completionTimeController),
                readOnly: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => _saveSubTask(
              goal,
              isEditing,
              index,
              nameController.text,
              descriptionController.text,
              amountController.text,
              completionTimeController.text,
              subTask?.subTaskStatus ?? false,
            ),
            child: Text(isEditing ? '保存' : '添加'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      controller.text = picked.toString().split(' ')[0]; // YYYY-MM-DD format
    }
  }

  Future<void> _saveSubGoal(
    Goal goal,
    bool isEditing,
    int? index,
    String name,
    String description,
    String amountStr,
    String completionTime,
    bool status,
  ) async {
    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入子目标名称')),
      );
      return;
    }

    final amount = double.tryParse(amountStr);
    
    final newSubGoal = SubGoal(
      subGoalId: isEditing && index != null 
          ? goal.subGoals[index].subGoalId 
          : DateTime.now().millisecondsSinceEpoch.toString(),
      subGoalName: name.trim(),
      subGoalDescription: description.trim().isEmpty ? null : description.trim(),
      subGoalAmount: amount,
      subGoalCompletionTime: completionTime.isEmpty ? null : completionTime,
      subGoalStatus: status,
    );

    final updatedSubGoals = List<SubGoal>.from(goal.subGoals);
    
    if (isEditing && index != null) {
      updatedSubGoals[index] = newSubGoal;
    } else {
      updatedSubGoals.add(newSubGoal);
    }

    Navigator.pop(context);

    final goalService = Provider.of<GoalService>(context, listen: false);
    final success = await goalService.updateSubGoals(context, goal.goalId, updatedSubGoals);
    
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? '子目标更新成功' : '子目标添加成功')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${isEditing ? '更新' : '添加'}失败: ${goalService.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSubTask(
    Goal goal,
    bool isEditing,
    int? index,
    String name,
    String description,
    String amountStr,
    String completionTime,
    bool status,
  ) async {
    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入任务名称')),
      );
      return;
    }

    final amount = double.tryParse(amountStr);
    
    final newSubTask = SubTask(
      subTaskId: isEditing && index != null 
          ? goal.subTasks[index].subTaskId 
          : DateTime.now().millisecondsSinceEpoch.toString(),
      subTaskName: name.trim(),
      subTaskDescription: description.trim().isEmpty ? null : description.trim(),
      subTaskAmount: amount,
      subTaskCompletionTime: completionTime.isEmpty ? null : completionTime,
      subTaskStatus: status,
    );

    final updatedSubTasks = List<SubTask>.from(goal.subTasks);
    
    if (isEditing && index != null) {
      updatedSubTasks[index] = newSubTask;
    } else {
      updatedSubTasks.add(newSubTask);
    }

    Navigator.pop(context);

    final goalService = Provider.of<GoalService>(context, listen: false);
    final success = await goalService.updateSubTasks(context, goal.goalId, updatedSubTasks);
    
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? '任务更新成功' : '任务添加成功')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${isEditing ? '更新' : '添加'}失败: ${goalService.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 