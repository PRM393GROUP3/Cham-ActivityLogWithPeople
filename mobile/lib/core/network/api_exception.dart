import 'package:dio/dio.dart';

/// Error shape returned by the backend: `{ "error": { "code", "message" } }`.
class ApiException implements Exception {
  const ApiException(this.code, this.message, {this.statusCode});

  final String code;
  final String message;
  final int? statusCode;

  /// Không tới được server (mất mạng, timeout): nên thử lại sau.
  bool get isNetworkError => statusCode == null;

  factory ApiException.fromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final error = data['error'] as Map;
      return ApiException('${error['code']}', '${error['message']}', statusCode: e.response?.statusCode);
    }
    if (e.response != null) {
      return ApiException('HTTP_${e.response!.statusCode}', 'Lỗi máy chủ (${e.response!.statusCode})',
          statusCode: e.response!.statusCode);
    }
    return const ApiException('NETWORK_ERROR', 'Không kết nối được máy chủ. Kiểm tra mạng và thử lại.');
  }

  @override
  String toString() => message;
}
