import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/goal_suggestion.dart';
import '../services/settings_service.dart';

/// 目标建议卡片组件
class GoalSuggestionCard extends StatefulWidget {
  final GoalSuggestionSet suggestionSet;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const GoalSuggestionCard({
    Key? key,
    required this.suggestionSet,
    this.onAccept,
    this.onReject,
  }) : super(key: key);

  @override
  State<GoalSuggestionCard> createState() => _GoalSuggestionCardState();
}

class _GoalSuggestionCardState extends State<GoalSuggestionCard> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsService>(
      builder: (context, settingsService, child) {
        final isProcessed = settingsService.isGoalSuggestionProcessed(widget.suggestionSet.id);
        final status = settingsService.getGoalSuggestionStatus(widget.suggestionSet.id);
        
        return Card(
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题和状态
                Row(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '目标建议',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const Spacer(),
                    if (isProcessed) _buildStatusIndicator(status),
                  ],
                ),
                const SizedBox(height: 16),

                // 目标列表
                if (widget.suggestionSet.goals.isNotEmpty) ...[
                  _buildSectionTitle('目标', Icons.track_changes_outlined),
                  const SizedBox(height: 8),
                  ...widget.suggestionSet.goals.map((goal) => _buildGoalItem(goal)),
                  const SizedBox(height: 16),
                ],

                // 子目标列表
                if (widget.suggestionSet.subGoals.isNotEmpty) ...[
                  _buildSectionTitle('子目标', Icons.radio_button_unchecked_outlined),
                  const SizedBox(height: 8),
                  ...widget.suggestionSet.subGoals.map((subGoal) => _buildSubGoalItem(subGoal)),
                  const SizedBox(height: 16),
                ],

                // 任务列表
                if (widget.suggestionSet.tasks.isNotEmpty) ...[
                  _buildSectionTitle('任务', Icons.task_outlined),
                  const SizedBox(height: 8),
                  ...widget.suggestionSet.tasks.map((task) => _buildTaskItem(task)),
                  const SizedBox(height: 16),
                ],

                // 按钮区域 - 仅在未处理时显示
                if (!isProcessed) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isProcessing ? null : _handleReject,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            '拒绝',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : _handleAccept,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('接受'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // 已处理状态显示
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor(status).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          color: _getStatusColor(status),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getStatusText(status),
                          style: TextStyle(
                            color: _getStatusColor(status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(GoalSuggestionStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(status),
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            _getStatusText(status),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(GoalSuggestionStatus status) {
    switch (status) {
      case GoalSuggestionStatus.accepted:
        return Colors.green;
      case GoalSuggestionStatus.rejected:
        return Colors.red;
      case GoalSuggestionStatus.pending:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(GoalSuggestionStatus status) {
    switch (status) {
      case GoalSuggestionStatus.accepted:
        return Icons.check_circle;
      case GoalSuggestionStatus.rejected:
        return Icons.cancel;
      case GoalSuggestionStatus.pending:
        return Icons.pending;
    }
  }

  String _getStatusText(GoalSuggestionStatus status) {
    switch (status) {
      case GoalSuggestionStatus.accepted:
        return '已接受';
      case GoalSuggestionStatus.rejected:
        return '已拒绝';
      case GoalSuggestionStatus.pending:
        return '待处理';
    }
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 16),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalItem(GoalSuggestion goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            goal.goalName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          if (goal.goalDescription.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              goal.goalDescription,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (goal.priority.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(goal.priority),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    goal.priority,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (goal.targetAmount.isNotEmpty) ...[
                Icon(Icons.attach_money, size: 12, color: Colors.grey.shade600),
                Text(
                  goal.targetAmount,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (goal.expectedCompletionTime.isNotEmpty) ...[
                Icon(Icons.schedule, size: 12, color: Colors.grey.shade600),
                Text(
                  _formatDate(goal.expectedCompletionTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubGoalItem(SubGoalSuggestion subGoal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subGoal.subGoalName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          if (subGoal.subGoalDescription.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subGoal.subGoalDescription,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (subGoal.subGoalAmount.isNotEmpty) ...[
                Icon(Icons.attach_money, size: 12, color: Colors.grey.shade600),
                Text(
                  subGoal.subGoalAmount,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (subGoal.expectedCompletionTime.isNotEmpty) ...[
                Icon(Icons.schedule, size: 12, color: Colors.grey.shade600),
                Text(
                  _formatDate(subGoal.expectedCompletionTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(TaskSuggestion task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.taskName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          if (task.taskDescription.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              task.taskDescription,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (task.taskAmount.isNotEmpty) ...[
                Icon(Icons.attach_money, size: 12, color: Colors.grey.shade600),
                Text(
                  task.taskAmount,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (task.expectedCompletionTime.isNotEmpty) ...[
                Icon(Icons.schedule, size: 12, color: Colors.grey.shade600),
                Text(
                  _formatDate(task.expectedCompletionTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case '高':
      case 'high':
        return Colors.red.shade600;
      case '中':
      case 'medium':
        return Colors.orange.shade600;
      case '低':
      case 'low':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final parsedDate = DateParser.parseDate(dateStr);
      return parsedDate;
    } catch (e) {
      return dateStr;
    }
  }

  void _handleAccept() {
    setState(() {
      _isProcessing = true;
    });
    
    // 延迟一点时间以显示加载状态
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        widget.onAccept?.call();
      }
    });
  }

  void _handleReject() {
    widget.onReject?.call();
  }
}

/// 目标建议卡片列表组件
class GoalSuggestionCardList extends StatelessWidget {
  final List<GoalSuggestionSet> suggestionSets;
  final Function(GoalSuggestionSet)? onAccept;
  final Function(GoalSuggestionSet)? onReject;

  const GoalSuggestionCardList({
    Key? key,
    required this.suggestionSets,
    this.onAccept,
    this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: suggestionSets.map((suggestionSet) {
        return GoalSuggestionCard(
          suggestionSet: suggestionSet,
          onAccept: () => onAccept?.call(suggestionSet),
          onReject: () => onReject?.call(suggestionSet),
        );
      }).toList(),
    );
  }
} 