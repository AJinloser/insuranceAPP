import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 实验信息模型
class ExperimentInfo {
  final String experimentId;
  final String groupCode;
  final bool showAlgorithmDeclaration;
  final bool showInterestDeclaration;
  final bool showPrivacyDeclaration;
  final bool showDataControl;
  final bool hasGuidedQuestions;
  final String chatbotApiKey;
  final bool completedPreSurvey;
  final bool completedDeclaration;
  final bool completedConversation;
  final bool completedPostSurvey;

  ExperimentInfo({
    required this.experimentId,
    required this.groupCode,
    required this.showAlgorithmDeclaration,
    required this.showInterestDeclaration,
    required this.showPrivacyDeclaration,
    required this.showDataControl,
    required this.hasGuidedQuestions,
    required this.chatbotApiKey,
    required this.completedPreSurvey,
    required this.completedDeclaration,
    required this.completedConversation,
    required this.completedPostSurvey,
  });

  factory ExperimentInfo.fromJson(Map<String, dynamic> json) {
    return ExperimentInfo(
      experimentId: json['experiment_id'] ?? '',
      groupCode: json['group_code'] ?? '00000',
      showAlgorithmDeclaration: json['show_algorithm_declaration'] ?? false,
      showInterestDeclaration: json['show_interest_declaration'] ?? false,
      showPrivacyDeclaration: json['show_privacy_declaration'] ?? false,
      showDataControl: json['show_data_control'] ?? false,
      hasGuidedQuestions: json['has_guided_questions'] ?? false,
      chatbotApiKey: json['chatbot_api_key'] ?? '',
      completedPreSurvey: json['completed_pre_survey'] ?? false,
      completedDeclaration: json['completed_declaration'] ?? false,
      completedConversation: json['completed_conversation'] ?? false,
      completedPostSurvey: json['completed_post_survey'] ?? false,
    );
  }
}

/// 实验服务
class ExperimentService extends ChangeNotifier {
  final String _baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api/v1';
  
  ExperimentInfo? _experimentInfo;
  ExperimentInfo? get experimentInfo => _experimentInfo;

  /// 获取实验信息
  Future<ExperimentInfo?> getExperimentInfo(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/experiment/info?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        _experimentInfo = ExperimentInfo.fromJson(data);
        notifyListeners();
        return _experimentInfo;
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        debugPrint('获取实验信息失败: ${error['detail']}');
        return null;
      }
    } catch (e) {
      debugPrint('获取实验信息异常: $e');
      return null;
    }
  }

  /// 更新实验进度
  Future<bool> updateProgress({
    required String userId,
    bool? completedPreSurvey,
    bool? completedDeclaration,
    bool? completedConversation,
    bool? completedPostSurvey,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'user_id': userId,
      };
      
      if (completedPreSurvey != null) {
        requestBody['completed_pre_survey'] = completedPreSurvey;
      }
      if (completedDeclaration != null) {
        requestBody['completed_declaration'] = completedDeclaration;
      }
      if (completedConversation != null) {
        requestBody['completed_conversation'] = completedConversation;
      }
      if (completedPostSurvey != null) {
        requestBody['completed_post_survey'] = completedPostSurvey;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/experiment/progress'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        // 更新本地缓存
        if (_experimentInfo != null) {
          _experimentInfo = ExperimentInfo(
            experimentId: _experimentInfo!.experimentId,
            groupCode: _experimentInfo!.groupCode,
            showAlgorithmDeclaration: _experimentInfo!.showAlgorithmDeclaration,
            showInterestDeclaration: _experimentInfo!.showInterestDeclaration,
            showPrivacyDeclaration: _experimentInfo!.showPrivacyDeclaration,
            showDataControl: _experimentInfo!.showDataControl,
            hasGuidedQuestions: _experimentInfo!.hasGuidedQuestions,
            chatbotApiKey: _experimentInfo!.chatbotApiKey,
            completedPreSurvey: completedPreSurvey ?? _experimentInfo!.completedPreSurvey,
            completedDeclaration: completedDeclaration ?? _experimentInfo!.completedDeclaration,
            completedConversation: completedConversation ?? _experimentInfo!.completedConversation,
            completedPostSurvey: completedPostSurvey ?? _experimentInfo!.completedPostSurvey,
          );
          notifyListeners();
        }
        return true;
      } else {
        final error = json.decode(utf8.decode(response.bodyBytes));
        debugPrint('更新实验进度失败: ${error['detail']}');
        return false;
      }
    } catch (e) {
      debugPrint('更新实验进度异常: $e');
      return false;
    }
  }

  /// 清空实验信息
  void clear() {
    _experimentInfo = null;
    notifyListeners();
  }
}

