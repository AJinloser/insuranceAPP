import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/goal_suggestion.dart';
import '../models/goal.dart';
import 'goal_service.dart';

/// 目标建议处理服务
class GoalSuggestionService {
  static const Uuid _uuid = Uuid();

  /// 处理目标建议的接受
  /// 将目标建议转换为实际的目标数据并调用API创建
  static Future<bool> acceptGoalSuggestion(
    BuildContext context,
    GoalSuggestionSet suggestionSet,
  ) async {
    try {
      debugPrint('===> GoalSuggestionService: 开始处理目标建议接受');
      
      final goalService = Provider.of<GoalService>(context, listen: false);
      
      // 获取当前目标列表
      final currentGoals = List<Goal>.from(goalService.goals);
      
      // 存储新创建的目标，用于后续添加子目标和子任务
      List<Goal> newGoals = [];
      
      // 处理目标建议
      for (final goalSuggestion in suggestionSet.goals) {
        final newGoal = _convertGoalSuggestionToGoal(goalSuggestion, suggestionSet);
        currentGoals.add(newGoal);
        newGoals.add(newGoal);
      }
      
      // 如果没有目标但有子目标或任务，创建一个默认目标
      if (suggestionSet.goals.isEmpty && (suggestionSet.subGoals.isNotEmpty || suggestionSet.tasks.isNotEmpty)) {
        final defaultGoal = _createDefaultGoal(suggestionSet);
        currentGoals.add(defaultGoal);
        newGoals.add(defaultGoal);
      }
      
      // 第一步：更新目标基本信息
      debugPrint('===> GoalSuggestionService: 步骤1 - 创建目标基本信息');
      final success = await goalService.updateGoalBasicInfo(context, currentGoals);
      
      if (!success) {
        debugPrint('===> GoalSuggestionService: 目标基本信息创建失败: ${goalService.error}');
        return false;
      }
      
      // 第二步：为每个新创建的目标添加子目标和子任务
      for (final newGoal in newGoals) {
        debugPrint('===> GoalSuggestionService: 步骤2 - 为目标 ${newGoal.goalId} 添加子目标和子任务');
        
        // 添加子目标
        if (newGoal.subGoals.isNotEmpty) {
          debugPrint('===> GoalSuggestionService: 添加 ${newGoal.subGoals.length} 个子目标');
          final subGoalSuccess = await goalService.updateSubGoals(context, newGoal.goalId, newGoal.subGoals);
          if (!subGoalSuccess) {
            debugPrint('===> GoalSuggestionService: 子目标创建失败: ${goalService.error}');
            // 继续处理，不要因为子目标失败而中断整个过程
          }
        }
        
        // 添加子任务
        if (newGoal.subTasks.isNotEmpty) {
          debugPrint('===> GoalSuggestionService: 添加 ${newGoal.subTasks.length} 个子任务');
          final subTaskSuccess = await goalService.updateSubTasks(context, newGoal.goalId, newGoal.subTasks);
          if (!subTaskSuccess) {
            debugPrint('===> GoalSuggestionService: 子任务创建失败: ${goalService.error}');
            // 继续处理，不要因为子任务失败而中断整个过程
          }
        }
      }
      
      // 第三步：重新获取目标列表以确保数据同步
      debugPrint('===> GoalSuggestionService: 步骤3 - 重新获取目标列表');
      await goalService.getGoalBasicInfo(context);
      
      debugPrint('===> GoalSuggestionService: 目标建议接受成功');
      return true;
      
    } catch (e) {
      debugPrint('===> GoalSuggestionService: 处理目标建议时发生错误: $e');
      return false;
    }
  }

  /// 处理目标建议的拒绝
  static void rejectGoalSuggestion(GoalSuggestionSet suggestionSet) {
    debugPrint('===> GoalSuggestionService: 用户拒绝了目标建议');
    // 目前只记录日志，后续可以添加用户反馈收集等功能
  }

  /// 将目标建议转换为Goal对象
  static Goal _convertGoalSuggestionToGoal(
    GoalSuggestion goalSuggestion,
    GoalSuggestionSet suggestionSet,
  ) {
    final goalId = _uuid.v4();
    
    // 转换子目标
    final subGoals = suggestionSet.subGoals.map((subGoalSuggestion) {
      return SubGoal(
        subGoalId: _uuid.v4(),
        subGoalName: subGoalSuggestion.subGoalName,
        subGoalDescription: subGoalSuggestion.subGoalDescription.isNotEmpty 
            ? subGoalSuggestion.subGoalDescription 
            : null,
        subGoalAmount: _parseAmount(subGoalSuggestion.subGoalAmount),
        subGoalCompletionTime: _parseDate(subGoalSuggestion.expectedCompletionTime),
        subGoalStatus: false,
      );
    }).toList();
    
    // 转换任务
    final subTasks = suggestionSet.tasks.map((taskSuggestion) {
      return SubTask(
        subTaskId: _uuid.v4(),
        subTaskName: taskSuggestion.taskName,
        subTaskDescription: taskSuggestion.taskDescription.isNotEmpty 
            ? taskSuggestion.taskDescription 
            : null,
        subTaskStatus: false,
        subTaskCompletionTime: _parseDate(taskSuggestion.expectedCompletionTime),
        subTaskAmount: _parseAmount(taskSuggestion.taskAmount),
      );
    }).toList();
    
    return Goal(
      goalId: goalId,
      goalName: goalSuggestion.goalName,
      goalDescription: goalSuggestion.goalDescription.isNotEmpty 
          ? goalSuggestion.goalDescription 
          : null,
      priority: goalSuggestion.priority.isNotEmpty 
          ? goalSuggestion.priority 
          : null,
      expectedCompletionTime: _parseDate(goalSuggestion.expectedCompletionTime),
      targetAmount: _parseAmount(goalSuggestion.targetAmount),
      completedAmount: 0.0,
      subGoals: subGoals,
      subTasks: subTasks,
      subTaskNum: subTasks.length,
      subTaskCompletedNum: 0,
    );
  }

