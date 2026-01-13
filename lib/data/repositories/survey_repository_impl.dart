import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:survey/core/error/exceptions.dart';
import 'package:survey/core/error/failures.dart';
import 'package:survey/data/datasources/local/survey_local_datasource.dart';
import 'package:survey/data/datasources/remote/survey_remote_datasource.dart';
import 'package:survey/data/models/answer_model.dart';
import 'package:survey/data/models/survey_model.dart';
import 'package:survey/domain/repositories/survey_repository.dart';

class SurveyRepositoryImpl implements SurveyRepository {
  final SurveyRemoteDataSource remoteDataSource;
  final SurveyLocalDataSource localDataSource;
  final Connectivity connectivity;

  SurveyRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.connectivity,
  });

  Future<bool> _hasConnection() async {
    try {
      final result = await connectivity.checkConnectivity();
      print('📶 Connectivity check result: $result');
      
      // Check if any connectivity is available
      final hasConnection = result.isNotEmpty && 
          !result.contains(ConnectivityResult.none);
      
      print('📶 Has connection: $hasConnection');
      return hasConnection;
    } catch (e) {
      print('⚠️ Connectivity check failed: $e, assuming connected');
      return true; // Assume connected if check fails
    }
  }

  @override
  Future<Either<Failure, SurveyListResponse>> getSurveys({
    bool forceRefresh = false,
  }) async {
    try {
      final hasConnection = await _hasConnection();

      if (!hasConnection && !forceRefresh) {
        // Return cached data if no connection
        final cachedSurveys = await localDataSource.getCachedSurveys();
        if (cachedSurveys != null) {
          return Right(cachedSurveys);
        } else {
          return const Left(
            NetworkFailure(message: 'لا يوجد اتصال بالإنترنت ولا توجد بيانات محفوظة'),
          );
        }
      }

      // Fetch from remote
      final surveys = await remoteDataSource.getSurveys();

      // Cache the result
      await localDataSource.cacheSurveys(surveys);

      return Right(surveys);
    } on ServerException catch (e) {
      // Try to return cached data on server error
      final cachedSurveys = await localDataSource.getCachedSurveys();
      if (cachedSurveys != null) {
        return Right(cachedSurveys);
      }
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      // Try to return cached data on network error
      final cachedSurveys = await localDataSource.getCachedSurveys();
      if (cachedSurveys != null) {
        return Right(cachedSurveys);
      }
      return Left(NetworkFailure(message: e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, SurveyModel>> getSurveyById({
    required int id,
    bool forceRefresh = false,
  }) async {
    try {
      final hasConnection = await _hasConnection();
      print('🔍 getSurveyById($id): hasConnection=$hasConnection, forceRefresh=$forceRefresh');

      // Always try to fetch from remote first
      try {
        print('🌐 Fetching survey $id from remote...');
        final survey = await remoteDataSource.getSurveyById(id);
        print('✅ Successfully fetched survey from remote');

        // Cache the result
        await localDataSource.cacheSurveyDetails(survey);

        return Right(survey);
      } catch (e) {
        print('⚠️ Remote fetch failed: $e');
        // If remote fails, try cache
        final cachedSurvey = await localDataSource.getCachedSurveyDetails(id);
        if (cachedSurvey != null) {
          print('📦 Returning cached survey');
          return Right(cachedSurvey);
        }
        // No cache available, return the error
        if (e is ServerException) {
          return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
        } else if (e is NetworkException) {
          return Left(NetworkFailure(message: e.message));
        }
        return Left(ServerFailure(message: 'فشل تحميل البيانات: ${e.toString()}'));
      }
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      print('❌ Unknown error in getSurveyById: $e');
      return Left(ServerFailure(message: 'فشل تحميل البيانات: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> saveAnswer({
    required AnswerModel answer,
    required int surveyId,
  }) async {
    try {
      await localDataSource.saveAnswer(answer, surveyId);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: 'حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> saveSurveyAnswers({
    required SurveyAnswersModel surveyAnswers,
  }) async {
    try {
      await localDataSource.saveSurveyAnswers(surveyAnswers);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: 'حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, SurveyAnswersModel?>> getSurveyAnswers({
    required int surveyId,
  }) async {
    try {
      final answers = await localDataSource.getSurveyAnswers(surveyId);
      return Right(answers);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: 'حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<SurveyAnswersModel>>> getAllDraftAnswers() async {
    try {
      final drafts = await localDataSource.getAllDraftAnswers();
      return Right(drafts);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: 'حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<SurveyAnswersModel>>> getAllCompletedAnswers() async {
    try {
      final completedAnswers = await localDataSource.getAllCompletedAnswers();
      return Right(completedAnswers);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: 'حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSurveyAnswers({
    required int surveyId,
  }) async {
    try {
      await localDataSource.deleteSurveyAnswers(surveyId);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: 'حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCompletedSurveyAnswer(String key) async {
    try {
      await localDataSource.deleteCompletedSurveyAnswer(key);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: 'حدث خطأ غير متوقع: ${e.toString()}'));
    }
  }
}
