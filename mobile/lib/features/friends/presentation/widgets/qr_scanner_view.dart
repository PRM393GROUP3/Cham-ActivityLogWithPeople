import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../domain/invite_qr.dart';

/// Quét mã QR kết bạn bằng camera (SOC-01), kèm bật đèn, quét từ ảnh (Android) và nhập mã tay.
/// Mỗi lần chỉ xử lý một mã: trong lúc [onCodeScanned] chưa xong, các lần đọc tiếp bị bỏ qua.
class QrScannerView extends StatefulWidget {
  const QrScannerView({
    super.key,
    required this.onCodeScanned,
    this.animateLaser = true,
    this.enableCamera = true,
  });

  /// Nhận nội dung thô (QR hoặc mã gõ tay); bên gọi giải mã bằng [InviteQr.decode].
  final Future<void> Function(String raw) onCodeScanned;
  final bool animateLaser;

  /// Tắt trong test / preview (không có camera).
  final bool enableCamera;

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _laserController;
  MobileScannerController? _camera;
  bool _isFlashOn = false;

  /// Đang xử lý một mã (hộp xác nhận / gọi API): bỏ qua các lần đọc khác.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (widget.animateLaser) {
      _laserController.repeat(reverse: true);
    }
    if (widget.enableCamera) {
      _camera = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
    }
  }

  @override
  void dispose() {
    _laserController.dispose();
    _camera?.dispose();
    super.dispose();
  }

  Future<void> _handle(String raw) async {
    if (_busy) return;
    _busy = true;
    try {
      await widget.onCodeScanned(raw);
    } finally {
      _busy = false;
    }
  }

  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw != null && raw.isNotEmpty) {
        _handle(raw);
        return;
      }
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _toggleFlash() async {
    final camera = _camera;
    if (camera == null) {
      setState(() => _isFlashOn = !_isFlashOn);
      return;
    }
    try {
      await camera.toggleTorch();
      setState(() => _isFlashOn = camera.value.torchState == TorchState.on);
    } catch (_) {
      _toast('Thiết bị này không bật được đèn.');
    }
  }

  Future<void> _pickImage() async {
    final camera = _camera;
    if (kIsWeb || camera == null) {
      _toast('Quét từ ảnh chỉ hỗ trợ trên ứng dụng Android. Hãy dùng camera hoặc "Nhập mã".');
      return;
    }
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final capture = await camera.analyzeImage(file.path, formats: const [BarcodeFormat.qrCode]);
    final raw = capture?.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
    if (raw == null) {
      if (mounted) _toast('Không tìm thấy mã QR trong ảnh.');
      return;
    }
    await _handle(raw);
  }

  void _openManualCodeDialog() {
    final TextEditingController textController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5DDD5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Nhập Mã Kết Bạn',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2C2523),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Nhập mã mời 10 ký tự từ mã QR của bạn bè.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF756E68),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: textController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'VD: K7M2P9XQ4R',
                  hintStyle: const TextStyle(color: Color(0xFFAAA29B)),
                  filled: true,
                  fillColor: const Color(0xFFFAF7F2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: const Icon(
                    Icons.tag_rounded,
                    color: Color(0xFFB53216),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB53216),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  final String code = textController.text.trim();
                  if (code.isNotEmpty) {
                    Navigator.of(context).pop();
                    _handle(code);
                  }
                },
                child: const Text(
                  'Kết nối bạn bè',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final camera = _camera;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Viewfinder: hình camera + khung góc + tia laser
          Container(
            width: double.infinity,
            height: 250,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF1F1A18),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (camera != null)
                  Positioned.fill(
                    child: MobileScanner(
                      controller: camera,
                      onDetect: _onDetect,
                      errorBuilder: (context, error) => _CameraMessage(
                        error.errorCode == MobileScannerErrorCode.permissionDenied
                            ? 'Chưa được cấp quyền camera.\nHãy cho phép trong cài đặt, hoặc dùng "Nhập mã".'
                            : 'Không mở được camera.\nHãy dùng "Nhập mã".',
                      ),
                    ),
                  )
                else
                  Center(
                    child: Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 48,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),

                // Corner guides
                CustomPaint(
                  size: const Size(200, 200),
                  painter: _ScannerFramePainter(
                    cornerColor: _isFlashOn
                        ? const Color(0xFFFFD166)
                        : const Color(0xFFE85835),
                  ),
                ),

                // Animated Laser Line
                AnimatedBuilder(
                  animation: _laserController,
                  builder: (context, child) {
                    return Positioned(
                      top: 35 + (_laserController.value * 175),
                      child: Container(
                        width: 170,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE85835),
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x99E85835),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Căn chỉnh mã QR vào trong khung để kết nối một chạm.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF756E68),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 20),

          // Control Actions (Flash, Upload image, Manual code)
          Row(
            children: [
              Expanded(
                child: _ScannerOptionButton(
                  icon: _isFlashOn
                      ? Icons.flash_on_rounded
                      : Icons.flash_off_rounded,
                  label: _isFlashOn ? 'Tắt đèn' : 'Bật đèn',
                  isActive: _isFlashOn,
                  onTap: _toggleFlash,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ScannerOptionButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Chọn ảnh',
                  onTap: _pickImage,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ScannerOptionButton(
                  icon: Icons.keyboard_alt_outlined,
                  label: 'Nhập mã',
                  onTap: _openManualCodeDialog,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Thông báo hiện trong khung camera khi không mở được camera.
class _CameraMessage extends StatelessWidget {
  const _CameraMessage(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
      ),
    );
  }
}

class _ScannerOptionButton extends StatelessWidget {
  const _ScannerOptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive ? const Color(0xFFFDE8E2) : const Color(0xFFF2ECE4),
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? const Color(0xFFB53216)
                    : const Color(0xFF2C2523),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isActive
                        ? const Color(0xFFB53216)
                        : const Color(0xFF2C2523),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScannerFramePainter extends CustomPainter {
  _ScannerFramePainter({required this.cornerColor});

  final Color cornerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = cornerColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 24.0;
    const double radius = 12.0;

    // Top-left
    final Path tlPath = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..lineTo(cornerLength, 0);
    canvas.drawPath(tlPath, paint);

    // Top-right
    final Path trPath = Path()
      ..moveTo(size.width - cornerLength, 0)
      ..lineTo(size.width - radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, radius)
      ..lineTo(size.width, cornerLength);
    canvas.drawPath(trPath, paint);

    // Bottom-left
    final Path blPath = Path()
      ..moveTo(0, size.height - cornerLength)
      ..lineTo(0, size.height - radius)
      ..quadraticBezierTo(0, size.height, radius, size.height)
      ..lineTo(cornerLength, size.height);
    canvas.drawPath(blPath, paint);

    // Bottom-right
    final Path brPath = Path()
      ..moveTo(size.width - cornerLength, size.height)
      ..lineTo(size.width - radius, size.height)
      ..quadraticBezierTo(size.width, size.height, size.width, size.height - radius)
      ..lineTo(size.width, size.height - cornerLength);
    canvas.drawPath(brPath, paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerFramePainter oldDelegate) {
    return oldDelegate.cornerColor != cornerColor;
  }
}

