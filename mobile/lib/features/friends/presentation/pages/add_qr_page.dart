import 'package:flutter/material.dart';
import '../../domain/qr_code_data.dart';
import '../widgets/custom_qr_view.dart';
import '../widgets/qr_scanner_view.dart';

enum QrTab { myQr, scanQr }

class AddQrPage extends StatefulWidget {
  const AddQrPage({
    super.key,
    this.initialTab = QrTab.myQr,
    this.animateLaser = true,
    this.qrData = const QrCodeData(
      displayName: 'Hà My (Tôi)',
      username: '@hamy_cham',
      inviteCode: 'CHAM-8F3K9M',
      avatarUrl:
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=240',
    ),
  });

  final QrTab initialTab;
  final bool animateLaser;
  final QrCodeData qrData;

  @override
  State<AddQrPage> createState() => _AddQrPageState();
}

class _AddQrPageState extends State<AddQrPage> {
  late QrTab _currentTab;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  void _onSharePhoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang chuẩn bị ảnh mã QR để chia sẻ...'),
        duration: Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onSaveToGallery() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu ảnh mã QR vào thư viện ảnh!'),
        duration: Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleScannedCode(String code) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32)),
              SizedBox(width: 8),
              Text(
                'Tìm thấy bạn bè!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2C2523),
                ),
              ),
            ],
          ),
          content: Text(
            'Đã nhận diện mã kết bạn "$code". Bạn có muốn gửi lời mời kết nối không?',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF5E5752),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB53216),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã kết nối thành công với mã $code!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Kết bạn'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F2),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF2C2523),
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Màn hình Chi Tiết Khoảnh Khắc / Kết Nối QR'),
                  duration: Duration(milliseconds: 1000),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
        title: const Text(
          'Chi Tiết Khoảnh Khắc',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2C2523),
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFB53216),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Segmented Tab Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE7DF),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TabButton(
                          icon: Icons.qr_code_2_rounded,
                          label: 'Mã QR của tôi',
                          isSelected: _currentTab == QrTab.myQr,
                          onTap: () {
                            setState(() {
                              _currentTab = QrTab.myQr;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: _TabButton(
                          icon: Icons.qr_code_scanner_rounded,
                          label: 'Quét mã QR',
                          isSelected: _currentTab == QrTab.scanQr,
                          onTap: () {
                            setState(() {
                              _currentTab = QrTab.scanQr;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Animated switcher between My QR and Scanner tabs
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _currentTab == QrTab.myQr
                    ? _buildMyQrCard(context)
                    : QrScannerView(
                        key: const ValueKey('scanner_view'),
                        animateLaser: widget.animateLaser,
                        onCodeScanned: _handleScannedCode,
                      ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyQrCard(BuildContext context) {
    return Container(
      key: const ValueKey('my_qr_card'),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
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
          // User Avatar with Badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFF3ECE5),
                    width: 3,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: widget.qrData.avatarUrl != null
                      ? Image.network(
                          widget.qrData.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildDefaultAvatar(),
                        )
                      : _buildDefaultAvatar(),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB53216),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Display Name
          Text(
            widget.qrData.displayName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2C2523),
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: 2),

          // Username Handle
          Text(
            widget.qrData.username,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8A827B),
            ),
          ),

          const SizedBox(height: 20),

          // QR Code Graphic
          CustomQrView(
            data: widget.qrData.inviteCode,
            size: 240,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Mã mời của bạn: ${widget.qrData.inviteCode}'),
                  duration: const Duration(milliseconds: 1400),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),

          const SizedBox(height: 18),

          // Instruction Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.qrData.instruction,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B645E),
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 22),

          // Action Buttons: Chia sẻ ảnh & Lưu vào máy
          Row(
            children: [
              Expanded(
                child: _QrActionButton(
                  icon: Icons.share_outlined,
                  label: 'Chia sẻ ảnh',
                  onTap: _onSharePhoto,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QrActionButton(
                  icon: Icons.download_rounded,
                  label: 'Lưu vào máy',
                  onTap: _onSaveToGallery,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFFF0EAE1),
      child: const Icon(
        Icons.person_rounded,
        size: 40,
        color: Color(0xFF8A827B),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(100),
      elevation: isSelected ? 1 : 0,
      shadowColor: const Color(0x1F000000),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? const Color(0xFF2C2523)
                    : const Color(0xFF756E68),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF2C2523)
                        : const Color(0xFF756E68),
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

class _QrActionButton extends StatelessWidget {
  const _QrActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF2ECE4),
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        borderRadius: BorderRadius.circular(100),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: const Color(0xFF2C2523),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2C2523),
                    letterSpacing: -0.1,
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

