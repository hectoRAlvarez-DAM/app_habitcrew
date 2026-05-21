import 'package:app_habitcrew/Screen/models/archievement.dart';
import 'package:app_habitcrew/Screen/models/archievement_category.dart';
import 'package:app_habitcrew/servicios/achievement_definitions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Lee el catálogo de logros desde Firestore (`logros_catalogo` y
/// `logros_categorias`). Si Firestore no está disponible, cae de vuelta
/// a los datos locales de [AchievementDefinition].
///
/// El estado del usuario (isUnlocked, currentValue, coinsClaimed) lo
/// gestiona AchievementService, no este repositorio.
class AchievementRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<AchievementCategory>? _cache;

  /// Invalida el caché para forzar una recarga desde Firestore.
  void invalidateCache() => _cache = null;

  Future<List<AchievementCategory>> getCategories() async {
    if (_cache != null) return _cache!;

    try {
      final catSnap = await _db.collection('logros_categorias').get();
      final achSnap = await _db.collection('logros_catalogo').get();

      if (catSnap.docs.isEmpty || achSnap.docs.isEmpty) {
        return _fallback();
      }

      // Ordenar logros por el campo `order` para preservar secuencia original.
      final sortedAch = [...achSnap.docs]
        ..sort((a, b) => ((a.data()['order'] as num?)?.toInt() ?? 0)
            .compareTo((b.data()['order'] as num?)?.toInt() ?? 0));

      // Agrupar logros por categoría.
      final achByCategory = <String, List<Achievement>>{};
      for (final doc in sortedAch) {
        final data = doc.data();
        final categoryId = (data['categoryId'] as String?) ?? '0';
        final codePoint =
            (data['iconCodePoint'] as num?)?.toInt() ?? Icons.star.codePoint;

        achByCategory.putIfAbsent(categoryId, () => []).add(
          Achievement(
            id: doc.id,
            title: (data['title'] as String?) ?? '',
            description: (data['description'] as String?) ?? '',
            icon: IconData(codePoint, fontFamily: 'MaterialIcons'),
            isUnlocked: false,
            currentValue: 0,
            targetValue: (data['targetValue'] as num?)?.toInt() ?? 0,
            categoryId: categoryId,
            coinReward: (data['coinReward'] as num?)?.toInt() ?? 0,
            conditionType: (data['conditionType'] as String?) ?? '',
          ),
        );
      }

      // Ordenar categorías por el campo `order`.
      final sortedCats = [...catSnap.docs]
        ..sort((a, b) => ((a.data()['order'] as num?)?.toInt() ?? 0)
            .compareTo((b.data()['order'] as num?)?.toInt() ?? 0));

      _cache = sortedCats.map((doc) {
        final data = doc.data();
        final catCodePoint =
            (data['iconCodePoint'] as num?)?.toInt() ?? Icons.star.codePoint;
        return AchievementCategory(
          id: doc.id,
          name: (data['name'] as String?) ?? '',
          icon: IconData(catCodePoint, fontFamily: 'MaterialIcons'),
          achievements: achByCategory[doc.id] ?? [],
        );
      }).toList();

      return _cache!;
    } catch (_) {
      return _fallback();
    }
  }

  /// Fallback: construye el catálogo desde los datos locales.
  List<AchievementCategory> _fallback() {
    Achievement build(AchievementDefinition def) => Achievement(
          id: def.id,
          title: def.title,
          description: def.description,
          icon: def.icon,
          isUnlocked: false,
          currentValue: 0,
          targetValue: def.targetValue,
          categoryId: def.categoryId,
          coinReward: def.coinReward,
          conditionType: def.conditionType,
        );

    return AchievementDefinition.categoryMeta.map((meta) {
      final (id, name, icon) = meta;
      return AchievementCategory(
        id: id,
        name: name,
        icon: icon,
        achievements: AchievementDefinition.allAchievements
            .where((a) => a.categoryId == id)
            .map(build)
            .toList(),
      );
    }).toList();
  }
}
