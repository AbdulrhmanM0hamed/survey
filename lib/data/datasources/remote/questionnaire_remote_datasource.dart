import 'package:dio/dio.dart';
import 'package:survey/data/models/answer_model.dart';

abstract class QuestionnaireRemoteDataSource {
  Future<bool> submitQuestionnaire(Map<String, dynamic> questionnaireData);
}

class QuestionnaireRemoteDataSourceImpl implements QuestionnaireRemoteDataSource {
  final Dio dio;

  QuestionnaireRemoteDataSourceImpl({required this.dio});

  @override
  Future<bool> submitQuestionnaire(Map<String, dynamic> questionnaireData) async {
    try {
      print('📤 Submitting questionnaire to API...');
      print('Data: ${questionnaireData}');
      
      final response = await dio.post(
        '/Questionnaire/save',
        data: questionnaireData,
      );

      if (response.statusCode == 200) {
        print('✅ Questionnaire submitted successfully');
        return true;
      }

      print('⚠️ Unexpected status code: ${response.statusCode}');
      return false;
    } on DioException catch (e) {
      print('❌ Error submitting questionnaire: ${e.message}');
      if (e.response != null) {
        print('Response data: ${e.response?.data}');
        print('Response status: ${e.response?.statusCode}');
      }
      throw Exception('Failed to submit questionnaire: ${e.message}');
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('Failed to submit questionnaire: $e');
    }
  }

  /// Convert SurveyAnswersModel to API format
  static Map<String, dynamic> convertToApiFormat(SurveyAnswersModel surveyAnswers) {
    return {
      "surveyId": surveyAnswers.surveyId,
      "householdCode": surveyAnswers.surveyCode,
      "managementInformationIds": _extractManagementIds(surveyAnswers),
      "neighborhoodName": surveyAnswers.neighborhoodName ?? "",
      "streetName": surveyAnswers.streetName ?? "",
      "isApproved": surveyAnswers.isApproved ?? true,
      "rejectReason": surveyAnswers.rejectReason ?? "",
      "interviewDate": surveyAnswers.completedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      "startAt": surveyAnswers.startedAt.toIso8601String(),
      "endAt": surveyAnswers.completedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      "status": surveyAnswers.isDraft ? "Draft" : "Completed",
      "answers": surveyAnswers.answers.map((answer) => _convertAnswer(answer)).toList(),
    };
  }

  static List<int> _extractManagementIds(SurveyAnswersModel surveyAnswers) {
    // Extract IDs from researcher, supervisor, city names if available
    // For now, return empty list - you can enhance this later
    return [];
  }

  static Map<String, dynamic> _convertAnswer(AnswerModel answer) {
    final answerMap = {
      "questionId": answer.questionId,
      "questionType": answer.questionType ?? 0, // Use stored type or default to Text (0)
      "groupId": answer.groupId, // null for non-grouped questions
      "repeatIndex": answer.groupInstanceId, // null for non-repeating groups
      "valueText": null,
      "valueNumber": null,
      "valueDate": null,
      "valueCode": null,
      "imageBase64": null,
      "selectedChoices": [],
    };

    // Add value based on question type
    if (answer.value == null) {
      // Keep all fields null/empty
      return answerMap;
    }
    
    final qType = answer.questionType ?? 0;
    
    if (qType == 0) {
      // Text
      answerMap["valueText"] = answer.value.toString();
    } else if (qType == 1 || qType == 2 || qType == 6) {
      // Integer, Decimal, Rating
      answerMap["valueNumber"] = answer.value is num 
          ? answer.value 
          : num.tryParse(answer.value.toString()) ?? 0;
    } else if (qType == 3) {
      // YesNo
      answerMap["valueCode"] = answer.value.toString();
    } else if (qType == 4 || qType == 5) {
      // SingleChoice, MultiChoice
      if (answer.value is List) {
        answerMap["selectedChoices"] = (answer.value as List).map((choiceId) {
          return {
            "choiceId": choiceId is int ? choiceId : int.tryParse(choiceId.toString()) ?? 0,
            "otherText": null
          };
        }).toList();
      } else if (answer.value is int) {
        // Single choice stored as int
        answerMap["selectedChoices"] = [{
          "choiceId": answer.value,
          "otherText": null
        }];
      }
    } else if (qType == 7) {
      // Date
      if (answer.value is DateTime) {
        answerMap["valueDate"] = (answer.value as DateTime).toIso8601String();
      } else {
        answerMap["valueDate"] = answer.value.toString();
      }
    } else if (qType == 8) {
      // Duration
      answerMap["valueText"] = answer.value.toString();
    } else if (qType == 9) {
      // Image
      answerMap["imageBase64"] = answer.value.toString();
    } else {
      // Fallback: treat as text
      answerMap["valueText"] = answer.value.toString();
    }

    return answerMap;
  }
}
