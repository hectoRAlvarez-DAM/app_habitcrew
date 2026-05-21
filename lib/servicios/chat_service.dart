import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _mensajesRef(String grupoId) {
    return _firestore.collection('grupos').doc(grupoId).collection('mensajes');
  }

  /// Stream de mensajes en tiempo real (excluye tipo reaccion — ya no existen como mensajes separados).
  Stream<List<Map<String, dynamic>>> obtenerMensajes(String grupoId) {
    return _mensajesRef(grupoId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .handleError((e) => <QuerySnapshot>[])
        .map((snap) {
          if (snap is! QuerySnapshot) return <Map<String, dynamic>>[];
          return (snap as QuerySnapshot<Map<String, dynamic>>)
              .docs
              .where((d) => d.data()['tipo'] != 'reaccion')
              .map((d) => {...d.data(), 'id': d.id})
              .toList();
        });
  }

  /// Stream de miembros del grupo [{uid, nom, foto?}]
  Stream<List<Map<String, dynamic>>> streamMiembros(String grupoId) {
    return _firestore.collection('grupos').doc(grupoId).snapshots().asyncMap(
        (snap) async {
      if (!snap.exists) return <Map<String, dynamic>>[];
      final uids = List<String>.from(snap.data()?['miembrosUids'] ?? []);
      final futures = uids.map((uid) => _firestore
          .collection('usuaris')
          .doc(uid)
          .get()
          .then((d) => {
                'uid': uid,
                'nom': d.data()?['nom'] as String? ?? 'Usuario',
                'foto': d.data()?['fotoPerfil'] as String?,
              })
          .catchError((_) => {'uid': uid, 'nom': 'Usuario', 'foto': null}));
      return await Future.wait(futures);
    });
  }

  /// Marca el chat como leído para el usuario actual.
  Future<void> marcarLeido(String grupoId) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _firestore
          .collection('grupos')
          .doc(grupoId)
          .collection('visto')
          .doc(uid)
          .set({'uid': uid, 'timestamp': FieldValue.serverTimestamp()});
    } catch (_) {}
  }

  /// Stream de UIDs que han marcado el chat como leído.
  Stream<Set<String>> streamVistos(String grupoId, String mensajeId) {
    return _firestore
        .collection('grupos')
        .doc(grupoId)
        .collection('visto')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toSet());
  }

  /// Envía un mensaje de texto, opcionalmente como respuesta a otro.
  Future<bool> enviarMensaje({
    required String grupoId,
    required String texto,
    required String nombreUsuario,
    Map<String, dynamic>? replyTo, // {id, texto, nombre}
  }) async {
    final uid = _uid;
    if (uid == null || texto.trim().isEmpty) return false;
    try {
      await _mensajesRef(grupoId).add({
        'uid': uid,
        'nombre': nombreUsuario,
        'texto': texto.trim(),
        'tipo': 'texto',
        'timestamp': FieldValue.serverTimestamp(),
        'reacciones': <String, dynamic>{}, // {emoji: [uid1, uid2, ...]}
        if (replyTo != null) 'replyTo': replyTo,
      });
      await marcarLeido(grupoId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Añade o elimina (toggle) una reacción emoji en un mensaje.
  Future<void> toggleReaccion({
    required String grupoId,
    required String mensajeId,
    required String emoji,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final ref = _mensajesRef(grupoId).doc(mensajeId);
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return;
        final reacciones = Map<String, dynamic>.from(
            snap.data()?['reacciones'] as Map? ?? {});
        final uids = List<String>.from(reacciones[emoji] ?? []);
        if (uids.contains(uid)) {
          uids.remove(uid);
        } else {
          uids.add(uid);
        }
        if (uids.isEmpty) {
          reacciones.remove(emoji);
        } else {
          reacciones[emoji] = uids;
        }
        tx.update(ref, {'reacciones': reacciones});
      });
    } catch (_) {}
  }
}
