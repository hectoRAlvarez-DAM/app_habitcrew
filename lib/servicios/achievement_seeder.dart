import 'package:app_habitcrew/servicios/achievement_definitions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Puebla las colecciones `logros_catalogo` y `logros_categorias` en Firestore
/// la primera vez que se ejecuta la app (o cuando las colecciones están vacías).
/// Después de la siembra, Firestore es la fuente de verdad para los logros.
class AchievementSeeder {
  static final AchievementSeeder instance = AchievementSeeder._internal();
  AchievementSeeder._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _done = false;

  /// Comprueba si ya se sembró y, si no, ejecuta la siembra.
  Future<void> seedIfNeeded() async {
    if (_done) return;
    try {
      final snap = await _db.collection('logros_categorias').limit(1).get();
      if (snap.docs.isNotEmpty) {
        _done = true;
        return;
      }
      await _seed();
      _done = true;
    } catch (_) {}
  }

  Future<void> _seed() async {
    // Firestore WriteBatch soporta hasta 500 ops; 72 logros + 8 categorías = 80.
    final batch = _db.batch();

    // Categorías
    for (int i = 0; i < AchievementDefinition.categoryMeta.length; i++) {
      final (id, name, icon) = AchievementDefinition.categoryMeta[i];
      batch.set(
        _db.collection('logros_categorias').doc(id),
        {
          'name': name,
          'iconCodePoint': icon.codePoint,
          'order': i,
        },
      );
    }

    // Logros
    for (int i = 0; i < AchievementDefinition.allAchievements.length; i++) {
      final a = AchievementDefinition.allAchievements[i];
      batch.set(
        _db.collection('logros_catalogo').doc(a.id),
        {
          'title': a.title,
          'description': a.description,
          'iconCodePoint': a.icon.codePoint,
          'categoryId': a.categoryId,
          'targetValue': a.targetValue,
          'coinReward': a.coinReward,
          'conditionType': a.conditionType,
          'order': i,
        },
      );
    }

    await batch.commit();
  }
}
