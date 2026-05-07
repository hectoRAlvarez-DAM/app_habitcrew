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

  /// Comprueba si hay logros nuevos que falten en Firestore y los añade.
  /// Devuelve true si sembró algo nuevo (para que el caller invalide su caché).
  Future<bool> seedIfNeeded() async {
    if (_done) return false;
    try {
      final snap = await _db.collection('logros_catalogo').get();
      final existingIds = snap.docs.map((d) => d.id).toSet();
      final expectedIds = AchievementDefinition.allAchievements.map((a) => a.id).toSet();

      _done = true;
      if (!existingIds.containsAll(expectedIds)) {
        await _seedMissing(existingIds);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _seedMissing(Set<String> existingIds) async {
    final batch = _db.batch();

    // Categorías (upsert por si acaso están vacías)
    for (int i = 0; i < AchievementDefinition.categoryMeta.length; i++) {
      final (id, name, icon) = AchievementDefinition.categoryMeta[i];
      batch.set(
        _db.collection('logros_categorias').doc(id),
        {'name': name, 'iconCodePoint': icon.codePoint, 'order': i},
        SetOptions(merge: true),
      );
    }

    // Solo los logros que no existen en Firestore
    final allAchievements = AchievementDefinition.allAchievements;
    for (int i = 0; i < allAchievements.length; i++) {
      final a = allAchievements[i];
      if (existingIds.contains(a.id)) continue;
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

  Future<void> _seed() async {
    await _seedMissing({});
  }
}
