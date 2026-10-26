import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Mã QR thật (quét được bằng camera) theo phong cách chấm tròn của Chấm, logo ở giữa.
/// Dùng mức sửa lỗi H (~30%) để logo che giữa không làm hỏng mã.
class CustomQrView extends StatelessWidget {
  const CustomQrView({
    super.key,
    required this.data,
    this.size = 240,
    this.onTap,
  });

  /// Nội dung mã hoá, vd. `InviteQr.encode(inviteCode)`.
  final String data;
  final double size;
  final VoidCallback? onTap;

  static const _ink = Color(0xFF231F1C);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Nền sáng, đủ tương phản với chấm tối để camera đọc được.
          color: const Color(0xFFFFFBF6),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF0E7DC)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            QrImageView(
              data: data,
              size: size - 32,
              padding: EdgeInsets.zero,
              errorCorrectionLevel: QrErrorCorrectLevel.H,
              backgroundColor: Colors.transparent,
              // Ô định vị phải vuông: máy quét dựa vào tỷ lệ 1:1:3:1:1 của ô vuông để tìm mã.
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: _ink),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: _ink),
              semanticsLabel: 'Mã QR kết bạn',
            ),
            // Logo Chấm ở giữa (nằm trong vùng sửa lỗi của mức H)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFE85835),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3.5),
                boxShadow: const [
                  BoxShadow(color: Color(0x26000000), blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              child: const Center(
                child: Icon(Icons.touch_app_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
