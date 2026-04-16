import 'package:app_habitcrew/Screen/models/archievement.dart';
import 'package:app_habitcrew/Screen/models/archievement_category.dart';
import 'package:flutter/material.dart';

/// Catálogo estático de 100 logros distribuidos en 7 categorías.
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
    return [
      // ── 1. CONSTANCIA (15 logros) ──────────────────────────────────────
      AchievementCategory(
        id: '1',
        name: 'Constancia',
        icon: Icons.local_fire_department,
        achievements: [
          Achievement(id: 'a1',  title: 'Primera chispa',         description: 'Completa un hábito por primera vez',                  icon: Icons.star,                isUnlocked: false, currentValue: 0, targetValue: 1,    categoryId: '1', coinReward: 25),
          Achievement(id: 'a13', title: '5 días de fuego',        description: 'Mantén una racha de 5 días consecutivos',             icon: Icons.whatshot,            isUnlocked: false, currentValue: 0, targetValue: 5,    categoryId: '1', coinReward: 60),
          Achievement(id: 'a2',  title: 'Racha de 3 días',        description: 'Mantén un hábito 3 días seguidos',                    icon: Icons.whatshot,            isUnlocked: false, currentValue: 0, targetValue: 3,    categoryId: '1', coinReward: 50),
          Achievement(id: 'a3',  title: 'Racha semanal',          description: 'Mantén un hábito 7 días seguidos',                    icon: Icons.calendar_today,      isUnlocked: false, currentValue: 0, targetValue: 7,    categoryId: '1', coinReward: 75),
          Achievement(id: 'a4',  title: 'Dos semanas',            description: 'Mantén una racha de 14 días consecutivos',            icon: Icons.date_range,          isUnlocked: false, currentValue: 0, targetValue: 14,   categoryId: '1', coinReward: 150),
          Achievement(id: 'a5',  title: 'Tres semanas',           description: 'Mantén una racha de 21 días consecutivos',            icon: Icons.event_repeat,        isUnlocked: false, currentValue: 0, targetValue: 21,   categoryId: '1', coinReward: 200),
          Achievement(id: 'a6',  title: 'Racha mensual',          description: 'Mantén un hábito 30 días seguidos',                   icon: Icons.calendar_month,      isUnlocked: false, currentValue: 0, targetValue: 30,   categoryId: '1', coinReward: 300),
          Achievement(id: 'a12', title: '45 días imparable',      description: 'Mantén una racha de 45 días consecutivos',            icon: Icons.bolt,                isUnlocked: false, currentValue: 0, targetValue: 45,   categoryId: '1', coinReward: 400),
          Achievement(id: 'a7',  title: 'Dos meses',              description: 'Mantén una racha de 60 días consecutivos',            icon: Icons.auto_awesome,        isUnlocked: false, currentValue: 0, targetValue: 60,   categoryId: '1', coinReward: 500),
          Achievement(id: 'a8',  title: 'Trimestre de fuego',     description: 'Mantén una racha de 90 días consecutivos',            icon: Icons.local_fire_department, isUnlocked: false, currentValue: 0, targetValue: 90, categoryId: '1', coinReward: 700),
          Achievement(id: 'a9',  title: 'Centenario',             description: 'Alcanza una racha de 100 días',                       icon: Icons.emoji_events,        isUnlocked: false, currentValue: 0, targetValue: 100,  categoryId: '1', coinReward: 800),
          Achievement(id: 'a14', title: '120 días sin parar',     description: 'Mantén una racha de 120 días consecutivos',           icon: Icons.directions_run,      isUnlocked: false, currentValue: 0, targetValue: 120,  categoryId: '1', coinReward: 900),
          Achievement(id: 'a10', title: 'Semestre legendario',    description: 'Mantén una racha de 180 días consecutivos',           icon: Icons.workspace_premium,   isUnlocked: false, currentValue: 0, targetValue: 180,  categoryId: '1', coinReward: 1000),
          Achievement(id: 'a11', title: 'Año completo',           description: 'Mantén una racha durante 365 días',                   icon: Icons.military_tech,       isUnlocked: false, currentValue: 0, targetValue: 365,  categoryId: '1', coinReward: 2000),
          Achievement(id: 'a15', title: 'Dos años de leyenda',    description: 'Mantén una racha durante 730 días consecutivos',      icon: Icons.diamond,             isUnlocked: false, currentValue: 0, targetValue: 730,  categoryId: '1', coinReward: 3000),
        ],
      ),

      // ── 2. PROGRESO (15 logros) ────────────────────────────────────────
      AchievementCategory(
        id: '2',
        name: 'Progreso',
        icon: Icons.trending_up,
        achievements: [
          // Creación de hábitos (numHabitos): b1, b2, b3, b13, b14, b15
          Achievement(id: 'b1',  title: 'Primer hábito',          description: 'Crea tu primer hábito',                               icon: Icons.add_task,            isUnlocked: false, currentValue: 0, targetValue: 1,    categoryId: '2', coinReward: 25),
          Achievement(id: 'b13', title: 'Tríada',                 description: 'Crea 3 hábitos diferentes',                           icon: Icons.filter_3,            isUnlocked: false, currentValue: 0, targetValue: 3,    categoryId: '2', coinReward: 75),
          Achievement(id: 'b2',  title: 'Coleccionista',          description: 'Crea 5 hábitos diferentes',                           icon: Icons.list_alt,            isUnlocked: false, currentValue: 0, targetValue: 5,    categoryId: '2', coinReward: 100),
          Achievement(id: 'b3',  title: 'Arsenal',                description: 'Crea 10 hábitos diferentes',                          icon: Icons.grid_view,           isUnlocked: false, currentValue: 0, targetValue: 10,   categoryId: '2', coinReward: 200),
          Achievement(id: 'b14', title: 'Explorador de hábitos',  description: 'Crea 15 hábitos diferentes',                          icon: Icons.explore,             isUnlocked: false, currentValue: 0, targetValue: 15,   categoryId: '2', coinReward: 300),
          Achievement(id: 'b15', title: 'Maestro coleccionista',  description: 'Crea 20 hábitos diferentes',                          icon: Icons.collections_bookmark, isUnlocked: false, currentValue: 0, targetValue: 20, categoryId: '2', coinReward: 500),
          // Hábitos completados (totalHabitosCompletados): b4-b12
          Achievement(id: 'b8',  title: 'Primeros pasos',         description: 'Completa 10 hábitos en total',                        icon: Icons.directions_walk,     isUnlocked: false, currentValue: 0, targetValue: 10,   categoryId: '2', coinReward: 50),
          Achievement(id: 'b9',  title: 'En marcha',              description: 'Completa 25 hábitos en total',                        icon: Icons.directions_run,      isUnlocked: false, currentValue: 0, targetValue: 25,   categoryId: '2', coinReward: 100),
          Achievement(id: 'b4',  title: 'Máquina de hábitos',     description: 'Completa 50 hábitos en total',                        icon: Icons.done_all,            isUnlocked: false, currentValue: 0, targetValue: 50,   categoryId: '2', coinReward: 150),
          Achievement(id: 'b5',  title: 'Centenario',             description: 'Completa 100 hábitos en total',                       icon: Icons.verified,            isUnlocked: false, currentValue: 0, targetValue: 100,  categoryId: '2', coinReward: 300),
          Achievement(id: 'b10', title: 'Constante',              description: 'Completa 200 hábitos en total',                       icon: Icons.trending_up,         isUnlocked: false, currentValue: 0, targetValue: 200,  categoryId: '2', coinReward: 500),
          Achievement(id: 'b6',  title: 'Imparable',              description: 'Completa 500 hábitos en total',                       icon: Icons.bolt,                isUnlocked: false, currentValue: 0, targetValue: 500,  categoryId: '2', coinReward: 800),
          Achievement(id: 'b7',  title: 'Leyenda',                description: 'Completa 1000 hábitos en total',                      icon: Icons.diamond,             isUnlocked: false, currentValue: 0, targetValue: 1000, categoryId: '2', coinReward: 1500),
          Achievement(id: 'b11', title: 'Élite',                  description: 'Completa 2000 hábitos en total',                      icon: Icons.military_tech,       isUnlocked: false, currentValue: 0, targetValue: 2000, categoryId: '2', coinReward: 2000),
          Achievement(id: 'b12', title: 'Inmortal de hábitos',    description: 'Completa 5000 hábitos en total',                      icon: Icons.auto_awesome,        isUnlocked: false, currentValue: 0, targetValue: 5000, categoryId: '2', coinReward: 3500),
        ],
      ),

      // ── 3. MAESTRÍA (15 logros) ────────────────────────────────────────
      AchievementCategory(
        id: '3',
        name: 'Maestría',
        icon: Icons.military_tech,
        achievements: [
          Achievement(id: 'c6',  title: 'Primer día perfecto',    description: 'Completa todos tus hábitos del día por primera vez',  icon: Icons.check_circle,        isUnlocked: false, currentValue: 0, targetValue: 1,    categoryId: '3', coinReward: 50),
          Achievement(id: 'c13', title: 'Tres perfectos',         description: 'Completa todos tus hábitos del día 3 veces',          icon: Icons.star_half,           isUnlocked: false, currentValue: 0, targetValue: 3,    categoryId: '3', coinReward: 75),
          Achievement(id: 'c7',  title: 'Cinco perfecto',         description: 'Completa todos tus hábitos del día 5 veces',          icon: Icons.star,                isUnlocked: false, currentValue: 0, targetValue: 5,    categoryId: '3', coinReward: 100),
          Achievement(id: 'c14', title: 'Semana perfecta',        description: 'Completa todos tus hábitos del día 7 veces',          icon: Icons.calendar_today,      isUnlocked: false, currentValue: 0, targetValue: 7,    categoryId: '3', coinReward: 150),
          Achievement(id: 'c1',  title: 'Disciplinado',           description: 'Completa todos tus hábitos del día 10 veces',         icon: Icons.verified,            isUnlocked: false, currentValue: 0, targetValue: 10,   categoryId: '3', coinReward: 200),
          Achievement(id: 'c8',  title: 'Veinte perfectos',       description: 'Completa todos tus hábitos del día 20 veces',         icon: Icons.grade,               isUnlocked: false, currentValue: 0, targetValue: 20,   categoryId: '3', coinReward: 300),
          Achievement(id: 'c15', title: 'Veinticinco perfectos',  description: 'Completa todos tus hábitos del día 25 veces',         icon: Icons.workspace_premium,   isUnlocked: false, currentValue: 0, targetValue: 25,   categoryId: '3', coinReward: 350),
          Achievement(id: 'c2',  title: 'Sin excusas',            description: 'Completa todos tus hábitos durante 30 días',          icon: Icons.shield,              isUnlocked: false, currentValue: 0, targetValue: 30,   categoryId: '3', coinReward: 400),
          Achievement(id: 'c9',  title: 'Cincuenta perfectos',    description: 'Completa todos tus hábitos del día 50 veces',         icon: Icons.bolt,                isUnlocked: false, currentValue: 0, targetValue: 50,   categoryId: '3', coinReward: 500),
          Achievement(id: 'c3',  title: 'Perfeccionista',         description: 'Completa todos tus hábitos durante 60 días',          icon: Icons.auto_awesome,        isUnlocked: false, currentValue: 0, targetValue: 60,   categoryId: '3', coinReward: 600),
          Achievement(id: 'c10', title: '75 días perfectos',      description: 'Completa todos tus hábitos del día 75 veces',         icon: Icons.emoji_events,        isUnlocked: false, currentValue: 0, targetValue: 75,   categoryId: '3', coinReward: 750),
          Achievement(id: 'c4',  title: 'Maestro',                description: 'Completa todos tus hábitos durante 100 días',         icon: Icons.workspace_premium,   isUnlocked: false, currentValue: 0, targetValue: 100,  categoryId: '3', coinReward: 1000),
          Achievement(id: 'c11', title: '150 días perfectos',     description: 'Completa todos tus hábitos del día 150 veces',        icon: Icons.diamond,             isUnlocked: false, currentValue: 0, targetValue: 150,  categoryId: '3', coinReward: 1500),
          Achievement(id: 'c5',  title: 'Inmortal',               description: 'Completa todos tus hábitos durante 200 días',         icon: Icons.local_fire_department, isUnlocked: false, currentValue: 0, targetValue: 200, categoryId: '3', coinReward: 2000),
          Achievement(id: 'c12', title: 'Año perfecto',           description: 'Completa todos tus hábitos del día durante 365 días', icon: Icons.military_tech,       isUnlocked: false, currentValue: 0, targetValue: 365,  categoryId: '3', coinReward: 3000),
        ],
      ),

      // ── 4. EQUIPO (10 logros) ──────────────────────────────────────────
      AchievementCategory(
        id: '4',
        name: 'Equipo',
        icon: Icons.group,
        achievements: [
          Achievement(id: 'd1',  title: 'Primer compañero',       description: 'Invita a un amigo a unirse a tu crew',                icon: Icons.person_add,          isUnlocked: false, currentValue: 0, targetValue: 1,  categoryId: '4', coinReward: 50),
          Achievement(id: 'd2',  title: 'Motivador',              description: 'Anima a 5 compañeros de tu crew',                     icon: Icons.thumb_up,            isUnlocked: false, currentValue: 0, targetValue: 5,  categoryId: '4', coinReward: 100),
          Achievement(id: 'd7',  title: 'Creador de crew',        description: 'Crea tu propio crew',                                 icon: Icons.group_add,           isUnlocked: false, currentValue: 0, targetValue: 1,  categoryId: '4', coinReward: 75),
          Achievement(id: 'd3',  title: 'Influencer',             description: 'Anima a 10 compañeros de tu crew',                    icon: Icons.record_voice_over,   isUnlocked: false, currentValue: 0, targetValue: 10, categoryId: '4', coinReward: 250),
          Achievement(id: 'd10', title: 'Familia de hábitos',     description: 'Ten 10 amigos en tu crew',                            icon: Icons.diversity_3,         isUnlocked: false, currentValue: 0, targetValue: 10, categoryId: '4', coinReward: 300),
          Achievement(id: 'd4',  title: 'Crew legendario',        description: 'Completa un desafío grupal con tu crew al 100%',      icon: Icons.groups,              isUnlocked: false, currentValue: 0, targetValue: 1,  categoryId: '4', coinReward: 300),
          Achievement(id: 'd9',  title: 'El más rápido',          description: 'Sé el primero de tu crew en completar un desafío',   icon: Icons.speed,               isUnlocked: false, currentValue: 0, targetValue: 1,  categoryId: '4', coinReward: 200),
          Achievement(id: 'd5',  title: 'Líder nato',             description: 'Crea y gestiona 3 desafíos grupales',                 icon: Icons.emoji_people,        isUnlocked: false, currentValue: 0, targetValue: 3,  categoryId: '4', coinReward: 200),
          Achievement(id: 'd6',  title: 'Campeón grupal',         description: 'Completa 5 desafíos grupales',                        icon: Icons.emoji_events,        isUnlocked: false, currentValue: 0, targetValue: 5,  categoryId: '4', coinReward: 500),
          Achievement(id: 'd8',  title: 'Crew de élite',          description: 'Completa 10 desafíos grupales',                       icon: Icons.military_tech,       isUnlocked: false, currentValue: 0, targetValue: 10, categoryId: '4', coinReward: 1000),
        ],
      ),

      // ── 5. MONEDAS (15 logros — monedasGanadas acumuladas) ────────────
      AchievementCategory(
        id: '5',
        name: 'Monedas',
        icon: Icons.monetization_on,
        achievements: [
          Achievement(id: 'e1',  title: 'Primeros ahorros',       description: 'Gana 100 monedas en total',                           icon: Icons.savings,             isUnlocked: false, currentValue: 0, targetValue: 100,    categoryId: '5', coinReward: 25),
          Achievement(id: 'e11', title: 'Primer centenar',        description: 'Gana 200 monedas en total',                           icon: Icons.toll,                isUnlocked: false, currentValue: 0, targetValue: 200,    categoryId: '5', coinReward: 30),
          Achievement(id: 'e2',  title: 'Pequeño tesoro',         description: 'Gana 250 monedas en total',                           icon: Icons.monetization_on,     isUnlocked: false, currentValue: 0, targetValue: 250,    categoryId: '5', coinReward: 50),
          Achievement(id: 'e3',  title: 'Ahorrista',              description: 'Gana 500 monedas en total',                           icon: Icons.account_balance,     isUnlocked: false, currentValue: 0, targetValue: 500,    categoryId: '5', coinReward: 75),
          Achievement(id: 'e12', title: 'Bienvenida dorada',      description: 'Gana 750 monedas en total',                           icon: Icons.star_border,         isUnlocked: false, currentValue: 0, targetValue: 750,    categoryId: '5', coinReward: 80),
          Achievement(id: 'e4',  title: 'Buen guardián',          description: 'Gana 1000 monedas en total',                          icon: Icons.shield,              isUnlocked: false, currentValue: 0, targetValue: 1000,   categoryId: '5', coinReward: 100),
          Achievement(id: 'e13', title: 'Creciendo',              description: 'Gana 1500 monedas en total',                          icon: Icons.trending_up,         isUnlocked: false, currentValue: 0, targetValue: 1500,   categoryId: '5', coinReward: 150),
          Achievement(id: 'e5',  title: 'Rico en logros',         description: 'Gana 2500 monedas en total',                          icon: Icons.workspace_premium,   isUnlocked: false, currentValue: 0, targetValue: 2500,   categoryId: '5', coinReward: 200),
          Achievement(id: 'e6',  title: 'Inversor',               description: 'Gana 5000 monedas en total',                          icon: Icons.account_balance_wallet, isUnlocked: false, currentValue: 0, targetValue: 5000, categoryId: '5', coinReward: 400),
          Achievement(id: 'e14', title: 'Prosperidad',            description: 'Gana 7500 monedas en total',                          icon: Icons.diamond,             isUnlocked: false, currentValue: 0, targetValue: 7500,   categoryId: '5', coinReward: 500),
          Achievement(id: 'e7',  title: 'Gran fortuna',           description: 'Gana 10.000 monedas en total',                        icon: Icons.auto_awesome,        isUnlocked: false, currentValue: 0, targetValue: 10000,  categoryId: '5', coinReward: 600),
          Achievement(id: 'e15', title: 'Élite de monedas',       description: 'Gana 15.000 monedas en total',                        icon: Icons.emoji_events,        isUnlocked: false, currentValue: 0, targetValue: 15000,  categoryId: '5', coinReward: 750),
          Achievement(id: 'e8',  title: 'Magnate',                description: 'Gana 25.000 monedas en total',                        icon: Icons.military_tech,       isUnlocked: false, currentValue: 0, targetValue: 25000,  categoryId: '5', coinReward: 1000),
          Achievement(id: 'e9',  title: 'Millonario virtual',     description: 'Gana 50.000 monedas en total',                        icon: Icons.stars,               isUnlocked: false, currentValue: 0, targetValue: 50000,  categoryId: '5', coinReward: 2000),
          Achievement(id: 'e10', title: 'Leyenda dorada',         description: 'Gana 100.000 monedas en total',                       icon: Icons.brightness_7,        isUnlocked: false, currentValue: 0, targetValue: 100000, categoryId: '5', coinReward: 3000),
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
          // Por compras (numCompras)
          Achievement(id: 'f1',  title: 'Primera compra',         description: 'Compra tu primer artículo en la tienda',              icon: Icons.shopping_bag,        isUnlocked: false, currentValue: 0, targetValue: 1,  categoryId: '6', coinReward: 50),
          Achievement(id: 'f6',  title: 'De vuelta a la tienda',  description: 'Compra 2 artículos en la tienda',                     icon: Icons.shopping_cart,       isUnlocked: false, currentValue: 0, targetValue: 2,  categoryId: '6', coinReward: 75),
          Achievement(id: 'f2',  title: 'Comprador frecuente',    description: 'Compra 3 artículos en la tienda',                     icon: Icons.local_mall,          isUnlocked: false, currentValue: 0, targetValue: 3,  categoryId: '6', coinReward: 100),
          Achievement(id: 'f10', title: 'Buen gusto',             description: 'Compra 4 artículos en la tienda',                     icon: Icons.style,               isUnlocked: false, currentValue: 0, targetValue: 4,  categoryId: '6', coinReward: 125),
          Achievement(id: 'f3',  title: 'Entusiasta',             description: 'Compra 5 artículos en la tienda',                     icon: Icons.favorite,            isUnlocked: false, currentValue: 0, targetValue: 5,  categoryId: '6', coinReward: 150),
          Achievement(id: 'f11', title: 'Decorador',              description: 'Compra 6 artículos en la tienda',                     icon: Icons.palette,             isUnlocked: false, currentValue: 0, targetValue: 6,  categoryId: '6', coinReward: 175),
          Achievement(id: 'f7',  title: 'Fan de la tienda',       description: 'Compra 7 artículos en la tienda',                     icon: Icons.storefront,          isUnlocked: false, currentValue: 0, targetValue: 7,  categoryId: '6', coinReward: 200),
          Achievement(id: 'f4',  title: 'Coleccionista de tienda', description: 'Compra 8 artículos en la tienda',                    icon: Icons.collections,         isUnlocked: false, currentValue: 0, targetValue: 8,  categoryId: '6', coinReward: 250),
          // Por saldo actual (currentMonedas)
          Achievement(id: 'f9',  title: 'Bolsillos llenos',       description: 'Ten 100 monedas al mismo tiempo',                     icon: Icons.account_balance_wallet, isUnlocked: false, currentValue: 0, targetValue: 100,   categoryId: '6', coinReward: 25),
          Achievement(id: 'f12', title: 'Ahorro básico',          description: 'Ten 500 monedas al mismo tiempo',                     icon: Icons.savings,             isUnlocked: false, currentValue: 0, targetValue: 500,   categoryId: '6', coinReward: 50),
          Achievement(id: 'f13', title: 'Buen saldo',             description: 'Ten 1000 monedas al mismo tiempo',                    icon: Icons.toll,                isUnlocked: false, currentValue: 0, targetValue: 1000,  categoryId: '6', coinReward: 100),
          Achievement(id: 'f14', title: 'Saldo generoso',         description: 'Ten 2000 monedas al mismo tiempo',                    icon: Icons.monetization_on,     isUnlocked: false, currentValue: 0, targetValue: 2000,  categoryId: '6', coinReward: 200),
          Achievement(id: 'f15', title: 'Rico de verdad',         description: 'Ten 5000 monedas al mismo tiempo',                    icon: Icons.workspace_premium,   isUnlocked: false, currentValue: 0, targetValue: 5000,  categoryId: '6', coinReward: 400),
          Achievement(id: 'f5',  title: 'El más rico',            description: 'Ten 10.000 monedas al mismo tiempo',                  icon: Icons.diamond,             isUnlocked: false, currentValue: 0, targetValue: 10000, categoryId: '6', coinReward: 700),
          Achievement(id: 'f8',  title: 'Millonario local',       description: 'Ten 20.000 monedas al mismo tiempo',                  icon: Icons.stars,               isUnlocked: false, currentValue: 0, targetValue: 20000, categoryId: '6', coinReward: 1200),
        ],
      ),

      // ── 7. FIDELIDAD (15 logros — días desde registro) ────────────────
      AchievementCategory(
        id: '7',
        name: 'Fidelidad',
        icon: Icons.favorite,
        achievements: [
          Achievement(id: 'g1',  title: 'Bienvenido',             description: 'Lleva 1 día usando HabitCrew',                        icon: Icons.waving_hand,         isUnlocked: false, currentValue: 0, targetValue: 1,    categoryId: '7', coinReward: 25),
          Achievement(id: 'g2',  title: 'Tres días',              description: 'Lleva 3 días usando HabitCrew',                       icon: Icons.calendar_view_day,   isUnlocked: false, currentValue: 0, targetValue: 3,    categoryId: '7', coinReward: 50),
          Achievement(id: 'g3',  title: 'Una semana',             description: 'Lleva 7 días usando HabitCrew',                       icon: Icons.calendar_today,      isUnlocked: false, currentValue: 0, targetValue: 7,    categoryId: '7', coinReward: 75),
          Achievement(id: 'g4',  title: 'Dos semanas',            description: 'Lleva 14 días usando HabitCrew',                      icon: Icons.date_range,          isUnlocked: false, currentValue: 0, targetValue: 14,   categoryId: '7', coinReward: 100),
          Achievement(id: 'g5',  title: 'Un mes fiel',            description: 'Lleva 30 días usando HabitCrew',                      icon: Icons.calendar_month,      isUnlocked: false, currentValue: 0, targetValue: 30,   categoryId: '7', coinReward: 200),
          Achievement(id: 'g6',  title: 'Mes y medio',            description: 'Lleva 45 días usando HabitCrew',                      icon: Icons.event_available,     isUnlocked: false, currentValue: 0, targetValue: 45,   categoryId: '7', coinReward: 300),
          Achievement(id: 'g7',  title: 'Dos meses fiel',         description: 'Lleva 60 días usando HabitCrew',                      icon: Icons.event_repeat,        isUnlocked: false, currentValue: 0, targetValue: 60,   categoryId: '7', coinReward: 400),
          Achievement(id: 'g8',  title: 'Trimestre',              description: 'Lleva 90 días usando HabitCrew',                      icon: Icons.today,               isUnlocked: false, currentValue: 0, targetValue: 90,   categoryId: '7', coinReward: 500),
          Achievement(id: 'g9',  title: 'Cuatro meses',           description: 'Lleva 120 días usando HabitCrew',                     icon: Icons.hourglass_top,       isUnlocked: false, currentValue: 0, targetValue: 120,  categoryId: '7', coinReward: 600),
          Achievement(id: 'g10', title: 'Medio año',              description: 'Lleva 180 días usando HabitCrew',                     icon: Icons.access_time,         isUnlocked: false, currentValue: 0, targetValue: 180,  categoryId: '7', coinReward: 800),
          Achievement(id: 'g11', title: 'Tres cuartos',           description: 'Lleva 270 días usando HabitCrew',                     icon: Icons.hourglass_bottom,    isUnlocked: false, currentValue: 0, targetValue: 270,  categoryId: '7', coinReward: 1000),
          Achievement(id: 'g12', title: 'Un año fiel',            description: 'Lleva 365 días usando HabitCrew',                     icon: Icons.celebration,         isUnlocked: false, currentValue: 0, targetValue: 365,  categoryId: '7', coinReward: 1500),
          Achievement(id: 'g13', title: 'Año y medio',            description: 'Lleva 548 días usando HabitCrew',                     icon: Icons.emoji_events,        isUnlocked: false, currentValue: 0, targetValue: 548,  categoryId: '7', coinReward: 2000),
          Achievement(id: 'g14', title: 'Dos años fiel',          description: 'Lleva 730 días usando HabitCrew',                     icon: Icons.workspace_premium,   isUnlocked: false, currentValue: 0, targetValue: 730,  categoryId: '7', coinReward: 2500),
          Achievement(id: 'g15', title: 'Veterano',               description: 'Lleva 1095 días usando HabitCrew (3 años)',           icon: Icons.military_tech,       isUnlocked: false, currentValue: 0, targetValue: 1095, categoryId: '7', coinReward: 3000),
        ],
      ),
    ];
  }
}
