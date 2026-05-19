import 'package:app_habitcrew/Screen/models/archievement.dart';
import 'package:app_habitcrew/Screen/models/archievement_category.dart';
import 'package:app_habitcrew/repositories/achievement_repository.dart';
import 'package:app_habitcrew/servicios/achievement_definitions.dart';
import 'package:app_habitcrew/servicios/achievement_seeder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

export 'package:app_habitcrew/servicios/achievement_definitions.dart'
    show AchievementDefinition;

class AchievementService {
  static final AchievementService instance = AchievementService._internal();
  AchievementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _repo = AchievementRepository();

  String? get _uid => _auth.currentUser?.uid;

  // Delegado a AchievementDefinition para compatibilidad con callers externos.
  static List<AchievementDefinition> get allAchievements =>
      AchievementDefinition.allAchievements;

  // ─── Nueva arquitectura: carga completa con subcol. logros ────────

  /// Carga todas las categorías con el estado real del usuario.
  /// Auto-desbloquea los logros cumplidos y persiste en Firestore.
  /// Actualiza `totalLogros` en el documento del usuario.
  /// Devuelve: (categorías fusionadas, IDs de logros ya reclamados)
  Future<(List<AchievementCategory>, Set<String>)> loadUserAchievements() async {
    // Siembra el catálogo en Firestore si aún no se ha hecho.
    await AchievementSeeder.instance.seedIfNeeded();

    final uid = _uid;
    if (uid == null) {
      final catalog = await _repo.getCategories();
      return (catalog, <String>{});
    }

    // ── 1. Catálogo desde Firestore ──────────────────────────────────────
    final catalog = await _repo.getCategories();

    try {
      final userRef = _firestore.collection('usuaris').doc(uid);

      // ── 2. Datos del usuario y subcolecciones en paralelo ────────────────
      final results = await Future.wait([
        userRef.get(),
        userRef.collection('habitos').get(),
        userRef.collection('logros').get(),
        userRef.collection('compras').get(),
      ]);

      final userDoc     = results[0] as DocumentSnapshot<Map<String, dynamic>>;
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

      // ── 5. Estados guardados en subcol. logros ───────────────────────────
      final savedLogros = {
        for (final doc in logrosSnap.docs) doc.id: doc.data()
      };

      // ── 6. Función de métrica por logro (usa conditionType de Firestore) ──
      int currentFor(Achievement a) {
        switch (a.conditionType) {
          case 'racha':             return mejorRacha;
          case 'total_completados': return totalCompletados;
          case 'num_habitos':       return numHabitos;
          case 'dias_perfectos':    return diasPerfectos;
          case 'amigos':            return 0;
          case 'monedas_ganadas':   return monedasGanadas;
          case 'num_compras':       return numCompras;
          case 'monedas_actuales':  return currentMonedas;
          case 'dias_registro':     return diasDesdeRegistro;
          default:                  return 0;
        }
      }

      // ── 7. Fusionar catálogo + Firestore, auto-desbloquear nuevos ────────
      final WriteBatch batch = _firestore.batch();

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

  /// Reclama las monedas de un logro de forma atómica.
  /// Devuelve true si tuvo éxito, false si ya estaba reclamado o hubo error.
  Future<bool> claimAchievement(String achievementId, int coinAmount) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      final userRef = _firestore.collection('usuaris').doc(uid);
      final logroRef = userRef.collection('logros').doc(achievementId);

      bool alreadyClaimed = false;
      await _firestore.runTransaction((tx) async {
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
      final userRef = _firestore.collection('usuaris').doc(uid);
      final batch = _firestore.batch();

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

  // ─── Obtener progreso real del usuario (legacy) ──────────────────

  Future<Map<String, dynamic>> obtenerProgreso() async {
    final uid = _uid;
    if (uid == null) return {};

    try {
      final results = await Future.wait([
        _firestore.collection('usuaris').doc(uid).get(),
        _firestore.collection('usuaris').doc(uid).collection('habitos').get(),
      ]);

      final userDoc     = results[0] as DocumentSnapshot;
      final habitosSnap = results[1] as QuerySnapshot;
      final userData    = userDoc.data() as Map<String, dynamic>? ?? {};

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
        'fechasLogros': userData['fechasLogros'] as Map<String, dynamic>? ?? {},
      };
    } catch (e) {
      return {};
    }
  }

  /// Asigna la insignia Beta al usuario automáticamente (una sola vez).
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

      if (desbloqueados.contains('beta') && tieneBannerBeta) return;

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

  /// Comprueba si hay logros nuevos que desbloquear y los procesa (legacy).
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
      final monedas = nuevosDesbloqueados.fold<int>(0, (acc, id) {
        final def = allAchievements.firstWhere((a) => a.id == id);
        return acc + def.coinReward;
      });

      final batch = _firestore.batch();
      final userRef = _firestore.collection('usuaris').doc(uid);

      batch.update(userRef, {
        'logrosDesbloqueados': FieldValue.arrayUnion(nuevosDesbloqueados),
        'fechasLogros': {
          for (final id in nuevosDesbloqueados) id: Timestamp.now(),
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
    if (equipadas.length >= 3) equipadas.removeAt(0);
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
