import 'package:survey/core/network/dio_client.dart';
import 'package:survey/data/models/management_information_model.dart';

abstract class ManagementInformationRemoteDataSource {
  Future<ManagementInformationResponse> getManagementInformations(ManagementInformationType type);
}

class ManagementInformationRemoteDataSourceImpl implements ManagementInformationRemoteDataSource {
  final DioClient dioClient;

  ManagementInformationRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<ManagementInformationResponse> getManagementInformations(ManagementInformationType type) async {
    try {
      String typeParam;
      switch (type) {
        case ManagementInformationType.researcherName:
          typeParam = 'ResearcherName';
          break;
        case ManagementInformationType.supervisorName:
          typeParam = 'SupervisorName';
          break;
        case ManagementInformationType.cityName:
          typeParam = 'CityName';
          break;
      }

      final response = await dioClient.get(
        '/ManagementInformations',
        queryParameters: {'type': typeParam},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['errorCode'] == 0) {
          return ManagementInformationResponse.fromJson(data['data']);
        } else {
          throw Exception(data['errorMessage'] ?? 'Unknown error');
        }
      } else {
        throw Exception('Failed to fetch management information');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
