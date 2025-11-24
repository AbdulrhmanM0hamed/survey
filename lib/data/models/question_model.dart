import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:survey/core/enums/question_type.dart';
import 'package:survey/data/models/choice_model.dart';
import 'package:survey/data/models/condition_model.dart';

part 'question_model.g.dart';

@HiveType(typeId: 2)
class QuestionModel extends Equatable {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String code;

  @HiveField(2)
  final String text;

  @HiveField(3)
  final int type;

  @HiveField(4)
  final int scope;

  @HiveField(5)
  final int order;

  @HiveField(6)
  final bool isRequired;

  @HiveField(7)
  final bool isActive;

  @HiveField(8)
  final List<ChoiceModel> choices;

  @HiveField(9)
  final List<ConditionModel> sourceConditions;

  @HiveField(10)
  final List<ConditionModel> targetConditions;

  const QuestionModel({
    required this.id,
    required this.code,
    required this.text,
    required this.type,
    required this.scope,
    required this.order,
    required this.isRequired,
    required this.isActive,
    required this.choices,
    required this.sourceConditions,
    required this.targetConditions,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      text: json['text'] ?? '',
      type: json['type'] ?? 0,
      scope: json['scope'] ?? 1,
      order: json['order'] ?? 0,
      isRequired: json['isRequired'] ?? false,
      isActive: json['isActive'] ?? true,
      choices: (json['choices'] as List<dynamic>?)
              ?.map((e) => ChoiceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      sourceConditions: (json['sourceConditions'] as List<dynamic>?)
              ?.map((e) => ConditionModel.fromJson(e as Map<String, dynamic>))
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
      'code': code,
      'text': text,
      'type': type,
      'scope': scope,
      'order': order,
      'isRequired': isRequired,
      'isActive': isActive,
      'choices': choices.map((e) => e.toJson()).toList(),
      'sourceConditions': sourceConditions.map((e) => e.toJson()).toList(),
      'targetConditions': targetConditions.map((e) => e.toJson()).toList(),
    };
  }

  QuestionType get questionType => QuestionType.fromValue(type);

  @override
  List<Object?> get props => [
        id,
        code,
        text,
        type,
        scope,
        order,
        isRequired,
        isActive,
        choices,
        sourceConditions,
        targetConditions,
      ];
}
