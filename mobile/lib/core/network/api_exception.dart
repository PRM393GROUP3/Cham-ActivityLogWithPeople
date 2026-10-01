import 'package:dio/dio.dart';

/// Error shape returned by the backend: `{ "error": { "code", "message" } }`.
class ApiException implements Exception {
  const ApiException(this.code, this.message);

  final String code;
  final String message;

  factory ApiException.fromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final error = data['error'] as Map;
      return ApiException('${error['code']}', '${error['message']}');
    }
    return ApiException('NETWORK_ERROR', e.message ?? 'Cannot reach server');
  }

  @override
  String toString() => message;
}
