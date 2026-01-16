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
  bool _isSyncing = false;
  int _pendingSyncCount = 0;

  TasksState get state => _state;
  List<TaskModel> get tasks => _tasks;
  String? get errorMessage => _errorMessage;
  int? get completingTaskId => _completingTaskId;
  bool get isSyncing => _isSyncing;
  int get pendingSyncCount => _pendingSyncCount;

  Future<void> loadTasks() async {
    _state = TasksState.loading;
    _errorMessage = null;
    notifyListeners();

    // Try to sync pending completions first
    await _syncPendingCompletions();

    final result = await repository.getTasks();

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _state = TasksState.error;
      },
      (tasks) {
        _tasks = tasks;
        _state = TasksState.loaded;
        _updatePendingSyncCount();
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
            isLocallyCompleted: true,
          );
        }
        _updatePendingSyncCount();
        success = true;
      },
    );

    _completingTaskId = null;
    notifyListeners();
    return success;
  }

  Future<void> _syncPendingCompletions() async {
    if (_isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      print('🔄 Starting auto-sync of pending task completions...');
      final result = await repository.syncPendingCompletions();
      
      result.fold(
        (failure) {
          print('⚠️ Auto-sync failed: ${failure.message}');
        },
        (syncedCount) {
          if (syncedCount > 0) {
            print('✅ Auto-synced $syncedCount pending task completions');
          }
        },
      );
    } catch (e) {
      print('❌ Error during auto-sync: $e');
    } finally {
      _isSyncing = false;
    }
  }

  void _updatePendingSyncCount() {
    _pendingSyncCount = _tasks.where((t) => t.isLocallyCompleted).length;
  }

  Future<Map<String, dynamic>> manualSync() async {
    if (_isSyncing) {
      return {
        'success': false,
        'message': 'المزامنة جارية بالفعل',
      };
    }

    _isSyncing = true;
    notifyListeners();

    try {
      final result = await repository.syncPendingCompletions();
      
      return result.fold(
        (failure) {
          _isSyncing = false;
          notifyListeners();
          return {
            'success': false,
            'message': failure.message,
          };
        },
        (syncedCount) async {
          _isSyncing = false;
          
          // Reload tasks to get updated status
          await loadTasks();
          
          return {
            'success': true,
            'syncedCount': syncedCount,
            'message': syncedCount > 0
                ? 'تم مزامنة $syncedCount مهمة بنجاح'
                : 'لا توجد مهام معلقة للمزامنة',
          };
        },
      );
    } catch (e) {
      _isSyncing = false;
      notifyListeners();
      return {
        'success': false,
        'message': 'حدث خطأ: $e',
      };
    }
  }
}
