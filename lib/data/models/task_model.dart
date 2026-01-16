import 'package:equatable/equatable.dart';

class TaskModel extends Equatable {
  final int id;
  final String title;
  final double latitude;
  final double longitude;
  final DateTime taskDate;
  final bool isDone;
  final DateTime? completedAt;
  final bool isLocallyCompleted; // Flag for offline completion

  const TaskModel({
    required this.id,
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.taskDate,
    required this.isDone,
    this.completedAt,
    this.isLocallyCompleted = false,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      taskDate: json['taskDate'] != null
          ? DateTime.parse(json['taskDate'])
          : DateTime.now(),
      isDone: json['isDone'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      isLocallyCompleted: json['isLocallyCompleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'latitude': latitude,
      'longitude': longitude,
      'taskDate': taskDate.toIso8601String(),
      'isDone': isDone,
      'completedAt': completedAt?.toIso8601String(),
      'isLocallyCompleted': isLocallyCompleted,
    };
  }

  TaskModel copyWith({
    int? id,
    String? title,
    double? latitude,
    double? longitude,
    DateTime? taskDate,
    bool? isDone,
    DateTime? completedAt,
    bool? isLocallyCompleted,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      taskDate: taskDate ?? this.taskDate,
      isDone: isDone ?? this.isDone,
      completedAt: completedAt ?? this.completedAt,
      isLocallyCompleted: isLocallyCompleted ?? this.isLocallyCompleted,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        latitude,
        longitude,
        taskDate,
        isDone,
        completedAt,
        isLocallyCompleted,
      ];
}
