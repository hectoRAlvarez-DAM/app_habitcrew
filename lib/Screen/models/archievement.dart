import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final DateTime? unlockedDate;
  final int currentValue;
  final int targetValue;
  final String categoryId;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    this.unlockedDate,
    required this.currentValue,
    required this.targetValue,
    required this.categoryId,
  });

  double get progress => (currentValue / targetValue).clamp(0.0, 1.0);
}
