import 'package:flutter/material.dart';
import '../models/goal.dart';

class ScheduleItemCard extends StatelessWidget {
  final Goal goal;
  final Function({
    required String type,
    required String goalId,
    String? subGoalId,
    String? subTaskId,
  }) onUpdateDate;
  final Function(String goalId, String subTaskId, bool status) onUpdateSubTaskStatus;

  const ScheduleItemCard({
    Key? key,
    required this.goal,
    required this.onUpdateDate,
    required this.onUpdateSubTaskStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 目标标题和进度
          _buildGoalHeader(primaryColor),
          
          // 子目标列表
          if (goal.subGoals.isNotEmpty) ...[
            const Divider(height: 1),
            ...goal.subGoals.map((subGoal) => _buildSubGoalItem(subGoal, primaryColor)),
          ],
          
          // 子任务列表
          if (goal.subTasks.isNotEmpty) ...[
            const Divider(height: 1),
            ...goal.subTasks.map((subTask) => _buildSubTaskItem(subTask, primaryColor)),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalHeader(Color primaryColor) {
    final progress = goal.targetAmount != null && goal.targetAmount! > 0
        ? goal.completedAmount / goal.targetAmount!
        : 0.0;
        
    return Dismissible(
      key: Key('goal_${goal.goalId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_calendar, color: Colors.white),
            SizedBox(height: 4),
            Text(
              '修改日期',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        onUpdateDate(
          type: 'goal',
          goalId: goal.goalId,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '目标',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    goal.goalName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (goal.targetAmount != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '¥${goal.completedAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                  Text(
                    ' / ¥${goal.targetAmount!.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubGoalItem(SubGoal subGoal, Color primaryColor) {
    return Dismissible(
      key: Key('subgoal_${subGoal.subGoalId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_calendar, color: Colors.white),
            SizedBox(height: 4),
            Text(
              '修改日期',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        onUpdateDate(
          type: 'sub_goal',
          goalId: goal.goalId,
          subGoalId: subGoal.subGoalId,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '子目标',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                subGoal.subGoalName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (subGoal.subGoalAmount != null)
              Text(
                '¥${subGoal.subGoalAmount!.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTaskItem(SubTask subTask, Color primaryColor) {
    return Dismissible(
      key: Key('subtask_${subTask.subTaskId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_calendar, color: Colors.white),
            SizedBox(height: 4),
            Text(
              '修改日期',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
      onDismissed: (_) {
        onUpdateDate(
          type: 'sub_task',
          goalId: goal.goalId,
          subTaskId: subTask.subTaskId,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '子任务',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                subTask.subTaskName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  decoration: subTask.subTaskStatus 
                      ? TextDecoration.lineThrough 
                      : TextDecoration.none,
                  color: subTask.subTaskStatus 
                      ? Colors.grey 
                      : Colors.black,
                ),
              ),
            ),
            if (subTask.subTaskAmount != null) ...[
              Text(
                '¥${subTask.subTaskAmount!.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: subTask.subTaskStatus ? Colors.grey : Colors.green,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Checkbox(
              value: subTask.subTaskStatus,
              onChanged: (value) {
                if (value != null) {
                  onUpdateSubTaskStatus(goal.goalId, subTask.subTaskId, value);
                }
              },
              activeColor: primaryColor,
            ),
          ],
        ),
      ),
    );
  }
} 