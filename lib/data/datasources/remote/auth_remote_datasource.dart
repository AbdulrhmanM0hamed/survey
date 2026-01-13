import 'package:survey/core/constants/api_endpoints.dart';
import 'package:survey/core/network/dio_client.dart';
import 'package:survey/data/models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String username, String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<UserModel> login(String username, String password) async {
    final response = await dioClient.post(
      ApiEndpoints.login,
      data: {
        'userName': username,
        'password': password,
      },
    );

    final responseData = response.data as Map<String, dynamic>;
    
    if (responseData['errorCode'] != 0) {
      throw Exception(responseData['errorMessage'] ?? 'فشل تسجيل الدخول');
    }

    return UserModel.fromJson(responseData);
  }
}
