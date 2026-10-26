import 'package:cham/core/network/api_exception.dart';
import 'package:cham/core/time/vn_time.dart';
import 'package:dio/dio.dart';
import 'package:cham/core/utils/uuid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VnTime (DAT-02, AC-08)', () {
    test('groups days by Vietnam time regardless of UTC date', () {
      // 23:30 ngày 1/10 giờ VN = 16:30Z ngày 1/10; 00:30 ngày 2/10 giờ VN = 17:30Z ngày 1/10.
      final lateNight = DateTime.utc(2026, 10, 1, 16, 30);
      final afterMidnight = DateTime.utc(2026, 10, 1, 17, 30);
      final morning = DateTime.utc(2026, 10, 1, 1, 0);

      expect(VnTime.of(lateNight).day, 1);
      expect(VnTime.of(afterMidnight).day, 2);
      expect(VnTime.isSameDay(lateNight, morning), isTrue);
      expect(VnTime.isSameDay(lateNight, afterMidnight), isFalse);
      expect(VnTime.hm(lateNight), '23:30');
    });

    test('formats relative times for the feed', () {
      final now = DateTime.utc(2026, 10, 2, 3, 0); // 10:00 giờ VN
      expect(VnTime.relative(now.subtract(const Duration(seconds: 20)), now: now), 'vừa xong');
      expect(VnTime.relative(now.subtract(const Duration(minutes: 15)), now: now), '15 phút trước');
      expect(VnTime.relative(now.subtract(const Duration(hours: 3)), now: now), '3 giờ trước');
      expect(VnTime.relative(DateTime.utc(2026, 10, 1, 14, 30), now: now), 'Hôm qua 21:30');
      expect(VnTime.relative(DateTime.utc(2026, 9, 28, 1, 0), now: now), '28/09 08:00');
    });
  });

  test('uuidV4 produces RFC 4122 v4 UUIDs accepted by the server', () {
    final pattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');
    final ids = List.generate(200, (_) => uuidV4());
    expect(ids.every(pattern.hasMatch), isTrue);
    expect(ids.toSet().length, ids.length);
  });

  group('ApiException', () {
    DioException withBody(int status, Object? body) {
      final req = RequestOptions(path: '/friends');
      return DioException(
        requestOptions: req,
        response: Response(requestOptions: req, statusCode: status, data: body),
        type: DioExceptionType.badResponse,
      );
    }

    test('shows Vietnamese messages for user-facing error codes', () {
      final e = ApiException.fromDio(withBody(404, {
        'error': {'code': 'INVITE_NOT_FOUND', 'message': 'Invite code is invalid or has been rotated'},
      }));
      expect(e.message, 'Mã mời không đúng hoặc đã được đổi.');
      expect(e.isNetworkError, isFalse);
    });

    test('treats an unreachable server as a retryable network error', () {
      final e = ApiException.fromDio(DioException(
        requestOptions: RequestOptions(path: '/feed'),
        type: DioExceptionType.connectionError,
      ));
      expect(e.isNetworkError, isTrue);
    });
  });
}
