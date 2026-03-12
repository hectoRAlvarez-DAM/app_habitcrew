import 'package:app_habitcrew/Screen/models/archievement.dart';
import 'package:app_habitcrew/Screen/models/archievement_category.dart';
import 'package:flutter/material.dart';

class AchievementRepository {
  Future<List<AchievementCategory>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 600));

    return [
      AchievementCategory(
        id: '1',
        name: 'Constancia',
        icon: Icons.local_fire_department,
        achievements: [
          Achievement(
            id: 'a1',
            title: 'Primera chispa',
            description: 'Completa un hábito por primera vez',
            icon: Icons.star,
            isUnlocked: true,
            unlockedDate: DateTime.now().subtract(const Duration(days: 10)),
            currentValue: 1,
            targetValue: 1,
            categoryId: '1',
          ),
          Achievement(
            id: 'a2',
            title: 'Racha de 7 días',
            description: 'Mantén un hábito 7 días seguidos',
            icon: Icons.calendar_today,
            isUnlocked: true,
            unlockedDate: DateTime.now().subtract(const Duration(days: 3)),
            currentValue: 7,
            targetValue: 7,
            categoryId: '1',
          ),
          Achievement(
            id: 'a3',
            title: 'Racha de 30 días',
            description: 'Mantén un hábito 30 días seguidos',
            icon: Icons.date_range,
            isUnlocked: false,
            currentValue: 14,
            targetValue: 30,
            categoryId: '1',
          ),
          Achievement(
            id: 'a4',
            title: 'Centenario',
            description: 'Alcanza una racha de 100 días',
            icon: Icons.emoji_events,
            isUnlocked: false,
            currentValue: 14,
            targetValue: 100,
            categoryId: '1',
          ),
        ],
      ),
      AchievementCategory(
        id: '2',
        name: 'Progreso',
        icon: Icons.trending_up,
        achievements: [
          Achievement(
            id: 'b1',
            title: 'Primer hábito',
            description: 'Crea tu primer hábito',
            icon: Icons.add_task,
            isUnlocked: true,
            unlockedDate: DateTime.now().subtract(const Duration(days: 15)),
            currentValue: 1,
            targetValue: 1,
            categoryId: '2',
          ),
          Achievement(
            id: 'b2',
            title: 'Coleccionista',
            description: 'Crea 5 hábitos diferentes',
            icon: Icons.list_alt,
            isUnlocked: false,
            currentValue: 3,
            targetValue: 5,
            categoryId: '2',
          ),
          Achievement(
            id: 'b3',
            title: 'Máquina de hábitos',
            description: 'Completa 50 hábitos en total',
            icon: Icons.done_all,
            isUnlocked: false,
            currentValue: 22,
            targetValue: 50,
            categoryId: '2',
          ),
        ],
      ),
      AchievementCategory(
        id: '3',
        name: 'Maestría',
        icon: Icons.military_tech,
        achievements: [
          Achievement(
            id: 'c1',
            title: 'Disciplinado',
            description: 'Completa todos tus hábitos del día 10 veces',
            icon: Icons.verified,
            isUnlocked: false,
            currentValue: 4,
            targetValue: 10,
            categoryId: '3',
          ),
          Achievement(
            id: 'c2',
            title: 'Sin excusas',
            description: 'No faltes ningún día durante un mes',
            icon: Icons.shield,
            isUnlocked: false,
            currentValue: 14,
            targetValue: 30,
            categoryId: '3',
          ),
        ],
      ),
    ];
  }
}
