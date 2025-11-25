import 'package:dartz/dartz.dart';
import 'package:survey/core/error/failures.dart';
import 'package:survey/data/models/answer_model.dart';
import 'package:survey/data/models/survey_model.dart';

abstract class SurveyRepository {
  Future<Either<Failure, SurveyListResponse>> getSurveys({
    bool forceRefresh = false,
  });

  Future<Either<Failure, SurveyModel>> getSurveyById({
    required int id,
    bool forceRefresh = false,
  });

  Future<Either<Failure, void>> saveAnswer({
    required AnswerModel answer,
    required int surveyId,
  });

  Future<Either<Failure, void>> saveSurveyAnswers({
    required SurveyAnswersModel surveyAnswers,
  });

  Future<Either<Failure, SurveyAnswersModel?>> getSurveyAnswers({
    required int surveyId,
  });

  Future<Either<Failure, List<SurveyAnswersModel>>> getAllDraftAnswers();

  Future<Either<Failure, List<SurveyAnswersModel>>> getAllCompletedAnswers();

  Future<Either<Failure, void>> deleteSurveyAnswers({
    required int surveyId,
  });

  Future<Either<Failure, void>> deleteCompletedSurveyAnswer(String key);
}
