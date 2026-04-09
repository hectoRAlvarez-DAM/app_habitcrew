import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Genera un código de grupo único de 6 caracteres alfanuméricos en mayúsculas
  String _generarCodigo() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final r = Random();
    return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
  }

  /// Crea un grupo nuevo y devuelve su ID y código
  Future<Map<String, String>> crearGrupo({
    required String nombreHabito,
    required String emoji,
    required String descripcion,
    required String frecuencia,
  }) async {
    final uid = _uid;
    if (uid == null) throw Exception('Usuario no autenticado');

    // Obtener nombre del usuario
    final userDoc = await _firestore.collection('usuaris').doc(uid).get();
    final userName = userDoc.data()?['nom'] ?? 'Usuario';

    final codigo = _generarCodigo();

    final grupoRef = await _firestore.collection('grupos').add({
      'nombreHabito': nombreHabito,
      'emoji': emoji,
      'descripcion': descripcion,
      'frecuencia': frecuencia,
      'codigo': codigo,
      'creadoPor': uid,
      'fechaCreacion': FieldValue.serverTimestamp(),
      'miembros': [
        {
          'uid': uid,
          'nombre': userName,
          'fechaUnion': Timestamp.now(),
        }
      ],
    });

    return {'grupoId': grupoRef.id, 'codigo': codigo};
  }

  /// Une al usuario a un grupo existente dado su código
  /// Devuelve el grupoId si tiene éxito, o null si el código no existe
  Future<Map<String, String>?> unirseAGrupo(String codigo) async {
    final uid = _uid;
    if (uid == null) return null;

    final query = await _firestore
        .collection('grupos')
        .where('codigo', isEqualTo: codigo.toUpperCase().trim())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final grupoDoc = query.docs.first;
    final grupoId = grupoDoc.id;
    final data = grupoDoc.data();

    // Comprobar si ya es miembro
    final miembros = List<Map<String, dynamic>>.from(data['miembros'] ?? []);
    final yaEsMiembro = miembros.any((m) => m['uid'] == uid);

    if (!yaEsMiembro) {
      final userDoc = await _firestore.collection('usuaris').doc(uid).get();
      final userName = userDoc.data()?['nom'] ?? 'Usuario';

      await grupoDoc.reference.update({
        'miembros': FieldValue.arrayUnion([
          {
            'uid': uid,
            'nombre': userName,
            'fechaUnion': Timestamp.now(),
          }
        ]),
      });
    }

    return {
      'grupoId': grupoId,
      'nombreHabito': data['nombreHabito'] ?? '',
      'emoji': data['emoji'] ?? '⭐',
      'descripcion': data['descripcion'] ?? '',
      'frecuencia': data['frecuencia'] ?? 'Diario',
      'codigo': data['codigo'] ?? '',
    };
  }

  /// Obtiene los datos de un grupo por ID
  Future<DocumentSnapshot?> obtenerGrupo(String grupoId) async {
    try {
      return await _firestore.collection('grupos').doc(grupoId).get();
    } catch (_) {
      return null;
    }
  }

  /// Stream de los completados de todos los miembros del grupo en los últimos 7 días
  /// Devuelve: { uid: { 'nombre': String, 'dias': List<bool> (7 días) } }
  Future<Map<String, dynamic>> obtenerEstadisticasGrupo(String grupoId) async {
    final grupoDoc = await _firestore.collection('grupos').doc(grupoId).get();
    if (!grupoDoc.exists) return {};

    final data = grupoDoc.data() as Map<String, dynamic>;
    final miembros = List<Map<String, dynamic>>.from(data['miembros'] ?? []);
    final frecuencia = data['frecuencia'] ?? 'Diario';

    final resultado = <String, dynamic>{};
    final ahora = DateTime.now();

    for (final miembro in miembros) {
      final mUid = miembro['uid'] as String;
      final mNombre = miembro['nombre'] as String? ?? 'Usuario';

      // Buscar el hábito de este usuario en este grupo
      final habitosSnap = await _firestore
          .collection('usuaris')
          .doc(mUid)
          .collection('habitos')
          .where('grupoId', isEqualTo: grupoId)
          .limit(1)
          .get();

      List<bool> diasCompletados = List.filled(7, false);

      if (habitosSnap.docs.isNotEmpty) {
        final habitoData = habitosSnap.docs.first.data();
        final historial = List<Map<String, dynamic>>.from(
            habitoData['historial'] ?? []);

        for (int i = 0; i < 7; i++) {
          final dia = DateTime(ahora.year, ahora.month, ahora.day)
              .subtract(Duration(days: 6 - i));
          diasCompletados[i] = _estaCompletadoEnDia(historial, dia, frecuencia);
        }
      }

      resultado[mUid] = {
        'nombre': mNombre,
        'dias': diasCompletados,
      };
    }

    return resultado;
  }

  bool _estaCompletadoEnDia(
      List<Map<String, dynamic>> historial, DateTime dia, String frecuencia) {
    for (final entry in historial) {
      final fecha = (entry['fecha'] as Timestamp?)?.toDate();
      if (fecha == null) continue;
      if (fecha.year == dia.year &&
          fecha.month == dia.month &&
          fecha.day == dia.day) {
        return true;
      }
    }
    return false;
  }
}