import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

/// 目标建议模型
/// 用于解析AI回答中的目标相关信息
class GoalSuggestion {
  final String goalName;
  final String goalDescription;
  final String priority;
  final String targetAmount;
  final String expectedCompletionTime;

  GoalSuggestion({
    required this.goalName,
    required this.goalDescription,
    required this.priority,
    required this.targetAmount,
    required this.expectedCompletionTime,
  });

  factory GoalSuggestion.fromJson(Map<String, dynamic> json) {
    return GoalSuggestion(
      goalName: json['目标名称'] ?? json['goalName'] ?? '',
      goalDescription: json['目标描述'] ?? json['goalDescription'] ?? '',
      priority: json['优先级'] ?? json['priority'] ?? '',
      targetAmount: json['目标金额'] ?? json['targetAmount'] ?? '',
      expectedCompletionTime: json['预计完成时间'] ?? json['expectedCompletionTime'] ?? '',
    );
  }
}

/// 子目标建议模型
class SubGoalSuggestion {
  final String subGoalName;
  final String subGoalDescription;
  final String subGoalAmount;
  final String expectedCompletionTime;

  SubGoalSuggestion({
    required this.subGoalName,
    required this.subGoalDescription,
    required this.subGoalAmount,
    required this.expectedCompletionTime,
  });

  factory SubGoalSuggestion.fromJson(Map<String, dynamic> json) {
    return SubGoalSuggestion(
      subGoalName: json['子目标名称'] ?? json['subGoalName'] ?? '',
      subGoalDescription: json['子目标描述'] ?? json['subGoalDescription'] ?? '',
      subGoalAmount: json['子目标金额'] ?? json['subGoalAmount'] ?? '',
      expectedCompletionTime: json['预计完成时间'] ?? json['expectedCompletionTime'] ?? '',
    );
  }
}

/// 任务建议模型
class TaskSuggestion {
  final String taskName;
  final String taskDescription;
  final String taskAmount;
  final String expectedCompletionTime;

  TaskSuggestion({
    required this.taskName,
    required this.taskDescription,
    required this.taskAmount,
    required this.expectedCompletionTime,
  });

  factory TaskSuggestion.fromJson(Map<String, dynamic> json) {
    return TaskSuggestion(
      taskName: json['任务名称'] ?? json['taskName'] ?? '',
      taskDescription: json['任务描述'] ?? json['taskDescription'] ?? '',
      taskAmount: json['任务金额'] ?? json['taskAmount'] ?? '',
      expectedCompletionTime: json['预计完成时间'] ?? json['expectedCompletionTime'] ?? '',
    );
  }
}

/// 目标建议集合处理状态
enum GoalSuggestionStatus {
  pending,   // 待处理
  accepted,  // 已接受
  rejected,  // 已拒绝
}

/// 目标建议组合模型
class GoalSuggestionSet {
  final String id; // 唯一标识
  final List<GoalSuggestion> goals;
  final List<SubGoalSuggestion> subGoals;
  final List<TaskSuggestion> tasks;
  final GoalSuggestionStatus status;

  GoalSuggestionSet({
    required this.id,
    required this.goals,
    required this.subGoals,
    required this.tasks,
    this.status = GoalSuggestionStatus.pending,
  });

