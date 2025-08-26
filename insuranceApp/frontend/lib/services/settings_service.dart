import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/goal_suggestion.dart';

/// 设置服务
/// 管理应用的各种设置选项
class SettingsService extends ChangeNotifier {
  static const String _insuranceJsonDetectionKey = 'insurance_json_detection_enabled';
  static const String _goalJsonDetectionKey = 'goal_json_detection_enabled';
  static const String _processedGoalSuggestionsKey = 'processed_goal_suggestions';
  
  // 功能开关相关
  static const String _productComparisonEnabledKey = 'product_comparison_enabled';
  static const String _productChatEnabledKey = 'product_chat_enabled';
  static const String _insuranceAnalysisEnabledKey = 'insurance_analysis_enabled';

  bool _insuranceJsonDetectionEnabled = false;
  bool _goalJsonDetectionEnabled = true;
  Set<String> _processedGoalSuggestions = <String>{};
  
  // 功能开关状态
  bool _productComparisonEnabled = false;
  bool _productChatEnabled = false;
  bool _insuranceAnalysisEnabled = false;

  bool get insuranceJsonDetectionEnabled => _insuranceJsonDetectionEnabled;
  bool get goalJsonDetectionEnabled => _goalJsonDetectionEnabled;
  Set<String> get processedGoalSuggestions => Set.from(_processedGoalSuggestions);
  
  // 功能开关getter
  bool get productComparisonEnabled => _productComparisonEnabled;
  bool get productChatEnabled => _productChatEnabled;
  bool get insuranceAnalysisEnabled => _insuranceAnalysisEnabled;

  /// 初始化设置
  Future<void> init() async {
    await loadSettings();
  }

  /// 加载设置
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _insuranceJsonDetectionEnabled = prefs.getBool(_insuranceJsonDetectionKey) ?? false;
      _goalJsonDetectionEnabled = prefs.getBool(_goalJsonDetectionKey) ?? true;
      
      // 加载功能开关设置
      _productComparisonEnabled = prefs.getBool(_productComparisonEnabledKey) ?? false;
      _productChatEnabled = prefs.getBool(_productChatEnabledKey) ?? false;
      _insuranceAnalysisEnabled = prefs.getBool(_insuranceAnalysisEnabledKey) ?? false;
      
      // 加载已处理的目标建议
      final processedList = prefs.getStringList(_processedGoalSuggestionsKey) ?? [];
      _processedGoalSuggestions = Set.from(processedList);
      
      notifyListeners();
    } catch (e) {
      debugPrint('加载设置失败: $e');
    }
  }

  /// 保存设置
  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_insuranceJsonDetectionKey, _insuranceJsonDetectionEnabled);
      await prefs.setBool(_goalJsonDetectionKey, _goalJsonDetectionEnabled);
      
      // 保存功能开关设置
      await prefs.setBool(_productComparisonEnabledKey, _productComparisonEnabled);
      await prefs.setBool(_productChatEnabledKey, _productChatEnabled);
      await prefs.setBool(_insuranceAnalysisEnabledKey, _insuranceAnalysisEnabled);
      
      // 保存已处理的目标建议
      await prefs.setStringList(_processedGoalSuggestionsKey, _processedGoalSuggestions.toList());
    } catch (e) {
      debugPrint('保存设置失败: $e');
    }
  }

  /// 设置保险产品JSON检测状态
  Future<void> setInsuranceJsonDetectionEnabled(bool enabled) async {
    if (_insuranceJsonDetectionEnabled != enabled) {
      _insuranceJsonDetectionEnabled = enabled;
      notifyListeners();
      await saveSettings();
    }
  }

  /// 设置目标JSON检测状态
  Future<void> setGoalJsonDetectionEnabled(bool enabled) async {
    if (_goalJsonDetectionEnabled != enabled) {
      _goalJsonDetectionEnabled = enabled;
      notifyListeners();
      await saveSettings();
    }
  }

  /// 检查目标建议是否已被处理
  bool isGoalSuggestionProcessed(String suggestionId) {
    return _processedGoalSuggestions.contains(suggestionId);
  }

  /// 获取目标建议的状态
  GoalSuggestionStatus getGoalSuggestionStatus(String suggestionId) {
    if (!_processedGoalSuggestions.contains(suggestionId)) {
      return GoalSuggestionStatus.pending;
    }
    
    // 这里可以扩展为更精确的状态管理，现在简化为已处理
    // 后续可以分别存储接受和拒绝的状态
    return GoalSuggestionStatus.accepted; // 简化处理
  }

  /// 标记目标建议为已接受
  Future<void> markGoalSuggestionAccepted(String suggestionId) async {
    if (!_processedGoalSuggestions.contains(suggestionId)) {
      _processedGoalSuggestions.add(suggestionId);
      notifyListeners();
      await saveSettings();
      debugPrint('===> SettingsService: 标记目标建议 $suggestionId 为已接受');
    }
  }

  /// 标记目标建议为已拒绝
  Future<void> markGoalSuggestionRejected(String suggestionId) async {
    if (!_processedGoalSuggestions.contains(suggestionId)) {
      _processedGoalSuggestions.add(suggestionId);
      notifyListeners();
      await saveSettings();
      debugPrint('===> SettingsService: 标记目标建议 $suggestionId 为已拒绝');
    }
  }

  /// 重置已处理的目标建议（调试用）
  Future<void> resetProcessedGoalSuggestions() async {
    _processedGoalSuggestions.clear();
    notifyListeners();
    await saveSettings();
    debugPrint('===> SettingsService: 重置已处理的目标建议');
  }

  /// 设置产品对比功能开关
  Future<void> setProductComparisonEnabled(bool enabled) async {
    if (_productComparisonEnabled != enabled) {
      _productComparisonEnabled = enabled;
      notifyListeners();
      await saveSettings();
    }
  }

  /// 设置产品对话功能开关
  Future<void> setProductChatEnabled(bool enabled) async {
    if (_productChatEnabled != enabled) {
      _productChatEnabled = enabled;
      notifyListeners();
      await saveSettings();
    }
  }

  /// 设置保单分析功能开关
  Future<void> setInsuranceAnalysisEnabled(bool enabled) async {
    if (_insuranceAnalysisEnabled != enabled) {
      _insuranceAnalysisEnabled = enabled;
      notifyListeners();
      await saveSettings();
    }
  }
} 