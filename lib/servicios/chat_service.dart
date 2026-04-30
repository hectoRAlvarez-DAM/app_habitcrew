import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _mensajesRef(String grupoId) {
    return _firestore
        .collection('grupos')
        .doc(grupoId)
        .collection('mensajes');
  }

  /// Stream de mensajes de un grupo en tiempo real, ordenados por fecha.
  Stream<List<Map<String, dynamic>>> obtenerMensajes(String grupoId) {
    return _mensajesRef(grupoId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .handleError((e) {
          // Ignorar errores de stream y devolver lista vacía
          return <QuerySnapshot>[];
        })
        .map((snap) {
          if (snap is! QuerySnapshot) return <Map<String, dynamic>>[];
          return (snap as QuerySnapshot<Map<String, dynamic>>)
              .docs
              .map((d) => {...d.data(), 'id': d.id})
              .toList();
        });
  }

  /// Envía un mensaje de texto al grupo.
  Future<bool> enviarMensaje({
    required String grupoId,
    required String texto,
    required String nombreUsuario,
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
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Envía una reacción emoji rápida al grupo.
  Future<bool> enviarReaccion({
    required String grupoId,
    required String emoji,
    required String nombreUsuario,
  }) async {
    final uid = _uid;
    if (uid == null) return false;

    try {
      await _mensajesRef(grupoId).add({
        'uid': uid,
        'nombre': nombreUsuario,
        'texto': emoji,
        'tipo': 'reaccion',
        'timestamp': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }
}