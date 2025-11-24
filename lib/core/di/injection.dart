import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:survey/core/network/dio_client.dart';
import 'package:survey/data/datasources/local/survey_local_datasource.dart';
import 'package:survey/data/datasources/remote/survey_remote_datasource.dart';
import 'package:survey/data/repositories/survey_repository_impl.dart';
import 'package:survey/domain/repositories/survey_repository.dart';
import 'package:survey/presentation/screens/survey_details/viewmodel/survey_details_viewmodel.dart';
import 'package:survey/presentation/screens/surveys_list/viewmodel/surveys_list_viewmodel.dart';

class Injection {
  static late DioClient _dioClient;
  static late SurveyRemoteDataSource _remoteDataSource;
  static late SurveyLocalDataSource _localDataSource;
  static late SurveyRepository _surveyRepository;
  static late Connectivity _connectivity;

  static void init() {
    // Network
    _dioClient = DioClient();
    _connectivity = Connectivity();

    // DataSources
    _remoteDataSource = SurveyRemoteDataSourceImpl(dioClient: _dioClient);
    _localDataSource = SurveyLocalDataSourceImpl();

    // Repositories
    _surveyRepository = SurveyRepositoryImpl(
      remoteDataSource: _remoteDataSource,
      localDataSource: _localDataSource,
      connectivity: _connectivity,
    );
  }

  // ViewModels
  static SurveysListViewModel get surveysListViewModel =>
      SurveysListViewModel(repository: _surveyRepository);

  static SurveyDetailsViewModel get surveyDetailsViewModel =>
      SurveyDetailsViewModel(repository: _surveyRepository);

  // Repository
  static SurveyRepository get surveyRepository => _surveyRepository;
}
