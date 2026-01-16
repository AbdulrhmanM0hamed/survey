import 'package:dartz/dartz.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:survey/core/error/failures.dart';
import 'package:survey/data/datasources/remote/task_remote_datasource.dart';
import 'package:survey/data/datasources/local/task_local_datasource.dart';
import 'package:survey/data/models/task_model.dart';

abstract class TaskRepository {
  Future<Either<Failure, List<TaskModel>>> getTasks();
  Future<Either<Failure, bool>> completeTask(int taskId);
  Future<Either<Failure, int>> syncPendingCompletions();
}

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;
  final TaskLocalDataSource localDataSource;

  TaskRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  Future<bool> _hasConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi) ||
        connectivityResult.contains(ConnectivityResult.ethernet);
  }

  @override
  Future<Either<Failure, List<TaskModel>>> getTasks() async {
    try {
      final hasConnection = await _hasConnection();

      if (hasConnection) {
        try {
          print('🌐 Fetching tasks from server...');
          final tasks = await remoteDataSource.getTasks();
          
          // Cache the tasks
          await localDataSource.cacheTasks(tasks);
          
          // Merge with local completion status
          final cachedTasks = await localDataSource.getCachedTasks();
          final mergedTasks = tasks.map((serverTask) {
            final cachedTask = cachedTasks.firstWhere(
              (t) => t.id == serverTask.id,
              orElse: () => serverTask,
            );
            
            // If locally completed but not on server, keep local status
            if (cachedTask.isLocallyCompleted && !serverTask.isDone) {
              return serverTask.copyWith(
                isDone: true,
                completedAt: cachedTask.completedAt,
                isLocallyCompleted: true,
              );
            }
            
            return serverTask;
          }).toList();
          
          print('✅ Fetched ${mergedTasks.length} tasks from server');
          return Right(mergedTasks);
        } catch (e) {
          print('⚠️ Server fetch failed, using cache: $e');
          final cachedTasks = await localDataSource.getCachedTasks();
          if (cachedTasks.isNotEmpty) {
            return Right(cachedTasks);
          }
          return Left(ServerFailure(message: e.toString()));
        }
      } else {
        print('📴 No connection, using cached tasks');
        final cachedTasks = await localDataSource.getCachedTasks();
        if (cachedTasks.isEmpty) {
          return Left(ServerFailure(message: 'لا يوجد اتصال بالإنترنت ولا توجد بيانات محفوظة'));
        }
        return Right(cachedTasks);
      }
    } catch (e) {
      print('❌ Error in getTasks: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> completeTask(int taskId) async {
    try {
      final hasConnection = await _hasConnection();
      final completedAt = DateTime.now();

      // Always mark as completed locally first
      await localDataSource.markTaskAsCompleted(taskId, completedAt);
      print('✅ Task $taskId marked as completed locally');

      if (hasConnection) {
        try {
          print('🌐 Syncing task $taskId completion to server...');
          final result = await remoteDataSource.completeTask(taskId);
          
          if (result) {
            // Remove from pending since it's synced
            await localDataSource.clearPendingTask(taskId);
            print('✅ Task $taskId synced to server');
          }
          
          return Right(result);
        } catch (e) {
          print('⚠️ Failed to sync to server, will retry later: $e');
          // Still return success since it's saved locally
          return const Right(true);
        }
      } else {
        print('📴 No connection, task $taskId will be synced later');
        return const Right(true);
      }
    } catch (e) {
      print('❌ Error completing task: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> syncPendingCompletions() async {
    try {
      final hasConnection = await _hasConnection();
      
      if (!hasConnection) {
        print('📴 No connection, skipping sync');
        return const Right(0);
      }

      final pendingTasks = await localDataSource.getPendingCompletedTasks();
      
      if (pendingTasks.isEmpty) {
        print('✅ No pending tasks to sync');
        return const Right(0);
      }

      print('🔄 Syncing ${pendingTasks.length} pending task completions...');
      int syncedCount = 0;

      for (final task in pendingTasks) {
        try {
          final result = await remoteDataSource.completeTask(task.id);
          if (result) {
            await localDataSource.clearPendingTask(task.id);
            syncedCount++;
            print('✅ Synced task ${task.id}');
          }
        } catch (e) {
          print('⚠️ Failed to sync task ${task.id}: $e');
        }
      }

      print('✅ Synced $syncedCount/${pendingTasks.length} pending tasks');
      return Right(syncedCount);
    } catch (e) {
      print('❌ Error syncing pending completions: $e');
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
