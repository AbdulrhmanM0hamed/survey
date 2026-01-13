import 'package:dartz/dartz.dart';
import 'package:survey/core/error/failures.dart';
import 'package:survey/data/datasources/remote/task_remote_datasource.dart';
import 'package:survey/data/models/task_model.dart';

abstract class TaskRepository {
  Future<Either<Failure, List<TaskModel>>> getTasks();
  Future<Either<Failure, bool>> completeTask(int taskId);
}

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource remoteDataSource;

  TaskRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<TaskModel>>> getTasks() async {
    try {
      final tasks = await remoteDataSource.getTasks();
      return Right(tasks);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> completeTask(int taskId) async {
    try {
      final result = await remoteDataSource.completeTask(taskId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
