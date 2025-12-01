import 'dart:convert';
import 'package:survey/core/error/exceptions.dart';
import 'package:survey/core/storage/hive_service.dart';
import 'package:survey/data/models/management_information_model.dart';

abstract class ManagementInformationLocalDataSource {
  Future<void> cacheManagementInformations(
    ManagementInformationType type,
    ManagementInformationResponse data,
  );
  Future<ManagementInformationResponse?> getCachedManagementInformations(
    ManagementInformationType type,
  );
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
      //print('✅ Cached ${type.name}: ${data.items.length} items');
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
      final data = ManagementInformationResponse.fromJson(jsonMap);
      //print('📂 Loaded cached ${type.name}: ${data.items.length} items');
      return data;
    } catch (e) {
      //print('⚠️ Error loading cached ${type.name}: $e');
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
