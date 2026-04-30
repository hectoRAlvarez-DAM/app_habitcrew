import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ─── Código de amigo ────────────────────────────────────────────

  String _generarCodigo() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final r = Random();
    return List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
  }

  /// Genera y guarda un nuevo código de amigo para el usuario actual.
  Future<String> regenerarCodigoAmigo() async {
    final uid = _uid;
    if (uid == null) throw Exception('No autenticado');

    String codigo;
    bool existe = true;

    // Asegurarse de que el código sea único
    do {
      codigo = _generarCodigo();
      final query = await _firestore
          .collection('usuaris')
          .where('codigoAmigo', isEqualTo: codigo)
          .limit(1)
          .get();
      existe = query.docs.isNotEmpty;
    } while (existe);

    await _firestore.collection('usuaris').doc(uid).update({
      'codigoAmigo': codigo,
    });

    return codigo;
  }

  /// Obtiene el código de amigo del usuario actual.
  /// Si no tiene, lo genera.
  Future<String> obtenerOCrearCodigoAmigo() async {
    final uid = _uid;
    if (uid == null) throw Exception('No autenticado');

    final doc = await _firestore.collection('usuaris').doc(uid).get();
    final codigo = doc.data()?['codigoAmigo'] as String?;

    if (codigo != null && codigo.isNotEmpty) return codigo;
    return regenerarCodigoAmigo();
  }

  // ─── Solicitudes ────────────────────────────────────────────────

  /// Busca un usuario por código de amigo y envía solicitud.
  /// Devuelve null si OK, o mensaje de error.
  Future<String?> enviarSolicitud(String codigo) async {
    final uid = _uid;
    if (uid == null) return 'No autenticado';

    final query = await _firestore
        .collection('usuaris')
        .where('codigoAmigo', isEqualTo: codigo.toUpperCase().trim())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return 'Código no encontrado';

    final destinatarioId = query.docs.first.id;

    if (destinatarioId == uid) return 'No puedes añadirte a ti mismo';

    // Comprobar si ya son amigos
    final myDoc = await _firestore.collection('usuaris').doc(uid).get();
    final amigos = List<String>.from(myDoc.data()?['amigos'] ?? []);
    if (amigos.contains(destinatarioId)) return 'Ya sois amigos';

    // Comprobar si ya hay solicitud pendiente
    final solicitudes = List<String>.from(
        query.docs.first.data()['solicitudesRecibidas'] ?? []);
    if (solicitudes.contains(uid)) return 'Solicitud ya enviada';

    await _firestore.collection('usuaris').doc(destinatarioId).update({
      'solicitudesRecibidas': FieldValue.arrayUnion([uid]),
    });

    return null;
  }

  /// Acepta una solicitud de amistad.
  Future<void> aceptarSolicitud(String solicitanteUid) async {
    final uid = _uid;
    if (uid == null) return;

    final batch = _firestore.batch();

    // Añadir como amigos mutuamente
    batch.update(_firestore.collection('usuaris').doc(uid), {
      'amigos': FieldValue.arrayUnion([solicitanteUid]),
      'solicitudesRecibidas': FieldValue.arrayRemove([solicitanteUid]),
    });
    batch.update(_firestore.collection('usuaris').doc(solicitanteUid), {
      'amigos': FieldValue.arrayUnion([uid]),
    });

    await batch.commit();
  }

  /// Rechaza una solicitud de amistad.
  Future<void> rechazarSolicitud(String solicitanteUid) async {
    final uid = _uid;
    if (uid == null) return;

    await _firestore.collection('usuaris').doc(uid).update({
      'solicitudesRecibidas': FieldValue.arrayRemove([solicitanteUid]),
    });
  }

  /// Elimina a un amigo.
  Future<void> eliminarAmigo(String amigoUid) async {
    final uid = _uid;
    if (uid == null) return;

    final batch = _firestore.batch();
    batch.update(_firestore.collection('usuaris').doc(uid), {
      'amigos': FieldValue.arrayRemove([amigoUid]),
    });
    batch.update(_firestore.collection('usuaris').doc(amigoUid), {
      'amigos': FieldValue.arrayRemove([uid]),
    });
    await batch.commit();
  }

  // ─── Datos ──────────────────────────────────────────────────────

  /// Stream de datos del usuario actual (para el panel).
  Stream<DocumentSnapshot> streamUsuarioActual() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _firestore.collection('usuaris').doc(uid).snapshots();
  }

  /// Obtiene los datos básicos de un usuario por UID.
  Future<Map<String, dynamic>?> obtenerDatosUsuario(String uid) async {
    try {
      final doc = await _firestore.collection('usuaris').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (_) {
      return null;
    }
  }

  /// Obtiene los datos de todos los amigos del usuario actual.
  Future<List<Map<String, dynamic>>> obtenerAmigos() async {
    final uid = _uid;
    if (uid == null) return [];

    final doc = await _firestore.collection('usuaris').doc(uid).get();
    final amigosUids = List<String>.from(doc.data()?['amigos'] ?? []);

    if (amigosUids.isEmpty) return [];

    final futures = amigosUids.map((aUid) => obtenerDatosUsuario(aUid));
    final resultados = await Future.wait(futures);

    return resultados
        .asMap()
        .entries
        .where((e) => e.value != null)
        .map((e) => {...e.value!, 'uid': amigosUids[e.key]})
        .toList();
  }

  /// Obtiene los datos de los usuarios que han enviado solicitud.
  Future<List<Map<String, dynamic>>> obtenerSolicitudes() async {
    final uid = _uid;
    if (uid == null) return [];

    final doc = await _firestore.collection('usuaris').doc(uid).get();
    final solicitudesUids =
        List<String>.from(doc.data()?['solicitudesRecibidas'] ?? []);

    if (solicitudesUids.isEmpty) return [];

    final futures = solicitudesUids.map((sUid) => obtenerDatosUsuario(sUid));
    final resultados = await Future.wait(futures);

    return resultados
        .asMap()
        .entries
        .where((e) => e.value != null)
        .map((e) => {...e.value!, 'uid': solicitudesUids[e.key]})
        .toList();
  }

  /// Comprueba si un usuario completó algún hábito hoy.
  Future<bool> completoAlgoHoy(String uid) async {
    try {
      final habitosSnap = await _firestore
          .collection('usuaris')
          .doc(uid)
          .collection('habitos')
          .get();

      final hoy = DateTime.now();
      for (final doc in habitosSnap.docs) {
        final data = doc.data();
        final fechaTimestamp = data['fechaUltimoCompletado'] as Timestamp?;
        if (fechaTimestamp == null) continue;
        final fecha = fechaTimestamp.toDate();
        if (fecha.year == hoy.year &&
            fecha.month == hoy.month &&
            fecha.day == hoy.day) {
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}