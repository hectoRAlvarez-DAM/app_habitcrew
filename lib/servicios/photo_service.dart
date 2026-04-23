import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class PhotoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  String? get _uid => _auth.currentUser?.uid;

  bool get camaraDisponible => !kIsWeb;

  Future<String?> seleccionarYSubirFoto({
    ImageSource source = ImageSource.gallery,
  }) async {
    final sourceReal = kIsWeb ? ImageSource.gallery : source;

    try {
      // Reducimos mucho el tamaño para que quepa en Firestore (límite 1MB)
      // 256x256 al 70% = ~15-30KB en base64 (~20-40KB), seguro bajo el límite
      final XFile? imagen = await _picker.pickImage(
        source: sourceReal,
        maxWidth: 256,
        maxHeight: 256,
        imageQuality: 70,
      );

      if (imagen == null) return null;

      final bytes = await imagen.readAsBytes();

      // Verificar tamaño — Firestore tiene límite de 1MB por documento
      // El base64 añade ~33% de overhead, así que el límite real de bytes es ~750KB
      // Con 256x256 al 70% casi nunca se supera, pero lo chequeamos igualmente
      if (bytes.length > 700000) {
        debugPrint('Imagen demasiado grande: ${bytes.length} bytes');
        return null;
      }

      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final uid = _uid;
      if (uid == null) return null;

      // Usamos set con merge para no fallar si el campo no existe
      await _firestore.collection('usuaris').doc(uid).set(
        {'fotoPerfil': base64String},
        SetOptions(merge: true),
      );

      return base64String;
    } catch (e) {
      debugPrint('Error subiendo foto: $e');
      return null;
    }
  }

  Future<void> eliminarFoto() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _firestore.collection('usuaris').doc(uid).set(
        {'fotoPerfil': null},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Error eliminando foto: $e');
    }
  }
}
