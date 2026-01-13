import 'package:hive_flutter/hive_flutter.dart';
import 'package:survey/core/error/exceptions.dart';

class HiveService {
  // Box names
  static const String surveysBox = 'surveys_box';
  static const String surveyDetailsBox = 'survey_details_box';
  static const String answersBox = 'answers_box';
  static const String draftAnswersBox = 'draft_answers_box';
  static const String authBox = 'auth_box';

  // Auth keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
  static const String userTypeKey = 'user_type';
  static const String isLoggedInKey = 'is_logged_in';

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
    await Hive.openBox(authBox);
  }

  // ============ Auth Methods ============
  
  static Future<void> saveAuthData({
    required String token,
    required String userId,
    required String fullName,
    required int userType,
  }) async {
    print('💾 Saving auth data...');
    print('   Token length: ${token.length}');
    print('   UserId: $userId');
    print('   FullName: $fullName');
    
    final box = _getBox(authBox);
    await box.put(tokenKey, token);
    await box.put(userIdKey, userId);
    await box.put(userNameKey, fullName);
    await box.put(userTypeKey, userType);
    await box.put(isLoggedInKey, true);
    
    print('✅ Auth data saved successfully');
    
    // Verify save
    final savedToken = box.get(tokenKey);
    print('🔍 Verification - Token saved: ${savedToken != null}');
  }

  static String? getToken() {
    try {
      if (!Hive.isBoxOpen(authBox)) {
        print('⚠️ Auth box is not open!');
        return null;
      }
      final box = Hive.box(authBox);
      final token = box.get(tokenKey) as String?;
      print('🔑 getToken: ${token != null ? "Token exists (${token.length} chars)" : "No token"}');
      return token;
    } catch (e) {
      print('❌ Error getting token: $e');
      return null;
    }
  }

  static String? getUserId() {
    try {
      final box = _getBox(authBox);
      return box.get(userIdKey) as String?;
    } catch (e) {
      return null;
    }
  }

  static String? getUserName() {
    try {
      final box = _getBox(authBox);
      return box.get(userNameKey) as String?;
    } catch (e) {
      return null;
    }
  }

  static int? getUserType() {
    try {
      final box = _getBox(authBox);
      return box.get(userTypeKey) as int?;
    } catch (e) {
      return null;
    }
  }

  static bool isLoggedIn() {
    try {
      final box = _getBox(authBox);
      return box.get(isLoggedInKey, defaultValue: false) as bool;
    } catch (e) {
      return false;
    }
  }

  static Future<void> clearAuthData() async {
    try {
      final box = _getBox(authBox);
      await box.clear();
    } catch (e) {
      throw CacheException(message: 'Failed to clear auth data: ${e.toString()}');
    }
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
