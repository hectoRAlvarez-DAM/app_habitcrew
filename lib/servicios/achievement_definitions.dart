import 'package:flutter/material.dart';

class AchievementDefinition {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final String categoryId;
  final int targetValue;
  final int coinReward;
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

  // Metadata de categorías: (id, nombre, icono)
  static const List<(String, String, IconData)> categoryMeta = [
    ('0', 'Especial',   Icons.rocket_launch),
    ('1', 'Constancia', Icons.local_fire_department),
    ('2', 'Progreso',   Icons.trending_up),
    ('3', 'Maestría',   Icons.military_tech),
    ('4', 'Equipo',     Icons.group),
    ('5', 'Monedas',    Icons.monetization_on),
    ('6', 'Tienda',     Icons.storefront),
    ('7', 'Fidelidad',  Icons.favorite),
  ];

  static const List<AchievementDefinition> allAchievements = [
    // ── 0. ESPECIAL ───────────────────────────────────────────────────
    AchievementDefinition(id: 'beta', title: 'Usuario Beta', description: 'Fuiste de los primeros en unirte a HabitCrew', icon: Icons.rocket_launch, categoryId: '0', targetValue: 1, coinReward: 0, conditionType: 'beta'),

    // ── 1. CONSTANCIA (rachas) ─────────────────────────────────────────
    AchievementDefinition(id: 'a1',  title: 'Primera chispa',      description: 'Completa un hábito por primera vez',                icon: Icons.star,                  categoryId: '1', targetValue: 1,   coinReward: 25,   conditionType: 'total_completados'),
    AchievementDefinition(id: 'a2',  title: 'Racha de 3 días',     description: 'Mantén un hábito 3 días seguidos',                 icon: Icons.whatshot,              categoryId: '1', targetValue: 3,   coinReward: 50,   conditionType: 'racha'),
    AchievementDefinition(id: 'a3',  title: 'Racha semanal',       description: 'Mantén un hábito 7 días seguidos',                 icon: Icons.calendar_today,        categoryId: '1', targetValue: 7,   coinReward: 75,   conditionType: 'racha'),
    AchievementDefinition(id: 'a4',  title: 'Dos semanas',         description: 'Mantén una racha de 14 días consecutivos',         icon: Icons.date_range,            categoryId: '1', targetValue: 14,  coinReward: 150,  conditionType: 'racha'),
    AchievementDefinition(id: 'a5',  title: 'Tres semanas',        description: 'Mantén una racha de 21 días consecutivos',         icon: Icons.event_repeat,          categoryId: '1', targetValue: 21,  coinReward: 200,  conditionType: 'racha'),
    AchievementDefinition(id: 'a6',  title: 'Racha mensual',       description: 'Mantén un hábito 30 días seguidos',                icon: Icons.calendar_month,        categoryId: '1', targetValue: 30,  coinReward: 300,  conditionType: 'racha'),
    AchievementDefinition(id: 'a7',  title: 'Dos meses',           description: 'Mantén una racha de 60 días consecutivos',         icon: Icons.auto_awesome,          categoryId: '1', targetValue: 60,  coinReward: 500,  conditionType: 'racha'),
    AchievementDefinition(id: 'a8',  title: 'Trimestre de fuego',  description: 'Mantén una racha de 90 días consecutivos',         icon: Icons.local_fire_department, categoryId: '1', targetValue: 90,  coinReward: 700,  conditionType: 'racha'),
    AchievementDefinition(id: 'a9',  title: 'Centenario',          description: 'Alcanza una racha de 100 días',                    icon: Icons.emoji_events,          categoryId: '1', targetValue: 100, coinReward: 800,  conditionType: 'racha'),
    AchievementDefinition(id: 'a10', title: 'Semestre legendario', description: 'Mantén una racha de 180 días consecutivos',        icon: Icons.workspace_premium,     categoryId: '1', targetValue: 180, coinReward: 1000, conditionType: 'racha'),
    AchievementDefinition(id: 'a11', title: 'Año completo',        description: 'Mantén una racha durante 365 días',                icon: Icons.military_tech,         categoryId: '1', targetValue: 365, coinReward: 2000, conditionType: 'racha'),

    // ── 2. PROGRESO ────────────────────────────────────────────────────
    AchievementDefinition(id: 'b1', title: 'Primer hábito',      description: 'Crea tu primer hábito',            icon: Icons.add_task,  categoryId: '2', targetValue: 1,    coinReward: 25,   conditionType: 'num_habitos'),
    AchievementDefinition(id: 'b2', title: 'Coleccionista',      description: 'Crea 5 hábitos diferentes',        icon: Icons.list_alt,  categoryId: '2', targetValue: 5,    coinReward: 100,  conditionType: 'num_habitos'),
    AchievementDefinition(id: 'b3', title: 'Arsenal',            description: 'Crea 10 hábitos diferentes',       icon: Icons.grid_view, categoryId: '2', targetValue: 10,   coinReward: 200,  conditionType: 'num_habitos'),
    AchievementDefinition(id: 'b4', title: 'Máquina de hábitos', description: 'Completa 50 hábitos en total',     icon: Icons.done_all,  categoryId: '2', targetValue: 50,   coinReward: 150,  conditionType: 'total_completados'),
    AchievementDefinition(id: 'b5', title: 'Centenario',         description: 'Completa 100 hábitos en total',    icon: Icons.verified,  categoryId: '2', targetValue: 100,  coinReward: 300,  conditionType: 'total_completados'),
    AchievementDefinition(id: 'b6', title: 'Imparable',          description: 'Completa 500 hábitos en total',    icon: Icons.bolt,      categoryId: '2', targetValue: 500,  coinReward: 800,  conditionType: 'total_completados'),
    AchievementDefinition(id: 'b7', title: 'Leyenda',            description: 'Completa 1000 hábitos en total',   icon: Icons.diamond,   categoryId: '2', targetValue: 1000, coinReward: 1500, conditionType: 'total_completados'),

    // ── 3. MAESTRÍA (días perfectos) ───────────────────────────────────
    AchievementDefinition(id: 'c1', title: 'Disciplinado',   description: 'Completa todos tus hábitos del día 10 veces',          icon: Icons.verified,          categoryId: '3', targetValue: 10,  coinReward: 200,  conditionType: 'dias_perfectos'),
    AchievementDefinition(id: 'c2', title: 'Sin excusas',    description: 'No faltes ningún día durante un mes',                  icon: Icons.shield,            categoryId: '3', targetValue: 30,  coinReward: 400,  conditionType: 'dias_perfectos'),
    AchievementDefinition(id: 'c3', title: 'Perfeccionista', description: 'Completa todos tus hábitos del día durante 60 días',   icon: Icons.grade,             categoryId: '3', targetValue: 60,  coinReward: 600,  conditionType: 'dias_perfectos'),
    AchievementDefinition(id: 'c4', title: 'Maestro',        description: 'Completa todos tus hábitos del día durante 100 días',  icon: Icons.workspace_premium, categoryId: '3', targetValue: 100, coinReward: 1000, conditionType: 'dias_perfectos'),
    AchievementDefinition(id: 'c5', title: 'Inmortal',       description: 'Completa todos tus hábitos del día durante 200 días',  icon: Icons.auto_awesome,      categoryId: '3', targetValue: 200, coinReward: 2000, conditionType: 'dias_perfectos'),

    // ── 4. EQUIPO (amigos) ─────────────────────────────────────────────
    AchievementDefinition(id: 'd1', title: 'Primer compañero', description: 'Añade tu primer amigo', icon: Icons.person_add,        categoryId: '4', targetValue: 1,  coinReward: 50,  conditionType: 'amigos'),
    AchievementDefinition(id: 'd2', title: 'Motivador',        description: 'Añade 5 amigos',        icon: Icons.thumb_up,          categoryId: '4', targetValue: 5,  coinReward: 100, conditionType: 'amigos'),
    AchievementDefinition(id: 'd3', title: 'Influencer',       description: 'Añade 10 amigos',       icon: Icons.record_voice_over, categoryId: '4', targetValue: 10, coinReward: 250, conditionType: 'amigos'),

    // ── 5. MONEDAS (monedasGanadas acumuladas) ─────────────────────────
    AchievementDefinition(id: 'e1',  title: 'Primeros ahorros',   description: 'Gana 100 monedas en total',      icon: Icons.savings,                categoryId: '5', targetValue: 100,    coinReward: 25,   conditionType: 'monedas_ganadas'),
    AchievementDefinition(id: 'e11', title: 'Primer centenar',    description: 'Gana 200 monedas en total',      icon: Icons.toll,                   categoryId: '5', targetValue: 200,    coinReward: 30,   conditionType: 'monedas_ganadas'),
    AchievementDefinition(id: 'e2',  title: 'Pequeño tesoro',     description: 'Gana 250 monedas en total',      icon: Icons.monetization_on,        categoryId: '5', targetValue: 250,    coinReward: 50,   conditionType: 'monedas_ganadas'),
    AchievementDefinition(id: 'e3',  title: 'Ahorrista',          description: 'Gana 500 monedas en total',      icon: Icons.account_balance,        categoryId: '5', targetValue: 500,    coinReward: 75,   conditionType: 'monedas_ganadas'),
    AchievementDefinition(id: 'e12', title: 'Bienvenida dorada',  description: 'Gana 750 monedas en total',      icon: Icons.star_border,            categoryId: '5', targetValue: 750,    coinReward: 80,   conditionType: 'monedas_ganadas'),
    AchievementDefinition(id: 'e4',  title: 'Buen guardián',      description: 'Gana 1000 monedas en total',     icon: Icons.shield,                 categoryId: '5', targetValue: 1000,   coinReward: 100,  conditionType: 'monedas_ganadas'),
    AchievementDefinition(id: 'e13', title: 'Creciendo',          description: 'Gana 1500 monedas en total',     icon: Icons.trending_up,            categoryId: '5', targetValue: 1500,   coinReward: 150,  conditionType: 'monedas_ganadas'),
    AchievementDefinition(id: 'e5',  title: 'Rico en logros',     description: 'Gana 2500 monedas en total',     icon: Icons.workspace_premium,      categoryId: '5', targetValue: 2500,   coinReward: 200,  conditionType: 'monedas_ganadas'),
    AchievementDefinition(id: 'e6',  title: 'Inversor',           description: 'Gana 5000 monedas en total',     icon: Icons.account_balance_wallet, categoryId: '5', targetValue: 5000,   coinReward: 400,  conditionType: 'monedas_ganadas'),
    AchievementDefinition(id: 'e14', title: 'Prosperidad',        description: 'Gana 7500 monedas en total',     icon: Icons.diamond,                categoryId: '5', targetValue: 7500,   coinReward: 500,  conditionType: 'monedas_ganadas'),
    AchievementDefinition(id: 'e7',  title: 'Gran fortuna',       description: 'Gana 10.000 monedas en total',   icon: Icons.auto_awesome,           categoryId: '5', targetValue: 10000,  coinReward: 600,  conditionType: 'monedas_ganadas'),
    AchievementDefinition(id: 'e15', title: 'Élite de monedas',   description: 'Gana 15.000 monedas en total',   icon: Icons.emoji_events,           categoryId: '5', targetValue: 15000,  coinReward: 750,  conditionType: 'monedas_ganadas'),
    AchievementDefinition(id: 'e8',  title: 'Magnate',            description: 'Gana 25.000 monedas en total',   icon: Icons.military_tech,          categoryId: '5', targetValue: 25000,  coinReward: 1000, conditionType: 'monedas_ganadas'),
    AchievementDefinition(id: 'e9',  title: 'Millonario virtual', description: 'Gana 50.000 monedas en total',   icon: Icons.stars,                  categoryId: '5', targetValue: 50000,  coinReward: 2000, conditionType: 'monedas_ganadas'),
    AchievementDefinition(id: 'e10', title: 'Leyenda dorada',     description: 'Gana 100.000 monedas en total',  icon: Icons.brightness_7,           categoryId: '5', targetValue: 100000, coinReward: 3000, conditionType: 'monedas_ganadas'),

    // ── 6. TIENDA ──────────────────────────────────────────────────────
    // f1-f4, f6, f7: artículos comprados (num_compras)
    AchievementDefinition(id: 'f1',  title: 'Primera compra',          description: 'Compra tu primer artículo en la tienda',  icon: Icons.shopping_bag,           categoryId: '6', targetValue: 1,     coinReward: 50,   conditionType: 'num_compras'),
    AchievementDefinition(id: 'f6',  title: 'De vuelta a la tienda',   description: 'Compra 2 artículos en la tienda',         icon: Icons.shopping_cart,          categoryId: '6', targetValue: 2,     coinReward: 75,   conditionType: 'num_compras'),
    AchievementDefinition(id: 'f2',  title: 'Comprador frecuente',     description: 'Compra 3 artículos en la tienda',         icon: Icons.local_mall,             categoryId: '6', targetValue: 3,     coinReward: 100,  conditionType: 'num_compras'),
    AchievementDefinition(id: 'f10', title: 'Buen gusto',              description: 'Compra 4 artículos en la tienda',         icon: Icons.style,                  categoryId: '6', targetValue: 4,     coinReward: 125,  conditionType: 'num_compras'),
    AchievementDefinition(id: 'f3',  title: 'Entusiasta',              description: 'Compra 5 artículos en la tienda',         icon: Icons.favorite,               categoryId: '6', targetValue: 5,     coinReward: 150,  conditionType: 'num_compras'),
    AchievementDefinition(id: 'f11', title: 'Decorador',               description: 'Compra 6 artículos en la tienda',         icon: Icons.palette,                categoryId: '6', targetValue: 6,     coinReward: 175,  conditionType: 'num_compras'),
    AchievementDefinition(id: 'f7',  title: 'Fan de la tienda',        description: 'Compra 7 artículos en la tienda',         icon: Icons.storefront,             categoryId: '6', targetValue: 7,     coinReward: 200,  conditionType: 'num_compras'),
    AchievementDefinition(id: 'f4',  title: 'Coleccionista de tienda', description: 'Compra 8 artículos en la tienda',         icon: Icons.collections,            categoryId: '6', targetValue: 8,     coinReward: 250,  conditionType: 'num_compras'),
    // f5, f8, f9, f12-f15: saldo actual de monedas (monedas_actuales)
    AchievementDefinition(id: 'f9',  title: 'Bolsillos llenos',        description: 'Ten 100 monedas al mismo tiempo',         icon: Icons.account_balance_wallet, categoryId: '6', targetValue: 100,   coinReward: 25,   conditionType: 'monedas_actuales'),
    AchievementDefinition(id: 'f12', title: 'Ahorro básico',           description: 'Ten 500 monedas al mismo tiempo',         icon: Icons.savings,                categoryId: '6', targetValue: 500,   coinReward: 50,   conditionType: 'monedas_actuales'),
    AchievementDefinition(id: 'f13', title: 'Buen saldo',              description: 'Ten 1000 monedas al mismo tiempo',        icon: Icons.toll,                   categoryId: '6', targetValue: 1000,  coinReward: 100,  conditionType: 'monedas_actuales'),
    AchievementDefinition(id: 'f14', title: 'Saldo generoso',          description: 'Ten 2000 monedas al mismo tiempo',        icon: Icons.monetization_on,        categoryId: '6', targetValue: 2000,  coinReward: 200,  conditionType: 'monedas_actuales'),
    AchievementDefinition(id: 'f15', title: 'Rico de verdad',          description: 'Ten 5000 monedas al mismo tiempo',        icon: Icons.workspace_premium,      categoryId: '6', targetValue: 5000,  coinReward: 400,  conditionType: 'monedas_actuales'),
    AchievementDefinition(id: 'f5',  title: 'El más rico',             description: 'Ten 10.000 monedas al mismo tiempo',      icon: Icons.diamond,                categoryId: '6', targetValue: 10000, coinReward: 700,  conditionType: 'monedas_actuales'),
    AchievementDefinition(id: 'f8',  title: 'Millonario local',        description: 'Ten 20.000 monedas al mismo tiempo',      icon: Icons.stars,                  categoryId: '6', targetValue: 20000, coinReward: 1200, conditionType: 'monedas_actuales'),

    // ── 7. FIDELIDAD (días desde registro) ────────────────────────────
    AchievementDefinition(id: 'login', title: 'Primer inicio de sesión', description: 'Inicia sesión en HabitCrew por primera vez', icon: Icons.login, categoryId: '7', targetValue: 1, coinReward: 10, conditionType: 'primer_sesion'),
    AchievementDefinition(id: 'g1',  title: 'Bienvenido',    description: 'Lleva 1 día usando HabitCrew',                 icon: Icons.waving_hand,       categoryId: '7', targetValue: 1,    coinReward: 25,   conditionType: 'dias_registro'),
    AchievementDefinition(id: 'g2',  title: 'Tres días',     description: 'Lleva 3 días usando HabitCrew',                icon: Icons.calendar_view_day, categoryId: '7', targetValue: 3,    coinReward: 50,   conditionType: 'dias_registro'),
    AchievementDefinition(id: 'g3',  title: 'Una semana',    description: 'Lleva 7 días usando HabitCrew',                icon: Icons.calendar_today,    categoryId: '7', targetValue: 7,    coinReward: 75,   conditionType: 'dias_registro'),
    AchievementDefinition(id: 'g4',  title: 'Dos semanas',   description: 'Lleva 14 días usando HabitCrew',               icon: Icons.date_range,        categoryId: '7', targetValue: 14,   coinReward: 100,  conditionType: 'dias_registro'),
    AchievementDefinition(id: 'g5',  title: 'Un mes fiel',   description: 'Lleva 30 días usando HabitCrew',               icon: Icons.calendar_month,    categoryId: '7', targetValue: 30,   coinReward: 200,  conditionType: 'dias_registro'),
    AchievementDefinition(id: 'g6',  title: 'Mes y medio',   description: 'Lleva 45 días usando HabitCrew',               icon: Icons.event_available,   categoryId: '7', targetValue: 45,   coinReward: 300,  conditionType: 'dias_registro'),
    AchievementDefinition(id: 'g7',  title: 'Dos meses fiel',description: 'Lleva 60 días usando HabitCrew',               icon: Icons.event_repeat,      categoryId: '7', targetValue: 60,   coinReward: 400,  conditionType: 'dias_registro'),
    AchievementDefinition(id: 'g8',  title: 'Trimestre',     description: 'Lleva 90 días usando HabitCrew',               icon: Icons.today,             categoryId: '7', targetValue: 90,   coinReward: 500,  conditionType: 'dias_registro'),
    AchievementDefinition(id: 'g9',  title: 'Cuatro meses',  description: 'Lleva 120 días usando HabitCrew',              icon: Icons.hourglass_top,     categoryId: '7', targetValue: 120,  coinReward: 600,  conditionType: 'dias_registro'),
    AchievementDefinition(id: 'g10', title: 'Medio año',     description: 'Lleva 180 días usando HabitCrew',              icon: Icons.access_time,       categoryId: '7', targetValue: 180,  coinReward: 800,  conditionType: 'dias_registro'),
    AchievementDefinition(id: 'g11', title: 'Tres cuartos',  description: 'Lleva 270 días usando HabitCrew',              icon: Icons.hourglass_bottom,  categoryId: '7', targetValue: 270,  coinReward: 1000, conditionType: 'dias_registro'),
    AchievementDefinition(id: 'g12', title: 'Un año fiel',   description: 'Lleva 365 días usando HabitCrew',              icon: Icons.celebration,       categoryId: '7', targetValue: 365,  coinReward: 1500, conditionType: 'dias_registro'),
    AchievementDefinition(id: 'g13', title: 'Año y medio',   description: 'Lleva 548 días usando HabitCrew',              icon: Icons.emoji_events,      categoryId: '7', targetValue: 548,  coinReward: 2000, conditionType: 'dias_registro'),
    AchievementDefinition(id: 'g14', title: 'Dos años fiel', description: 'Lleva 730 días usando HabitCrew',              icon: Icons.workspace_premium, categoryId: '7', targetValue: 730,  coinReward: 2500, conditionType: 'dias_registro'),
    AchievementDefinition(id: 'g15', title: 'Veterano',      description: 'Lleva 1095 días usando HabitCrew (3 años)',    icon: Icons.military_tech,     categoryId: '7', targetValue: 1095, coinReward: 3000, conditionType: 'dias_registro'),
  ];
}
