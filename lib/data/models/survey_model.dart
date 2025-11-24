import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:survey/data/models/section_model.dart';

part 'survey_model.g.dart';

@HiveType(typeId: 5)
class SurveyModel extends Equatable {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String code;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String version;

  @HiveField(4)
  final String description;

  @HiveField(5)
  final String language;

  @HiveField(6)
  final String scope;

  @HiveField(7)
  final String? termsAndConditions;

  @HiveField(8)
  final bool isActive;

  @HiveField(9)
  final List<SectionModel>? sections;

  const SurveyModel({
    required this.id,
    required this.code,
    required this.name,
    required this.version,
    required this.description,
    required this.language,
    required this.scope,
    this.termsAndConditions,
    required this.isActive,
    this.sections,
  });

  factory SurveyModel.fromJson(Map<String, dynamic> json) {
    return SurveyModel(
      id: json['id'] ?? 0,
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      version: json['version'] ?? '',
      description: json['description'] ?? '',
      language: json['language'] ?? 'ar',
      scope: json['scope'] ?? '',
      termsAndConditions: json['termsAndConditions'],
      isActive: json['isActive'] ?? true,
      sections: json['sections'] != null
          ? (json['sections'] as List<dynamic>)
              .map((e) => SectionModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'version': version,
      'description': description,
      'language': language,
      'scope': scope,
      'termsAndConditions': termsAndConditions,
      'isActive': isActive,
      'sections': sections?.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        version,
        description,
        language,
        scope,
        termsAndConditions,
        isActive,
        sections,
      ];
}

@HiveType(typeId: 6)
class SurveyListResponse extends Equatable {
  @HiveField(0)
  final List<SurveyModel> items;

  @HiveField(1)
  final int total;

  const SurveyListResponse({
    required this.items,
    required this.total,
  });

  factory SurveyListResponse.fromJson(Map<String, dynamic> json) {
    return SurveyListResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => SurveyModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((e) => e.toJson()).toList(),
      'total': total,
    };
  }

  @override
  List<Object?> get props => [items, total];
}
