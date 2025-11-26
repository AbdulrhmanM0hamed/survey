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
    // Determine question type from value type
    String questionType = "Text"; // Default
    
    if (answer.value is num || answer.value is int || answer.value is double) {
      questionType = "Number";
    } else if (answer.value is DateTime) {
      questionType = "Date";
    } else if (answer.value is bool) {
      questionType = "YesNo";
    } else if (answer.value is List) {
      questionType = "Choice";
    }

    final answerMap = {
      "questionId": answer.questionId,
      "questionType": questionType,
      "groupId": 0, // No groupId in AnswerModel
      "repeatIndex": answer.groupInstanceId ?? 0,
      "valueText": null,
      "valueNumber": null,
      "valueDate": null,
      "valueCode": null,
      "imageBase64": null,
      "selectedChoices": null,
    };

    // Add value based on detected type
    if (answer.value == null) {
      answerMap["valueText"] = "";
    } else if (answer.value is num || answer.value is int || answer.value is double) {
      answerMap["valueNumber"] = answer.value;
      answerMap["questionType"] = "Number";
    } else if (answer.value is DateTime) {
      answerMap["valueDate"] = (answer.value as DateTime).toIso8601String();
      answerMap["questionType"] = "Date";
    } else if (answer.value is bool) {
      answerMap["valueCode"] = answer.value.toString();
      answerMap["questionType"] = "YesNo";
    } else if (answer.value is List) {
      answerMap["selectedChoices"] = (answer.value as List).map((choiceId) {
        return {
          "choiceId": choiceId is int ? choiceId : int.tryParse(choiceId.toString()) ?? 0,
          "otherText": ""
        };
      }).toList();
      answerMap["questionType"] = "Choice";
    } else {
      // String or other types
      final valueStr = answer.value.toString();
      
      // Check if it's a base64 image (starts with common base64 image prefixes or is very long)
      if (valueStr.length > 1000 && !valueStr.contains(' ')) {
        // Likely a base64 image
        answerMap["imageBase64"] = valueStr;
        answerMap["questionType"] = "Image";
      } else {
        // Regular text
        answerMap["valueText"] = valueStr;
      }
    }

    return answerMap;
  }
}
