import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:survey/core/enums/condition_action.dart';
import 'package:survey/core/enums/condition_operator.dart';
import 'package:survey/core/enums/target_type.dart';

part 'condition_model.g.dart';

@HiveType(typeId: 1)
class ConditionModel extends Equatable {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final int targetType;

  @HiveField(2)
  final String targetTypeString;

  @HiveField(3)
  final int? targetQuestionId;

  @HiveField(4)
  final int? targetGroupId;

  @HiveField(5)
  final int? targetSectionId;

  @HiveField(6)
  final String? targetQuestionName;

  @HiveField(7)
  final String? targetGroupName;

  @HiveField(8)
  final String? targetSectionName;

  @HiveField(9)
  final int action;

  @HiveField(10)
  final String actionString;

  @HiveField(11)
  final String? value;

  @HiveField(12)
  final String? description;

  @HiveField(13)
  final int operator;

  @HiveField(14)
  final String operatorString;

  @HiveField(15)
  final int sourceQuestionId;

  @HiveField(16)
  final String? sourceQuestionText;

  const ConditionModel({
    required this.id,
    required this.targetType,
    required this.targetTypeString,
    this.targetQuestionId,
    this.targetGroupId,
    this.targetSectionId,
    this.targetQuestionName,
    this.targetGroupName,
    this.targetSectionName,
    required this.action,
    required this.actionString,
    this.value,
    this.description,
    required this.operator,
    required this.operatorString,
    required this.sourceQuestionId,
    this.sourceQuestionText,
  });

  factory ConditionModel.fromJson(Map<String, dynamic> json) {
    return ConditionModel(
      id: json['id'] ?? 0,
      targetType: json['targetType'] ?? 1,
      targetTypeString: json['targetTypeString'] ?? '',
      targetQuestionId: json['targetQuestionId'],
      targetGroupId: json['targetGroupId'],
      targetSectionId: json['targetSectionId'],
      targetQuestionName: json['targetQuestionName'],
      targetGroupName: json['targetGroupName'],
      targetSectionName: json['targetSectionName'],
      action: json['action'] ?? 1,
      actionString: json['actionString'] ?? '',
      value: json['value'],
      description: json['description'],
      operator: json['operator'] ?? 1,
      operatorString: json['operatorString'] ?? '',
      sourceQuestionId: json['sourceQuestionId'] ?? 0,
      sourceQuestionText: json['sourceQuestionText'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'targetType': targetType,
      'targetTypeString': targetTypeString,
      'targetQuestionId': targetQuestionId,
      'targetGroupId': targetGroupId,
      'targetSectionId': targetSectionId,
      'targetQuestionName': targetQuestionName,
      'targetGroupName': targetGroupName,
      'targetSectionName': targetSectionName,
      'action': action,
      'actionString': actionString,
      'value': value,
      'description': description,
      'operator': operator,
      'operatorString': operatorString,
      'sourceQuestionId': sourceQuestionId,
      'sourceQuestionText': sourceQuestionText,
    };
  }

  TargetType get targetTypeEnum => TargetType.fromValue(targetType);
  ConditionAction get actionEnum => ConditionAction.fromValue(action);
  ConditionOperator get operatorEnum => ConditionOperator.fromValue(operator);

  @override
  List<Object?> get props => [
        id,
        targetType,
        targetQuestionId,
        targetGroupId,
        targetSectionId,
        action,
        operator,
        sourceQuestionId,
        value,
      ];
}
