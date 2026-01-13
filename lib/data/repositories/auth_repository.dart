import 'package:dartz/dartz.dart';
import 'package:survey/core/error/failures.dart';
import 'package:survey/core/storage/hive_service.dart';
import 'package:survey/data/datasources/remote/auth_remote_datasource.dart';
import 'package:survey/data/models/user_model.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserModel>> login(String username, String password);
  Future<void> logout();
  bool isLoggedIn();
  String? getToken();
  String? getUserName();
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, UserModel>> login(String username, String password) async {
    try {
      final user = await remoteDataSource.login(username, password);
      
      // Save auth data to local storage
      await HiveService.saveAuthData(
        token: user.token,
        userId: user.userId,
        fullName: user.fullName,
        userType: user.userType,
      );
      
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<void> logout() async {
    await HiveService.clearAuthData();
  }

  @override
  bool isLoggedIn() {
    return HiveService.isLoggedIn();
  }

  @override
  String? getToken() {
    return HiveService.getToken();
  }

  @override
  String? getUserName() {
    return HiveService.getUserName();
  }
}
