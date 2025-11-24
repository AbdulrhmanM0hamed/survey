import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'answer_model.g.dart';

@HiveType(typeId: 7)
class AnswerModel extends Equatable {
  @HiveField(0)
  final int questionId;

  @HiveField(1)
  final String questionCode;

  @HiveField(2)
  final dynamic value;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final int? groupInstanceId; // For repeated groups

  const AnswerModel({
    required this.questionId,
    required this.questionCode,
    required this.value,
    required this.timestamp,
    this.groupInstanceId,
  });

  factory AnswerModel.fromJson(Map<String, dynamic> json) {
    return AnswerModel(
      questionId: json['questionId'] ?? 0,
      questionCode: json['questionCode'] ?? '',
      value: json['value'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      groupInstanceId: json['groupInstanceId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'questionCode': questionCode,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'groupInstanceId': groupInstanceId,
    };
  }

  AnswerModel copyWith({
    int? questionId,
    String? questionCode,
    dynamic value,
    DateTime? timestamp,
    int? groupInstanceId,
  }) {
    return AnswerModel(
      questionId: questionId ?? this.questionId,
      questionCode: questionCode ?? this.questionCode,
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
      groupInstanceId: groupInstanceId ?? this.groupInstanceId,
    );
  }

  @override
  List<Object?> get props => [
        questionId,
        questionCode,
        value,
        timestamp,
        groupInstanceId,
      ];
}

@HiveType(typeId: 8)
class SurveyAnswersModel extends Equatable {
  @HiveField(0)
  final int surveyId;

  @HiveField(1)
  final String surveyCode;

  @HiveField(2)
  final List<AnswerModel> answers;

  @HiveField(3)
  final DateTime startedAt;

  @HiveField(4)
  final DateTime? completedAt;

  @HiveField(5)
  final bool isDraft;

  @HiveField(6)
  final String? researcherName;

  @HiveField(7)
  final String? supervisorName;

  @HiveField(8)
  final String? cityName;

  @HiveField(9)
  final String? neighborhoodName;

  @HiveField(10)
  final String? streetName;

  @HiveField(11)
  final bool? isApproved;

  @HiveField(12)
  final String? rejectReason;

  const SurveyAnswersModel({
    required this.surveyId,
    required this.surveyCode,
    required this.answers,
    required this.startedAt,
    this.completedAt,
    required this.isDraft,
    this.researcherName,
    this.supervisorName,
    this.cityName,
    this.neighborhoodName,
    this.streetName,
    this.isApproved,
    this.rejectReason,
  });

  factory SurveyAnswersModel.fromJson(Map<String, dynamic> json) {
    return SurveyAnswersModel(
      surveyId: json['surveyId'] ?? 0,
      surveyCode: json['surveyCode'] ?? '',
      answers: (json['answers'] as List<dynamic>?)
              ?.map((e) => AnswerModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      isDraft: json['isDraft'] ?? true,
      researcherName: json['researcherName'],
      supervisorName: json['supervisorName'],
      cityName: json['cityName'],
      neighborhoodName: json['neighborhoodName'],
      streetName: json['streetName'],
      isApproved: json['isApproved'],
      rejectReason: json['rejectReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surveyId': surveyId,
      'surveyCode': surveyCode,
      'answers': answers.map((e) => e.toJson()).toList(),
      'startedAt': startedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'isDraft': isDraft,
      'researcherName': researcherName,
      'supervisorName': supervisorName,
      'cityName': cityName,
      'neighborhoodName': neighborhoodName,
      'streetName': streetName,
      'isApproved': isApproved,
      'rejectReason': rejectReason,
    };
  }

  SurveyAnswersModel copyWith({
    int? surveyId,
    String? surveyCode,
    List<AnswerModel>? answers,
    DateTime? startedAt,
    DateTime? completedAt,
    bool? isDraft,
    String? researcherName,
    String? supervisorName,
    String? cityName,
    String? neighborhoodName,
    String? streetName,
    bool? isApproved,
    String? rejectReason,
  }) {
    return SurveyAnswersModel(
      surveyId: surveyId ?? this.surveyId,
      surveyCode: surveyCode ?? this.surveyCode,
      answers: answers ?? this.answers,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      isDraft: isDraft ?? this.isDraft,
      researcherName: researcherName ?? this.researcherName,
      supervisorName: supervisorName ?? this.supervisorName,
      cityName: cityName ?? this.cityName,
      neighborhoodName: neighborhoodName ?? this.neighborhoodName,
      streetName: streetName ?? this.streetName,
      isApproved: isApproved ?? this.isApproved,
      rejectReason: rejectReason ?? this.rejectReason,
    );
  }

  @override
  List<Object?> get props => [
        surveyId,
        surveyCode,
        answers,
        startedAt,
        completedAt,
        isDraft,
        researcherName,
        supervisorName,
        cityName,
        neighborhoodName,
        streetName,
        isApproved,
        rejectReason,
      ];
}