  /// 创建默认目标（当只有子目标或任务时）
  static Goal _createDefaultGoal(GoalSuggestionSet suggestionSet) {
    final goalId = _uuid.v4();
    
    // 转换子目标
    final subGoals = suggestionSet.subGoals.map((subGoalSuggestion) {
      return SubGoal(
        subGoalId: _uuid.v4(),
        subGoalName: subGoalSuggestion.subGoalName,
        subGoalDescription: subGoalSuggestion.subGoalDescription.isNotEmpty 
            ? subGoalSuggestion.subGoalDescription 
            : null,
        subGoalAmount: _parseAmount(subGoalSuggestion.subGoalAmount),
        subGoalCompletionTime: _parseDate(subGoalSuggestion.expectedCompletionTime),
        subGoalStatus: false,
      );
    }).toList();
    
    // 转换任务
    final subTasks = suggestionSet.tasks.map((taskSuggestion) {
      return SubTask(
        subTaskId: _uuid.v4(),
        subTaskName: taskSuggestion.taskName,
        subTaskDescription: taskSuggestion.taskDescription.isNotEmpty 
            ? taskSuggestion.taskDescription 
            : null,
        subTaskStatus: false,
        subTaskCompletionTime: _parseDate(taskSuggestion.expectedCompletionTime),
        subTaskAmount: _parseAmount(taskSuggestion.taskAmount),
      );
    }).toList();
    
    // 计算总目标金额
    double totalAmount = 0.0;
    for (final subGoal in subGoals) {
      totalAmount += subGoal.subGoalAmount ?? 0.0;
    }
    for (final subTask in subTasks) {
      totalAmount += subTask.subTaskAmount ?? 0.0;
    }
    
    return Goal(
      goalId: goalId,
      goalName: '财务规划目标',
      goalDescription: '根据AI建议生成的财务规划目标',
      priority: '中',
      expectedCompletionTime: _findEarliestDate(suggestionSet),
      targetAmount: totalAmount > 0 ? totalAmount : null,
      completedAmount: 0.0,
      subGoals: subGoals,
      subTasks: subTasks,
      subTaskNum: subTasks.length,
      subTaskCompletedNum: 0,
    );
  }

  /// 解析金额字符串
  static double? _parseAmount(String amountStr) {
    if (amountStr.isEmpty) return null;
    
    try {
      // 移除常见的货币符号和单位
      String cleanAmount = amountStr
          .replaceAll(RegExp(r'[¥$€£,，]'), '')
          .replaceAll('元', '')
          .replaceAll('万', '0000')
          .replaceAll('千', '000')
          .replaceAll('百', '00')
          .trim();
      
      if (cleanAmount.isEmpty || cleanAmount == '0') return 0.0;
      
      // 尝试解析数字
      final amount = double.tryParse(cleanAmount);
      return amount;
    } catch (e) {
      debugPrint('解析金额失败: $amountStr, 错误: $e');
      return null;
    }
  }

  /// 解析日期字符串
  static String? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    
    try {
      return DateParser.parseDate(dateStr);
    } catch (e) {
      debugPrint('解析日期失败: $dateStr, 错误: $e');
      return null;
    }
  }

  /// 找到最早的日期作为目标完成时间
  static String? _findEarliestDate(GoalSuggestionSet suggestionSet) {
    DateTime? earliestDate;
    
    // 检查子目标的日期
    for (final subGoal in suggestionSet.subGoals) {
      if (subGoal.expectedCompletionTime.isNotEmpty) {
        try {
          final parsedDate = DateParser.parseDate(subGoal.expectedCompletionTime);
          final date = DateTime.parse(parsedDate);
          if (earliestDate == null || date.isBefore(earliestDate)) {
            earliestDate = date;
          }
        } catch (e) {
          debugPrint('解析子目标日期失败: ${subGoal.expectedCompletionTime}');
        }
      }
    }
    
    // 检查任务的日期
    for (final task in suggestionSet.tasks) {
      if (task.expectedCompletionTime.isNotEmpty) {
        try {
          final parsedDate = DateParser.parseDate(task.expectedCompletionTime);
          final date = DateTime.parse(parsedDate);
          if (earliestDate == null || date.isBefore(earliestDate)) {
            earliestDate = date;
          }
        } catch (e) {
          debugPrint('解析任务日期失败: ${task.expectedCompletionTime}');
        }
      }
    }
    
    if (earliestDate != null) {
      return '${earliestDate.year.toString().padLeft(4, '0')}-${earliestDate.month.toString().padLeft(2, '0')}-${earliestDate.day.toString().padLeft(2, '0')}';
    }
    
    return null;
  }
} 