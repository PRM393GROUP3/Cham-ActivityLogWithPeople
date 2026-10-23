import 'package:flutter/material.dart';
import '../../domain/widget_config.dart';
import '../widgets/add_widget_dialog.dart';
import '../widgets/widget_medium_preview.dart';
import '../widgets/widget_small_preview.dart';

class WidgetSelectionPage extends StatefulWidget {
  const WidgetSelectionPage({super.key});

  @override
  State<WidgetSelectionPage> createState() => _WidgetSelectionPageState();
}

class _WidgetSelectionPageState extends State<WidgetSelectionPage> {
  WidgetSize _selectedSize = WidgetSize.small;

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
            // In case there is a navigator stack or root
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đây là màn hình Cài Đặt Widget.'),
                  duration: Duration(milliseconds: 1000),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
        title: const Text(
          'Cài Đặt',
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
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tài khoản cá nhân ẩn danh của bạn'),
                      duration: Duration(milliseconds: 1000),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB53216),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Segmented Tab Toggle: "Nhỏ (2×2)" | "Vừa (4×2)"
              _buildSegmentedToggle(),

              const SizedBox(height: 24),

              // Preview Section with AnimatedSwitcher
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.96, end: 1.0).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _selectedSize == WidgetSize.small
                          ? const WidgetSmallPreview(key: ValueKey('small_widget'))
                          : const WidgetMediumPreview(key: ValueKey('medium_widget')),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Bottom Action Button: "+ Thêm Widget"
              _buildAddWidgetButton(),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedToggle() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEBE5DC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabItem(
              size: WidgetSize.small,
              label: 'Nhỏ (2×2)',
            ),
          ),
          Expanded(
            child: _buildTabItem(
              size: WidgetSize.medium,
              label: 'Vừa (4×2)',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required WidgetSize size,
    required String label,
  }) {
    final isSelected = _selectedSize == size;

    return GestureDetector(
      onTap: () {
        if (_selectedSize != size) {
          setState(() {
            _selectedSize = size;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF2C2523) : const Color(0xFF756C67),
          ),
        ),
      ),
    );
  }

  Widget _buildAddWidgetButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () => AddWidgetModal.show(context, _selectedSize),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB53216),
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: const Color(0xFFB53216).withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.add,
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Thêm Widget',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
