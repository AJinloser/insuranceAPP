import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/goal_service.dart';
import '../models/goal.dart';
import 'goal_detail_page.dart';
import '../widgets/goal_card.dart';
import '../widgets/coming_soon_page.dart';

class PlanningPage extends StatefulWidget {
  const PlanningPage({Key? key}) : super(key: key);

  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    
    // 初始化时加载目标数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentTabIndex == 0) {
        _loadGoals();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    final goalService = Provider.of<GoalService>(context, listen: false);
    await goalService.getGoalBasicInfo(context);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('财务规划'),
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
            Tab(text: '目标'),
            Tab(text: '日程'),
            Tab(text: '规划'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGoalsTab(),
          const ComingSoonPage(title: '日程管理'),
          const ComingSoonPage(title: '财务规划'),
        ],
      ),
    );
  }

  Widget _buildGoalsTab() {
    return Consumer<GoalService>(
      builder: (context, goalService, child) {
        if (goalService.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (goalService.error != null) {
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
                  goalService.error!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadGoals,
                  child: const Text('重试'),
                ),
              ],
            ),
          );
        }

        if (goalService.goals.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: _loadGoals,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goalService.goals.length + 1, // +1 for add button
            itemBuilder: (context, index) {
              if (index == goalService.goals.length) {
                return _buildAddGoalCard();
              }
              
              final goal = goalService.goals[index];
              return GoalCard(
                goal: goal,
                onTap: () => _navigateToGoalDetail(goal),
                onEdit: () => _editGoal(goal),
                onDelete: () => _deleteGoal(goal),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.flag_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '还没有设定目标',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '设定你的第一个目标，开始规划你的财务未来',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _addNewGoal,
            icon: const Icon(Icons.add),
            label: const Text('添加目标'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddGoalCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: _addNewGoal,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '添加新目标',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '设定一个新的财务目标',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToGoalDetail(Goal goal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GoalDetailPage(goalId: goal.goalId),
      ),
    ).then((_) {
      // 返回时刷新数据，确保统计信息正确更新
      _loadGoals();
    });
  }

  void _addNewGoal() {
    _showGoalEditDialog();
  }

  void _editGoal(Goal goal) {
    _showGoalEditDialog(goal: goal);
  }

  void _deleteGoal(Goal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除目标'),
        content: Text('确定要删除目标"${goal.goalName}"吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDeleteGoal(goal);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteGoal(Goal goal) async {
    final goalService = Provider.of<GoalService>(context, listen: false);
    final updatedGoals = goalService.goals.where((g) => g.goalId != goal.goalId).toList();
    
    final success = await goalService.updateGoalBasicInfo(context, updatedGoals);
    
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('目标删除成功')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: ${goalService.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showGoalEditDialog({Goal? goal}) {
    final isEditing = goal != null;
    
    final nameController = TextEditingController(text: goal?.goalName ?? '');
    final descriptionController = TextEditingController(text: goal?.goalDescription ?? '');
    final priorityController = TextEditingController(text: goal?.priority ?? '');
    final targetAmountController = TextEditingController(
      text: goal?.targetAmount != null ? goal!.targetAmount.toString() : '',
    );
    final completionTimeController = TextEditingController(text: goal?.expectedCompletionTime ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? '编辑目标' : '添加目标'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '目标名称 *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '目标描述',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priorityController,
                decoration: const InputDecoration(
                  labelText: '优先级',
                  border: OutlineInputBorder(),
                  hintText: '例如：高、中、低',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: targetAmountController,
                decoration: const InputDecoration(
                  labelText: '目标金额',
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
            onPressed: () => _saveGoal(
              context,
              isEditing,
              goal,
              nameController.text,
              descriptionController.text,
              priorityController.text,
              targetAmountController.text,
              completionTimeController.text,
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

  Future<void> _saveGoal(
    BuildContext context,
    bool isEditing,
    Goal? originalGoal,
    String name,
    String description,
    String priority,
    String targetAmountStr,
    String completionTime,
  ) async {
    if (name.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入目标名称')),
      );
      return;
    }

    final targetAmount = double.tryParse(targetAmountStr);

    final goalService = Provider.of<GoalService>(context, listen: false);
    final currentGoals = List<Goal>.from(goalService.goals);

    final newGoal = Goal(
      goalId: originalGoal?.goalId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      goalName: name.trim(),
      goalDescription: description.trim().isEmpty ? null : description.trim(),
      priority: priority.trim().isEmpty ? null : priority.trim(),
      expectedCompletionTime: completionTime.isEmpty ? null : completionTime,
      targetAmount: targetAmount,
      completedAmount: originalGoal?.completedAmount ?? 0.0,
    );

    if (isEditing) {
      final index = currentGoals.indexWhere((g) => g.goalId == originalGoal!.goalId);
      if (index != -1) {
        currentGoals[index] = newGoal;
      }
    } else {
      currentGoals.add(newGoal);
    }

    Navigator.pop(context);

    final success = await goalService.updateGoalBasicInfo(context, currentGoals);
    
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? '目标更新成功' : '目标添加成功')),
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