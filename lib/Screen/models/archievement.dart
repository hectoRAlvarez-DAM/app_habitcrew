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
  final int coinReward;

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
    this.coinReward = 0,
  });

  double get progress => (currentValue / targetValue).clamp(0.0, 1.0);

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    IconData? icon,
    bool? isUnlocked,
    DateTime? unlockedDate,
    int? currentValue,
    int? targetValue,
    String? categoryId,
    int? coinReward,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedDate: unlockedDate ?? this.unlockedDate,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue ?? this.targetValue,
      categoryId: categoryId ?? this.categoryId,
      coinReward: coinReward ?? this.coinReward,
    );
  }
}
