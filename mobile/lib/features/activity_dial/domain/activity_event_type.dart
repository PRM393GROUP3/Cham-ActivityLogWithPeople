import 'package:flutter/material.dart';

/// Một loại sự kiện (LOG-01, LOG-02): emoji + tên, kèm icon và màu khi là loại mặc định.
/// Người dùng thêm / sửa / xoá / sắp xếp trong Cài đặt (LOG-05); thứ tự quyết định vị trí
/// trên vòng Dial (xem `dial_layout.dart`), nên [orbit] và [angleDegree] được tính lại khi hiển thị.
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
    this.isCustom = false,
  });

  /// Loại sự kiện người dùng tự tạo trong Cài đặt: hiển thị bằng emoji.
  const ActivityEventType.custom({
    required this.id,
    required this.name,
    required this.emoji,
  }) : icon = null,
       bgColor = const Color(0xFFFFF4EC),
       accentColor = const Color(0xFFB53216),
       orbit = 0,
       angleDegree = 0,
       isCustom = true;

  final String id;
  final String name;
  final String emoji;

  /// Icon Material của loại mặc định; `null` = hiển thị [emoji] (loại tự tạo, hoặc loại mặc định
  /// đã bị đổi emoji).
  final IconData? icon;
  final Color bgColor;
  final Color accentColor;

  /// Quỹ đạo: 1 = vòng trong, 2 = vòng giữa, 3 = vòng ngoài, 0 = hàng bên dưới vòng Dial.
  final int orbit;

  /// Vị trí góc trên vòng tròn tính bằng độ (-90 độ là đỉnh 12 giờ)
  final double angleDegree;

  final bool isCustom;

  /// Đổi emoji thì bỏ icon Material (không còn khớp), hiển thị emoji mới.
  ActivityEventType copyWith({String? name, String? emoji, int? orbit, double? angleDegree}) {
    final emojiChanged = emoji != null && emoji != this.emoji;
    return ActivityEventType(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      icon: emojiChanged ? null : icon,
      bgColor: bgColor,
      accentColor: accentColor,
      orbit: orbit ?? this.orbit,
      angleDegree: angleDegree ?? this.angleDegree,
      isCustom: isCustom,
    );
  }

  /// Chỉ lưu id, tên, emoji; icon và màu của loại mặc định được lấy lại theo id.
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'emoji': emoji};

  factory ActivityEventType.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final name = json['name'] as String;
    final emoji = json['emoji'] as String;
    for (final d in defaultTypes) {
      if (d.id == id) return d.copyWith(name: name, emoji: emoji);
    }
    return ActivityEventType.custom(id: id, name: name, emoji: emoji);
  }

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
    ),
  ];
}
