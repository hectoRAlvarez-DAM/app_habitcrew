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
