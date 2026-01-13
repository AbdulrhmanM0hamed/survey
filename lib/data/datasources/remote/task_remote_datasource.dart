import 'package:survey/core/network/dio_client.dart';
import 'package:survey/data/models/task_model.dart';

abstract class TaskRemoteDataSource {
  Future<List<TaskModel>> getTasks();
  Future<bool> completeTask(int taskId);
}

class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {
  final DioClient dioClient;

  TaskRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<TaskModel>> getTasks() async {
    final response = await dioClient.get('/researcher/tasks');

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['errorCode'] == 0) {
        final List<dynamic> tasksJson = data['data'] ?? [];
        return tasksJson.map((json) => TaskModel.fromJson(json)).toList();
      } else {
        throw Exception(data['errorMessage'] ?? 'فشل تحميل المواقع');
      }
    } else {
      throw Exception('فشل تحميل المواقع');
    }
  }

  @override
  Future<bool> completeTask(int taskId) async {
    final response = await dioClient.post('/researcher/tasks/$taskId/complete');

    if (response.statusCode == 200) {
      final data = response.data;
      if (data['errorCode'] == 0) {
        return true;
      } else {
        throw Exception(data['errorMessage'] ?? 'فشل تأكيد الزيارة');
      }
    } else {
      throw Exception('فشل تأكيد الزيارة');
    }
  }
}
