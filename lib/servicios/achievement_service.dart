import 'package:app_habitcrew/Screen/models/archievement.dart';
import 'package:app_habitcrew/Screen/models/archievement_category.dart';
import 'package:app_habitcrew/repositories/achievement_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Gestiona el estado real de logros del usuario en Firestore.
///
/// Colección: usuaris/{uid}/logros/{achievementId}
/// Campos: isUnlocked, unlockedDate, coinsClaimed, claimedAt
///
/// Métricas para calcular progreso (calculadas en vivo desde Firestore):
///   - Constancia (cat 1)  : mejorRacha = max(recordRacha, rachaActual) entre todos los hábitos
///   - Progreso crear (cat 2, b1/b2/b3/b13/b14/b15): numHabitos
///   - Progreso completar (cat 2, resto)           : totalHabitosCompletados
///   - Maestría (cat 3)    : diasPerfectos
///   - Equipo (cat 4)      : sin implementar (siempre 0)
///   - Monedas (cat 5)     : monedasGanadas (acumulado total)
///   - Tienda compras (cat 6, f1-f8) : numCompras
///   - Tienda saldo (cat 6, f9-f15)  : monedas actuales
///   - Fidelidad (cat 7)   : días desde data_registre
class AchievementService {
  static final AchievementService instance = AchievementService._internal();
  AchievementService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _repo = AchievementRepository();

  // IDs de logros de tienda que usan saldo actual (no numCompras)
  static const _shopBalanceIds = {'f9', 'f10', 'f11', 'f12', 'f13', 'f14', 'f15'};
  // IDs de logros de progreso que usan numHabitos (creación, no completados)
  static const _habitCreationIds = {'b1', 'b2', 'b3', 'b13', 'b14', 'b15'};

  String? get _uid => _auth.currentUser?.uid;

