import 'package:hive_flutter/hive_flutter.dart';
import 'package:survey/core/error/exceptions.dart';

class HiveService {
  // Box names
  static const String surveysBox = 'surveys_box';
  static const String surveyDetailsBox = 'survey_details_box';
  static const String answersBox = 'answers_box';
  static const String draftAnswersBox = 'draft_answers_box';

  // Initialize Hive
  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters here when created
    // Hive.registerAdapter(SurveyModelAdapter());
    
    // Open boxes
    await Hive.openBox(surveysBox);
    await Hive.openBox(surveyDetailsBox);
    await Hive.openBox(answersBox);
    await Hive.openBox(draftAnswersBox);
  }

  // Get box instance
  static Box _getBox(String boxName) {
    if (!Hive.isBoxOpen(boxName)) {
      throw CacheException(message: 'Box $boxName is not opened');
    }
    return Hive.box(boxName);
  }

  // Save data
  static Future<void> saveData<T>({
    required String boxName,
    required String key,
    required T value,
  }) async {
    try {
      final box = _getBox(boxName);
      await box.put(key, value);
    } catch (e) {
      throw CacheException(message: 'Failed to save data: ${e.toString()}');
    }
  }

  // Get data
  static T? getData<T>({
    required String boxName,
    required String key,
  }) {
    try {
      final box = _getBox(boxName);
      return box.get(key) as T?;
    } catch (e) {
      throw CacheException(message: 'Failed to get data: ${e.toString()}');
    }
  }

  // Delete data
  static Future<void> deleteData({
    required String boxName,
    required String key,
  }) async {
    try {
      final box = _getBox(boxName);
      await box.delete(key);
    } catch (e) {
      throw CacheException(message: 'Failed to delete data: ${e.toString()}');
    }
  }

  // Clear box
  static Future<void> clearBox(String boxName) async {
    try {
      final box = _getBox(boxName);
      await box.clear();
    } catch (e) {
      throw CacheException(message: 'Failed to clear box: ${e.toString()}');
    }
  }

  // Get all keys
  static List<String> getAllKeys(String boxName) {
    try {
      final box = _getBox(boxName);
      return box.keys.cast<String>().toList();
    } catch (e) {
      throw CacheException(message: 'Failed to get keys: ${e.toString()}');
    }
  }

  // Get all values
  static List<T> getAllValues<T>(String boxName) {
    try {
      final box = _getBox(boxName);
      return box.values.cast<T>().toList();
    } catch (e) {
      throw CacheException(message: 'Failed to get values: ${e.toString()}');
    }
  }

  // Check if key exists
  static bool containsKey(String boxName, String key) {
    try {
      final box = _getBox(boxName);
      return box.containsKey(key);
    } catch (e) {
      return false;
    }
  }

  // Save list
  static Future<void> saveList<T>({
    required String boxName,
    required String key,
    required List<T> list,
  }) async {
    try {
      final box = _getBox(boxName);
      await box.put(key, list);
    } catch (e) {
      throw CacheException(message: 'Failed to save list: ${e.toString()}');
    }
  }

  // Get list
  static List<T> getList<T>({
    required String boxName,
    required String key,
  }) {
    try {
      final box = _getBox(boxName);
      final data = box.get(key);
      if (data is List) {
        return data.cast<T>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Close all boxes
  static Future<void> closeAll() async {
    await Hive.close();
  }
}
