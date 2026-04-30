import 'package:flutter/material.dart';

/// Definición estática de todos los logros del juego.
/// Cada logro tiene un ID único, condición de desbloqueo y recompensa.
class AchievementDefinition {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String categoryId;
  final int targetValue;
  final int coinReward;
  // Tipo de condición: 'racha', 'total_completados', 'num_habitos', 'dias_perfectos', 'amigos'
  final String conditionType;

  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.categoryId,
    required this.targetValue,
    required this.coinReward,
    required this.conditionType,
  });

  static const List<AchievementDefinition> allAchievements = [
    // ESPECIAL — insignia beta
    AchievementDefinition(
      id: 'beta',
      title: 'Usuario Beta',
      description: 'Fuiste de los primeros en unirte a HabitCrew',
      icon: Icons.rocket_launch,
      categoryId: '0',
      targetValue: 1,
      coinReward: 0,
      conditionType: 'beta',
    ),

    // CONSTANCIA — rachas
    AchievementDefinition(id: 'a1',  title: 'Primera chispa',        description: 'Completa un hábito por primera vez',                   icon: Icons.star,                 categoryId: '1', targetValue: 1,   coinReward: 25,   conditionType: 'total_completados'),
    AchievementDefinition(id: 'a2',  title: 'Racha de 3 días',       description: 'Mantén un hábito 3 días seguidos',                      icon: Icons.whatshot,             categoryId: '1', targetValue: 3,   coinReward: 50,   conditionType: 'racha'),
    AchievementDefinition(id: 'a3',  title: 'Racha semanal',         description: 'Mantén un hábito 7 días seguidos',                      icon: Icons.calendar_today,       categoryId: '1', targetValue: 7,   coinReward: 75,   conditionType: 'racha'),
    AchievementDefinition(id: 'a4',  title: 'Dos semanas',           description: 'Mantén una racha de 14 días consecutivos',              icon: Icons.date_range,           categoryId: '1', targetValue: 14,  coinReward: 150,  conditionType: 'racha'),
    AchievementDefinition(id: 'a5',  title: 'Tres semanas',          description: 'Mantén una racha de 21 días consecutivos',              icon: Icons.event_repeat,         categoryId: '1', targetValue: 21,  coinReward: 200,  conditionType: 'racha'),
    AchievementDefinition(id: 'a6',  title: 'Racha mensual',         description: 'Mantén un hábito 30 días seguidos',                     icon: Icons.calendar_month,       categoryId: '1', targetValue: 30,  coinReward: 300,  conditionType: 'racha'),
    AchievementDefinition(id: 'a7',  title: 'Dos meses',             description: 'Mantén una racha de 60 días consecutivos',              icon: Icons.auto_awesome,         categoryId: '1', targetValue: 60,  coinReward: 500,  conditionType: 'racha'),
    AchievementDefinition(id: 'a8',  title: 'Trimestre de fuego',    description: 'Mantén una racha de 90 días consecutivos',              icon: Icons.local_fire_department, categoryId: '1', targetValue: 90,  coinReward: 700,  conditionType: 'racha'),
    AchievementDefinition(id: 'a9',  title: 'Centenario',            description: 'Alcanza una racha de 100 días',                         icon: Icons.emoji_events,         categoryId: '1', targetValue: 100, coinReward: 800,  conditionType: 'racha'),
    AchievementDefinition(id: 'a10', title: 'Semestre legendario',   description: 'Mantén una racha de 180 días consecutivos',             icon: Icons.workspace_premium,    categoryId: '1', targetValue: 180, coinReward: 1000, conditionType: 'racha'),
    AchievementDefinition(id: 'a11', title: 'Año completo',          description: 'Mantén una racha durante 365 días',                     icon: Icons.military_tech,        categoryId: '1', targetValue: 365, coinReward: 2000, conditionType: 'racha'),

    // PROGRESO — total completados / hábitos creados
    AchievementDefinition(id: 'b1',  title: 'Primer hábito',         description: 'Crea tu primer hábito',                                 icon: Icons.add_task,             categoryId: '2', targetValue: 1,    coinReward: 25,   conditionType: 'num_habitos'),
    AchievementDefinition(id: 'b2',  title: 'Coleccionista',         description: 'Crea 5 hábitos diferentes',                             icon: Icons.list_alt,             categoryId: '2', targetValue: 5,    coinReward: 100,  conditionType: 'num_habitos'),
    AchievementDefinition(id: 'b3',  title: 'Arsenal',               description: 'Crea 10 hábitos diferentes',                            icon: Icons.grid_view,            categoryId: '2', targetValue: 10,   coinReward: 200,  conditionType: 'num_habitos'),
    AchievementDefinition(id: 'b4',  title: 'Máquina de hábitos',    description: 'Completa 50 hábitos en total',                          icon: Icons.done_all,             categoryId: '2', targetValue: 50,   coinReward: 150,  conditionType: 'total_completados'),
    AchievementDefinition(id: 'b5',  title: 'Centenario',            description: 'Completa 100 hábitos en total',                         icon: Icons.verified,             categoryId: '2', targetValue: 100,  coinReward: 300,  conditionType: 'total_completados'),
    AchievementDefinition(id: 'b6',  title: 'Imparable',             description: 'Completa 500 hábitos en total',                         icon: Icons.bolt,                 categoryId: '2', targetValue: 500,  coinReward: 800,  conditionType: 'total_completados'),
    AchievementDefinition(id: 'b7',  title: 'Leyenda',               description: 'Completa 1000 hábitos en total',                        icon: Icons.diamond,              categoryId: '2', targetValue: 1000, coinReward: 1500, conditionType: 'total_completados'),

    // MAESTRÍA — días perfectos
    AchievementDefinition(id: 'c1',  title: 'Disciplinado',          description: 'Completa todos tus hábitos del día 10 veces',           icon: Icons.verified,             categoryId: '3', targetValue: 10,  coinReward: 200,  conditionType: 'dias_perfectos'),
    AchievementDefinition(id: 'c2',  title: 'Sin excusas',           description: 'No faltes ningún día durante un mes',                   icon: Icons.shield,               categoryId: '3', targetValue: 30,  coinReward: 400,  conditionType: 'dias_perfectos'),
    AchievementDefinition(id: 'c3',  title: 'Perfeccionista',        description: 'Completa todos tus hábitos del día durante 60 días',    icon: Icons.grade,                categoryId: '3', targetValue: 60,  coinReward: 600,  conditionType: 'dias_perfectos'),
    AchievementDefinition(id: 'c4',  title: 'Maestro',               description: 'Completa todos tus hábitos del día durante 100 días',   icon: Icons.workspace_premium,    categoryId: '3', targetValue: 100, coinReward: 1000, conditionType: 'dias_perfectos'),
    AchievementDefinition(id: 'c5',  title: 'Inmortal',              description: 'Completa todos tus hábitos del día durante 200 días',   icon: Icons.auto_awesome,         categoryId: '3', targetValue: 200, coinReward: 2000, conditionType: 'dias_perfectos'),

    // EQUIPO — amigos
    AchievementDefinition(id: 'd1',  title: 'Primer compañero',      description: 'Añade tu primer amigo',                                 icon: Icons.person_add,           categoryId: '4', targetValue: 1,  coinReward: 50,  conditionType: 'amigos'),
    AchievementDefinition(id: 'd2',  title: 'Motivador',             description: 'Añade 5 amigos',                                        icon: Icons.thumb_up,             categoryId: '4', targetValue: 5,  coinReward: 100, conditionType: 'amigos'),
    AchievementDefinition(id: 'd3',  title: 'Influencer',            description: 'Añade 10 amigos',                                       icon: Icons.record_voice_over,    categoryId: '4', targetValue: 10, coinReward: 250, conditionType: 'amigos'),
  ];
}
