class SubGoal {
  final String subGoalId;
  final String subGoalName;
  final String? subGoalDescription;
  final double? subGoalAmount;
  final String? subGoalCompletionTime;
  final bool subGoalStatus;

  SubGoal({
    required this.subGoalId,
    required this.subGoalName,
    this.subGoalDescription,
    this.subGoalAmount,
    this.subGoalCompletionTime,
    this.subGoalStatus = false,
  });

  factory SubGoal.fromJson(Map<String, dynamic> json) {
    return SubGoal(
      subGoalId: json['sub_goal_id'] ?? '',
      subGoalName: json['sub_goal_name'] ?? '',
      subGoalDescription: json['sub_goal_description'],
      subGoalAmount: json['sub_goal_amount']?.toDouble(),
      subGoalCompletionTime: json['sub_goal_completion_time'],
      subGoalStatus: json['sub_goal_status'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sub_goal_id': subGoalId,
      'sub_goal_name': subGoalName,
      'sub_goal_description': subGoalDescription,
      'sub_goal_amount': subGoalAmount,
      'sub_goal_completion_time': subGoalCompletionTime,
      'sub_goal_status': subGoalStatus,
    };
  }

  SubGoal copyWith({
    String? subGoalId,
    String? subGoalName,
    String? subGoalDescription,
    double? subGoalAmount,
    String? subGoalCompletionTime,
    bool? subGoalStatus,
  }) {
    return SubGoal(
      subGoalId: subGoalId ?? this.subGoalId,
      subGoalName: subGoalName ?? this.subGoalName,
      subGoalDescription: subGoalDescription ?? this.subGoalDescription,
      subGoalAmount: subGoalAmount ?? this.subGoalAmount,
      subGoalCompletionTime: subGoalCompletionTime ?? this.subGoalCompletionTime,
      subGoalStatus: subGoalStatus ?? this.subGoalStatus,
    );
  }
}

class SubTask {
  final String subTaskId;
  final String subTaskName;
  final String? subTaskDescription;
  final bool subTaskStatus;
  final String? subTaskCompletionTime;
  final double? subTaskAmount;

  SubTask({
    required this.subTaskId,
    required this.subTaskName,
    this.subTaskDescription,
    this.subTaskStatus = false,
    this.subTaskCompletionTime,
    this.subTaskAmount,
  });

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      subTaskId: json['sub_task_id'] ?? '',
      subTaskName: json['sub_task_name'] ?? '',
      subTaskDescription: json['sub_task_description'],
      subTaskStatus: json['sub_task_status'] ?? false,
      subTaskCompletionTime: json['sub_task_completion_time'],
      subTaskAmount: json['sub_task_amount']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sub_task_id': subTaskId,
      'sub_task_name': subTaskName,
      'sub_task_description': subTaskDescription,
      'sub_task_status': subTaskStatus,
      'sub_task_completion_time': subTaskCompletionTime,
      'sub_task_amount': subTaskAmount,
    };
  }

  SubTask copyWith({
    String? subTaskId,
    String? subTaskName,
    String? subTaskDescription,
    bool? subTaskStatus,
    String? subTaskCompletionTime,
    double? subTaskAmount,
  }) {
    return SubTask(
      subTaskId: subTaskId ?? this.subTaskId,
      subTaskName: subTaskName ?? this.subTaskName,
      subTaskDescription: subTaskDescription ?? this.subTaskDescription,
      subTaskStatus: subTaskStatus ?? this.subTaskStatus,
      subTaskCompletionTime: subTaskCompletionTime ?? this.subTaskCompletionTime,
      subTaskAmount: subTaskAmount ?? this.subTaskAmount,
    );
  }
}

class Goal {
  final String goalId;
  final String goalName;
  final String? goalDescription;
  final String? priority;
  final String? expectedCompletionTime;
  final double? targetAmount;
  final double completedAmount;
  final List<SubGoal> subGoals;
  final List<SubTask> subTasks;
  final int subTaskNum;
  final int subTaskCompletedNum;

  Goal({
    required this.goalId,
    required this.goalName,
    this.goalDescription,
    this.priority,
    this.expectedCompletionTime,
    this.targetAmount,
    this.completedAmount = 0.0,
    this.subGoals = const [],
    this.subTasks = const [],
    this.subTaskNum = 0,
    this.subTaskCompletedNum = 0,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      goalId: json['goal_id'] ?? '',
      goalName: json['goal_name'] ?? '',
      goalDescription: json['goal_description'],
      priority: json['priority'],
      expectedCompletionTime: json['expected_completion_time'],
      targetAmount: json['target_amount']?.toDouble(),
      completedAmount: json['completed_amount']?.toDouble() ?? 0.0,
      subGoals: (json['sub_goals'] as List<dynamic>?)
          ?.map((e) => SubGoal.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      subTasks: (json['sub_tasks'] as List<dynamic>?)
          ?.map((e) => SubTask.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      subTaskNum: json['sub_task_num'] ?? 0,
      subTaskCompletedNum: json['sub_task_completed_num'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goal_id': goalId,
      'goal_name': goalName,
      'goal_description': goalDescription,
      'priority': priority,
      'expected_completion_time': expectedCompletionTime,
      'target_amount': targetAmount,
      'completed_amount': completedAmount,
      'sub_goals': subGoals.map((e) => e.toJson()).toList(),
      'sub_tasks': subTasks.map((e) => e.toJson()).toList(),
      'sub_task_num': subTaskNum,
      'sub_task_completed_num': subTaskCompletedNum,
    };
  }

  Map<String, dynamic> toBasicJson() {
    return {
      'goal_id': goalId,
      'goal_name': goalName,
      'goal_description': goalDescription,
      'priority': priority,
      'expected_completion_time': expectedCompletionTime,
      'target_amount': targetAmount,
      'completed_amount': completedAmount,
    };
  }

  Goal copyWith({
    String? goalId,
    String? goalName,
    String? goalDescription,
    String? priority,
    String? expectedCompletionTime,
    double? targetAmount,
    double? completedAmount,
    List<SubGoal>? subGoals,
    List<SubTask>? subTasks,
    int? subTaskNum,
    int? subTaskCompletedNum,
  }) {
    return Goal(
      goalId: goalId ?? this.goalId,
      goalName: goalName ?? this.goalName,
      goalDescription: goalDescription ?? this.goalDescription,
      priority: priority ?? this.priority,
      expectedCompletionTime: expectedCompletionTime ?? this.expectedCompletionTime,
      targetAmount: targetAmount ?? this.targetAmount,
      completedAmount: completedAmount ?? this.completedAmount,
      subGoals: subGoals ?? this.subGoals,
      subTasks: subTasks ?? this.subTasks,
      subTaskNum: subTaskNum ?? this.subTaskNum,
      subTaskCompletedNum: subTaskCompletedNum ?? this.subTaskCompletedNum,
    );
  }

  double get progress {
    if (targetAmount == null || targetAmount == 0) return 0.0;
    return (completedAmount / targetAmount!).clamp(0.0, 1.0);
  }
} 