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