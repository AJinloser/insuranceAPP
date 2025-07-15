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

  /// 从Markdown JSON内容提取目标建议 - 支持分散JSON片段
  static List<GoalSuggestionSet> fromMarkdown(String markdown) {
    debugPrint('===> GoalSuggestionSet.fromMarkdown: 开始解析目标建议 (内容长度: ${markdown.length})');
    debugPrint('原始内容预览: ${markdown.substring(0, min(300, markdown.length))}...');
    
    // 首先尝试解析完整的answer格式
    String completeJson = _findCompleteAnswerJson(markdown);
    if (completeJson.isNotEmpty) {
      debugPrint('找到完整的answer格式JSON，长度: ${completeJson.length}');
      return _parseCompleteJson(completeJson);
    }
    
    debugPrint('未找到完整的answer格式，尝试收集分散的JSON片段');
    // 如果没有完整格式，尝试收集分散的JSON片段
    return _collectAndParseFragments(markdown);
  }

  /// 查找完整的answer格式JSON
  static String _findCompleteAnswerJson(String content) {
    debugPrint('开始查找完整的answer格式JSON');
    
    int startPos = content.indexOf('{"answer":');
    if (startPos == -1) {
      debugPrint('未找到{"answer":开头');
      return '';
    }
    
    debugPrint('找到answer开始位置: $startPos');
    
    int braceCount = 0;
    int endPos = startPos;
    
    for (int i = startPos; i < content.length; i++) {
      if (content[i] == '{') {
        braceCount++;
      } else if (content[i] == '}') {
        braceCount--;
        if (braceCount == 0) {
          endPos = i + 1;
          break;
        }
      }
    }
    
    debugPrint('括号匹配结束位置: $endPos, 括号计数: $braceCount');
    
    if (braceCount == 0 && endPos > startPos) {
      String extractedJson = content.substring(startPos, endPos);
      debugPrint('提取原始JSON长度: ${extractedJson.length}');
      debugPrint('提取的原始JSON: ${extractedJson.substring(0, min(400, extractedJson.length))}...');
      
      String fixedJson = _fixJsonFormat(extractedJson);
      debugPrint('修复后JSON长度: ${fixedJson.length}');
      
      return fixedJson;
    }
    
    debugPrint('括号匹配失败或无效范围');
    return '';
  }

  /// 解析完整的JSON
  static List<GoalSuggestionSet> _parseCompleteJson(String jsonStr) {
    debugPrint('开始解析完整JSON');
    
    try {
      final dynamic parsed = json.decode(jsonStr);
      debugPrint('JSON解码成功');
      
      if (parsed is Map<String, dynamic>) {
        debugPrint('JSON是Map类型');
        
        Map<String, dynamic> dataMap = parsed.containsKey('answer') && parsed['answer'] is Map
            ? parsed['answer']
            : parsed;
        
        debugPrint('数据映射键: ${dataMap.keys.toList()}');
        
        // 检查每个字段的内容
        if (dataMap.containsKey('目标')) {
          debugPrint('找到目标字段，类型: ${dataMap['目标'].runtimeType}');
          if (dataMap['目标'] is List) {
            debugPrint('目标字段是List，长度: ${(dataMap['目标'] as List).length}');
          } else {
            debugPrint('目标字段内容: ${dataMap['目标']}');
          }
        } else {
          debugPrint('未找到目标字段');
        }
        
        if (dataMap.containsKey('子目标')) {
          debugPrint('找到子目标字段，类型: ${dataMap['子目标'].runtimeType}');
          if (dataMap['子目标'] is List) {
            debugPrint('子目标字段是List，长度: ${(dataMap['子目标'] as List).length}');
          }
        } else {
          debugPrint('未找到子目标字段');
        }
        
        if (dataMap.containsKey('任务')) {
          debugPrint('找到任务字段，类型: ${dataMap['任务'].runtimeType}');
          if (dataMap['任务'] is List) {
            debugPrint('任务字段是List，长度: ${(dataMap['任务'] as List).length}');
          }
        } else {
          debugPrint('未找到任务字段');
        }
        
        final goals = _extractGoals(dataMap);
        final subGoals = _extractSubGoals(dataMap);
        final tasks = _extractTasks(dataMap);
        
        debugPrint('===> 完整JSON解析成功: 目标${goals.length}个, 子目标${subGoals.length}个, 任务${tasks.length}个');
        
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
      } else {
        debugPrint('JSON不是Map类型，而是: ${parsed.runtimeType}');
      }
    } catch (e) {
      debugPrint('===> 完整JSON解析失败: $e');
      debugPrint('失败的JSON内容: ${jsonStr.substring(0, min(500, jsonStr.length))}...');
    }
    
    return [];
  }

  /// 收集并解析分散的JSON片段
  static List<GoalSuggestionSet> _collectAndParseFragments(String markdown) {
    debugPrint('开始收集分散的JSON片段');
    
    List<GoalSuggestion> allGoals = [];
    List<SubGoalSuggestion> allSubGoals = [];
    List<TaskSuggestion> allTasks = [];
    
    // 查找所有JSON代码块
    final RegExp jsonBlockRegex = RegExp(r'```json\s*([\s\S]*?)\s*```');
    final matches = jsonBlockRegex.allMatches(markdown);
    
    for (final match in matches) {
      try {
        final String jsonContent = match.group(1)!;
        
        final dynamic parsed = json.decode(jsonContent);
        
        if (parsed is Map<String, dynamic>) {
          // 检查是否是单个目标对象
          if (_isGoalObject(parsed)) {
            allGoals.add(GoalSuggestion(
              goalName: parsed['目标名称'] ?? parsed['goalName'] ?? '未命名目标',
              goalDescription: parsed['目标描述'] ?? parsed['goalDescription'] ?? '',
              priority: parsed['优先级'] ?? parsed['priority'] ?? '',
              targetAmount: parsed['目标金额'] ?? parsed['targetAmount'] ?? '',
              expectedCompletionTime: _cleanTime(parsed['预计完成时间'] ?? parsed['expectedCompletionTime'] ?? ''),
            ));
          }
          // 检查是否是单个子目标对象
          else if (_isSubGoalObject(parsed)) {
            allSubGoals.add(SubGoalSuggestion(
              subGoalName: parsed['子目标名称'] ?? parsed['subGoalName'] ?? '未命名子目标',
              subGoalDescription: parsed['子目标描述'] ?? parsed['subGoalDescription'] ?? '',
              subGoalAmount: parsed['子目标金额'] ?? parsed['subGoalAmount'] ?? '',
              expectedCompletionTime: _cleanTime(parsed['预计完成时间'] ?? parsed['expectedCompletionTime'] ?? ''),
            ));
          }
          // 检查是否是单个任务对象
          else if (_isTaskObject(parsed)) {
            allTasks.add(TaskSuggestion(
              taskName: parsed['任务名称'] ?? parsed['taskName'] ?? '未命名任务',
              taskDescription: parsed['任务描述'] ?? parsed['taskDescription'] ?? '',
              taskAmount: parsed['任务金额'] ?? parsed['taskAmount'] ?? '',
              expectedCompletionTime: _cleanTime(parsed['预计完成时间'] ?? parsed['expectedCompletionTime'] ?? ''),
            ));
          }
        }
        else if (parsed is List && parsed.isNotEmpty) {
          // 检查是否是子目标数组
          if (parsed[0] is Map<String, dynamic> && _isSubGoalObject(parsed[0])) {
            for (final item in parsed) {
              if (item is Map<String, dynamic>) {
                allSubGoals.add(SubGoalSuggestion(
                  subGoalName: item['子目标名称'] ?? item['subGoalName'] ?? '未命名子目标',
                  subGoalDescription: item['子目标描述'] ?? item['subGoalDescription'] ?? '',
                  subGoalAmount: item['子目标金额'] ?? item['subGoalAmount'] ?? '',
                  expectedCompletionTime: _cleanTime(item['预计完成时间'] ?? item['expectedCompletionTime'] ?? ''),
                ));
              }
            }
          }
          // 检查是否是任务数组
          else if (parsed[0] is Map<String, dynamic> && _isTaskObject(parsed[0])) {
            for (final item in parsed) {
              if (item is Map<String, dynamic>) {
                allTasks.add(TaskSuggestion(
                  taskName: item['任务名称'] ?? item['taskName'] ?? '未命名任务',
                  taskDescription: item['任务描述'] ?? item['taskDescription'] ?? '',
                  taskAmount: item['任务金额'] ?? item['taskAmount'] ?? '',
                  expectedCompletionTime: _cleanTime(item['预计完成时间'] ?? item['expectedCompletionTime'] ?? ''),
                ));
              }
            }
          }
        }
      } catch (e) {
        // 减少错误日志输出
      }
    }
    
    debugPrint('===> 片段收集完成: 目标${allGoals.length}个, 子目标${allSubGoals.length}个, 任务${allTasks.length}个');
    
    // 如果找到了任何内容，创建建议集合
    if (allGoals.isNotEmpty || allSubGoals.isNotEmpty || allTasks.isNotEmpty) {
      // 生成唯一ID
      final id = _generateUniqueId(allGoals, allSubGoals, allTasks);
      
      return [GoalSuggestionSet(
        id: id,
        goals: allGoals,
        subGoals: allSubGoals,
        tasks: allTasks,
      )];
    }
    
    return [];
  }

  /// 检查是否是目标对象
  static bool _isGoalObject(Map<String, dynamic> data) {
    return data.containsKey('目标名称') || data.containsKey('goalName');
  }

  /// 检查是否是子目标对象
  static bool _isSubGoalObject(Map<String, dynamic> data) {
    return data.containsKey('子目标名称') || data.containsKey('subGoalName');
  }

  /// 检查是否是任务对象
  static bool _isTaskObject(Map<String, dynamic> data) {
    return data.containsKey('任务名称') || data.containsKey('taskName');
  }

  /// 修复JSON格式 - 强化版本
  static String _fixJsonFormat(String jsonStr) {
    debugPrint('开始修复JSON格式');
    String fixed = jsonStr;
    
    debugPrint('修复前: ${fixed.substring(0, min(200, fixed.length))}...');
    
    // 核心修复：处理 "目标 [" 格式错误
    int fixCount = 0;
    String oldFixed = fixed;
    
    // 修复各种可能的格式错误
    fixed = fixed.replaceAll(RegExp(r'"目标\s*\['), '"目标": [');
    if (fixed != oldFixed) {
      fixCount++;
      debugPrint('修复了目标字段格式错误');
    }
    
    oldFixed = fixed;
    fixed = fixed.replaceAll(RegExp(r'"子目标\s*\['), '"子目标": [');
    if (fixed != oldFixed) {
      fixCount++;
      debugPrint('修复了子目标字段格式错误');
    }
    
    oldFixed = fixed;
    fixed = fixed.replaceAll(RegExp(r'"任务\s*\['), '"任务": [');
    if (fixed != oldFixed) {
      fixCount++;
      debugPrint('修复了任务字段格式错误');
    }
    
    // 处理更复杂的格式错误
    oldFixed = fixed;
    fixed = fixed.replaceAll(RegExp(r'"(目标|子目标|任务)\s+(\[)'), '"\\1": \\2');
    if (fixed != oldFixed) {
      fixCount++;
      debugPrint('修复了复杂的字段格式错误');
    }
    
    // 处理字段后面直接跟着对象的情况
    oldFixed = fixed;
    fixed = fixed.replaceAll(RegExp(r'"(目标|子目标|任务)"\s*\{'), '"\\1": {');
    if (fixed != oldFixed) {
      fixCount++;
      debugPrint('修复了字段后直接跟对象的格式错误');
    }
    
    // 处理缺少冒号的情况
    oldFixed = fixed;
    fixed = fixed.replaceAll(RegExp(r'"(目标|子目标|任务)"\s*([^\s:])'), '"\\1": \\2');
    if (fixed != oldFixed) {
      fixCount++;
      debugPrint('修复了缺少冒号的格式错误');
    }
    
    // 修复多余的空格和换行
    fixed = fixed.replaceAll(RegExp(r'\s*}\s*]'), '}]');
    fixed = fixed.replaceAll(RegExp(r'\s*,\s*]'), ']');
    fixed = fixed.replaceAll(RegExp(r'\s*,\s*}'), '}');
    fixed = fixed.replaceAll(RegExp(r'\[\s*\]'), '[]');
    fixed = fixed.replaceAll(RegExp(r'\{\s*\}'), '{}');
    
    // 确保JSON的基本结构正确
    if (!fixed.startsWith('{')) {
      fixed = '{' + fixed;
      fixCount++;
      debugPrint('添加了开头的大括号');
    }
    
    if (!fixed.endsWith('}')) {
      fixed = fixed + '}';
      fixCount++;
      debugPrint('添加了结尾的大括号');
    }
    
    debugPrint('总共进行了${fixCount}个修复');
    debugPrint('修复后: ${fixed.substring(0, min(300, fixed.length))}...');
    
    return fixed;
  }

  /// 提取目标列表
  static List<GoalSuggestion> _extractGoals(Map<String, dynamic> dataMap) {
    final goalsData = dataMap['目标'] ?? dataMap['goals'];
    if (goalsData is! List) return [];
    
    return goalsData
        .where((item) => item is Map<String, dynamic>)
        .map((item) => GoalSuggestion(
          goalName: item['目标名称'] ?? item['goalName'] ?? '未命名目标',
          goalDescription: item['目标描述'] ?? item['goalDescription'] ?? '',
          priority: item['优先级'] ?? item['priority'] ?? '',
          targetAmount: item['目标金额'] ?? item['targetAmount'] ?? '',
          expectedCompletionTime: _cleanTime(item['预计完成时间'] ?? item['expectedCompletionTime'] ?? ''),
        ))
        .toList();
  }

  /// 提取子目标列表
  static List<SubGoalSuggestion> _extractSubGoals(Map<String, dynamic> dataMap) {
    final subGoalsData = dataMap['子目标'] ?? dataMap['subGoals'];
    if (subGoalsData is! List) return [];
    
    return subGoalsData
        .where((item) => item is Map<String, dynamic>)
        .map((item) => SubGoalSuggestion(
          subGoalName: item['子目标名称'] ?? item['subGoalName'] ?? '未命名子目标',
          subGoalDescription: item['子目标描述'] ?? item['subGoalDescription'] ?? '',
          subGoalAmount: item['子目标金额'] ?? item['subGoalAmount'] ?? '',
          expectedCompletionTime: _cleanTime(item['预计完成时间'] ?? item['expectedCompletionTime'] ?? ''),
        ))
        .toList();
  }

  /// 提取任务列表
  static List<TaskSuggestion> _extractTasks(Map<String, dynamic> dataMap) {
    final tasksData = dataMap['任务'] ?? dataMap['tasks'];
    if (tasksData is! List) return [];
    
    return tasksData
        .where((item) => item is Map<String, dynamic>)
        .map((item) => TaskSuggestion(
          taskName: item['任务名称'] ?? item['taskName'] ?? '未命名任务',
          taskDescription: item['任务描述'] ?? item['taskDescription'] ?? '',
          taskAmount: item['任务金额'] ?? item['taskAmount'] ?? '',
          expectedCompletionTime: _cleanTime(item['预计完成时间'] ?? item['expectedCompletionTime'] ?? ''),
        ))
        .toList();
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