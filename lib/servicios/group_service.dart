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
      // Array plano de UIDs para poder usar arrayContains en queries
      'miembrosUids': [uid],
    });

    return {'grupoId': grupoRef.id, 'codigo': codigo};
  }

  /// Une al usuario a un grupo existente dado su código.
  /// Devuelve los datos del grupo si tiene éxito, o null si el código no existe.
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
        'miembrosUids': FieldValue.arrayUnion([uid]),
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

  /// Obtiene el código de un grupo por su ID.
  /// Devuelve null si no existe o hay error.
  Future<String?> obtenerCodigoGrupo(String grupoId) async {
    try {
      final doc = await _firestore.collection('grupos').doc(grupoId).get();
      if (!doc.exists) return null;
      return doc.data()?['codigo'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Obtiene los datos de un grupo por ID
  Future<DocumentSnapshot?> obtenerGrupo(String grupoId) async {
    try {
      return await _firestore.collection('grupos').doc(grupoId).get();
    } catch (_) {
      return null;
    }
  }

  /// Obtiene las estadísticas de todos los miembros del grupo en paralelo.
  /// Si un miembro falla, se omite sin romper el resto.
  /// Devuelve: { uid: { 'nombre': String, 'dias': List<bool> (7 días) } }
  Future<Map<String, dynamic>> obtenerEstadisticasGrupo(String grupoId) async {
    try {
      final grupoDoc =
          await _firestore.collection('grupos').doc(grupoId).get();
      if (!grupoDoc.exists) return {};

      final data = grupoDoc.data() as Map<String, dynamic>;
      final miembros =
          List<Map<String, dynamic>>.from(data['miembros'] ?? []);
      final ahora = DateTime.now();

      // Lanzar todas las queries en paralelo con Future.wait
      final futures = miembros.map((miembro) async {
        final mUid = miembro['uid'] as String;
        final mNombre = miembro['nombre'] as String? ?? 'Usuario';

        try {
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
              diasCompletados[i] = _estaCompletadoEnDia(historial, dia);
            }
          }

          return MapEntry(mUid, {
            'nombre': mNombre,
            'dias': diasCompletados,
          });
        } catch (e) {
          // Si este miembro falla, devolvemos días vacíos en vez de romper todo
          print('⚠️ Error cargando stats del miembro $mUid: $e');
          return MapEntry(mUid, {
            'nombre': mNombre,
            'dias': List.filled(7, false),
          });
        }
      }).toList();

      // Esperar todos en paralelo
      final resultados = await Future.wait(futures);

      return Map.fromEntries(resultados);
    } catch (e) {
      print('❌ Error cargando estadísticas del grupo: $e');
      return {};
    }
  }

  bool _estaCompletadoEnDia(
      List<Map<String, dynamic>> historial, DateTime dia) {
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