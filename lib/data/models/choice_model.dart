import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'choice_model.g.dart';

@HiveType(typeId: 0)
class ChoiceModel extends Equatable {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String code;

  @HiveField(2)
  final String label;

  @HiveField(3)
  final int sortOrder;

  @HiveField(4)
  final bool isActive;

  const ChoiceModel({
    required this.id,
    required this.code,
    required this.label,
    required this.sortOrder,
    required this.isActive,
  });

  factory ChoiceModel.fromJson(Map<String, dynamic> json) {
    return ChoiceModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      label: json['label'] ?? '',
      sortOrder: json['sortOrder'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'label': label,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }

  @override
  List<Object?> get props => [id, code, label, sortOrder, isActive];
}
