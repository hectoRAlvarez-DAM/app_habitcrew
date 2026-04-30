import 'package:app_habitcrew/Screen/models/archievement.dart';
import 'package:app_habitcrew/Screen/models/archievement_category.dart';
import 'package:app_habitcrew/servicios/achievement_definitions.dart';
import 'package:flutter/material.dart';

/// Catálogo estático de logros distribuidos en 7 categorías.
/// Devuelve achievements con isUnlocked=false y currentValue=0.
/// El estado real (isUnlocked, currentValue, coinsClaimed) lo gestiona AchievementService.
///
/// Categorías y métricas usadas:
///   1 · Constancia   → mejorRacha (max recordRacha/rachaActual entre todos los hábitos)
///   2 · Progreso     → numHabitos para b1/b2/b3/b13/b14/b15 · totalHabitosCompletados para el resto
///   3 · Maestría     → diasPerfectos
///   4 · Equipo       → sin implementar (siempre 0)
///   5 · Monedas      → monedasGanadas (acumulado total)
///   6 · Tienda       → numCompras para f1-f8 · monedas actuales para f9-f15
///   7 · Fidelidad    → días transcurridos desde data_registre
class AchievementRepository {
  Future<List<AchievementCategory>> getCategories() async {
    Achievement _build(AchievementDefinition def) {
      return Achievement(
        id: def.id,
        title: def.title,
        description: def.description,
        icon: def.icon,
        isUnlocked: false,
        unlockedDate: null,
        currentValue: 0,
        targetValue: def.targetValue,
        categoryId: def.categoryId,
        coinReward: def.coinReward,
      );
    }

    final constancia = AchievementDefinition.allAchievements
        .where((a) => a.categoryId == '1')
        .map(_build)
        .toList();

    final progreso2 = AchievementDefinition.allAchievements
        .where((a) => a.categoryId == '2')
        .map(_build)
        .toList();

    final maestria = AchievementDefinition.allAchievements
        .where((a) => a.categoryId == '3')
        .map(_build)
        .toList();

    final equipo = AchievementDefinition.allAchievements
        .where((a) => a.categoryId == '4')
        .map(_build)
        .toList();

    return [
      AchievementCategory(
        id: '0',
        name: 'Especial',
        icon: Icons.rocket_launch,
        achievements: AchievementDefinition.allAchievements
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

      // ── 5. MONEDAS (15 logros — monedasGanadas acumuladas) ────────────
      AchievementCategory(
        id: '5',
        name: 'Monedas',
        icon: Icons.monetization_on,
        achievements: [
          Achievement(id: 'e1',  title: 'Primeros ahorros',       description: 'Gana 100 monedas en total',        icon: Icons.savings,                isUnlocked: false, currentValue: 0, targetValue: 100,    categoryId: '5', coinReward: 25),
          Achievement(id: 'e11', title: 'Primer centenar',        description: 'Gana 200 monedas en total',        icon: Icons.toll,                   isUnlocked: false, currentValue: 0, targetValue: 200,    categoryId: '5', coinReward: 30),
          Achievement(id: 'e2',  title: 'Pequeño tesoro',         description: 'Gana 250 monedas en total',        icon: Icons.monetization_on,        isUnlocked: false, currentValue: 0, targetValue: 250,    categoryId: '5', coinReward: 50),
          Achievement(id: 'e3',  title: 'Ahorrista',              description: 'Gana 500 monedas en total',        icon: Icons.account_balance,        isUnlocked: false, currentValue: 0, targetValue: 500,    categoryId: '5', coinReward: 75),
          Achievement(id: 'e12', title: 'Bienvenida dorada',      description: 'Gana 750 monedas en total',        icon: Icons.star_border,            isUnlocked: false, currentValue: 0, targetValue: 750,    categoryId: '5', coinReward: 80),
          Achievement(id: 'e4',  title: 'Buen guardián',          description: 'Gana 1000 monedas en total',       icon: Icons.shield,                 isUnlocked: false, currentValue: 0, targetValue: 1000,   categoryId: '5', coinReward: 100),
          Achievement(id: 'e13', title: 'Creciendo',              description: 'Gana 1500 monedas en total',       icon: Icons.trending_up,            isUnlocked: false, currentValue: 0, targetValue: 1500,   categoryId: '5', coinReward: 150),
          Achievement(id: 'e5',  title: 'Rico en logros',         description: 'Gana 2500 monedas en total',       icon: Icons.workspace_premium,      isUnlocked: false, currentValue: 0, targetValue: 2500,   categoryId: '5', coinReward: 200),
          Achievement(id: 'e6',  title: 'Inversor',               description: 'Gana 5000 monedas en total',       icon: Icons.account_balance_wallet, isUnlocked: false, currentValue: 0, targetValue: 5000,   categoryId: '5', coinReward: 400),
          Achievement(id: 'e14', title: 'Prosperidad',            description: 'Gana 7500 monedas en total',       icon: Icons.diamond,                isUnlocked: false, currentValue: 0, targetValue: 7500,   categoryId: '5', coinReward: 500),
          Achievement(id: 'e7',  title: 'Gran fortuna',           description: 'Gana 10.000 monedas en total',     icon: Icons.auto_awesome,           isUnlocked: false, currentValue: 0, targetValue: 10000,  categoryId: '5', coinReward: 600),
          Achievement(id: 'e15', title: 'Élite de monedas',       description: 'Gana 15.000 monedas en total',     icon: Icons.emoji_events,           isUnlocked: false, currentValue: 0, targetValue: 15000,  categoryId: '5', coinReward: 750),
          Achievement(id: 'e8',  title: 'Magnate',                description: 'Gana 25.000 monedas en total',     icon: Icons.military_tech,          isUnlocked: false, currentValue: 0, targetValue: 25000,  categoryId: '5', coinReward: 1000),
          Achievement(id: 'e9',  title: 'Millonario virtual',     description: 'Gana 50.000 monedas en total',     icon: Icons.stars,                  isUnlocked: false, currentValue: 0, targetValue: 50000,  categoryId: '5', coinReward: 2000),
          Achievement(id: 'e10', title: 'Leyenda dorada',         description: 'Gana 100.000 monedas en total',    icon: Icons.brightness_7,           isUnlocked: false, currentValue: 0, targetValue: 100000, categoryId: '5', coinReward: 3000),
        ],
      ),

      // ── 6. TIENDA (15 logros) ──────────────────────────────────────────
      // f1-f8: número de artículos comprados (numCompras)
      // f9-f15: saldo actual de monedas (monedas en Firestore)
      AchievementCategory(
        id: '6',
        name: 'Tienda',
        icon: Icons.storefront,
        achievements: [
          Achievement(id: 'f1',  title: 'Primera compra',          description: 'Compra tu primer artículo en la tienda',     icon: Icons.shopping_bag,           isUnlocked: false, currentValue: 0, targetValue: 1,     categoryId: '6', coinReward: 50),
          Achievement(id: 'f6',  title: 'De vuelta a la tienda',   description: 'Compra 2 artículos en la tienda',            icon: Icons.shopping_cart,          isUnlocked: false, currentValue: 0, targetValue: 2,     categoryId: '6', coinReward: 75),
          Achievement(id: 'f2',  title: 'Comprador frecuente',     description: 'Compra 3 artículos en la tienda',            icon: Icons.local_mall,             isUnlocked: false, currentValue: 0, targetValue: 3,     categoryId: '6', coinReward: 100),
          Achievement(id: 'f10', title: 'Buen gusto',              description: 'Compra 4 artículos en la tienda',            icon: Icons.style,                  isUnlocked: false, currentValue: 0, targetValue: 4,     categoryId: '6', coinReward: 125),
          Achievement(id: 'f3',  title: 'Entusiasta',              description: 'Compra 5 artículos en la tienda',            icon: Icons.favorite,               isUnlocked: false, currentValue: 0, targetValue: 5,     categoryId: '6', coinReward: 150),
          Achievement(id: 'f11', title: 'Decorador',               description: 'Compra 6 artículos en la tienda',            icon: Icons.palette,                isUnlocked: false, currentValue: 0, targetValue: 6,     categoryId: '6', coinReward: 175),
          Achievement(id: 'f7',  title: 'Fan de la tienda',        description: 'Compra 7 artículos en la tienda',            icon: Icons.storefront,             isUnlocked: false, currentValue: 0, targetValue: 7,     categoryId: '6', coinReward: 200),
          Achievement(id: 'f4',  title: 'Coleccionista de tienda', description: 'Compra 8 artículos en la tienda',            icon: Icons.collections,            isUnlocked: false, currentValue: 0, targetValue: 8,     categoryId: '6', coinReward: 250),
          Achievement(id: 'f9',  title: 'Bolsillos llenos',        description: 'Ten 100 monedas al mismo tiempo',            icon: Icons.account_balance_wallet, isUnlocked: false, currentValue: 0, targetValue: 100,   categoryId: '6', coinReward: 25),
          Achievement(id: 'f12', title: 'Ahorro básico',           description: 'Ten 500 monedas al mismo tiempo',            icon: Icons.savings,                isUnlocked: false, currentValue: 0, targetValue: 500,   categoryId: '6', coinReward: 50),
          Achievement(id: 'f13', title: 'Buen saldo',              description: 'Ten 1000 monedas al mismo tiempo',           icon: Icons.toll,                   isUnlocked: false, currentValue: 0, targetValue: 1000,  categoryId: '6', coinReward: 100),
          Achievement(id: 'f14', title: 'Saldo generoso',          description: 'Ten 2000 monedas al mismo tiempo',           icon: Icons.monetization_on,        isUnlocked: false, currentValue: 0, targetValue: 2000,  categoryId: '6', coinReward: 200),
          Achievement(id: 'f15', title: 'Rico de verdad',          description: 'Ten 5000 monedas al mismo tiempo',           icon: Icons.workspace_premium,      isUnlocked: false, currentValue: 0, targetValue: 5000,  categoryId: '6', coinReward: 400),
          Achievement(id: 'f5',  title: 'El más rico',             description: 'Ten 10.000 monedas al mismo tiempo',         icon: Icons.diamond,                isUnlocked: false, currentValue: 0, targetValue: 10000, categoryId: '6', coinReward: 700),
          Achievement(id: 'f8',  title: 'Millonario local',        description: 'Ten 20.000 monedas al mismo tiempo',         icon: Icons.stars,                  isUnlocked: false, currentValue: 0, targetValue: 20000, categoryId: '6', coinReward: 1200),
        ],
      ),

      // ── 7. FIDELIDAD (15 logros — días desde registro) ────────────────
      AchievementCategory(
        id: '7',
        name: 'Fidelidad',
        icon: Icons.favorite,
        achievements: [
          Achievement(id: 'g1',  title: 'Bienvenido',       description: 'Lleva 1 día usando HabitCrew',                  icon: Icons.waving_hand,         isUnlocked: false, currentValue: 0, targetValue: 1,    categoryId: '7', coinReward: 25),
          Achievement(id: 'g2',  title: 'Tres días',        description: 'Lleva 3 días usando HabitCrew',                 icon: Icons.calendar_view_day,   isUnlocked: false, currentValue: 0, targetValue: 3,    categoryId: '7', coinReward: 50),
          Achievement(id: 'g3',  title: 'Una semana',       description: 'Lleva 7 días usando HabitCrew',                 icon: Icons.calendar_today,      isUnlocked: false, currentValue: 0, targetValue: 7,    categoryId: '7', coinReward: 75),
          Achievement(id: 'g4',  title: 'Dos semanas',      description: 'Lleva 14 días usando HabitCrew',                icon: Icons.date_range,          isUnlocked: false, currentValue: 0, targetValue: 14,   categoryId: '7', coinReward: 100),
          Achievement(id: 'g5',  title: 'Un mes fiel',      description: 'Lleva 30 días usando HabitCrew',                icon: Icons.calendar_month,      isUnlocked: false, currentValue: 0, targetValue: 30,   categoryId: '7', coinReward: 200),
          Achievement(id: 'g6',  title: 'Mes y medio',      description: 'Lleva 45 días usando HabitCrew',                icon: Icons.event_available,     isUnlocked: false, currentValue: 0, targetValue: 45,   categoryId: '7', coinReward: 300),
          Achievement(id: 'g7',  title: 'Dos meses fiel',   description: 'Lleva 60 días usando HabitCrew',                icon: Icons.event_repeat,        isUnlocked: false, currentValue: 0, targetValue: 60,   categoryId: '7', coinReward: 400),
          Achievement(id: 'g8',  title: 'Trimestre',        description: 'Lleva 90 días usando HabitCrew',                icon: Icons.today,               isUnlocked: false, currentValue: 0, targetValue: 90,   categoryId: '7', coinReward: 500),
          Achievement(id: 'g9',  title: 'Cuatro meses',     description: 'Lleva 120 días usando HabitCrew',               icon: Icons.hourglass_top,       isUnlocked: false, currentValue: 0, targetValue: 120,  categoryId: '7', coinReward: 600),
          Achievement(id: 'g10', title: 'Medio año',        description: 'Lleva 180 días usando HabitCrew',               icon: Icons.access_time,         isUnlocked: false, currentValue: 0, targetValue: 180,  categoryId: '7', coinReward: 800),
          Achievement(id: 'g11', title: 'Tres cuartos',     description: 'Lleva 270 días usando HabitCrew',               icon: Icons.hourglass_bottom,    isUnlocked: false, currentValue: 0, targetValue: 270,  categoryId: '7', coinReward: 1000),
          Achievement(id: 'g12', title: 'Un año fiel',      description: 'Lleva 365 días usando HabitCrew',               icon: Icons.celebration,         isUnlocked: false, currentValue: 0, targetValue: 365,  categoryId: '7', coinReward: 1500),
          Achievement(id: 'g13', title: 'Año y medio',      description: 'Lleva 548 días usando HabitCrew',               icon: Icons.emoji_events,        isUnlocked: false, currentValue: 0, targetValue: 548,  categoryId: '7', coinReward: 2000),
          Achievement(id: 'g14', title: 'Dos años fiel',    description: 'Lleva 730 días usando HabitCrew',               icon: Icons.workspace_premium,   isUnlocked: false, currentValue: 0, targetValue: 730,  categoryId: '7', coinReward: 2500),
          Achievement(id: 'g15', title: 'Veterano',         description: 'Lleva 1095 días usando HabitCrew (3 años)',     icon: Icons.military_tech,       isUnlocked: false, currentValue: 0, targetValue: 1095, categoryId: '7', coinReward: 3000),
        ],
      ),
    ];
  }
}
