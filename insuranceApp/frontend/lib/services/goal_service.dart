import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../models/goal.dart';
import 'auth_service.dart';

class GoalService extends ChangeNotifier {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  // 静态获取后端URL的方法
  static String get backendUrl {
    final url = dotenv.env['BACKEND_URL'] ?? baseUrl;
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  List<Goal> _goals = [];
  Goal? _currentGoal;
  bool _isLoading = false;
  String? _error;

  List<Goal> get goals => _goals;
  Goal? get currentGoal => _currentGoal;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // 获取目标基本信息
  Future<bool> getGoalBasicInfo(BuildContext context) async {
    try {
      setLoading(true);
      clearError();

      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.userId;

      if (userId == null) {
        setError('用户未登录');
        return false;
      }

      final url = Uri.parse('${backendUrl}/api/v1/goals/get_basic_info');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      debugPrint('获取目标基本信息响应: ${response.statusCode}');
      debugPrint('响应内容: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['code'] == 200) {
          _goals = (data['goals'] as List<dynamic>)
              .map((goalJson) => Goal.fromJson(goalJson as Map<String, dynamic>))
              .toList();
          setLoading(false);
          notifyListeners();
          return true;
        } else {
          setError(data['message'] ?? '获取目标信息失败');
          return false;
        }
      } else {
        setError('网络请求失败: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('获取目标基本信息失败: $e');
      setError('获取目标信息失败: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // 更新目标基本信息
  Future<bool> updateGoalBasicInfo(BuildContext context, List<Goal> goals) async {
    try {
      setLoading(true);
      clearError();

      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.userId;

      if (userId == null) {
        setError('用户未登录');
        return false;
      }

      final url = Uri.parse('${backendUrl}/api/v1/goals/update_basic_info');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'goals': goals.map((goal) => goal.toBasicJson()).toList(),
        }),
      );

      debugPrint('更新目标基本信息响应: ${response.statusCode}');
      debugPrint('响应内容: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['code'] == 200) {
          _goals = List.from(goals);
          setLoading(false);
          notifyListeners();
          return true;
        } else {
          setError(data['message'] ?? '更新目标信息失败');
          return false;
        }
      } else {
        setError('网络请求失败: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('更新目标基本信息失败: $e');
      setError('更新目标信息失败: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // 获取目标详细信息
  Future<bool> getGoalDetailInfo(BuildContext context, String goalId) async {
    try {
      setLoading(true);
      clearError();

      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.userId;

      if (userId == null) {
        setError('用户未登录');
        return false;
      }

      final url = Uri.parse('${backendUrl}/api/v1/goals/get_detail_info');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'goal_id': goalId,
        }),
      );

      debugPrint('获取目标详细信息响应: ${response.statusCode}');
      debugPrint('响应内容: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['code'] == 200 && data['goal_detail'] != null) {
          _currentGoal = Goal.fromJson(data['goal_detail'] as Map<String, dynamic>);
          setLoading(false);
          notifyListeners();
          return true;
        } else {
          setError(data['message'] ?? '获取目标详细信息失败');
          return false;
        }
      } else {
        setError('网络请求失败: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('获取目标详细信息失败: $e');
      setError('获取目标详细信息失败: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // 更新子目标
  Future<bool> updateSubGoals(BuildContext context, String goalId, List<SubGoal> subGoals) async {
    try {
      setLoading(true);
      clearError();

      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.userId;

      if (userId == null) {
        setError('用户未登录');
        return false;
      }

      final url = Uri.parse('${backendUrl}/api/v1/goals/update_sub_goal');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'goal_id': goalId,
          'sub_goals': subGoals.map((subGoal) => subGoal.toJson()).toList(),
        }),
      );

      debugPrint('更新子目标响应: ${response.statusCode}');
      debugPrint('响应内容: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['code'] == 200) {
          // 更新成功后，重新获取目标详细信息以获得最新的统计数据
          await getGoalDetailInfo(context, goalId);
          // 同时刷新目标基本信息列表
          await getGoalBasicInfo(context);
          setLoading(false);
          return true;
        } else {
          setError(data['message'] ?? '更新子目标失败');
          return false;
        }
      } else {
        setError('网络请求失败: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('更新子目标失败: $e');
      setError('更新子目标失败: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // 更新子任务
  Future<bool> updateSubTasks(BuildContext context, String goalId, List<SubTask> subTasks) async {
    try {
      setLoading(true);
      clearError();

      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.userId;

      if (userId == null) {
        setError('用户未登录');
        return false;
      }

      final url = Uri.parse('${backendUrl}/api/v1/goals/update_sub_task');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'goal_id': goalId,
          'sub_tasks': subTasks.map((subTask) => subTask.toJson()).toList(),
        }),
      );

      debugPrint('更新子任务响应: ${response.statusCode}');
      debugPrint('响应内容: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['code'] == 200) {
          // 更新成功后，重新获取目标详细信息以获得最新的统计数据
          await getGoalDetailInfo(context, goalId);
          // 同时刷新目标基本信息列表
          await getGoalBasicInfo(context);
          setLoading(false);
          return true;
        } else {
          setError(data['message'] ?? '更新子任务失败');
          return false;
        }
      } else {
        setError('网络请求失败: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('更新子任务失败: $e');
      setError('更新子任务失败: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  // 清除当前目标详情
  void clearCurrentGoal() {
    _currentGoal = null;
    notifyListeners();
  }

  // 添加新目标到本地列表
  void addGoal(Goal goal) {
    _goals.add(goal);
    notifyListeners();
  }

  // 从本地列表删除目标
  void removeGoal(String goalId) {
    _goals.removeWhere((goal) => goal.goalId == goalId);
    notifyListeners();
  }

  // 更新本地目标
  void updateLocalGoal(Goal updatedGoal) {
    final index = _goals.indexWhere((goal) => goal.goalId == updatedGoal.goalId);
    if (index != -1) {
      _goals[index] = updatedGoal;
      notifyListeners();
    }
  }

  // 新增：通过日期获取目标、子目标、子任务
  Future<List<Goal>> getGoalsByDate(BuildContext context, String date) async {
    try {
      clearError();

      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.userId;

      if (userId == null) {
        setError('用户未登录');
        return [];
      }

      final url = Uri.parse('${backendUrl}/api/v1/goals/get_by_date?user_id=$userId&date=$date');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('通过日期获取目标响应: ${response.statusCode}');
      debugPrint('响应内容: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['code'] == 200) {
          return (data['goals'] as List<dynamic>)
              .map((goalJson) => Goal.fromJson(goalJson as Map<String, dynamic>))
              .toList();
        } else {
          setError(data['message'] ?? '获取日期目标失败');
          return [];
        }
      } else {
        setError('网络请求失败: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('通过日期获取目标失败: $e');
      setError('获取日期目标失败: $e');
      return [];
    }
  }

  // 新增：修改目标/子目标/子任务的日期
  Future<bool> updateDate(BuildContext context, {
    required String type,
    required String goalId,
    String? subGoalId,
    String? subTaskId,
    required String date,
  }) async {
    try {
      clearError();

      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.userId;

      if (userId == null) {
        setError('用户未登录');
        return false;
      }

      final url = Uri.parse('${backendUrl}/api/v1/goals/update_date');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'type': type,
          'goal_id': goalId,
          if (subGoalId != null) 'sub_goal_id': subGoalId,
          if (subTaskId != null) 'sub_task_id': subTaskId,
          'date': date,
        }),
      );

      debugPrint('修改日期响应: ${response.statusCode}');
      debugPrint('响应内容: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['code'] == 200) {
          // 更新成功后，刷新相关数据
          await getGoalBasicInfo(context);
          return true;
        } else {
          setError(data['message'] ?? '修改日期失败');
          return false;
        }
      } else {
        setError('网络请求失败: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('修改日期失败: $e');
      setError('修改日期失败: $e');
      return false;
    }
  }

  // 新增：更新子任务状态
  Future<bool> updateSubTaskStatus(BuildContext context, {
    required String goalId,
    required String subTaskId,
    required bool status,
  }) async {
    try {
      clearError();

      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.userId;

      if (userId == null) {
        setError('用户未登录');
        return false;
      }

      final url = Uri.parse('${backendUrl}/api/v1/goals/update_sub_task_status');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'goal_id': goalId,
          'sub_task_id': subTaskId,
          'sub_task_status': status,
        }),
      );

      debugPrint('更新子任务状态响应: ${response.statusCode}');
      debugPrint('响应内容: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['code'] == 200) {
          // 更新成功后，刷新相关数据
          await getGoalBasicInfo(context);
          return true;
        } else {
          setError(data['message'] ?? '更新子任务状态失败');
          return false;
        }
      } else {
        setError('网络请求失败: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('更新子任务状态失败: $e');
      setError('更新子任务状态失败: $e');
      return false;
    }
  }
} 