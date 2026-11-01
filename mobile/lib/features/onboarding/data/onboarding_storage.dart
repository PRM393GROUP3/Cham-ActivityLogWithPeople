import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final onboardingStorageProvider = Provider<OnboardingStorage>((ref) => OnboardingStorage());

/// Đã xem màn chào lần đầu hay chưa.
class OnboardingStorage {
  static const _key = 'cham_onboarded_v1';

  /// Máy đã có dữ liệu từ bản trước (tài khoản hoặc nhật ký) cũng coi như đã xem: không bắt
  /// người dùng cũ đi lại màn chào sau khi cập nhật app.
  static const _existingDataKeys = ['cham_account_v1', 'cham_activity_logs_v1'];

  Future<bool> isDone() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_key) ?? false) return true;
    if (_existingDataKeys.any(prefs.containsKey)) {
      await prefs.setBool(_key, true);
      return true;
    }
    return false;
  }

  Future<void> markDone() async => (await SharedPreferences.getInstance()).setBool(_key, true);
}
