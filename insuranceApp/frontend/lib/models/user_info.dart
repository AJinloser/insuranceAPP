import 'dart:convert';

class BasicInfo {
  String? age;
  String? city;
  String? gender;

  BasicInfo({
    this.age,
    this.city,
    this.gender,
  });

  factory BasicInfo.fromJson(Map<String, dynamic> json) {
    return BasicInfo(
      age: json['age'],
      city: json['city'],
      gender: json['gender'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'city': city,
      'gender': gender,
    };
  }

  BasicInfo copyWith({
    String? age,
    String? city,
    String? gender,
  }) {
    return BasicInfo(
      age: age ?? this.age,
      city: city ?? this.city,
      gender: gender ?? this.gender,
    );
  }
}

class FinancialInfo {
  String? occupation;
  String? income;
  String? expenses;
  String? assets;
  String? liabilities;

  FinancialInfo({
    this.occupation,
    this.income,
    this.expenses,
    this.assets,
    this.liabilities,
  });

  factory FinancialInfo.fromJson(Map<String, dynamic> json) {
    return FinancialInfo(
      occupation: json['occupation'],
      income: json['income'],
      expenses: json['expenses'],
      assets: json['assets'],
      liabilities: json['liabilities'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'occupation': occupation,
      'income': income,
      'expenses': expenses,
      'assets': assets,
      'liabilities': liabilities,
    };
  }

  FinancialInfo copyWith({
    String? occupation,
    String? income,
    String? expenses,
    String? assets,
    String? liabilities,
  }) {
    return FinancialInfo(
      occupation: occupation ?? this.occupation,
      income: income ?? this.income,
      expenses: expenses ?? this.expenses,
      assets: assets ?? this.assets,
      liabilities: liabilities ?? this.liabilities,
    );
  }
}

class RiskInfo {
  String? riskAversion;

  RiskInfo({
    this.riskAversion,
  });

  factory RiskInfo.fromJson(Map<String, dynamic> json) {
    return RiskInfo(
      riskAversion: json['risk_aversion'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'risk_aversion': riskAversion,
    };
  }

  RiskInfo copyWith({String? riskAversion}) {
    return RiskInfo(
      riskAversion: riskAversion ?? this.riskAversion,
    );
  }
}

class RetirementInfo {
  String? retirementAge;
  String? retirementIncome;

  RetirementInfo({
    this.retirementAge,
    this.retirementIncome,
  });

  factory RetirementInfo.fromJson(Map<String, dynamic> json) {
    return RetirementInfo(
      retirementAge: json['retirement_age'],
      retirementIncome: json['retirement_income'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'retirement_age': retirementAge,
      'retirement_income': retirementIncome,
    };
  }

  RetirementInfo copyWith({
    String? retirementAge,
    String? retirementIncome,
  }) {
    return RetirementInfo(
      retirementAge: retirementAge ?? this.retirementAge,
      retirementIncome: retirementIncome ?? this.retirementIncome,
    );
  }
}

class FamilyMember {
  String? relation;
  String? age;
  String? occupation;
  String? income;

  FamilyMember({
    this.relation,
    this.age,
    this.occupation,
    this.income,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      relation: json['relation'],
      age: json['age'],
      occupation: json['occupation'],
      income: json['income'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'relation': relation,
      'age': age,
      'occupation': occupation,
      'income': income,
    };
  }

  FamilyMember copyWith({
    String? relation,
    String? age,
    String? occupation,
    String? income,
  }) {
    return FamilyMember(
      relation: relation ?? this.relation,
      age: age ?? this.age,
      occupation: occupation ?? this.occupation,
      income: income ?? this.income,
    );
  }
}

class FamilyInfo {
  List<FamilyMember> familyMembers;

  FamilyInfo({
    required this.familyMembers,
  });

  factory FamilyInfo.fromJson(Map<String, dynamic> json) {
    return FamilyInfo(
      familyMembers: (json['family_members'] as List<dynamic>?)
              ?.map((item) => FamilyMember.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'family_members': familyMembers.map((member) => member.toJson()).toList(),
    };
  }

  FamilyInfo copyWith({List<FamilyMember>? familyMembers}) {
    return FamilyInfo(
      familyMembers: familyMembers ?? List.from(this.familyMembers),
    );
  }
}

class Goal {
  String? goalDetails;

