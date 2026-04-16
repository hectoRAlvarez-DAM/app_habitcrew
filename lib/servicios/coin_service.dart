import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class CoinService {
  static final CoinService instance = CoinService._internal();
  CoinService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ValueNotifier<int> coinsNotifier = ValueNotifier<int>(0);

  bool _loaded = false;
  String? get _uid => _auth.currentUser?.uid;
  int get coins => coinsNotifier.value;

  Future<void> load() async {
    if (_loaded) return;
    final uid = _uid;
    if (uid == null) return;
    try {
      final doc = await _db.collection('usuaris').doc(uid).get();
      coinsNotifier.value =
          (doc.data()?['monedas'] as num?)?.toInt() ?? 500;
    } catch (_) {
      coinsNotifier.value = 500;
    }
    _loaded = true;
  }

  void reset() {
    _loaded = false;
    coinsNotifier.value = 0;
  }

  Future<void> add(int amount) async {
    if (amount <= 0) return;
    coinsNotifier.value += amount;
    await _persist();
  }

  Future<bool> spend(int amount) async {
    if (coinsNotifier.value < amount) return false;
    coinsNotifier.value -= amount;
    await _persist();
    return true;
  }

  Future<void> _persist() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await _db.collection('usuaris').doc(uid).set(
        {'monedas': coinsNotifier.value},
        SetOptions(merge: true),
      );
    } catch (_) {}
  }
}
