import 'package:equatable/equatable.dart';

class ApiResponse<T> extends Equatable {
  final int errorCode;
  final String errorMessage;
  final T? data;

  const ApiResponse({
    required this.errorCode,
    required this.errorMessage,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    return ApiResponse<T>(
      errorCode: json['errorCode'] ?? 0,
      errorMessage: json['errorMessage'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson(Object? Function(T?)? toJsonT) {
    return {
      'errorCode': errorCode,
      'errorMessage': errorMessage,
      'data': toJsonT != null ? toJsonT(data) : data,
    };
  }

  bool get isSuccess => errorCode == 0;

  @override
  List<Object?> get props => [errorCode, errorMessage, data];
}
