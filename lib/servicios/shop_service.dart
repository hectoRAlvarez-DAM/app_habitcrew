import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Gestiona la persistencia de compras de la tienda en Firestore.
class ShopService {
  static final ShopService instance = ShopService._internal();
  ShopService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  /// Devuelve los IDs de artículos ya comprados por el usuario.
  Future<Set<String>> loadPurchasedIds() async {
    final uid = _uid;
    if (uid == null) return {};
    try {
      final snapshot = await _db
          .collection('usuaris')
          .doc(uid)
          .collection('compras')
          .get();
      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (_) {
      return {};
    }
  }

  /// Guarda una compra en Firestore.
  Future<void> savePurchase(String itemId, String name, int price) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db
          .collection('usuaris')
          .doc(uid)
          .collection('compras')
          .doc(itemId)
          .set({
        'name': name,
        'price': price,
        'purchasedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Equipa un banner en el perfil del usuario.
  Future<void> equiparBanner(String nombre) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db
          .collection('usuaris')
          .doc(uid)
          .set({'bannerEquipado': nombre.isEmpty ? null : nombre},
              SetOptions(merge: true));
    } catch (_) {}
  }

  /// Carga los nombres de banners comprados en tienda.
  Future<Set<String>> loadPurchasedBannerNames() async {
    final uid = _uid;
    if (uid == null) return {};
    try {
      final snapshot = await _db
          .collection('usuaris')
          .doc(uid)
          .collection('compras')
          .get();
      return snapshot.docs
          .map((doc) => doc.data()['name'] as String? ?? '')
          .where((name) => name.isNotEmpty)
          .toSet();
    } catch (_) {
      return {};
    }
  }
}
