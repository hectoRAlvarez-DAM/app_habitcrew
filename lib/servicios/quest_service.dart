import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ─── Tipos de recompensa ────────────────────────────────────────────
enum RewardType { monedasSmall, monedasBig, banner }

class ChestReward {
  final RewardType type;
  final int monedas;
  final String? itemName;
  final String? itemEmoji;

  const ChestReward({
    required this.type,
    this.monedas = 0,
    this.itemName,
    this.itemEmoji,
  });
}

// ─── Definición de misión ───────────────────────────────────────────
class DailyQuest {
  final String id;
  final String title;
  final String description;
  final String emoji;
  final int targetValue;
  // Tipo: 'completar_habitos', 'completar_todos', 'racha', 'completar_grupal'
  final String type;

  const DailyQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.targetValue,
    required this.type,
  });
}

class QuestService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ─── Pool completo de misiones ──────────────────────────────────

  static const List<DailyQuest> _questPool = [
    DailyQuest(
      id: 'q1',
      title: 'Primer paso',
      description: 'Completa 1 hábito hoy',
      emoji: '👣',
      targetValue: 1,
      type: 'completar_habitos',
    ),
    DailyQuest(
      id: 'q2',
      title: 'En marcha',
      description: 'Completa 2 hábitos hoy',
      emoji: '🚀',
      targetValue: 2,
      type: 'completar_habitos',
    ),
    DailyQuest(
      id: 'q3',
      title: 'Constante',
      description: 'Completa 3 hábitos hoy',
      emoji: '💪',
      targetValue: 3,
      type: 'completar_habitos',
    ),
    DailyQuest(
      id: 'q4',
      title: 'Imparable',
      description: 'Completa 5 hábitos hoy',
      emoji: '⚡',
      targetValue: 5,
      type: 'completar_habitos',
    ),
    DailyQuest(
      id: 'q5',
      title: 'Perfecto',
      description: 'Completa todos tus hábitos diarios',
      emoji: '🏆',
      targetValue: 1,
      type: 'completar_todos',
    ),
    DailyQuest(
      id: 'q6',
      title: 'En racha',
      description: 'Mantén una racha de 3 días en cualquier hábito',
      emoji: '🔥',
      targetValue: 3,
      type: 'racha',
    ),
    DailyQuest(
      id: 'q7',
      title: 'Veterano',
      description: 'Mantén una racha de 7 días en cualquier hábito',
      emoji: '🌟',
      targetValue: 7,
      type: 'racha',
    ),
    DailyQuest(
      id: 'q8',
      title: 'Madrugador',
      description: 'Completa un hábito antes de las 9:00',
      emoji: '🌅',
      targetValue: 1,
      type: 'completar_habitos',
    ),
    DailyQuest(
      id: 'q9',
      title: 'Trabajo en equipo',
      description: 'Completa un hábito grupal',
      emoji: '👥',
      targetValue: 1,
      type: 'completar_grupal',
    ),
    DailyQuest(
      id: 'q10',
      title: 'Disciplina',
      description: 'Completa 4 hábitos hoy',
      emoji: '🎯',
      targetValue: 4,
      type: 'completar_habitos',
    ),
    DailyQuest(
      id: 'q11',
      title: 'Fuerza de voluntad',
      description: 'Completa 2 hábitos antes del mediodía',
      emoji: '☀️',
      targetValue: 2,
      type: 'completar_habitos',
    ),
    DailyQuest(
      id: 'q12',
      title: 'Sin excusas',
      description: 'Completa todos tus hábitos de hoy',
      emoji: '✨',
      targetValue: 1,
      type: 'completar_todos',
    ),
  ];

  // ─── Banners y avatares exclusivos del cofre ────────────────────

  static const List<Map<String, String>> _bannersExclusivos = [
    {'nombre': 'Aurora boreal', 'emoji': '🌌'},
    {'nombre': 'Tormenta eléctrica', 'emoji': '⛈️'},
    {'nombre': 'Volcán', 'emoji': '🌋'},
    {'nombre': 'Galaxia espiral', 'emoji': '🌀'},
    {'nombre': 'Fondo del mar', 'emoji': '🌊'},
  ];


  // ─── Obtener misiones del día ───────────────────────────────────

  /// Devuelve las 3 misiones del día usando la fecha como semilla.
  /// Todos los usuarios ven las mismas misiones el mismo día.
  List<DailyQuest> obtenerMisionesDelDia() {
    final ahora = DateTime.now();
    // Semilla basada en la fecha (mismo resultado para todos el mismo día)
    final semilla = ahora.year * 10000 + ahora.month * 100 + ahora.day;
    final rng = Random(semilla);

    final pool = List<DailyQuest>.from(_questPool);
    pool.shuffle(rng);
    return pool.take(3).toList();
  }

  /// Calcula el progreso actual de una misión para el usuario.
  Future<int> calcularProgreso(DailyQuest quest, List<Map<String, dynamic>> habitos) async {
    final ahora = DateTime.now();

    switch (quest.type) {
      case 'completar_habitos':
      case 'completar_todos':
        int completadosHoy = 0;
        for (final h in habitos) {
          final ts = h['fechaUltimoCompletado'];
          if (ts == null) continue;
          final fecha = (ts as dynamic).toDate() as DateTime;
          if (fecha.year == ahora.year &&
              fecha.month == ahora.month &&
              fecha.day == ahora.day) {
            completadosHoy++;
          }
        }
        if (quest.type == 'completar_todos') {
          final diarios = habitos
              .where((h) => (h['frecuencia'] ?? '').toLowerCase() == 'diario')
              .toList();
          if (diarios.isEmpty) return 0;
          final todosCompletados = diarios.every((h) {
            final ts = h['fechaUltimoCompletado'];
            if (ts == null) return false;
            final fecha = (ts as dynamic).toDate() as DateTime;
            return fecha.year == ahora.year &&
                fecha.month == ahora.month &&
                fecha.day == ahora.day;
          });
          return todosCompletados ? 1 : 0;
        }
        return completadosHoy;

      case 'racha':
        int mejorRacha = 0;
        for (final h in habitos) {
          final racha = (h['rachaActual'] as num?)?.toInt() ?? 0;
          if (racha > mejorRacha) mejorRacha = racha;
        }
        return mejorRacha.clamp(0, quest.targetValue);

      case 'completar_grupal':
        int grupalesHoy = 0;
        for (final h in habitos) {
          if (!(h['esGrupal'] as bool? ?? false)) continue;
          final ts = h['fechaUltimoCompletado'];
          if (ts == null) continue;
          final fecha = (ts as dynamic).toDate() as DateTime;
          if (fecha.year == ahora.year &&
              fecha.month == ahora.month &&
              fecha.day == ahora.day) {
            grupalesHoy++;
          }
        }
        return grupalesHoy;

      default:
        return 0;
    }
  }

  // ─── Estado de cofres del día ───────────────────────────────────

  /// Obtiene qué misiones han sido completadas y qué cofres reclamados hoy.
  Future<Map<String, dynamic>> obtenerEstadoMisiones() async {
    final uid = _uid;
    if (uid == null) return {};

    try {
      final doc = await _firestore.collection('usuaris').doc(uid).get();
      final data = doc.data() ?? {};
      final ahora = DateTime.now();
      final hoyStr = '${ahora.year}-${ahora.month}-${ahora.day}';

      final estadoGuardado =
          data['estadoMisiones'] as Map<String, dynamic>? ?? {};
      final fechaGuardada = estadoGuardado['fecha'] as String? ?? '';

      // Si es un día nuevo, resetear
      if (fechaGuardada != hoyStr) {
        return {'cofresReclamados': <String>[], 'fecha': hoyStr};
      }

      return {
        'cofresReclamados': List<String>.from(
            estadoGuardado['cofresReclamados'] ?? []),
        'fecha': hoyStr,
      };
    } catch (_) {
      return {'cofresReclamados': <String>[], 'fecha': ''};
    }
  }

  // ─── Abrir cofre ────────────────────────────────────────────────

  /// Abre el cofre de una misión y devuelve la recompensa.
  /// Devuelve null si ya fue reclamado.
  Future<ChestReward?> abrirCofre(String questId) async {
    final uid = _uid;
    if (uid == null) return null;

    try {
      final estado = await obtenerEstadoMisiones();
      final reclamados =
          List<String>.from(estado['cofresReclamados'] ?? []);

      if (reclamados.contains(questId)) return null;

      // Generar recompensa aleatoria
      final reward = _generarRecompensa();

      // Guardar en Firestore
      final ahora = DateTime.now();
      final hoyStr = '${ahora.year}-${ahora.month}-${ahora.day}';
      reclamados.add(questId);

      final batch = _firestore.batch();
      final userRef = _firestore.collection('usuaris').doc(uid);

      batch.set(
        userRef,
        {
          'estadoMisiones': {
            'fecha': hoyStr,
            'cofresReclamados': reclamados,
          },
        },
        SetOptions(merge: true),
      );

      // Añadir recompensa
      if (reward.type == RewardType.monedasSmall ||
          reward.type == RewardType.monedasBig) {
        batch.set(
          userRef,
          {'monedas': FieldValue.increment(reward.monedas)},
          SetOptions(merge: true),
        );
      } else {
        // Guardar item desbloqueado
        batch.set(
          userRef,
          {
            'itemsCofre': FieldValue.arrayUnion([
              {
                'tipo': 'banner',
                'nombre': reward.itemName,
                'emoji': reward.itemEmoji,
                'fecha': Timestamp.now(),
              }
            ])
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
      return reward;
    } catch (_) {
      return null;
    }
  }

  // ─── Equipar items del cofre ────────────────────────────────────

  /// Equipa un banner del cofre en el perfil del usuario.
  Future<void> equiparBanner(String nombreBanner) async {
    final uid = _uid;
    if (uid == null) return;
    await _firestore.collection('usuaris').doc(uid).set(
      {'bannerEquipado': nombreBanner},
      SetOptions(merge: true),
    );
  }


  ChestReward _generarRecompensa() {
    final rng = Random();
    final roll = rng.nextDouble() * 100;

    if (roll < 70) {
      // 70% — monedas pequeñas (50-200)
      final monedas = 50 + rng.nextInt(151);
      return ChestReward(type: RewardType.monedasSmall, monedas: monedas);
    } else if (roll < 90) {
      // 20% — monedas grandes (200-500)
      final monedas = 200 + rng.nextInt(301);
      return ChestReward(type: RewardType.monedasBig, monedas: monedas);
    } else if (roll < 97) {
      // 7% — banner exclusivo
      final item = _bannersExclusivos[rng.nextInt(_bannersExclusivos.length)];
      return ChestReward(
        type: RewardType.banner,
        itemName: item['nombre'],
        itemEmoji: item['emoji'],
      );
    } else {
      // Avatar eliminado — suma a monedas pequeñas
      return ChestReward(
        type: RewardType.monedasSmall,
        monedas: 15 + rng.nextInt(10),
      );
    }
  }
}