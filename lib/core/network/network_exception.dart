import 'package:dio/dio.dart';

/// Wraps Dio exceptions into user-friendly messages
class NetworkException implements Exception {
  final String message;
  final int? statusCode;

  const NetworkException({required this.message, this.statusCode});

  factory NetworkException.fromDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const NetworkException(message: 'Connection timed out. Check your internet.');
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final data = e.response?.data;
        String msg = 'Something went wrong';
        if (data is Map) {
          msg = data['message'] ?? data['error'] ?? msg;
        }
        return NetworkException(message: msg, statusCode: code);
      case DioExceptionType.cancel:
        return const NetworkException(message: 'Request was cancelled.');
      default:
        return const NetworkException(message: 'No internet connection.');
    }
  }

  @override
  String toString() => message;
}