  factory GoalSuggestionSet.fromJson(Map<String, dynamic> json) {
    return GoalSuggestionSet(
      id: json['id'] ?? '',
      goals: _parseGoals(json['目标'] ?? json['goals'] ?? []),
      subGoals: _parseSubGoals(json['子目标'] ?? json['subGoals'] ?? []),
      tasks: _parseTasks(json['任务'] ?? json['tasks'] ?? []),
      status: GoalSuggestionStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => GoalSuggestionStatus.pending,
      ),
    );
  }

  static List<GoalSuggestion> _parseGoals(dynamic data) {
    if (data is List) {
      return data
          .map((item) => GoalSuggestion.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static List<SubGoalSuggestion> _parseSubGoals(dynamic data) {
    if (data is List) {
      return data
          .map((item) => SubGoalSuggestion.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  static List<TaskSuggestion> _parseTasks(dynamic data) {
    if (data is List) {
      return data
          .map((item) => TaskSuggestion.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// 生成基于内容的唯一ID
  static String _generateUniqueId(List<GoalSuggestion> goals, List<SubGoalSuggestion> subGoals, List<TaskSuggestion> tasks) {
    // 创建内容指纹
    final content = StringBuffer();
    
    // 添加目标内容
    for (final goal in goals) {
      content.write('${goal.goalName}|${goal.goalDescription}|${goal.priority}|${goal.targetAmount}|${goal.expectedCompletionTime}||');
    }
    
    // 添加子目标内容
    for (final subGoal in subGoals) {
      content.write('${subGoal.subGoalName}|${subGoal.subGoalDescription}|${subGoal.subGoalAmount}|${subGoal.expectedCompletionTime}||');
    }
    
    // 添加任务内容
    for (final task in tasks) {
      content.write('${task.taskName}|${task.taskDescription}|${task.taskAmount}|${task.expectedCompletionTime}||');
    }
    
    // 生成MD5哈希
    final bytes = utf8.encode(content.toString());
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  /// 复制并更新状态
  GoalSuggestionSet copyWith({
    String? id,
    List<GoalSuggestion>? goals,
    List<SubGoalSuggestion>? subGoals,
    List<TaskSuggestion>? tasks,
    GoalSuggestionStatus? status,
  }) {
    return GoalSuggestionSet(
      id: id ?? this.id,
      goals: goals ?? this.goals,
      subGoals: subGoals ?? this.subGoals,
      tasks: tasks ?? this.tasks,
      status: status ?? this.status,
    );
  }

  /// 从Markdown JSON内容提取目标建议 - 超简化版本
  static List<GoalSuggestionSet> fromMarkdown(String markdown) {
    debugPrint('===> GoalSuggestionSet.fromMarkdown: 开始解析目标建议 (内容长度: ${markdown.length})');
    debugPrint('原始内容预览: ${markdown.substring(0, min(300, markdown.length))}...');
    
    // 调试：检查是否包含关键字段
    final containsGoal = markdown.contains('"目标名称"');
    final containsSubGoal = markdown.contains('"子目标名称"');
    final containsTask = markdown.contains('"任务名称"');
    debugPrint('===> 内容检查: 包含目标名称=$containsGoal, 包含子目标名称=$containsSubGoal, 包含任务名称=$containsTask');
    
    // 如果不包含任何关键字段，直接返回
    if (!containsGoal && !containsSubGoal && !containsTask) {
      debugPrint('===> 内容中不包含目标相关字段，跳过解析');
      return [];
    }
    
    // 超简化策略：直接提取字段，不依赖JSON格式
    final goals = _extractGoalsDirectly(markdown);
    final subGoals = _extractSubGoalsDirectly(markdown);
    final tasks = _extractTasksDirectly(markdown);
    
    debugPrint('===> 直接提取结果: 目标${goals.length}个, 子目标${subGoals.length}个, 任务${tasks.length}个');
    
    if (goals.isNotEmpty || subGoals.isNotEmpty || tasks.isNotEmpty) {
      // 生成唯一ID
      final id = _generateUniqueId(goals, subGoals, tasks);
      
      return [GoalSuggestionSet(
        id: id,
        goals: goals,
        subGoals: subGoals,
        tasks: tasks,
      )];
    }
    
    return [];
  }

  /// 直接提取目标信息
  static List<GoalSuggestion> _extractGoalsDirectly(String content) {
    final List<GoalSuggestion> goals = [];
    
    // 使用正则表达式查找所有目标名称
    final RegExp goalPattern = RegExp(r'"目标名称"\s*:\s*"([^"]+)"');
    final matches = goalPattern.allMatches(content);
    
    debugPrint('===> 目标提取: 正则匹配到${matches.length}个目标名称');
    
    for (final match in matches) {
      final goalName = match.group(1) ?? '';
      debugPrint('===> 找到目标名称: $goalName');
      
      // 找到这个目标名称后面的相关信息
      final startIndex = match.start;
      final endIndex = _findNextGoalEnd(content, startIndex);
      final goalBlock = content.substring(startIndex, endIndex);
      
      debugPrint('===> 目标数据块长度: ${goalBlock.length}');
      debugPrint('===> 目标数据块内容: ${goalBlock.substring(0, min(200, goalBlock.length))}...');
      
      // 提取各个字段
      final description = _extractField(goalBlock, r'"目标描述"\s*:\s*"([^"]+)"');
      final priority = _extractField(goalBlock, r'"优先级"\s*:\s*"([^"]+)"');
      final targetAmount = _extractField(goalBlock, r'"目标金额"\s*:\s*"([^"]+)"');
      final completionTime = _extractField(goalBlock, r'"预计完成时间"\s*:\s*"([^"]+)"');
      
      debugPrint('===> 提取字段: 描述="$description", 优先级="$priority", 金额="$targetAmount", 时间="$completionTime"');
      
      goals.add(GoalSuggestion(
        goalName: goalName,
        goalDescription: description,
        priority: priority,
        targetAmount: targetAmount,
        expectedCompletionTime: _cleanTime(completionTime),
      ));
      
      debugPrint('提取到目标: $goalName');
    }
    
    return goals;
  }

  /// 直接提取子目标信息
  static List<SubGoalSuggestion> _extractSubGoalsDirectly(String content) {
    final List<SubGoalSuggestion> subGoals = [];
    
    // 使用正则表达式查找所有子目标名称
    final RegExp subGoalPattern = RegExp(r'"子目标名称"\s*:\s*"([^"]+)"');
    final matches = subGoalPattern.allMatches(content);
    
    debugPrint('===> 子目标提取: 正则匹配到${matches.length}个子目标名称');
    
    for (final match in matches) {
      final subGoalName = match.group(1) ?? '';
      debugPrint('===> 找到子目标名称: $subGoalName');
      
      // 找到这个子目标名称后面的相关信息
      final startIndex = match.start;
      final endIndex = _findNextGoalEnd(content, startIndex);
      final subGoalBlock = content.substring(startIndex, endIndex);
      
      // 提取各个字段
      final description = _extractField(subGoalBlock, r'"子目标描述"\s*:\s*"([^"]+)"');
      final amount = _extractField(subGoalBlock, r'"子目标金额"\s*:\s*"([^"]+)"');
      final completionTime = _extractField(subGoalBlock, r'"预计完成时间"\s*:\s*"([^"]+)"');
      
      subGoals.add(SubGoalSuggestion(
        subGoalName: subGoalName,
        subGoalDescription: description,
        subGoalAmount: amount,
        expectedCompletionTime: _cleanTime(completionTime),
      ));
      
      debugPrint('提取到子目标: $subGoalName');
    }
    
    return subGoals;
  }

  /// 直接提取任务信息
  static List<TaskSuggestion> _extractTasksDirectly(String content) {
    final List<TaskSuggestion> tasks = [];
    
    // 使用正则表达式查找所有任务名称
    final RegExp taskPattern = RegExp(r'"任务名称"\s*:\s*"([^"]+)"');
    final matches = taskPattern.allMatches(content);
    
    debugPrint('===> 任务提取: 正则匹配到${matches.length}个任务名称');
    
    for (final match in matches) {
      final taskName = match.group(1) ?? '';
      debugPrint('===> 找到任务名称: $taskName');
      
      // 找到这个任务名称后面的相关信息
      final startIndex = match.start;
      final endIndex = _findNextGoalEnd(content, startIndex);
      final taskBlock = content.substring(startIndex, endIndex);
      
      // 提取各个字段
      final description = _extractField(taskBlock, r'"任务描述"\s*:\s*"([^"]+)"');
      final amount = _extractField(taskBlock, r'"任务金额"\s*:\s*"([^"]+)"');
      final completionTime = _extractField(taskBlock, r'"预计完成时间"\s*:\s*"([^"]+)"');
      
      tasks.add(TaskSuggestion(
        taskName: taskName,
        taskDescription: description,
        taskAmount: amount,
        expectedCompletionTime: _cleanTime(completionTime),
      ));
      
      debugPrint('提取到任务: $taskName');
    }
    
    return tasks;
  }

  /// 提取单个字段的值
  static String _extractField(String text, String pattern) {
    final RegExp regex = RegExp(pattern);
    final match = regex.firstMatch(text);
    return match?.group(1) ?? '';
  }

  /// 找到下一个目标/子目标/任务的结束位置
  static int _findNextGoalEnd(String content, int startIndex) {
    // 简单策略：找到下一个大括号结束或者下一个目标名称开始
    final nextGoalStart = content.indexOf('"目标名称"', startIndex + 1);
    final nextSubGoalStart = content.indexOf('"子目标名称"', startIndex + 1);
    final nextTaskStart = content.indexOf('"任务名称"', startIndex + 1);
    
    int nextStart = content.length;
    if (nextGoalStart != -1) nextStart = min(nextStart, nextGoalStart);
    if (nextSubGoalStart != -1) nextStart = min(nextStart, nextSubGoalStart);
    if (nextTaskStart != -1) nextStart = min(nextStart, nextTaskStart);
    
    // 往前找到最近的}或者使用剩余的内容
    int endPos = min(nextStart, content.length);
    final blockContent = content.substring(startIndex, endPos);
    final lastBrace = blockContent.lastIndexOf('}');
    
    if (lastBrace != -1) {
      return startIndex + lastBrace + 1;
    }
    
    return endPos;
  }

  /// 清理时间字段，过滤无用内容
  static String _cleanTime(String timeStr) {
    if (timeStr.isEmpty) return '';
    
    // 过滤无用的时间描述
    final uselessTimes = ['长期', '待定', '未定', '不确定', '暂无', '无'];
    for (final useless in uselessTimes) {
      if (timeStr.contains(useless)) {
        return '';
      }
    }
    
    return timeStr;
  }
}

/// 日期解析工具类
class DateParser {
  /// 解析各种格式的日期字符串为YYYY-MM-DD格式
  static String parseDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    
    try {
      // 移除可能的额外字符
      String cleanDate = dateStr.trim();
      
      // 处理YYYYMMDD格式
      if (RegExp(r'^\d{8}$').hasMatch(cleanDate)) {
        return '${cleanDate.substring(0, 4)}-${cleanDate.substring(4, 6)}-${cleanDate.substring(6, 8)}';
      }
      
      // 处理YYYY年MM月DD日格式
      final RegExp chineseDateRegex = RegExp(r'^(\d{4})年(\d{1,2})月(\d{1,2})日$');
      final chineseMatch = chineseDateRegex.firstMatch(cleanDate);
      if (chineseMatch != null) {
        final year = chineseMatch.group(1)!;
        final month = chineseMatch.group(2)!.padLeft(2, '0');
        final day = chineseMatch.group(3)!.padLeft(2, '0');
        return '$year-$month-$day';
      }
      
      // 处理YYYY-MM-DD格式（已经是目标格式）
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(cleanDate)) {
        return cleanDate;
      }
      
      // 处理YYYY/MM/DD格式
      if (RegExp(r'^\d{4}/\d{1,2}/\d{1,2}$').hasMatch(cleanDate)) {
        final parts = cleanDate.split('/');
        return '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
      }
      
      // 如果无法解析，返回原始字符串
      return cleanDate;
    } catch (e) {
      debugPrint('日期解析出错: $e');
      return dateStr;
    }
  }
} 