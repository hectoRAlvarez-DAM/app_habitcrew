import 'package:app_habitcrew/Screen/models/archievement.dart';
import 'package:flutter/material.dart';

class AchievementCategory {
  final String id;
  final String name;
  final IconData icon;
  final List<Achievement> achievements;

  AchievementCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.achievements,
  });

  int get totalAchievements => achievements.length;
  int get unlockedAchievements => achievements.where((a) => a.isUnlocked).length;
  double get completionPercentage =>
      totalAchievements > 0 ? unlockedAchievements / totalAchievements : 0;
}
