class ApiEndpoints {
  ApiEndpoints._();

  // Base URL
  static const String baseUrl = 'http://45.94.209.137:8080/api';

  // Surveys Endpoints
  static const String surveys = '/Surveys';
  
  static String getSurveyById(int id) => '/Surveys/$id/exportData';
  
  // Timeout durations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