  /// Carga todas las categorías con el estado real del usuario.
  /// Auto-desbloquea los logros cumplidos y persiste en Firestore.
  /// Actualiza `totalLogros` en el documento del usuario.
  /// Devuelve: (categorías fusionadas, IDs de logros ya reclamados)
  Future<(List<AchievementCategory>, Set<String>)> loadUserAchievements() async {
    final uid = _uid;
    if (uid == null) {
      final catalog = await _repo.getCategories();
      return (catalog, <String>{});
    }

    // ── 1. Catálogo estático ─────────────────────────────────────────────
    final catalog = await _repo.getCategories();

    try {
      final userRef = _db.collection('usuaris').doc(uid);

      // ── 2. Datos del usuario y subcolecciones en paralelo ────────────────
      final results = await Future.wait([
        userRef.get(),
        userRef.collection('habitos').get(),
        userRef.collection('logros').get(),
        userRef.collection('compras').get(),
      ]);

      final userDoc    = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final habitosSnap = results[1] as QuerySnapshot<Map<String, dynamic>>;
      final logrosSnap  = results[2] as QuerySnapshot<Map<String, dynamic>>;
      final comprasSnap = results[3] as QuerySnapshot<Map<String, dynamic>>;

      final userData = userDoc.data() ?? {};

      // ── 3. Métricas globales ─────────────────────────────────────────────
      final totalCompletados = (userData['totalHabitosCompletados'] as num?)?.toInt() ?? 0;
      final diasPerfectos    = (userData['diasPerfectos']           as num?)?.toInt() ?? 0;
      final monedasGanadas   = (userData['monedasGanadas']          as num?)?.toInt() ?? 0;
      final currentMonedas   = (userData['monedas']                 as num?)?.toInt() ?? 0;
      final numCompras       = comprasSnap.docs.length;

      final dataRegistre = userData['data_registre'] as Timestamp?;
      final diasDesdeRegistro = dataRegistre != null
          ? DateTime.now().difference(dataRegistre.toDate()).inDays
          : 0;

      // ── 4. Mejor racha y número de hábitos ──────────────────────────────
      final numHabitos = habitosSnap.docs.length;
      int mejorRacha = 0;
      for (final doc in habitosSnap.docs) {
        final d = doc.data();
        final record = (d['recordRacha'] as num?)?.toInt() ?? 0;
        final actual = (d['rachaActual'] as num?)?.toInt() ?? 0;
        final best = record > actual ? record : actual;
        if (best > mejorRacha) mejorRacha = best;
      }

      // ── 5. Estados guardados ─────────────────────────────────────────────
      final savedLogros = {
        for (final doc in logrosSnap.docs) doc.id: doc.data()
      };

      // ── 6. Función de métrica por logro ──────────────────────────────────
      int currentFor(Achievement a) {
        switch (a.categoryId) {
          case '1': return mejorRacha;
          case '2': return _habitCreationIds.contains(a.id) ? numHabitos : totalCompletados;
          case '3': return diasPerfectos;
          case '4': return 0;
          case '5': return monedasGanadas;
          case '6': return _shopBalanceIds.contains(a.id) ? currentMonedas : numCompras;
          case '7': return diasDesdeRegistro;
          default:  return 0;
        }
      }

      // ── 7. Fusionar catálogo + Firestore, auto-desbloquear nuevos ────────
      final WriteBatch batch = _db.batch();

      final updatedCategories = catalog.map((cat) {
        final updatedAchievements = cat.achievements.map((a) {
          final saved = savedLogros[a.id];
          final currentVal = currentFor(a);
          final alreadyUnlocked = saved?['isUnlocked'] == true;
          final newlyUnlocked = !alreadyUnlocked && currentVal >= a.targetValue;
          final isUnlocked = alreadyUnlocked || newlyUnlocked;

          DateTime? unlockedDate;
          if (alreadyUnlocked && saved?['unlockedDate'] != null) {
            unlockedDate = (saved!['unlockedDate'] as Timestamp).toDate();
          } else if (newlyUnlocked) {
            unlockedDate = DateTime.now();
            batch.set(
              userRef.collection('logros').doc(a.id),
              {
                'isUnlocked': true,
                'unlockedDate': FieldValue.serverTimestamp(),
                'coinsClaimed': false,
              },
              SetOptions(merge: true),
            );
          }

          return a.copyWith(
            isUnlocked: isUnlocked,
            unlockedDate: unlockedDate,
            currentValue: currentVal,
          );
        }).toList();

        return AchievementCategory(
          id: cat.id,
          name: cat.name,
          icon: cat.icon,
          achievements: updatedAchievements,
        );
      }).toList();

      // ── 8. Guardar totalLogros en el documento del usuario ───────────────
      final totalUnlocked = updatedCategories
          .expand((c) => c.achievements)
          .where((a) => a.isUnlocked)
          .length;

      batch.set(
        userRef,
        {'totalLogros': totalUnlocked},
        SetOptions(merge: true),
      );

      await batch.commit();

      // ── 9. IDs de logros con monedas ya reclamadas ───────────────────────
      final claimedIds = {
        for (final e in savedLogros.entries)
          if (e.value['coinsClaimed'] == true) e.key
      };

      return (updatedCategories, claimedIds);
    } catch (_) {
      return (catalog, <String>{});
    }
  }

  /// Reclama las monedas de un logro de forma atómica:
  /// marca coinsClaimed=true e incrementa monedas en una sola transacción.
  /// Devuelve true si tuvo éxito, false si ya estaba reclamado o hubo error.
  Future<bool> claimAchievement(String achievementId, int coinAmount) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      final userRef = _db.collection('usuaris').doc(uid);
      final logroRef = userRef.collection('logros').doc(achievementId);

      bool alreadyClaimed = false;
      await _db.runTransaction((tx) async {
        final snap = await tx.get(logroRef);
        if (snap.data()?['coinsClaimed'] == true) {
          alreadyClaimed = true;
          return;
        }
        tx.set(
          logroRef,
          {'coinsClaimed': true, 'claimedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
        tx.update(userRef, {
          'monedas': FieldValue.increment(coinAmount),
          'monedasGanadas': FieldValue.increment(coinAmount),
        });
      });
      return !alreadyClaimed;
    } catch (_) {
      return false;
    }
  }

