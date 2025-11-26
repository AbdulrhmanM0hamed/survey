import 'package:equatable/equatable.dart';

enum ManagementInformationType {
  researcherName(1),
  supervisorName(2),
  cityName(3);

  final int value;
  const ManagementInformationType(this.value);

  static ManagementInformationType fromValue(int value) {
    return ManagementInformationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ManagementInformationType.researcherName,
    );
  }
}

class ManagementInformationModel extends Equatable {
  final int id;
  final String name;
  final ManagementInformationType type;
  final bool isActive;
  final int usageCount;

  const ManagementInformationModel({
    required this.id,
    required this.name,
    required this.type,
    required this.isActive,
    required this.usageCount,
  });

  factory ManagementInformationModel.fromJson(Map<String, dynamic> json) {
    return ManagementInformationModel(
      id: json['id'] as int,
      name: json['name'] as String,
      type: ManagementInformationType.fromValue(json['managementInformationType'] as int),
      isActive: json['isActive'] as bool,
      usageCount: json['usageCount'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'managementInformationType': type.value,
      'isActive': isActive,
      'usageCount': usageCount,
    };
  }

  @override
  List<Object?> get props => [id, name, type, isActive, usageCount];
}

class ManagementInformationResponse extends Equatable {
  final List<ManagementInformationModel> items;
  final int total;

  const ManagementInformationResponse({
    required this.items,
    required this.total,
  });

  factory ManagementInformationResponse.fromJson(Map<String, dynamic> json) {
    return ManagementInformationResponse(
      items: (json['items'] as List)
          .map((item) => ManagementInformationModel.fromJson(item))
          .toList(),
      total: json['total'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'total': total,
    };
  }

  @override
  List<Object?> get props => [items, total];
}
