import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:survey/data/models/condition_model.dart';
import 'package:survey/data/models/question_group_model.dart';
import 'package:survey/data/models/question_model.dart';

part 'section_model.g.dart';

@HiveType(typeId: 4)
class SectionModel extends Equatable {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int order;

  @HiveField(3)
  final bool isForEnumeratorOnly;

  @HiveField(4)
  final bool isActive;

  @HiveField(5)
  final List<QuestionGroupModel> questionGroups;

  @HiveField(6)
  final List<QuestionModel> questions;

  @HiveField(7)
  final List<ConditionModel> targetConditions;

  const SectionModel({
    required this.id,
    required this.name,
    required this.order,
    required this.isForEnumeratorOnly,
    required this.isActive,
    required this.questionGroups,
    required this.questions,
    required this.targetConditions,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      order: json['order'] ?? 0,
      isForEnumeratorOnly: json['isForEnumeratorOnly'] ?? false,
      isActive: json['isActive'] ?? true,
      questionGroups: (json['questionGroups'] as List<dynamic>?)
              ?.map((e) =>
                  QuestionGroupModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
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
      'order': order,
      'isForEnumeratorOnly': isForEnumeratorOnly,
      'isActive': isActive,
      'questionGroups': questionGroups.map((e) => e.toJson()).toList(),
      'questions': questions.map((e) => e.toJson()).toList(),
      'targetConditions': targetConditions.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        order,
        isForEnumeratorOnly,
        isActive,
        questionGroups,
        questions,
        targetConditions,
      ];
}
