import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../account/presentation/account_controller.dart';

/// Bottom Sheet hiển thị hồ sơ người dùng ẩn danh và mã mời kết bạn (SOC-01).
/// Tài khoản chỉ được tạo khi dùng tính năng xã hội lần đầu, nên có thể chưa có mã mời.
class UserProfileSheet extends ConsumerWidget {
  const UserProfileSheet({super.key});

  static const _noCode = 'Chưa có';

  void _copyInviteCode(BuildContext context, String inviteCode) {
    if (inviteCode == _noCode) return;
    Clipboard.setData(ClipboardData(text: inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép mã mời: $inviteCode'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountControllerProvider).value;
    final displayName = account?.displayName ?? AccountController.defaultDisplayName;
    final inviteCode = account?.inviteCode ?? _noCode;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFDF9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle bar
          Container(
            width: 44,
            height: 4.5,
            decoration: BoxDecoration(
              color: const Color(0xFFE2D6C8),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 20),

          // Avatar lớn với viền cam
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFA93B24),
              border: Border.all(color: const Color(0xFFFF6F52), width: 3),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFA93B24).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 42,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

          // Tên hiển thị người dùng
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF261E1A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Mã mời: $inviteCode',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF8A7C72),
            ),
          ),
          const SizedBox(height: 18),

          // Thẻ mã QR & mã mời kết bạn (SOC-01)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F2EC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8DFD4)),
            ),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_2_rounded, color: Color(0xFFA93B24), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'MÃ MỜI KẾT BẠN (SOC-01)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Color(0xFF5A4C42),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => _copyInviteCode(context, inviteCode),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2D6C8)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          inviteCode,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                            color: Color(0xFFA93B24),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.copy_rounded,
                          size: 16,
                          color: Color(0xFF8A7C72),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Quét mã này để kết bạn hai chiều. Mã QR không chứa nhật ký cá nhân.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7E7268),
                  ),
                ),
                const SizedBox(height: 14),

                // Button mở màn hình Add QR & Quét QR
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFB53216),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/add-qr');
                    },
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                    label: const Text(
                      'Mở Mã QR & Quét Bạn Bè',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Danh sách bạn bè / huỷ kết bạn (SOC-02)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB53216),
                      side: const BorderSide(color: Color(0xFFE5C9BE)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/friends');
                    },
                    icon: const Icon(Icons.people_alt_outlined, size: 18),
                    label: const Text(
                      'Danh sách bạn bè',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Nút đóng
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF2E241F),
                side: const BorderSide(color: Color(0xFFD6C9BA)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Đóng',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
