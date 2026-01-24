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

  @HiveField(5)
  final int? questionType; // Question type (0-9)

  @HiveField(6)
  final int? groupId; // Group ID if in a group

  const AnswerModel({
    required this.questionId,
    required this.questionCode,
    required this.value,
    required this.timestamp,
    this.groupInstanceId,
    this.questionType,
    this.groupId,
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
      questionType: json['questionType'],
      groupId: json['groupId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'questionCode': questionCode,
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'groupInstanceId': groupInstanceId,
      'questionType': questionType,
      'groupId': groupId,
    };
  }

  AnswerModel copyWith({
    int? questionId,
    String? questionCode,
    dynamic value,
    DateTime? timestamp,
    int? groupInstanceId,
    int? questionType,
    int? groupId,
  }) {
    return AnswerModel(
      questionId: questionId ?? this.questionId,
      questionCode: questionCode ?? this.questionCode,
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
      groupInstanceId: groupInstanceId ?? this.groupInstanceId,
      questionType: questionType ?? this.questionType,
      groupId: groupId ?? this.groupId,
    );
  }

  @override
  List<Object?> get props => [
    questionId,
    questionCode,
    value,
    timestamp,
    groupInstanceId,
    questionType,
    groupId,
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

  @HiveField(13)
  final int? researcherId;

  @HiveField(14)
  final int? supervisorId;

  @HiveField(15)
  final int? cityId;

  @HiveField(16)
  final double? latitude;

  @HiveField(17)
  final double? longitude;

  @HiveField(18)
  final int? buildingFloorsCount;

  @HiveField(19)
  final int? apartmentsPerFloor;

  @HiveField(20)
  final int? selectedFloor;

  @HiveField(21)
  final int? selectedApartment;

  @HiveField(22)
  final int? governorateId;

  @HiveField(23)
  final int? areaId;

  @HiveField(24)
  final String? governorateName;

  @HiveField(25)
  final String? areaName;

  @HiveField(26)
  final int completionStatus; // 0 = incomplete (early finish), 1 = complete (all required answered)

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
    this.researcherId,
    this.supervisorId,
    this.cityId,
    this.latitude,
    this.longitude,
    this.buildingFloorsCount,
    this.apartmentsPerFloor,
    this.selectedFloor,
    this.selectedApartment,
    this.governorateId,
    this.areaId,
    this.governorateName,
    this.areaName,
    this.completionStatus = 1, // Default to complete
  });

  factory SurveyAnswersModel.fromJson(Map<String, dynamic> json) {
    return SurveyAnswersModel(
      surveyId: json['surveyId'] ?? 0,
      surveyCode: json['surveyCode'] ?? '',
      answers:
          (json['answers'] as List<dynamic>?)
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
      researcherId: json['researcherId'],
      supervisorId: json['supervisorId'],
      cityId: json['cityId'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      buildingFloorsCount: json['buildingFloorsCount'],
      apartmentsPerFloor: json['apartmentsPerFloor'],
      selectedFloor: json['selectedFloor'],
      selectedApartment: json['selectedApartment'],
      governorateId: json['governorateId'],
      areaId: json['areaId'],
      governorateName: json['governorateName'],
      areaName: json['areaName'],
      completionStatus: json['status'] ?? 1, // Default to complete
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
      'researcherId': researcherId,
      'supervisorId': supervisorId,
      'cityId': cityId,
      'latitude': latitude,
      'longitude': longitude,
      'buildingFloorsCount': buildingFloorsCount,
      'apartmentsPerFloor': apartmentsPerFloor,
      'selectedFloor': selectedFloor,
      'selectedApartment': selectedApartment,
      'governorateId': governorateId,
      'areaId': areaId,
      'governorateName': governorateName,
      'areaName': areaName,
      'status': completionStatus,
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
    int? researcherId,
    int? supervisorId,
    int? cityId,
    double? latitude,
    double? longitude,
    int? buildingFloorsCount,
    int? apartmentsPerFloor,
    int? selectedFloor,
    int? selectedApartment,
    int? governorateId,
    int? areaId,
    String? governorateName,
    String? areaName,
    int? completionStatus,
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
      researcherId: researcherId ?? this.researcherId,
      supervisorId: supervisorId ?? this.supervisorId,
      cityId: cityId ?? this.cityId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      buildingFloorsCount: buildingFloorsCount ?? this.buildingFloorsCount,
      apartmentsPerFloor: apartmentsPerFloor ?? this.apartmentsPerFloor,
      selectedFloor: selectedFloor ?? this.selectedFloor,
      selectedApartment: selectedApartment ?? this.selectedApartment,
      governorateId: governorateId ?? this.governorateId,
      areaId: areaId ?? this.areaId,
      governorateName: governorateName ?? this.governorateName,
      areaName: areaName ?? this.areaName,
      completionStatus: completionStatus ?? this.completionStatus,
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
    researcherId,
    supervisorId,
    cityId,
    latitude,
    longitude,
    buildingFloorsCount,
    apartmentsPerFloor,
    selectedFloor,
    selectedApartment,
    governorateId,
    areaId,
    governorateName,
    areaName,
    completionStatus,
  ];
}
