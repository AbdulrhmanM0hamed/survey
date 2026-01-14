import 'dart:convert';
import 'package:survey/core/error/exceptions.dart';
import 'package:survey/core/storage/hive_service.dart';
import 'package:survey/data/models/management_information_model.dart';
import 'package:survey/data/models/lookup_model.dart';

abstract class ManagementInformationLocalDataSource {
  Future<void> cacheManagementInformations(
    ManagementInformationType type,
    ManagementInformationResponse data,
  );
  Future<ManagementInformationResponse?> getCachedManagementInformations(
    ManagementInformationType type,
  );

  Future<void> cacheGovernorates(LookupResponse data);
  Future<LookupResponse?> getCachedGovernorates();

  Future<void> cacheAreas(int governorateId, LookupResponse data);
  Future<LookupResponse?> getCachedAreas(int governorateId);
}

class ManagementInformationLocalDataSourceImpl
    implements ManagementInformationLocalDataSource {
  @override
  Future<void> cacheManagementInformations(
    ManagementInformationType type,
    ManagementInformationResponse data,
  ) async {
    try {
      final jsonString = jsonEncode(data.toJson());
      await HiveService.saveData(
        boxName: HiveService.surveysBox,
        key: 'management_info_${type.name}',
        value: jsonString,
      );
    } catch (e) {
      throw CacheException(
        message: 'فشل في حفظ ${_getTypeLabel(type)}: ${e.toString()}',
      );
    }
  }

  @override
  Future<ManagementInformationResponse?> getCachedManagementInformations(
    ManagementInformationType type,
  ) async {
    try {
      final jsonString = HiveService.getData<String>(
        boxName: HiveService.surveysBox,
        key: 'management_info_${type.name}',
      );

      if (jsonString == null) return null;

      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return ManagementInformationResponse.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheGovernorates(LookupResponse data) async {
    try {
      final jsonString = jsonEncode(data.toJson());
      await HiveService.saveData(
        boxName: HiveService.surveysBox,
        key: 'lookups_governorates',
        value: jsonString,
      );
    } catch (e) {
      throw CacheException(message: 'Failed to cache governorates: $e');
    }
  }

  @override
  Future<LookupResponse?> getCachedGovernorates() async {
    try {
      final jsonString = HiveService.getData<String>(
        boxName: HiveService.surveysBox,
        key: 'lookups_governorates',
      );

      if (jsonString == null) return null;

      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      // Since LookupResponse.fromJson expects List<dynamic> for items, NOT Map with 'items'
      // Wait, let's check LookupResponse.fromJson in lookup_model.dart I just created
      // It expects List<dynamic> in one factory, but toJson returns {'items': ...}
      // So I need to use the map correctly.

      // Let's re-read LookupResponse in previous step.
      // factory LookupResponse.fromJson(List<dynamic> json)
      // Map<String, dynamic> toJson() { return {'items': ...} }

      // THIS IS A MISMATCH. I need to fix either the model or the usage.
      // The API returns { data: [ ... ] }. The RemoteDS implementation passed `data['data'] as List` to `fromJson`.
      // The RemoteDS used `LookupResponse.fromJson(data['data'] as List)`.
      // So `LookupResponse.fromJson` expects a List.
      // But `toJson` returns a Map `{'items': List}`.

      // So when decoding here:
      // jsonMap is `{'items': [...]}`.
      // So I should pass `jsonMap['items']` to `fromJson`.

      return LookupResponse.fromJson(jsonMap['items'] as List);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheAreas(int governorateId, LookupResponse data) async {
    try {
      final jsonString = jsonEncode(data.toJson());
      await HiveService.saveData(
        boxName: HiveService.surveysBox,
        key: 'lookups_areas_$governorateId',
        value: jsonString,
      );
    } catch (e) {
      throw CacheException(message: 'Failed to cache areas: $e');
    }
  }

  @override
  Future<LookupResponse?> getCachedAreas(int governorateId) async {
    try {
      final jsonString = HiveService.getData<String>(
        boxName: HiveService.surveysBox,
        key: 'lookups_areas_$governorateId',
      );

      if (jsonString == null) return null;

      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return LookupResponse.fromJson(jsonMap['items'] as List);
    } catch (e) {
      return null;
    }
  }

  String _getTypeLabel(ManagementInformationType type) {
    switch (type) {
      case ManagementInformationType.researcherName:
        return 'الباحثين';
      case ManagementInformationType.supervisorName:
        return 'المشرفين';
      case ManagementInformationType.cityName:
        return 'المدن';
    }
  }
}
