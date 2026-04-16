import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Screen/models/habit.dart';

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

  /// Crea un nuevo hábito personalizado.
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
    });
  }

  /// Alterna el estado completado/no completado de un hábito para hoy.
  /// Actualiza la racha y el contador global del usuario.
  Future<void> toggleCompletado(Habit habit) async {
    final ref = _habitsRef;
    final uid = _uid;
    if (ref == null || uid == null) return;

    final docRef = ref.doc(habit.id);
    final userRef = _firestore.collection('usuaris').doc(uid);

    if (habit.completadoHoy) {
      // Desmarcar
      if (habit.rachaActual <= 1) {
        await docRef.update({'fechaUltimoCompletado': null, 'rachaActual': 0});
      } else {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        await docRef.update({
          'fechaUltimoCompletado': Timestamp.fromDate(yesterday),
          'rachaActual': habit.rachaActual - 1,
        });
      }
      if (habit.totalCompletados > 0) {
        await docRef.update({'totalCompletados': FieldValue.increment(-1)});
        await userRef.update({
          'totalHabitosCompletados': FieldValue.increment(-1),
        });
      }
    } else {
      // Marcar como completado hoy
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
      });
      // Usar set con merge para crear el campo si no existe
      await userRef.set(
        {'totalHabitosCompletados': FieldValue.increment(1)},
        SetOptions(merge: true),
      );

      // ── Comprobar si todos los hábitos del día están completados ──────
      // Si es así, incrementar diasPerfectos (sólo una vez por día)
      await _checkDiaPerfecto(uid, ref, ahora);
    }
  }

  /// Comprueba si todos los hábitos están completados hoy.
  /// Si es así y no se ha registrado ya hoy, incrementa diasPerfectos.
  Future<void> _checkDiaPerfecto(
    String uid,
    CollectionReference<Map<String, dynamic>> ref,
    DateTime ahora,
  ) async {
    try {
      final hoy = DateTime(ahora.year, ahora.month, ahora.day);
      final hoyStr =
          '${ahora.year}-${ahora.month.toString().padLeft(2, '0')}-${ahora.day.toString().padLeft(2, '0')}';

      // Verificar si ya se contó hoy
      final diaRef = _firestore
          .collection('usuaris')
          .doc(uid)
          .collection('diasPerfectos')
          .doc(hoyStr);
      final diaDoc = await diaRef.get();
      if (diaDoc.exists) return; // Ya contado hoy

      // Comprobar si todos los hábitos están completados hoy
      final snap = await ref.get();
      if (snap.docs.isEmpty) return;

      final todosCompletos = snap.docs.every((doc) {
        final data = doc.data();
        final ultimo = (data['fechaUltimoCompletado'] as Timestamp?)?.toDate();
        if (ultimo == null) return false;
        final ultimoDia = DateTime(ultimo.year, ultimo.month, ultimo.day);
        return ultimoDia == hoy;
      });

      if (todosCompletos) {
        // Marcar el día como perfecto y sumar al contador
        await diaRef.set({'fecha': FieldValue.serverTimestamp()});
        await _firestore.collection('usuaris').doc(uid).set(
          {'diasPerfectos': FieldValue.increment(1)},
          SetOptions(merge: true),
        );
      }
    } catch (_) {
      // No interrumpir el flujo principal si falla
    }
  }

  /// Elimina un hábito por su ID.
  Future<void> eliminarHabito(String habitId) async {
    final ref = _habitsRef;
    if (ref == null) return;
    await ref.doc(habitId).delete();
  }
}
