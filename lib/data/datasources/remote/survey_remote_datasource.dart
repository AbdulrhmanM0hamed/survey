import 'package:survey/core/constants/api_endpoints.dart';
import 'package:survey/core/error/exceptions.dart';
import 'package:survey/core/network/dio_client.dart';
import 'package:survey/data/models/api_response_model.dart';
import 'package:survey/data/models/survey_model.dart';

abstract class SurveyRemoteDataSource {
  Future<SurveyListResponse> getSurveys();
  Future<SurveyModel> getSurveyById(int id);
}

class SurveyRemoteDataSourceImpl implements SurveyRemoteDataSource {
  final DioClient dioClient;

  SurveyRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<SurveyListResponse> getSurveys() async {
    try {
      final response = await dioClient.get(ApiEndpoints.surveys);

      final apiResponse = ApiResponse<SurveyListResponse>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => SurveyListResponse.fromJson(data as Map<String, dynamic>),
      );

      if (apiResponse.isSuccess && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ServerException(
          message: apiResponse.errorMessage,
          statusCode: apiResponse.errorCode,
        );
      }
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(
        message: 'فشل في جلب الاستبيانات: ${e.toString()}',
      );
    }
  }

  @override
  Future<SurveyModel> getSurveyById(int id) async {
    try {
      final response = await dioClient.get(ApiEndpoints.getSurveyById(id));

      final apiResponse = ApiResponse<SurveyModel>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => SurveyModel.fromJson(data as Map<String, dynamic>),
      );

      if (apiResponse.isSuccess && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ServerException(
          message: apiResponse.errorMessage,
          statusCode: apiResponse.errorCode,
        );
      }
    } catch (e) {
      if (e is ServerException || e is NetworkException) {
        rethrow;
      }
      throw ServerException(
        message: 'فشل في جلب تفاصيل الاستبيان: ${e.toString()}',
      );
    }
  }
}
