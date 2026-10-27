import 'package:flutter/material.dart';
import '../../data/home_widget_bridge.dart';
import '../../domain/widget_config.dart';

class AddWidgetModal extends StatelessWidget {
  final WidgetSize selectedSize;

  const AddWidgetModal({
    super.key,
    required this.selectedSize,
  });

  static Future<void> show(BuildContext context, WidgetSize size) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddWidgetModal(selectedSize: size),
    );
  }

  Future<void> _handlePinAndClose(BuildContext context) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final pinned = await HomeWidgetBridge.pinWidget(selectedSize);
    await HomeWidgetBridge.updateWidgets();
    if (nav.canPop()) {
      nav.pop();
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          pinned
              ? 'Đã gửi yêu cầu ghim Widget ${selectedSize.label} ra màn hình chính!'
              : 'Đã lưu cấu hình Widget ${selectedSize.label}!',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFFB53216),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = selectedSize == WidgetSize.small;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Icon + Title
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFFBF0EC),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.widgets_rounded,
              color: Color(0xFFB53216),
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Thêm Widget ${selectedSize.label}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF2C2523),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSmall
                ? 'Widget Nhỏ (2×2) giúp bạn ghi nhận nhanh một lần chạm ngay ngoài màn hình chính Android.'
                : 'Widget Vừa (4×2) hiển thị 4 hoạt động quen thuộc cùng chuỗi ngày duy trì thói quen.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6E6662),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 20),

          // Instructions Steps
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF8F5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEFE8E1)),
            ),
            child: Column(
              children: [
                _buildStep(
                  step: '1',
                  text: 'Nhấn nút bên dưới để ghim trực tiếp, hoặc nhấn giữ khoảng trống trên màn hình chính của điện thoại.',
                ),
                const SizedBox(height: 10),
                _buildStep(
                  step: '2',
                  text: 'Chọn biểu tượng "Widgets" (Tiện ích).',
                ),
                const SizedBox(height: 10),
                _buildStep(
                  step: '3',
                  text: 'Tìm ứng dụng "Chăm", chọn kiểu "${selectedSize.dimensions}" và kéo ra vị trí mong muốn.',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Close / Confirm & Pin button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _handlePinAndClose(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB53216),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Đã hiểu',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({required String step, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFB53216),
            shape: BoxShape.circle,
          ),
          child: Text(
            step,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF3B3330),
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
