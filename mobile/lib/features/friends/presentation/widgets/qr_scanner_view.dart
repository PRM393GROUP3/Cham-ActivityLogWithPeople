import 'package:flutter/material.dart';

/// Interactive QR scanner screen mockup with laser animation and manual code entry.
class QrScannerView extends StatefulWidget {
  const QrScannerView({
    super.key,
    required this.onCodeScanned,
    this.animateLaser = true,
  });

  final ValueChanged<String> onCodeScanned;
  final bool animateLaser;

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _laserController;
  bool _isFlashOn = false;

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
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
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
                'Nhập mã mời 6-8 ký tự từ mã QR của bạn bè.',
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
                  hintText: 'VD: CHAM-7K9M2P',
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
                    widget.onCodeScanned(code);
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
          // Viewfinder Container
          Container(
            width: double.infinity,
            height: 250,
            decoration: BoxDecoration(
              color: const Color(0xFF1F1A18),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
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

                // Center camera icon indicator
                Center(
                  child: Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
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
                  onTap: () {
                    setState(() {
                      _isFlashOn = !_isFlashOn;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ScannerOptionButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Chọn ảnh',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tính năng quét ảnh từ thư viện'),
                        duration: Duration(milliseconds: 1200),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
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

