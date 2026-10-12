import 'package:flutter/material.dart';

/// Đại diện cho một loại sự kiện trên vòng Dial (LOG-01, LOG-02).
/// Định nghĩa vị trí trên quỹ đạo (orbit 1, 2, 3) và góc radial tương ứng.
class ActivityEventType {
  const ActivityEventType({
    required this.id,
    required this.name,
    required this.emoji,
    required this.icon,
    required this.bgColor,
    required this.accentColor,
    required this.orbit,
    required this.angleDegree,
    this.shareByDefault = false,
  });

  final String id;
  final String name;
  final String emoji;
  final IconData icon;
  final Color bgColor;
  final Color accentColor;

  /// Quỹ đạo: 1 = vòng trong (Inner), 2 = vòng giữa (Middle), 3 = vòng ngoài (Outer)
  final int orbit;

  /// Vị trí góc trên vòng tròn tính bằng độ (-90 độ là đỉnh 12 giờ)
  final double angleDegree;

  /// Cấu hình chia sẻ mặc định (SOC-03, DAT-03)
  final bool shareByDefault;

  /// 19 Loại sự kiện chuẩn theo bản thiết kế "Wear OS Dial"
  static const List<ActivityEventType> defaultTypes = [
    // --- VÒNG TRONG (INNER ORBIT: 6 hoạt động thói quen cao) ---
    ActivityEventType(
      id: 'coffee',
      name: 'Cà phê',
      emoji: '☕',
      icon: Icons.local_cafe_rounded,
      bgColor: Color(0xFFFFF0E6),
      accentColor: Color(0xFFD97746),
      orbit: 1,
      angleDegree: -90, // Đỉnh 12h
      shareByDefault: true,
    ),
    ActivityEventType(
      id: 'water',
      name: 'Nước',
      emoji: '💧',
      icon: Icons.water_drop_rounded,
      bgColor: Color(0xFFEAF4FF),
      accentColor: Color(0xFF388EE6),
      orbit: 1,
      angleDegree: -30, // 2h
    ),
    ActivityEventType(
      id: 'running',
      name: 'Chạy bộ',
      emoji: '🏃',
      icon: Icons.directions_run_rounded,
      bgColor: Color(0xFFEDF7ED),
      accentColor: Color(0xFF4C9854),
      orbit: 1,
      angleDegree: 30, // 4h
      shareByDefault: true,
    ),
    ActivityEventType(
      id: 'eating',
      name: 'Ăn uống',
      emoji: '🍽️',
      icon: Icons.restaurant_rounded,
      bgColor: Color(0xFFFFF8E7),
      accentColor: Color(0xFFC78A33),
      orbit: 1,
      angleDegree: 90, // Đáy 6h
    ),
    ActivityEventType(
      id: 'focus',
      name: 'Tập trung',
      emoji: '💻',
      icon: Icons.laptop_chromebook_rounded,
      bgColor: Color(0xFFFDEEE9),
      accentColor: Color(0xFFB85D43),
      orbit: 1,
      angleDegree: 150, // 8h
    ),
    ActivityEventType(
      id: 'reading',
      name: 'Đọc sách',
      emoji: '📖',
      icon: Icons.menu_book_rounded,
      bgColor: Color(0xFFF4EEFD),
      accentColor: Color(0xFF7A52A3),
      orbit: 1,
      angleDegree: 210, // 10h
      shareByDefault: true,
    ),

    // --- VÒNG GIỮA (MIDDLE ORBIT: 6 hoạt động) ---
    ActivityEventType(
      id: 'meditate',
      name: 'Thiền',
      emoji: '🧘',
      icon: Icons.self_improvement_rounded,
      bgColor: Color(0xFFF5EDFC),
      accentColor: Color(0xFF8755B3),
      orbit: 2,
      angleDegree: -90, // 12h
    ),
    ActivityEventType(
      id: 'walk',
      name: 'Đi dạo',
      emoji: '🚶',
      icon: Icons.park_rounded,
      bgColor: Color(0xFFEAF7EE),
      accentColor: Color(0xFF468F5A),
      orbit: 2,
      angleDegree: -25, // ~2h
      shareByDefault: true,
    ),
    ActivityEventType(
      id: 'sleep',
      name: 'Ngủ',
      emoji: '🌙',
      icon: Icons.bedtime_rounded,
      bgColor: Color(0xFFEEF2F9),
      accentColor: Color(0xFF4B6584),
      orbit: 2,
      angleDegree: 50, // ~4h
    ),
    ActivityEventType(
      id: 'clean',
      name: 'Dọn dẹp',
      emoji: '🏠',
      icon: Icons.roofing_rounded,
      bgColor: Color(0xFFE8F6F6),
      accentColor: Color(0xFF378D8D),
      orbit: 2,
      angleDegree: 110, // ~6h
    ),
    ActivityEventType(
      id: 'music',
      name: 'Nghe nhạc',
      emoji: '🎧',
      icon: Icons.headphones_rounded,
      bgColor: Color(0xFFFCEEF9),
      accentColor: Color(0xFFB0479E),
      orbit: 2,
      angleDegree: 170, // ~8h
    ),
    ActivityEventType(
      id: 'pet',
      name: 'Thú cưng',
      emoji: '🐾',
      icon: Icons.pets_rounded,
      bgColor: Color(0xFFFFF9E6),
      accentColor: Color(0xFFD49A24),
      orbit: 2,
      angleDegree: 230, // ~10h
      shareByDefault: true,
    ),

    // --- VÒNG NGOÀI (OUTER ORBIT: 7 hoạt động) ---
    ActivityEventType(
      id: 'cook',
      name: 'Nấu ăn',
      emoji: '🍲',
      icon: Icons.soup_kitchen_rounded,
      bgColor: Color(0xFFFFF1E8),
      accentColor: Color(0xFFDE743E),
      orbit: 3,
      angleDegree: -90, // 12h
    ),
    ActivityEventType(
      id: 'plant',
      name: 'Tưới cây',
      emoji: '🪴',
      icon: Icons.spa_rounded,
      bgColor: Color(0xFFE8F8F0),
      accentColor: Color(0xFF389E68),
      orbit: 3,
      angleDegree: -40, // ~1h
    ),
    ActivityEventType(
      id: 'gym',
      name: 'Gym',
      emoji: '🏋️',
      icon: Icons.fitness_center_rounded,
      bgColor: Color(0xFFFDECEB),
      accentColor: Color(0xFFC94A4A),
      orbit: 3,
      angleDegree: 20, // ~3h
      shareByDefault: true,
    ),
    ActivityEventType(
      id: 'movie',
      name: 'Xem phim',
      emoji: '🎬',
      icon: Icons.theaters_rounded,
      bgColor: Color(0xFFF0EEFC),
      accentColor: Color(0xFF6C5CE7),
      orbit: 3,
      angleDegree: 70, // ~5h
    ),
    ActivityEventType(
      id: 'journal',
      name: 'Nhật ký',
      emoji: '✏️',
      icon: Icons.edit_rounded,
      bgColor: Color(0xFFFDF0F4),
      accentColor: Color(0xFFD65076),
      orbit: 3,
      angleDegree: 115, // ~6h
    ),
    ActivityEventType(
      id: 'shopping',
      name: 'Mua sắm',
      emoji: '🛍️',
      icon: Icons.shopping_bag_rounded,
      bgColor: Color(0xFFFDEEF1),
      accentColor: Color(0xFFCC4E77),
      orbit: 3,
      angleDegree: 160, // ~7h
    ),
    ActivityEventType(
      id: 'cycling',
      name: 'Đạp xe',
      emoji: '🚲',
      icon: Icons.pedal_bike_rounded,
      bgColor: Color(0xFFEAF8F7),
      accentColor: Color(0xFF2FA296),
      orbit: 3,
      angleDegree: 215, // ~10h
      shareByDefault: true,
    ),
  ];
}
