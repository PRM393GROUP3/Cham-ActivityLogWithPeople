import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/account/data/account_storage.dart';
import '../config/env.dart';
import 'api_exception.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: '${Env.apiBaseUrl}/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: Headers.jsonContentType,
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final account = await ref.read(accountStorageProvider).load();
        if (account != null) options.headers['Authorization'] = 'Bearer ${account.token}';
        handler.next(options);
      },
      onError: (e, handler) => handler.reject(
        e.copyWith(error: ApiException.fromDio(e)),
      ),
    ),
  );
  return dio;
});

/// Chạy một request và chuyển mọi lỗi Dio thành [ApiException].
Future<T> guardApi<T>(Future<T> Function() request) async {
  try {
    return await request();
  } on DioException catch (e) {
    throw e.error is ApiException ? e.error! : ApiException.fromDio(e);
  }
}
