import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Screen/models/habit.dart';
import 'achievement_service.dart';

class HabitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _habitsRef {
    final uid = _uid;
    if (uid == null) return null;
    return _firestore.collection('usuaris').doc(uid).collection('habitos');
  }

  static const List<Map<String, String>> _habitosDefecto = [
    {
      'nombre': 'Meditar',
      'emoji': '🌅',
      'descripcion': 'Tomarse un momento para meditar y relajar la mente',
      'frecuencia': 'Diario',
    },
    {
      'nombre': 'Beber agua',
      'emoji': '💧',
      'descripcion': 'Mantenerse hidratado durante todo el día',
      'frecuencia': 'Diario',
    },
    {
      'nombre': 'Leer 30 min',
      'emoji': '📚',
      'descripcion': 'Leer al menos 30 minutos al día',
      'frecuencia': 'Diario',
    },
  ];

  /// Crea los 3 hábitos por defecto si el usuario no los tiene todavía.
  Future<void> crearHabitosDefecto() async {
    try {
      final ref = _habitsRef;
      if (ref == null) return;

      final existing = await ref.where('esDefecto', isEqualTo: true).get();
      if (existing.docs.isNotEmpty) return;

      final batch = _firestore.batch();
      for (final habit in _habitosDefecto) {
        final docRef = ref.doc();
        batch.set(docRef, {
          'nombre': habit['nombre'],
          'emoji': habit['emoji'],
          'descripcion': habit['descripcion'],
          'frecuencia': habit['frecuencia'],
          'fechaCreacion': FieldValue.serverTimestamp(),
          'fechaUltimoCompletado': null,
          'rachaActual': 0,
          'recordRacha': 0,
          'totalCompletados': 0,
          'esDefecto': true,
          'esGrupal': false,
          'grupoId': null,
          'historial': [],
        });
      }
      await batch.commit();
    } catch (e) {
      // ignore silently
    }
  }

  /// Stream en tiempo real de los hábitos del usuario.
  Stream<List<Habit>> obtenerHabitos() {
    final ref = _habitsRef;
    if (ref == null) return const Stream.empty();

    return ref.orderBy('fechaCreacion').snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => Habit.fromFirestore(doc)).toList(),
        );
  }

  /// Crea un nuevo hábito individual.
  Future<void> crearHabito({
    required String nombre,
    required String emoji,
    required String descripcion,
    required String frecuencia,
  }) async {
    final ref = _habitsRef;
    if (ref == null) return;

    await ref.add({
      'nombre': nombre,
      'emoji': emoji,
      'descripcion': descripcion,
      'frecuencia': frecuencia,
      'fechaCreacion': FieldValue.serverTimestamp(),
      'fechaUltimoCompletado': null,
      'rachaActual': 0,
      'recordRacha': 0,
      'totalCompletados': 0,
      'esDefecto': false,
      'esGrupal': false,
      'grupoId': null,
      'historial': [],
    });
  }

  /// Crea un hábito grupal vinculado a un grupo.
  Future<void> crearHabitoGrupal({
    required String nombre,
    required String emoji,
    required String descripcion,
    required String frecuencia,
    required String grupoId,
  }) async {
    final ref = _habitsRef;
    if (ref == null) return;

    await ref.add({
      'nombre': nombre,
      'emoji': emoji,
      'descripcion': descripcion,
      'frecuencia': frecuencia,
      'fechaCreacion': FieldValue.serverTimestamp(),
      'fechaUltimoCompletado': null,
      'rachaActual': 0,
      'recordRacha': 0,
      'totalCompletados': 0,
      'esDefecto': false,
      'esGrupal': true,
      'grupoId': grupoId,
      'historial': [],
    });
  }

  /// Edita los datos de un hábito existente.
  Future<void> editarHabito({
    required String habitId,
    required String nombre,
    required String emoji,
    required String descripcion,
    required String frecuencia,
  }) async {
    final ref = _habitsRef;
    if (ref == null) return;

    await ref.doc(habitId).update({
      'nombre': nombre,
      'emoji': emoji,
      'descripcion': descripcion,
      'frecuencia': frecuencia,
    });
  }

  /// Alterna el estado completado/no completado de un hábito para el período actual.
  Future<void> toggleCompletado(Habit habit) async {
    final ref = _habitsRef;
    final uid = _uid;
    if (ref == null || uid == null) return;

    final docRef = ref.doc(habit.id);
    final userRef = _firestore.collection('usuaris').doc(uid);

    if (habit.completadoHoy) {
      // ── DESMARCAR ─────────────────────────────────────────────────────────
      final ahora = DateTime.now();
      if (habit.rachaActual <= 1) {
        await docRef.update({'fechaUltimoCompletado': null, 'rachaActual': 0});
      } else {
        final yesterday = ahora.subtract(const Duration(days: 1));
        await docRef.update({
          'fechaUltimoCompletado': Timestamp.fromDate(yesterday),
          'rachaActual': habit.rachaActual - 1,
        });
      }
      // completadoHoy garantiza que totalCompletados >= 1 en Firestore
      await docRef.update({'totalCompletados': FieldValue.increment(-1)});
      await userRef.update({
        'totalHabitosCompletados': FieldValue.increment(-1),
      });
      // Eliminar del historial el registro de hoy
      final hoyStr = '${ahora.year}-${ahora.month}-${ahora.day}';
      final snap = await docRef.get();
      final historial =
          List<Map<String, dynamic>>.from(snap.data()?['historial'] ?? []);
      historial.removeWhere((e) {
        final f = (e['fecha'] as Timestamp?)?.toDate();
        if (f == null) return false;
        return '${f.year}-${f.month}-${f.day}' == hoyStr;
      });
      await docRef.update({'historial': historial});

      // Racha global: revertir solo si ningún otro hábito fue completado hoy
      final allSnap = await ref.get();
      final otroCompletadoHoy = allSnap.docs.any((doc) {
        if (doc.id == habit.id) return false;
        final data = doc.data();
        final ts = data['fechaUltimoCompletado'] as Timestamp?;
        if (ts == null) return false;
        final fecha = ts.toDate();
        return fecha.year == ahora.year &&
            fecha.month == ahora.month &&
            fecha.day == ahora.day;
      });

      if (!otroCompletadoHoy) {
        final userSnap = await userRef.get();
        final ud = userSnap.data() ?? {};
        final rachaGlobal = (ud['rachaGlobalActual'] as num?)?.toInt() ?? 0;
        if (rachaGlobal <= 1) {
          await userRef.set(
            {'rachaGlobalActual': 0, 'fechaUltimaActividad': null},
            SetOptions(merge: true),
          );
        } else {
          final ayer = ahora.subtract(const Duration(days: 1));
          await userRef.set({
            'rachaGlobalActual': rachaGlobal - 1,
            'fechaUltimaActividad': Timestamp.fromDate(ayer),
          }, SetOptions(merge: true));
        }
      }
    } else {
      // ── MARCAR COMO COMPLETADO ────────────────────────────────────────────
      final ahora = DateTime.now();
      int nuevaRacha = 1;

      if (habit.fechaUltimoCompletado != null) {
        final hoy = DateTime(ahora.year, ahora.month, ahora.day);
        final ayer = hoy.subtract(const Duration(days: 1));
        final ultimo = habit.fechaUltimoCompletado!;
        final ultimoDia = DateTime(ultimo.year, ultimo.month, ultimo.day);
        if (ultimoDia == ayer) nuevaRacha = habit.rachaActual + 1;
      }

      final nuevoRecord =
          nuevaRacha > habit.recordRacha ? nuevaRacha : habit.recordRacha;

      await docRef.update({
        'fechaUltimoCompletado': Timestamp.fromDate(ahora),
        'rachaActual': nuevaRacha,
        'recordRacha': nuevoRecord,
        'totalCompletados': FieldValue.increment(1),
        'historial': FieldValue.arrayUnion([
          {'fecha': Timestamp.fromDate(ahora)}
        ]),
      });

      await userRef.set(
        {'totalHabitosCompletados': FieldValue.increment(1)},
        SetOptions(merge: true),
      );

      // Racha global: +1 solo si este es el primer hábito completado hoy
      final userSnap = await userRef.get();
      final ud = userSnap.data() ?? {};
      final fechaUltimaActividad =
          (ud['fechaUltimaActividad'] as Timestamp?)?.toDate();
      int rachaGlobal = (ud['rachaGlobalActual'] as num?)?.toInt() ?? 0;
      int recordGlobal = (ud['recordRachaGlobal'] as num?)?.toInt() ?? 0;

      final hoyDia = DateTime(ahora.year, ahora.month, ahora.day);
      final yaContadoHoy = fechaUltimaActividad != null &&
          DateTime(fechaUltimaActividad.year, fechaUltimaActividad.month,
                  fechaUltimaActividad.day) ==
              hoyDia;

      if (!yaContadoHoy) {
        final ayerDia = hoyDia.subtract(const Duration(days: 1));
        final eraAyer = fechaUltimaActividad != null &&
            DateTime(fechaUltimaActividad.year, fechaUltimaActividad.month,
                    fechaUltimaActividad.day) ==
                ayerDia;
        rachaGlobal = eraAyer ? rachaGlobal + 1 : 1;
        if (rachaGlobal > recordGlobal) recordGlobal = rachaGlobal;

        await userRef.set({
          'rachaGlobalActual': rachaGlobal,
          'recordRachaGlobal': recordGlobal,
          'fechaUltimaActividad': Timestamp.fromDate(ahora),
        }, SetOptions(merge: true));
      }

      // Comprobar logros nuevos en background
      AchievementService.instance.comprobarLogros();

      // Comprobar si todos los hábitos de hoy están completados
      _comprobarDiaPerfecto();
    }
  }

  /// Comprueba si todos los hábitos diarios están completados hoy
  /// y registra un día perfecto si es así.
  Future<void> _comprobarDiaPerfecto() async {
    try {
      final ref = _habitsRef;
      if (ref == null) return;
      final snap = await ref.where('frecuencia', isEqualTo: 'Diario').get();
      if (snap.docs.isEmpty) return;

      final ahora = DateTime.now();
      final todoCompletados = snap.docs.every((doc) {
        final data = doc.data();
        final timestamp = data['fechaUltimoCompletado'] as Timestamp?;
        if (timestamp == null) return false;
        final fecha = timestamp.toDate();
        return fecha.year == ahora.year &&
            fecha.month == ahora.month &&
            fecha.day == ahora.day;
      });

      if (todoCompletados) {
        await AchievementService.instance.registrarDiaPerfecto();
      }
    } catch (_) {}
  }

  /// Obtiene el historial de completados de los últimos 7 días para un hábito.
  /// Devuelve una lista de 7 bools (índice 0 = hace 6 días, índice 6 = hoy)
  Future<List<bool>> obtenerHistorial7Dias(String habitId) async {
    final ref = _habitsRef;
    if (ref == null) return List.filled(7, false);

    try {
      final doc = await ref.doc(habitId).get();
      if (!doc.exists) return List.filled(7, false);

      final historial =
          List<Map<String, dynamic>>.from(doc.data()?['historial'] ?? []);

      final ahora = DateTime.now();
      final resultado = List<bool>.filled(7, false);

      for (int i = 0; i < 7; i++) {
        final dia = DateTime(ahora.year, ahora.month, ahora.day)
            .subtract(Duration(days: 6 - i));
        resultado[i] = historial.any((e) {
          final f = (e['fecha'] as Timestamp?)?.toDate();
          if (f == null) return false;
          return f.year == dia.year &&
              f.month == dia.month &&
              f.day == dia.day;
        });
      }

      return resultado;
    } catch (e) {
      return List.filled(7, false);
    }
  }

  /// Elimina un hábito por su ID.
  Future<void> eliminarHabito(String habitId) async {
    final ref = _habitsRef;
    if (ref == null) return;
    await ref.doc(habitId).delete();
  }
}