import 'package:flutter/material.dart';

enum WidgetSize {
  small('Nhỏ (2×2)', '2×2'),
  medium('Vừa (4×2)', '4×2');

  final String label;
  final String dimensions;

  const WidgetSize(this.label, this.dimensions);
}

class QuickLogItem {
  final String id;
  final String title;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final Color dotColor;
  final bool isCompleted;

  const QuickLogItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.dotColor,
    this.isCompleted = false,
  });

  QuickLogItem copyWith({
    String? id,
    String? title,
    IconData? icon,
    Color? backgroundColor,
    Color? iconColor,
    Color? dotColor,
    bool? isCompleted,
  }) {
    return QuickLogItem(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      iconColor: iconColor ?? this.iconColor,
      dotColor: dotColor ?? this.dotColor,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