  Goal({
    this.goalDetails,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      goalDetails: json['goal_details'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goal_details': goalDetails,
    };
  }

  Goal copyWith({String? goalDetails}) {
    return Goal(
      goalDetails: goalDetails ?? this.goalDetails,
    );
  }
}

class GoalInfo {
  List<Goal> goals;

  GoalInfo({
    required this.goals,
  });

  factory GoalInfo.fromJson(Map<String, dynamic> json) {
    return GoalInfo(
      goals: (json['goals'] as List<dynamic>?)
              ?.map((item) => Goal.fromJson(item))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goals': goals.map((goal) => goal.toJson()).toList(),
    };
  }

  GoalInfo copyWith({List<Goal>? goals}) {
    return GoalInfo(
      goals: goals ?? List.from(this.goals),
    );
  }
}

class UserInfo {
  String? userId;
  BasicInfo basicInfo;
  FinancialInfo financialInfo;
  RiskInfo riskInfo;
  RetirementInfo retirementInfo;
  FamilyInfo familyInfo;
  GoalInfo goalInfo;
  Map<String, dynamic> otherInfo;

  UserInfo({
    this.userId,
    required this.basicInfo,
    required this.financialInfo,
    required this.riskInfo,
    required this.retirementInfo,
    required this.familyInfo,
    required this.goalInfo,
    required this.otherInfo,
  });

  factory UserInfo.empty() {
    return UserInfo(
      basicInfo: BasicInfo(),
      financialInfo: FinancialInfo(),
      riskInfo: RiskInfo(),
      retirementInfo: RetirementInfo(),
      familyInfo: FamilyInfo(familyMembers: []),
      goalInfo: GoalInfo(goals: []),
      otherInfo: {},
    );
  }

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      userId: json['user_id'],
      basicInfo: BasicInfo.fromJson(json['basic_info'] ?? {}),
      financialInfo: FinancialInfo.fromJson(json['financial_info'] ?? {}),
      riskInfo: RiskInfo.fromJson(json['risk_info'] ?? {}),
      retirementInfo: RetirementInfo.fromJson(json['retirement_info'] ?? {}),
      familyInfo: FamilyInfo.fromJson(json['family_info'] ?? {}),
      goalInfo: GoalInfo.fromJson(json['goal_info'] ?? {}),
      otherInfo: Map<String, dynamic>.from(json['other_info'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'basic_info': basicInfo.toJson(),
      'financial_info': financialInfo.toJson(),
      'risk_info': riskInfo.toJson(),
      'retirement_info': retirementInfo.toJson(),
      'family_info': familyInfo.toJson(),
      'goal_info': goalInfo.toJson(),
      'other_info': otherInfo,
    };
  }

  UserInfo copyWith({
    String? userId,
    BasicInfo? basicInfo,
    FinancialInfo? financialInfo,
    RiskInfo? riskInfo,
    RetirementInfo? retirementInfo,
    FamilyInfo? familyInfo,
    GoalInfo? goalInfo,
    Map<String, dynamic>? otherInfo,
  }) {
    return UserInfo(
      userId: userId ?? this.userId,
      basicInfo: basicInfo ?? this.basicInfo,
      financialInfo: financialInfo ?? this.financialInfo,
      riskInfo: riskInfo ?? this.riskInfo,
      retirementInfo: retirementInfo ?? this.retirementInfo,
      familyInfo: familyInfo ?? this.familyInfo,
      goalInfo: goalInfo ?? this.goalInfo,
      otherInfo: otherInfo ?? Map.from(this.otherInfo),
    );
  }
}

class UserInfoApiResponse {
  int code;
  String message;
  UserInfo? userInfo;

  UserInfoApiResponse({
    required this.code,
    required this.message,
    this.userInfo,
  });

  factory UserInfoApiResponse.fromJson(Map<String, dynamic> json) {
    return UserInfoApiResponse(
      code: json['code'],
      message: json['message'],
      userInfo: json['user_info'] != null ? UserInfo.fromJson(json['user_info']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'user_info': userInfo?.toJson(),
    };
  }
} 