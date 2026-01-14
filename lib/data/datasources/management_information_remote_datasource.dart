import 'package:survey/core/network/dio_client.dart';
import 'package:survey/data/models/management_information_model.dart';
import 'package:survey/data/models/lookup_model.dart';
import 'package:survey/core/constants/api_endpoints.dart';

abstract class ManagementInformationRemoteDataSource {
  Future<ManagementInformationResponse> getManagementInformations(
    ManagementInformationType type,
  );
  Future<LookupResponse> getGovernorates();
  Future<LookupResponse> getAreas(int governorateId);
}

class ManagementInformationRemoteDataSourceImpl
    implements ManagementInformationRemoteDataSource {
  final DioClient dioClient;

  ManagementInformationRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<ManagementInformationResponse> getManagementInformations(
    ManagementInformationType type,
  ) async {
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

  @override
  Future<LookupResponse> getGovernorates() async {
    try {
      final response = await dioClient.get(
        ApiEndpoints.governorates,
        queryParameters: {'activeOnly': true},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['errorCode'] == 0) {
          return LookupResponse.fromJson(data['data'] as List);
        } else {
          throw Exception(data['errorMessage'] ?? 'Unknown error');
        }
      } else {
        throw Exception('Failed to fetch governorates');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  @override
  Future<LookupResponse> getAreas(int governorateId) async {
    try {
      final response = await dioClient.get(
        ApiEndpoints.areas,
        queryParameters: {'governorateId': governorateId, 'activeOnly': true},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['errorCode'] == 0) {
          return LookupResponse.fromJson(data['data'] as List);
        } else {
          throw Exception(data['errorMessage'] ?? 'Unknown error');
        }
      } else {
        throw Exception('Failed to fetch areas');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
