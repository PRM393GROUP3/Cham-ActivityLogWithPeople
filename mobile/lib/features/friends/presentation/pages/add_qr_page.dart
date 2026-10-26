import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/image_saver/image_saver.dart';
import '../../../account/presentation/account_controller.dart';
import '../../domain/invite_qr.dart';
import '../../domain/qr_code_data.dart';
import '../controllers/friends_controller.dart';
import '../widgets/custom_qr_view.dart';
import '../widgets/qr_scanner_view.dart';

enum QrTab { myQr, scanQr }

/// QR cá nhân (mã mời) và quét / nhập mã để kết bạn trực tiếp (SOC-01).
class AddQrPage extends ConsumerStatefulWidget {
  const AddQrPage({
    super.key,
    this.initialTab = QrTab.myQr,
    this.animateLaser = true,
    this.enableCamera = true,
    this.qrData,
  });

  final QrTab initialTab;
  final bool animateLaser;

  /// Tắt camera trong test / preview.
  final bool enableCamera;

  /// Dữ liệu QR cố định (dùng cho test/preview). `null` = lấy từ tài khoản, tự đăng ký lần đầu.
  final QrCodeData? qrData;

  @override
  ConsumerState<AddQrPage> createState() => _AddQrPageState();
}

class _AddQrPageState extends ConsumerState<AddQrPage> {
  late QrTab _currentTab;

  /// Vùng chụp ảnh mã QR (QR + dòng mã mời) để lưu về máy.
  final _qrImageKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tạo tài khoản ẩn danh ngay khi mở màn QR lần đầu để có mã mời.
    if (widget.qrData == null) {
      ref.read(accountControllerProvider.notifier).ensure().ignore();
    }
  }

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _copyCode(String inviteCode) {
    Clipboard.setData(ClipboardData(text: inviteCode));
    _toast('Đã sao chép mã mời: $inviteCode');
  }

  /// Lưu ảnh mã QR (kèm mã mời) về máy: Android → thư viện ảnh, Web → tải file PNG.
  Future<void> _saveQrImage(String inviteCode) async {
    try {
      final boundary = _qrImageKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final save = ref.read(pngSaverProvider);
      final message = await save(png!.buffer.asUint8List(), fileName: 'cham-ma-moi-$inviteCode');
      if (mounted) _toast(message);
    } catch (e) {
      if (mounted) _toast(e is StateError ? e.message : 'Không lưu được ảnh mã QR.');
    }
  }

  Future<void> _rotateCode() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đổi mã mời?'),
        content: const Text(
          'Mã và ảnh QR cũ sẽ không dùng để kết bạn được nữa. Bạn bè hiện có không bị ảnh hưởng.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB53216)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đổi mã'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final account = await ref.read(accountControllerProvider.notifier).rotateInviteCode();
      if (mounted) _toast('Mã mời mới: ${account.inviteCode}');
    } catch (e) {
      if (mounted) _toast('Không đổi được mã: $e');
    }
  }

  /// Nội dung quét / nhập → mã mời → xác nhận → kết bạn ngay (SOC-01).
  Future<void> _handleScannedCode(String raw) async {
    final code = InviteQr.decode(raw);
    if (code == null) {
      _toast('Đây không phải mã QR kết bạn của Chấm.');
      return;
    }
    final own = widget.qrData?.inviteCode ?? ref.read(accountControllerProvider).value?.inviteCode;
    if (code == own) {
      _toast('Đây là mã mời của chính bạn.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.qr_code_2_rounded, color: Color(0xFFB53216)),
              SizedBox(width: 8),
              Text(
                'Kết bạn?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2C2523),
                ),
              ),
            ],
          ),
          content: Text(
            'Kết bạn ngay với chủ mã "$code"? Hai bạn sẽ thấy các hoạt động Công khai của nhau.',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF5E5752),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB53216),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Kết bạn'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final friend = await ref.read(friendsControllerProvider.notifier).add(code);
      messenger.showSnackBar(
        SnackBar(content: Text('Đã kết bạn với ${friend.displayName}!'), behavior: SnackBarBehavior.floating),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Không kết bạn được: $e'), behavior: SnackBarBehavior.floating),
      );
    }
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
            padding: const EdgeInsets.only(right: 12),
            child: IconButton.filled(
              style: IconButton.styleFrom(backgroundColor: const Color(0xFFB53216)),
              tooltip: 'Danh sách bạn bè',
              onPressed: () => Navigator.pushNamed(context, '/friends'),
              icon: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 20),
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
                    ? _buildMyQr(context)
                    : QrScannerView(
                        key: const ValueKey('scanner_view'),
                        animateLaser: widget.animateLaser,
                        enableCamera: widget.enableCamera,
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

  Widget _buildMyQr(BuildContext context) {
    if (widget.qrData != null) return _buildMyQrCard(context, widget.qrData!);

    final account = ref.watch(accountControllerProvider);
    final data = account.value;
    if (data != null) {
      return _buildMyQrCard(
        context,
        QrCodeData(displayName: data.displayName, username: 'Mã mời: ${data.inviteCode}', inviteCode: data.inviteCode),
      );
    }
    return Padding(
      key: const ValueKey('my_qr_pending'),
      padding: const EdgeInsets.all(32),
      child: account.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Text(
                  'Cần kết nối mạng ở lần đầu để tạo mã mời.'
                  '${account.hasError ? '\n${account.error}' : ''}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF6B645E)),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB53216)),
                  onPressed: () => ref.read(accountControllerProvider.notifier).ensure().ignore(),
                  child: const Text('Thử lại'),
                ),
              ],
            ),
    );
  }

  Widget _buildMyQrCard(BuildContext context, QrCodeData qrData) {
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
                  child: qrData.avatarUrl != null
                      ? Image.network(
                          qrData.avatarUrl!,
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
            qrData.displayName,
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
            qrData.username,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8A827B),
            ),
          ),

          const SizedBox(height: 20),

          // QR Code Graphic
          // Vùng được chụp khi "Lưu ảnh QR": QR + mã mời trên nền trắng.
          RepaintBoundary(
            key: _qrImageKey,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomQrView(
                    data: InviteQr.encode(qrData.inviteCode),
                    size: 240,
                    onTap: () => _copyCode(qrData.inviteCode),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Chấm · Mã mời ${qrData.inviteCode}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8A827B),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Instruction Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              qrData.instruction,
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

          // Sao chép mã & Lưu ảnh QR; Đổi mã mời (chỉ với tài khoản thật) ở hàng dưới
          Row(
            children: [
              Expanded(
                child: _QrActionButton(
                  icon: Icons.copy_rounded,
                  label: 'Sao chép mã',
                  onTap: () => _copyCode(qrData.inviteCode),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QrActionButton(
                  icon: Icons.download_rounded,
                  label: 'Lưu ảnh QR',
                  onTap: () => _saveQrImage(qrData.inviteCode),
                ),
              ),
            ],
          ),
          if (widget.qrData == null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: _QrActionButton(
                icon: Icons.autorenew_rounded,
                label: 'Đổi mã mời',
                onTap: _rotateCode,
              ),
            ),
          ],
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

