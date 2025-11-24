import 'package:flutter/foundation.dart';
import 'package:survey/data/models/survey_model.dart';
import 'package:survey/domain/repositories/survey_repository.dart';

enum SurveysListState { initial, loading, loaded, error }

class SurveysListViewModel extends ChangeNotifier {
  final SurveyRepository repository;

  SurveysListViewModel({required this.repository});

  SurveysListState _state = SurveysListState.initial;
  SurveysListState get state => _state;

  List<SurveyModel> _surveys = [];
  List<SurveyModel> get surveys => _surveys;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _totalCount = 0;
  int get totalCount => _totalCount;

  Future<void> loadSurveys({bool forceRefresh = false}) async {
    _setState(SurveysListState.loading);

    final result = await repository.getSurveys(forceRefresh: forceRefresh);

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setState(SurveysListState.error);
      },
      (surveyList) {
        _surveys = surveyList.items;
        _totalCount = surveyList.total;
        _errorMessage = null;
        _setState(SurveysListState.loaded);
      },
    );
  }

  Future<void> refresh() async {
    await loadSurveys(forceRefresh: true);
  }

  void _setState(SurveysListState newState) {
    _state = newState;
    notifyListeners();
  }
}