  /// Reclama todos los logros desbloqueados no reclamados en un único batch.
  /// Devuelve las monedas totales añadidas (0 si falló).
  Future<int> claimAllAchievements(
      List<String> achievementIds, int totalCoins) async {
    final uid = _uid;
    if (uid == null || achievementIds.isEmpty) return 0;
    try {
      final userRef = _db.collection('usuaris').doc(uid);
      final batch = _db.batch();

      for (final id in achievementIds) {
        batch.set(
          userRef.collection('logros').doc(id),
          {'coinsClaimed': true, 'claimedAt': FieldValue.serverTimestamp()},
          SetOptions(merge: true),
        );
      }
      batch.update(userRef, {
        'monedas': FieldValue.increment(totalCoins),
        'monedasGanadas': FieldValue.increment(totalCoins),
      });

      await batch.commit();
      return totalCoins;
    } catch (_) {
      return 0;
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  // Tipo de condición: 'racha', 'total_completados', 'num_habitos', 'amigos'
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
}

class AchievementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ─── Definiciones de todos los logros ───────────────────────────

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
    AchievementDefinition(id: 'a1', title: 'Primera chispa', description: 'Completa un hábito por primera vez', icon: Icons.star, categoryId: '1', targetValue: 1, coinReward: 25, conditionType: 'total_completados'),
    AchievementDefinition(id: 'a2', title: 'Racha de 3 días', description: 'Mantén un hábito 3 días seguidos', icon: Icons.whatshot, categoryId: '1', targetValue: 3, coinReward: 50, conditionType: 'racha'),
    AchievementDefinition(id: 'a3', title: 'Racha semanal', description: 'Mantén un hábito 7 días seguidos', icon: Icons.calendar_today, categoryId: '1', targetValue: 7, coinReward: 75, conditionType: 'racha'),
    AchievementDefinition(id: 'a4', title: 'Dos semanas', description: 'Mantén una racha de 14 días consecutivos', icon: Icons.date_range, categoryId: '1', targetValue: 14, coinReward: 150, conditionType: 'racha'),
    AchievementDefinition(id: 'a5', title: 'Tres semanas', description: 'Mantén una racha de 21 días consecutivos', icon: Icons.event_repeat, categoryId: '1', targetValue: 21, coinReward: 200, conditionType: 'racha'),
    AchievementDefinition(id: 'a6', title: 'Racha mensual', description: 'Mantén un hábito 30 días seguidos', icon: Icons.calendar_month, categoryId: '1', targetValue: 30, coinReward: 300, conditionType: 'racha'),
    AchievementDefinition(id: 'a7', title: 'Dos meses', description: 'Mantén una racha de 60 días consecutivos', icon: Icons.auto_awesome, categoryId: '1', targetValue: 60, coinReward: 500, conditionType: 'racha'),
    AchievementDefinition(id: 'a8', title: 'Trimestre de fuego', description: 'Mantén una racha de 90 días consecutivos', icon: Icons.local_fire_department, categoryId: '1', targetValue: 90, coinReward: 700, conditionType: 'racha'),
    AchievementDefinition(id: 'a9', title: 'Centenario', description: 'Alcanza una racha de 100 días', icon: Icons.emoji_events, categoryId: '1', targetValue: 100, coinReward: 800, conditionType: 'racha'),
    AchievementDefinition(id: 'a10', title: 'Semestre legendario', description: 'Mantén una racha de 180 días consecutivos', icon: Icons.workspace_premium, categoryId: '1', targetValue: 180, coinReward: 1000, conditionType: 'racha'),
    AchievementDefinition(id: 'a11', title: 'Año completo', description: 'Mantén una racha durante 365 días', icon: Icons.military_tech, categoryId: '1', targetValue: 365, coinReward: 2000, conditionType: 'racha'),

    // PROGRESO — total completados / hábitos creados
    AchievementDefinition(id: 'b1', title: 'Primer hábito', description: 'Crea tu primer hábito', icon: Icons.add_task, categoryId: '2', targetValue: 1, coinReward: 25, conditionType: 'num_habitos'),
    AchievementDefinition(id: 'b2', title: 'Coleccionista', description: 'Crea 5 hábitos diferentes', icon: Icons.list_alt, categoryId: '2', targetValue: 5, coinReward: 100, conditionType: 'num_habitos'),
    AchievementDefinition(id: 'b3', title: 'Arsenal', description: 'Crea 10 hábitos diferentes', icon: Icons.grid_view, categoryId: '2', targetValue: 10, coinReward: 200, conditionType: 'num_habitos'),
    AchievementDefinition(id: 'b4', title: 'Máquina de hábitos', description: 'Completa 50 hábitos en total', icon: Icons.done_all, categoryId: '2', targetValue: 50, coinReward: 150, conditionType: 'total_completados'),
    AchievementDefinition(id: 'b5', title: 'Centenario', description: 'Completa 100 hábitos en total', icon: Icons.verified, categoryId: '2', targetValue: 100, coinReward: 300, conditionType: 'total_completados'),
    AchievementDefinition(id: 'b6', title: 'Imparable', description: 'Completa 500 hábitos en total', icon: Icons.bolt, categoryId: '2', targetValue: 500, coinReward: 800, conditionType: 'total_completados'),
    AchievementDefinition(id: 'b7', title: 'Leyenda', description: 'Completa 1000 hábitos en total', icon: Icons.diamond, categoryId: '2', targetValue: 1000, coinReward: 1500, conditionType: 'total_completados'),

    // MAESTRÍA — días perfectos
    AchievementDefinition(id: 'c1', title: 'Disciplinado', description: 'Completa todos tus hábitos del día 10 veces', icon: Icons.verified, categoryId: '3', targetValue: 10, coinReward: 200, conditionType: 'dias_perfectos'),
    AchievementDefinition(id: 'c2', title: 'Sin excusas', description: 'No faltes ningún día durante un mes', icon: Icons.shield, categoryId: '3', targetValue: 30, coinReward: 400, conditionType: 'dias_perfectos'),
    AchievementDefinition(id: 'c3', title: 'Perfeccionista', description: 'Completa todos tus hábitos del día durante 60 días', icon: Icons.grade, categoryId: '3', targetValue: 60, coinReward: 600, conditionType: 'dias_perfectos'),
    AchievementDefinition(id: 'c4', title: 'Maestro', description: 'Completa todos tus hábitos del día durante 100 días', icon: Icons.workspace_premium, categoryId: '3', targetValue: 100, coinReward: 1000, conditionType: 'dias_perfectos'),
    AchievementDefinition(id: 'c5', title: 'Inmortal', description: 'Completa todos tus hábitos del día durante 200 días', icon: Icons.auto_awesome, categoryId: '3', targetValue: 200, coinReward: 2000, conditionType: 'dias_perfectos'),

    // EQUIPO — amigos
    AchievementDefinition(id: 'd1', title: 'Primer compañero', description: 'Añade tu primer amigo', icon: Icons.person_add, categoryId: '4', targetValue: 1, coinReward: 50, conditionType: 'amigos'),
    AchievementDefinition(id: 'd2', title: 'Motivador', description: 'Añade 5 amigos', icon: Icons.thumb_up, categoryId: '4', targetValue: 5, coinReward: 100, conditionType: 'amigos'),
    AchievementDefinition(id: 'd3', title: 'Influencer', description: 'Añade 10 amigos', icon: Icons.record_voice_over, categoryId: '4', targetValue: 10, coinReward: 250, conditionType: 'amigos'),
  ];

