import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/share_op.dart';

final shareApiProvider = Provider<ShareApi>((ref) => ShareApi(ref.watch(dioProvider)));

class ShareApi {
  ShareApi(this._dio);

  final Dio _dio;

  /// Gửi một thao tác trong hàng đợi. Cả hai đều idempotent nên gửi lại an toàn (AC-05).
  Future<void> send(ShareOp op) => guardApi(() async {
        switch (op.type) {
          case ShareOpType.publish:
            await _dio.put<void>('/shares/${op.recordId}', data: {
              'emoji': op.emoji,
              'name': op.name,
              'occurredAt': op.occurredAt!.toUtc().toIso8601String(),
            });
          case ShareOpType.revoke:
            await _dio.delete<void>('/shares/${op.recordId}');
        }
      });
}
