import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:survey/core/network/dio_client.dart';
import 'package:survey/data/datasources/local/survey_local_datasource.dart';
import 'package:survey/data/datasources/local/task_local_datasource.dart';
import 'package:survey/data/datasources/remote/auth_remote_datasource.dart';
import 'package:survey/data/datasources/remote/survey_remote_datasource.dart';
import 'package:survey/data/datasources/remote/task_remote_datasource.dart';
import 'package:survey/data/repositories/auth_repository.dart';
import 'package:survey/data/repositories/survey_repository_impl.dart';
import 'package:survey/data/repositories/task_repository.dart';
import 'package:survey/domain/repositories/survey_repository.dart';
import 'package:survey/presentation/screens/login/viewmodel/login_viewmodel.dart';
import 'package:survey/presentation/screens/survey_details/viewmodel/survey_details_viewmodel.dart';
import 'package:survey/presentation/screens/surveys_list/viewmodel/surveys_list_viewmodel.dart';
import 'package:survey/presentation/screens/tasks/viewmodel/tasks_viewmodel.dart';

class Injection {
  static late DioClient _dioClient;
  static late SurveyRemoteDataSource _remoteDataSource;
  static late SurveyLocalDataSource _localDataSource;
  static late SurveyRepository _surveyRepository;
  static late Connectivity _connectivity;
  static late AuthRemoteDataSource _authRemoteDataSource;
  static late AuthRepository _authRepository;
  static late TaskRemoteDataSource _taskRemoteDataSource;
  static late TaskLocalDataSource _taskLocalDataSource;
  static late TaskRepository _taskRepository;

  static void init() {
    // Network
    _dioClient = DioClient();
    _connectivity = Connectivity();

    // DataSources
    _remoteDataSource = SurveyRemoteDataSourceImpl(dioClient: _dioClient);
    _localDataSource = SurveyLocalDataSourceImpl();
    _authRemoteDataSource = AuthRemoteDataSourceImpl(dioClient: _dioClient);
    _taskRemoteDataSource = TaskRemoteDataSourceImpl(dioClient: _dioClient);
    _taskLocalDataSource = TaskLocalDataSourceImpl();

    // Repositories
    _surveyRepository = SurveyRepositoryImpl(
      remoteDataSource: _remoteDataSource,
      localDataSource: _localDataSource,
      connectivity: _connectivity,
    );
    _authRepository = AuthRepositoryImpl(remoteDataSource: _authRemoteDataSource);
    _taskRepository = TaskRepositoryImpl(
      remoteDataSource: _taskRemoteDataSource,
      localDataSource: _taskLocalDataSource,
    );
  }

  // DioClient (for other screens that need it)
  static DioClient get dioClient => _dioClient;

  // ViewModels
  static SurveysListViewModel get surveysListViewModel =>
      SurveysListViewModel(repository: _surveyRepository);

  static SurveyDetailsViewModel get surveyDetailsViewModel =>
      SurveyDetailsViewModel(repository: _surveyRepository);

  static LoginViewModel get loginViewModel =>
      LoginViewModel(repository: _authRepository);

  static TasksViewModel get tasksViewModel =>
      TasksViewModel(repository: _taskRepository);

  // Repositories
  static SurveyRepository get surveyRepository => _surveyRepository;
  static AuthRepository get authRepository => _authRepository;
  static TaskRepository get taskRepository => _taskRepository;
}
