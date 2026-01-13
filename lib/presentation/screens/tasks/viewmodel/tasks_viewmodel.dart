import 'package:flutter/foundation.dart';
import 'package:survey/data/models/task_model.dart';
import 'package:survey/data/repositories/task_repository.dart';

enum TasksState { initial, loading, loaded, error }

class TasksViewModel extends ChangeNotifier {
  final TaskRepository repository;

  TasksViewModel({required this.repository});

  TasksState _state = TasksState.initial;
  List<TaskModel> _tasks = [];
  String? _errorMessage;
  int? _completingTaskId;

  TasksState get state => _state;
  List<TaskModel> get tasks => _tasks;
  String? get errorMessage => _errorMessage;
  int? get completingTaskId => _completingTaskId;

  Future<void> loadTasks() async {
    _state = TasksState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await repository.getTasks();

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _state = TasksState.error;
      },
      (tasks) {
        _tasks = tasks;
        _state = TasksState.loaded;
      },
    );

    notifyListeners();
  }

  Future<bool> completeTask(int taskId) async {
    _completingTaskId = taskId;
    notifyListeners();

    final result = await repository.completeTask(taskId);

    bool success = false;
    result.fold(
      (failure) {
        _errorMessage = failure.message;
        success = false;
      },
      (_) {
        // Update local task state
        final index = _tasks.indexWhere((t) => t.id == taskId);
        if (index != -1) {
          _tasks[index] = _tasks[index].copyWith(
            isDone: true,
            completedAt: DateTime.now(),
          );
        }
        success = true;
      },
    );

    _completingTaskId = null;
    notifyListeners();
    return success;
  }
}
