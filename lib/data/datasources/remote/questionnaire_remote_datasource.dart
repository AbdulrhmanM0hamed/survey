import 'package:dio/dio.dart';
import 'package:survey/data/models/answer_model.dart'; // Contains both AnswerModel and SurveyAnswersModel

abstract class QuestionnaireRemoteDataSource {
  Future<dynamic> submitQuestionnaire(Map<String, dynamic> questionnaireData);
}

class QuestionnaireRemoteDataSourceImpl
    implements QuestionnaireRemoteDataSource {
  final Dio dio;

  QuestionnaireRemoteDataSourceImpl({required this.dio});

  @override
  Future<dynamic> submitQuestionnaire(
    Map<String, dynamic> questionnaireData,
  ) async {
    try {
      ////print('📤 Submitting questionnaire to API...');
      ////print('Data: ${questionnaireData}');

      // ////print main data
      ////print('📊 Survey Data:');
      ////print('  surveyId: ${questionnaireData['surveyId']}');
      ////print('  householdCode: ${questionnaireData['householdCode']}');
      ////print('  managementInformationIds: ${questionnaireData['managementInformationIds']}');
      ////print('  isApproved: ${questionnaireData['isApproved']}');
      ////print('  rejectReason: "${questionnaireData['rejectReason']}"');
      ////print('  startAt: ${questionnaireData['startAt']}');
      ////print('  endAt: ${questionnaireData['endAt']}');
      ////print('  status: ${questionnaireData['status']}');
      ////print('  answers count: ${(questionnaireData['answers'] as List).length}');

      // ////print each answer separately
      ////print('\n📝 Answers:');
      final answers = questionnaireData['answers'] as List;
      for (var i = 0; i < answers.length; i++) {
        final answer = answers[i];
        ////print('  Answer ${i + 1}:');
        ////print('    questionId: ${answer['questionId']}');
        ////print('    questionType: ${answer['questionType']}');
        ////print('    groupId: ${answer['groupId']}');
        ////print('    repeatIndex: ${answer['repeatIndex']}');
        ////print('    valueText: ${answer['valueText']}');
        ////print('    valueNumber: ${answer['valueNumber']}');
        ////print('    imageBase64: ${answer['imageBase64'] != null ? (answer['imageBase64'].toString().length > 50 ? "${answer['imageBase64'].toString().substring(0, 50)}..." : answer['imageBase64']) : "null"}');
        ////print('    selectedChoices: ${answer['selectedChoices']}');
      }
      ////print('\n');

      // Log governorate and area data
      print('📍 Location Data being sent:');
      print('   governorateId: ${questionnaireData['governorateId']}');
      print('   areaId: ${questionnaireData['areaId']}');
      print('   latitude: ${questionnaireData['latitude']}');
      print('   longitude: ${questionnaireData['longitude']}');

      final response = await dio.post(
        '/Questionnaire/save',
        data: questionnaireData,
      );

      print('📥 رد السيرفر الكامل:');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('Status Code: ${response.statusCode}');
      print('Response Data: ${response.data}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      if (response.statusCode == 200) {
        // Check if response has errors
        if (response.data != null && response.data is Map) {
          final errorCode = response.data['errorCode'];
          final errorMessage = response.data['errorMessage'];

          // Check if there's a validation error message
          // السيرفر يرجع errorCode: 0 حتى مع وجود أخطاء validation
          if (errorMessage != null && errorMessage.toString().isNotEmpty) {
            // Check if it's an actual error (not "Operation succeeded")
            final isError =
                errorMessage.toString().contains('لم يتم') ||
                errorMessage.toString().contains('خطأ') ||
                errorMessage.toString().contains('فشل') ||
                (errorCode != null && errorCode != 0);

            if (isError) {
              print('❌ API validation error: $errorMessage');
              print('❌ Error code: $errorCode');
              print('❌ Missing questions: ${response.data['data']}');

              return {
                'success': false,
                'errorCode': errorCode ?? -1,
                'errorMessage': errorMessage,
                'missingQuestions': response.data['data'],
                'fullResponse': response.data,
              };
            } else {
              print('ℹ️ API message: $errorMessage');
            }
          }
        }

        return response.data;
      }

      print('⚠️ Unexpected status code: ${response.statusCode}');
      return {'success': false, 'statusCode': response.statusCode};
    } on DioException catch (e) {
      ////print('❌ Error submitting questionnaire: ${e.message}');
      if (e.response != null) {
        ////print('Response data: ${e.response?.data}');
        ////print('Response status: ${e.response?.statusCode}');
      }
      throw Exception('Failed to submit questionnaire: ${e.message}');
    } catch (e) {
      ////print('❌ Unexpected error: $e');
      throw Exception('Failed to submit questionnaire: $e');
    }
  }

  /// Convert SurveyAnswersModel to API format
  static Map<String, dynamic> convertToApiFormat(
    SurveyAnswersModel surveyAnswers,
  ) {
    return {
      "surveyId": surveyAnswers.surveyId,
      "householdCode": surveyAnswers.surveyCode,
      "governorateId": surveyAnswers.governorateId ?? 0,
      "areaId": surveyAnswers.areaId ?? 0,
      "supervisorId": surveyAnswers.supervisorId, // Send null if not set, not 0
      "researcherId": surveyAnswers.researcherId?.toString() ?? "",
      "managementInformationIds": _extractManagementIds(surveyAnswers),
      "neighborhoodName": surveyAnswers.neighborhoodName ?? "",
      "streetName": surveyAnswers.streetName ?? "",
      "isApproved": surveyAnswers.isApproved ?? true,
      "rejectReason": surveyAnswers.rejectReason ?? "",
      "interviewDate":
          surveyAnswers.completedAt?.toIso8601String() ??
          DateTime.now().toIso8601String(),
      "startAt": surveyAnswers.startedAt.toIso8601String(),
      "endAt":
          surveyAnswers.completedAt?.toIso8601String() ??
          DateTime.now().toIso8601String(),
      "status": surveyAnswers.isDraft ? "Draft" : "Completed",
      "latitude": surveyAnswers.latitude ?? 0,
      "longitude": surveyAnswers.longitude ?? 0,
      "buildingFloorsCount": surveyAnswers.buildingFloorsCount ?? 0,
      "apartmentsPerFloor": surveyAnswers.apartmentsPerFloor ?? 0,
      "selectedFloor": surveyAnswers.selectedFloor ?? 0,
      "selectedApartment": surveyAnswers.selectedApartment ?? 0,
      "answers": surveyAnswers.answers
          .map((answer) => _convertAnswer(answer))
          .toList(),
    };
  }

  static List<int> _extractManagementIds(SurveyAnswersModel surveyAnswers) {
    // Extract IDs from researcher, supervisor, city
    final List<int> ids = [];

    if (surveyAnswers.researcherId != null) {
      ids.add(surveyAnswers.researcherId!);
    }
    if (surveyAnswers.supervisorId != null) {
      ids.add(surveyAnswers.supervisorId!);
    }
    if (surveyAnswers.cityId != null) {
      ids.add(surveyAnswers.cityId!);
    }

    return ids;
  }

  static Map<String, dynamic> _convertAnswer(AnswerModel answer) {
    final answerMap = {
      "questionId": answer.questionId,
      "questionType":
          answer.questionType ?? 0, // Use stored type or default to Text (0)
      "groupId": answer.groupId, // null for non-grouped questions
      "repeatIndex": answer.groupInstanceId != null
          ? answer.groupInstanceId! + 1
          : null, // API expects 1-indexed, app uses 0-indexed
      "valueText": null,
      "valueNumber": null,
      "valueDate": null,
      "valueCode": null,
      "imageBase64": null,
      "selectedChoices": [],
    };

    // Add value based on question type
    final qType = answer.questionType ?? 0;

    // If value is null, return empty answer (all fields remain null/empty)
    if (answer.value == null) {
      return answerMap;
    }

    if (qType == 0) {
      // Text
      answerMap["valueText"] = answer.value.toString();
    } else if (qType == 1 || qType == 2 || qType == 6) {
      // Integer, Decimal, Rating
      answerMap["valueNumber"] = answer.value is num
          ? answer.value
          : num.tryParse(answer.value.toString()) ?? 0;
    } else if (qType == 3) {
      // YesNo - now stores choiceId like SingleChoice
      if (answer.value is int) {
        answerMap["selectedChoices"] = [
          {"choiceId": answer.value, "otherText": null},
        ];
      } else if (answer.value is bool) {
        // Legacy support: convert bool to text (should not happen with new code)
        final bool yesNo = answer.value as bool;
        answerMap["valueCode"] = yesNo ? "نعم" : "لا";
        ////print('⚠️ WARNING: YesNo question ${answer.questionId} has legacy bool value instead of choiceId');
      } else {
        // Unknown format
        answerMap["valueCode"] = answer.value.toString();
        ////print('⚠️ WARNING: YesNo question ${answer.questionId} has unexpected value type: ${answer.value.runtimeType}');
      }
    } else if (qType == 4 || qType == 5) {
      // SingleChoice, MultiChoice
      if (answer.value is List) {
        answerMap["selectedChoices"] = (answer.value as List).map((choiceId) {
          return {
            "choiceId": choiceId is int
                ? choiceId
                : int.tryParse(choiceId.toString()) ?? 0,
            "otherText": null,
          };
        }).toList();
      } else if (answer.value is int) {
        // Single choice stored as int
        answerMap["selectedChoices"] = [
          {"choiceId": answer.value, "otherText": null},
        ];
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
