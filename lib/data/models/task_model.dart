import 'package:equatable/equatable.dart';

class TaskModel extends Equatable {
  final int id;
  final String title;
  final double latitude;
  final double longitude;
  final DateTime taskDate;
  final bool isDone;
  final DateTime? completedAt;

  const TaskModel({
    required this.id,
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.taskDate,
    required this.isDone,
    this.completedAt,
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
    );
  }

  TaskModel copyWith({
    int? id,
    String? title,
    double? latitude,
    double? longitude,
    DateTime? taskDate,
    bool? isDone,
    DateTime? completedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      taskDate: taskDate ?? this.taskDate,
      isDone: isDone ?? this.isDone,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  List<Object?> get props => [id, title, latitude, longitude, taskDate, isDone, completedAt];
}
