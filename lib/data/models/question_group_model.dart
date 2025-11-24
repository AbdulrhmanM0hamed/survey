import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:survey/data/models/condition_model.dart';
import 'package:survey/data/models/question_model.dart';

part 'question_group_model.g.dart';

@HiveType(typeId: 3)
class QuestionGroupModel extends Equatable {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int minCount;

  @HiveField(3)
  final int? maxCount;

  @HiveField(4)
  final String code;

  @HiveField(5)
  final int order;

  @HiveField(6)
  final bool isActive;

  @HiveField(7)
  final List<QuestionModel> questions;

  @HiveField(8)
  final List<ConditionModel> targetConditions;

  const QuestionGroupModel({
    required this.id,
    required this.name,
    required this.minCount,
    this.maxCount,
    required this.code,
    required this.order,
    required this.isActive,
    required this.questions,
    required this.targetConditions,
  });

  factory QuestionGroupModel.fromJson(Map<String, dynamic> json) {
    return QuestionGroupModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      minCount: json['minCount'] ?? 1,
      maxCount: json['maxCount'],
      code: json['code'] ?? '',
      order: json['order'] ?? 0,
      isActive: json['isActive'] ?? true,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((e) => QuestionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      targetConditions: (json['targetConditions'] as List<dynamic>?)
              ?.map((e) => ConditionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'minCount': minCount,
      'maxCount': maxCount,
      'code': code,
      'order': order,
      'isActive': isActive,
      'questions': questions.map((e) => e.toJson()).toList(),
      'targetConditions': targetConditions.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        minCount,
        maxCount,
        code,
        order,
        isActive,
        questions,
        targetConditions,
      ];
}
