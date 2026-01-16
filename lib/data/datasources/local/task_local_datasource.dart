import 'dart:convert';
import 'package:survey/core/storage/hive_service.dart';
import 'package:survey/data/models/task_model.dart';

abstract class TaskLocalDataSource {
  Future<void> cacheTasks(List<TaskModel> tasks);
  Future<List<TaskModel>> getCachedTasks();
  Future<void> markTaskAsCompleted(int taskId, DateTime completedAt);
  Future<List<TaskModel>> getPendingCompletedTasks();
  Future<void> clearPendingTask(int taskId);
}

class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  static const String _tasksKey = 'cached_tasks';
  static const String _pendingCompletionsKey = 'pending_task_completions';

  @override
  Future<void> cacheTasks(List<TaskModel> tasks) async {
    try {
      final jsonString = jsonEncode(
        tasks.map((task) => task.toJson()).toList(),
      );
      await HiveService.saveData(
        boxName: HiveService.surveysBox,
        key: _tasksKey,
        value: jsonString,
      );
      print('📦 Cached ${tasks.length} tasks');
    } catch (e) {
      print('❌ Failed to cache tasks: $e');
    }
  }

  @override
  Future<List<TaskModel>> getCachedTasks() async {
    try {
      final jsonString = HiveService.getData<String>(
        boxName: HiveService.surveysBox,
        key: _tasksKey,
      );

      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final tasks = jsonList.map((json) => TaskModel.fromJson(json)).toList();
      print('📦 Retrieved ${tasks.length} cached tasks');
      return tasks;
    } catch (e) {
      print('❌ Failed to get cached tasks: $e');
      return [];
    }
  }

  @override
  Future<void> markTaskAsCompleted(int taskId, DateTime completedAt) async {
    try {
      // Get current cached tasks
      final tasks = await getCachedTasks();
      
      // Update the specific task
      final updatedTasks = tasks.map((task) {
        if (task.id == taskId) {
          return task.copyWith(
            isDone: true,
            completedAt: completedAt,
            isLocallyCompleted: true,
          );
        }
        return task;
      }).toList();

      // Save updated tasks
      await cacheTasks(updatedTasks);

      // Add to pending completions for sync
      await _addPendingCompletion(taskId, completedAt);
      
      print('✅ Marked task $taskId as completed locally');
    } catch (e) {
      print('❌ Failed to mark task as completed: $e');
    }
  }

  Future<void> _addPendingCompletion(int taskId, DateTime completedAt) async {
    try {
      final pending = await getPendingCompletedTasks();
      
      // Check if already exists
      if (pending.any((t) => t.id == taskId)) {
        print('⚠️ Task $taskId already in pending completions');
        return;
      }

      // Get the task details
      final tasks = await getCachedTasks();
      final task = tasks.firstWhere((t) => t.id == taskId);
      
      pending.add(task.copyWith(
        isDone: true,
        completedAt: completedAt,
        isLocallyCompleted: true,
      ));

      final jsonString = jsonEncode(
        pending.map((task) => task.toJson()).toList(),
      );
      await HiveService.saveData(
        boxName: HiveService.surveysBox,
        key: _pendingCompletionsKey,
        value: jsonString,
      );
      
      print('📝 Added task $taskId to pending completions (${pending.length} total)');
    } catch (e) {
      print('❌ Failed to add pending completion: $e');
    }
  }

  @override
  Future<List<TaskModel>> getPendingCompletedTasks() async {
    try {
      final jsonString = HiveService.getData<String>(
        boxName: HiveService.surveysBox,
        key: _pendingCompletionsKey,
      );

      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      final tasks = jsonList.map((json) => TaskModel.fromJson(json)).toList();
      print('📋 Retrieved ${tasks.length} pending task completions');
      return tasks;
    } catch (e) {
      print('❌ Failed to get pending completions: $e');
      return [];
    }
  }

  @override
  Future<void> clearPendingTask(int taskId) async {
    try {
      final pending = await getPendingCompletedTasks();
      final updated = pending.where((t) => t.id != taskId).toList();

      if (updated.isEmpty) {
        await HiveService.deleteData(
          boxName: HiveService.surveysBox,
          key: _pendingCompletionsKey,
        );
      } else {
        final jsonString = jsonEncode(
          updated.map((task) => task.toJson()).toList(),
        );
        await HiveService.saveData(
          boxName: HiveService.surveysBox,
          key: _pendingCompletionsKey,
          value: jsonString,
        );
      }
      
      print('🗑️ Cleared pending task $taskId (${updated.length} remaining)');
    } catch (e) {
      print('❌ Failed to clear pending task: $e');
    }
  }
}
