import 'dart:convert';
import 'package:survey/core/error/exceptions.dart';
import 'package:survey/core/storage/hive_service.dart';
import 'package:survey/data/models/answer_model.dart';
import 'package:survey/data/models/survey_model.dart';

abstract class SurveyLocalDataSource {
  Future<void> cacheSurveys(SurveyListResponse surveys);
  Future<SurveyListResponse?> getCachedSurveys();
  Future<void> cacheSurveyDetails(SurveyModel survey);
  Future<SurveyModel?> getCachedSurveyDetails(int surveyId);
  Future<void> saveAnswer(AnswerModel answer, int surveyId);
  Future<void> saveSurveyAnswers(SurveyAnswersModel surveyAnswers);
  Future<SurveyAnswersModel?> getSurveyAnswers(int surveyId);
  Future<List<SurveyAnswersModel>> getAllDraftAnswers();
  Future<void> deleteSurveyAnswers(int surveyId);
}

class SurveyLocalDataSourceImpl implements SurveyLocalDataSource {
  @override
  Future<void> cacheSurveys(SurveyListResponse surveys) async {
    try {
      final jsonString = jsonEncode(surveys.toJson());
      await HiveService.saveData(
        boxName: HiveService.surveysBox,
        key: 'surveys_list',
        value: jsonString,
      );
    } catch (e) {
      throw CacheException(message: 'فشل في حفظ الاستبيانات: ${e.toString()}');
    }
  }

  @override
  Future<SurveyListResponse?> getCachedSurveys() async {
    try {
      final jsonString = HiveService.getData<String>(
        boxName: HiveService.surveysBox,
        key: 'surveys_list',
      );

      if (jsonString == null) return null;

      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return SurveyListResponse.fromJson(jsonMap);
    } catch (e) {
      throw CacheException(message: 'فشل في جلب الاستبيانات المحفوظة: ${e.toString()}');
    }
  }

  @override
  Future<void> cacheSurveyDetails(SurveyModel survey) async {
    try {
      final jsonString = jsonEncode(survey.toJson());
      await HiveService.saveData(
        boxName: HiveService.surveyDetailsBox,
        key: 'survey_${survey.id}',
        value: jsonString,
      );
    } catch (e) {
      throw CacheException(
        message: 'فشل في حفظ تفاصيل الاستبيان: ${e.toString()}',
      );
    }
  }

  @override
  Future<SurveyModel?> getCachedSurveyDetails(int surveyId) async {
    try {
      final jsonString = HiveService.getData<String>(
        boxName: HiveService.surveyDetailsBox,
        key: 'survey_$surveyId',
      );

      if (jsonString == null) return null;

      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return SurveyModel.fromJson(jsonMap);
    } catch (e) {
      throw CacheException(
        message: 'فشل في جلب تفاصيل الاستبيان المحفوظة: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> saveAnswer(AnswerModel answer, int surveyId) async {
    try {
      // Get existing survey answers or create new
      var surveyAnswers = await getSurveyAnswers(surveyId);

      if (surveyAnswers == null) {
        surveyAnswers = SurveyAnswersModel(
          surveyId: surveyId,
          surveyCode: '', // Will be updated when survey details are available
          answers: [answer],
          startedAt: DateTime.now(),
          isDraft: true,
        );
      } else {
        // Update or add answer
        final existingIndex = surveyAnswers.answers.indexWhere(
          (a) =>
              a.questionId == answer.questionId &&
              a.groupInstanceId == answer.groupInstanceId,
        );

        List<AnswerModel> updatedAnswers;
        if (existingIndex != -1) {
          updatedAnswers = List.from(surveyAnswers.answers);
          updatedAnswers[existingIndex] = answer;
        } else {
          updatedAnswers = [...surveyAnswers.answers, answer];
        }

        surveyAnswers = surveyAnswers.copyWith(answers: updatedAnswers);
      }

      await saveSurveyAnswers(surveyAnswers);
    } catch (e) {
      throw CacheException(message: 'فشل في حفظ الإجابة: ${e.toString()}');
    }
  }

  @override
  Future<void> saveSurveyAnswers(SurveyAnswersModel surveyAnswers) async {
    try {
      final jsonString = jsonEncode(surveyAnswers.toJson());
      final boxName = surveyAnswers.isDraft
          ? HiveService.draftAnswersBox
          : HiveService.answersBox;

      await HiveService.saveData(
        boxName: boxName,
        key: 'survey_answers_${surveyAnswers.surveyId}',
        value: jsonString,
      );
    } catch (e) {
      throw CacheException(message: 'فشل في حفظ إجابات الاستبيان: ${e.toString()}');
    }
  }

  @override
  Future<SurveyAnswersModel?> getSurveyAnswers(int surveyId) async {
    try {
      // Try draft answers first
      var jsonString = HiveService.getData<String>(
        boxName: HiveService.draftAnswersBox,
        key: 'survey_answers_$surveyId',
      );

      // If not in draft, try completed answers
      jsonString ??= HiveService.getData<String>(
        boxName: HiveService.answersBox,
        key: 'survey_answers_$surveyId',
      );

      if (jsonString == null) return null;

      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return SurveyAnswersModel.fromJson(jsonMap);
    } catch (e) {
      throw CacheException(
        message: 'فشل في جلب إجابات الاستبيان: ${e.toString()}',
      );
    }
  }

  @override
  Future<List<SurveyAnswersModel>> getAllDraftAnswers() async {
    try {
      final keys = HiveService.getAllKeys(HiveService.draftAnswersBox);
      final List<SurveyAnswersModel> draftAnswers = [];

      for (final key in keys) {
        final jsonString = HiveService.getData<String>(
          boxName: HiveService.draftAnswersBox,
          key: key,
        );

        if (jsonString != null) {
          final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
          draftAnswers.add(SurveyAnswersModel.fromJson(jsonMap));
        }
      }

      return draftAnswers;
    } catch (e) {
      throw CacheException(
        message: 'فشل في جلب المسودات: ${e.toString()}',
      );
    }
  }

  @override
  Future<void> deleteSurveyAnswers(int surveyId) async {
    try {
      final key = 'survey_answers_$surveyId';

      // Delete from draft
      if (HiveService.containsKey(HiveService.draftAnswersBox, key)) {
        await HiveService.deleteData(
          boxName: HiveService.draftAnswersBox,
          key: key,
        );
      }

      // Delete from completed
      if (HiveService.containsKey(HiveService.answersBox, key)) {
        await HiveService.deleteData(
          boxName: HiveService.answersBox,
          key: key,
        );
      }
    } catch (e) {
      throw CacheException(message: 'فشل في حذف الإجابات: ${e.toString()}');
    }
  }
}
