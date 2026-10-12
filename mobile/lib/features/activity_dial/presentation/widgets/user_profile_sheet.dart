import 'package:flutter/material.dart';

import '../activity_dial_controller.dart';

/// Modal BottomSheet hiển thị thông tin tài khoản ẩn danh, mã mời QR kết bạn (SOC-01)
class UserProfileSheet extends StatelessWidget {
  const UserProfileSheet({
    super.key,
    required this.state,
  });

  final ActivityDialState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFDF9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD6CBC0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Avatar
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: Color(0xFFA93B24),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            state.displayName,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: Color(0xFF261E1A),
            ),
          ),
          const Text(
            'Tài khoản ẩn danh trên thiết bị (DAT-01)',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF887B70),
            ),
          ),
          const SizedBox(height: 20),

          // Khung mã mời kết bạn (QR Code placeholder & text)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F1E7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFEADBCE)),
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2D6C8)),
                  ),
                  child: Text(
                    state.inviteCode,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                      color: Color(0xFFA93B24),
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
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Nút đóng
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2E241F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Đóng',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