  // ─── Obtener progreso real del usuario ───────────────────────────

  Future<Map<String, dynamic>> obtenerProgreso() async {
    final uid = _uid;
    if (uid == null) return {};

    try {
      final results = await Future.wait([
        _firestore.collection('usuaris').doc(uid).get(),
        _firestore.collection('usuaris').doc(uid).collection('habitos').get(),
      ]);

      final userDoc = results[0] as DocumentSnapshot;
      final habitosSnap = results[1] as QuerySnapshot;
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};

      // Calcular mejor racha entre todos los hábitos
      int mejorRacha = 0;
      int numHabitos = habitosSnap.docs.length;
      for (final doc in habitosSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final racha = (data['recordRacha'] as num?)?.toInt() ?? 0;
        if (racha > mejorRacha) mejorRacha = racha;
      }

      return {
        'totalCompletados': (userData['totalHabitosCompletados'] as num?)?.toInt() ?? 0,
        'mejorRacha': mejorRacha,
        'numHabitos': numHabitos,
        'diasPerfectos': (userData['diasPerfectos'] as num?)?.toInt() ?? 0,
        'numAmigos': (userData['amigos'] as List?)?.length ?? 0,
        'logrosDesbloqueados': List<String>.from(userData['logrosDesbloqueados'] ?? []),
        'insigniasEquipadas': List<String>.from(userData['insigniasEquipadas'] ?? []),
      };
    } catch (e) {
      return {};
    }
  }

  /// Asigna la insignia Beta a todos los usuarios automáticamente.
  /// Solo se ejecuta una vez — si ya la tiene, no hace nada.
  Future<void> asignarInsigniaBeta() async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final doc = await _firestore.collection('usuaris').doc(uid).get();
      final data = doc.data() ?? {};
      final desbloqueados = List<String>.from(data['logrosDesbloqueados'] ?? []);
      final itemsCofre = List<Map<String, dynamic>>.from(data['itemsCofre'] ?? []);

      final tieneBannerBeta = itemsCofre.any(
          (i) => i['tipo'] == 'banner' && i['nombre'] == 'Beta');
      final tieneAvatarBeta = itemsCofre.any(
          (i) => i['tipo'] == 'avatar' && i['nombre'] == 'Beta');

      // Si ya tiene todo, no hacer nada
      if (desbloqueados.contains('beta') && tieneBannerBeta && tieneAvatarBeta) return;

      final updates = <String, dynamic>{};

      if (!desbloqueados.contains('beta')) {
        updates['logrosDesbloqueados'] = FieldValue.arrayUnion(['beta']);
        updates['fechasLogros'] = {'beta': Timestamp.now()};
      }

      final itemsNuevos = <Map<String, dynamic>>[];
      if (!tieneBannerBeta) {
        itemsNuevos.add({
          'tipo': 'banner',
          'nombre': 'Beta',
          'emoji': '🚀',
          'fecha': Timestamp.now(),
        });
      }
      if (!tieneAvatarBeta) {
        itemsNuevos.add({
          'tipo': 'avatar',
          'nombre': 'Beta',
          'emoji': 'β',
          'fecha': Timestamp.now(),
        });
      }
      if (itemsNuevos.isNotEmpty) {
        updates['itemsCofre'] = FieldValue.arrayUnion(itemsNuevos);
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('usuaris').doc(uid).set(
          updates,
          SetOptions(merge: true),
        );
      }
    } catch (_) {}
  }

  /// Comprueba si hay logros nuevos que desbloquear y los procesa.
  /// Devuelve lista de IDs de logros recién desbloqueados.
  Future<List<String>> comprobarLogros() async {
    final uid = _uid;
    if (uid == null) return [];

    final progreso = await obtenerProgreso();
    if (progreso.isEmpty) return [];

    final yaDesbloqueados = List<String>.from(progreso['logrosDesbloqueados'] ?? []);
    final nuevosDesbloqueados = <String>[];

    for (final logro in allAchievements) {
      if (yaDesbloqueados.contains(logro.id)) continue;

      int valorActual = 0;
      switch (logro.conditionType) {
        case 'racha':
          valorActual = progreso['mejorRacha'] as int? ?? 0;
          break;
        case 'total_completados':
          valorActual = progreso['totalCompletados'] as int? ?? 0;
          break;
        case 'num_habitos':
          valorActual = progreso['numHabitos'] as int? ?? 0;
          break;
        case 'dias_perfectos':
          valorActual = progreso['diasPerfectos'] as int? ?? 0;
          break;
        case 'amigos':
          valorActual = progreso['numAmigos'] as int? ?? 0;
          break;
      }

      if (valorActual >= logro.targetValue) {
        nuevosDesbloqueados.add(logro.id);
      }
    }

    if (nuevosDesbloqueados.isNotEmpty) {
      // Guardar logros desbloqueados y sumar monedas
      final monedas = nuevosDesbloqueados.fold<int>(0, (sum, id) {
        final def = allAchievements.firstWhere((a) => a.id == id);
        return sum + def.coinReward;
      });

      final batch = _firestore.batch();
      final userRef = _firestore.collection('usuaris').doc(uid);

      batch.update(userRef, {
        'logrosDesbloqueados': FieldValue.arrayUnion(nuevosDesbloqueados),
        'fechasLogros': {
          for (final id in nuevosDesbloqueados)
            id: Timestamp.now(),
        },
        'monedas': FieldValue.increment(monedas),
      });

      await batch.commit();
    }

    return nuevosDesbloqueados;
  }

  /// Registra un día perfecto (todos los hábitos completados).
  Future<void> registrarDiaPerfecto() async {
    final uid = _uid;
    if (uid == null) return;

    await _firestore.collection('usuaris').doc(uid).set(
      {'diasPerfectos': FieldValue.increment(1)},
      SetOptions(merge: true),
    );
  }

  // ─── Insignias equipadas ─────────────────────────────────────────

  /// Equipa una insignia (máximo 3 simultáneas).
  Future<void> equiparInsignia(String logroId) async {
    final uid = _uid;
    if (uid == null) return;

    final doc = await _firestore.collection('usuaris').doc(uid).get();
    final equipadas = List<String>.from(doc.data()?['insigniasEquipadas'] ?? []);

    if (equipadas.contains(logroId)) return;
    if (equipadas.length >= 3) equipadas.removeAt(0); // Quitar la más antigua
    equipadas.add(logroId);

    await _firestore.collection('usuaris').doc(uid).update({
      'insigniasEquipadas': equipadas,
    });
  }

  /// Desequipa una insignia.
  Future<void> desequiparInsignia(String logroId) async {
    final uid = _uid;
    if (uid == null) return;

    await _firestore.collection('usuaris').doc(uid).update({
      'insigniasEquipadas': FieldValue.arrayRemove([logroId]),
    });
  }

  /// Equipa un banner en el perfil.
  Future<void> equiparBanner(String nombre) async {
    final uid = _uid;
    if (uid == null) return;
    await _firestore.collection('usuaris').doc(uid).set(
      {'bannerEquipado': nombre}, SetOptions(merge: true));
  }

  /// Desequipa el banner.
  Future<void> desequiparBanner() async {
    final uid = _uid;
    if (uid == null) return;
    await _firestore.collection('usuaris').doc(uid).update(
      {'bannerEquipado': null});
  }

  /// Equipa un avatar en el perfil.
  Future<void> equiparAvatar(String nombre) async {
    final uid = _uid;
    if (uid == null) return;
    await _firestore.collection('usuaris').doc(uid).set(
      {'avatarEquipado': nombre}, SetOptions(merge: true));
  }

  /// Desequipa el avatar.
  Future<void> desequiparAvatar() async {
    final uid = _uid;
    if (uid == null) return;
    await _firestore.collection('usuaris').doc(uid).update(
      {'avatarEquipado': null});
  }

  /// Stream de datos del usuario para actualizar insignias en tiempo real.
  Stream<DocumentSnapshot> streamUsuario() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _firestore.collection('usuaris').doc(uid).snapshots();
  }

  // ─── Helper: obtener definición por ID ──────────────────────────

  static AchievementDefinition? getById(String id) {
    try {
      return allAchievements.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}