import 'package:dio/dio.dart';
import 'package:survey/core/constants/api_endpoints.dart';
import 'package:survey/core/error/exceptions.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: ApiEndpoints.connectTimeout,
        receiveTimeout: ApiEndpoints.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for logging and error handling
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('🚀 REQUEST[${options.method}] => PATH: ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
            '✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
          );
          return handler.next(response);
        },
        onError: (error, handler) {
          print(
            '❌ ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}',
          );
          return handler.next(error);
        },
      ),
    );
  }

  // GET Request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // POST Request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // PUT Request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // DELETE Request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // Error Handler
  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkException(
          message: 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.',
        );
      case DioExceptionType.badResponse:
        return ServerException(
          message: _extractErrorMessage(error.response?.data),
          statusCode: error.response?.statusCode,
        );
      case DioExceptionType.cancel:
        return NetworkException(message: 'تم إلغاء الطلب.');
      case DioExceptionType.connectionError:
        return NetworkException(
          message: 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال.',
        );
      default:
        return ServerException(
          message: 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.',
        );
    }
  }

  String _extractErrorMessage(dynamic responseData) {
    if (responseData == null) {
      return 'حدث خطأ في الخادم.';
    }

    if (responseData is Map<String, dynamic>) {
      // Try to get error message from common fields
      return responseData['errorMessage'] ??
          responseData['message'] ??
          responseData['error'] ??
          'حدث خطأ في الخادم.';
    }

    return responseData.toString();
  }
}
