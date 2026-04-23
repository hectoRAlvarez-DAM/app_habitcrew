import 'package:app_habitcrew/Screen/models/archievement.dart';
import 'package:app_habitcrew/Screen/models/archievement_category.dart';
import 'package:app_habitcrew/servicios/achievement_service.dart';
import 'package:flutter/material.dart';

class AchievementRepository {
  final AchievementService _service = AchievementService();

  Future<List<AchievementCategory>> getCategories() async {
    final progreso = await _service.obtenerProgreso();

    final totalCompletados = progreso['totalCompletados'] as int? ?? 0;
    final mejorRacha = progreso['mejorRacha'] as int? ?? 0;
    final numHabitos = progreso['numHabitos'] as int? ?? 0;
    final diasPerfectos = progreso['diasPerfectos'] as int? ?? 0;
    final numAmigos = progreso['numAmigos'] as int? ?? 0;
    final desbloqueados = List<String>.from(progreso['logrosDesbloqueados'] ?? []);
    final fechasLogros = progreso['fechasLogros'] as Map<String, dynamic>? ?? {};

    Achievement _build(AchievementDefinition def) {
      int current = 0;
      switch (def.conditionType) {
        case 'racha': current = mejorRacha; break;
        case 'total_completados': current = totalCompletados; break;
        case 'num_habitos': current = numHabitos; break;
        case 'dias_perfectos': current = diasPerfectos; break;
        case 'amigos': current = numAmigos; break;
      }

      final isUnlocked = desbloqueados.contains(def.id);
      final fechaTimestamp = fechasLogros[def.id];
      DateTime? unlockedDate;
      if (fechaTimestamp != null) {
        try {
          unlockedDate = (fechaTimestamp as dynamic).toDate();
        } catch (_) {}
      }

      return Achievement(
        id: def.id,
        title: def.title,
        description: def.description,
        icon: def.icon,
        isUnlocked: isUnlocked,
        unlockedDate: unlockedDate,
        currentValue: current.clamp(0, def.targetValue),
        targetValue: def.targetValue,
        categoryId: def.categoryId,
        coinReward: def.coinReward,
      );
    }

    final constancia = AchievementService.allAchievements
        .where((a) => a.categoryId == '1')
        .map(_build)
        .toList();

    final progreso2 = AchievementService.allAchievements
        .where((a) => a.categoryId == '2')
        .map(_build)
        .toList();

    final maestria = AchievementService.allAchievements
        .where((a) => a.categoryId == '3')
        .map(_build)
        .toList();

    final equipo = AchievementService.allAchievements
        .where((a) => a.categoryId == '4')
        .map(_build)
        .toList();

    return [
      AchievementCategory(
        id: '0',
        name: 'Especial',
        icon: Icons.rocket_launch,
        achievements: AchievementService.allAchievements
            .where((a) => a.categoryId == '0')
            .map(_build)
            .toList(),
      ),
      AchievementCategory(
        id: '1',
        name: 'Constancia',
        icon: Icons.local_fire_department,
        achievements: constancia,
      ),
      AchievementCategory(
        id: '2',
        name: 'Progreso',
        icon: Icons.trending_up,
        achievements: progreso2,
      ),
      AchievementCategory(
        id: '3',
        name: 'Maestría',
        icon: Icons.military_tech,
        achievements: maestria,
      ),
      AchievementCategory(
        id: '4',
        name: 'Equipo',
        icon: Icons.group,
        achievements: equipo,
      ),
    ];
  }
}