import 'package:app_habitcrew/Screen/models/archievement.dart';
import 'package:app_habitcrew/Screen/models/archievement_category.dart';
import 'package:app_habitcrew/Widgets/achivement_unlock_overlay.dart';
import 'package:app_habitcrew/repositories/achievement_repository.dart';
import 'package:app_habitcrew/servicios/achievement_service.dart';
import 'package:app_habitcrew/servicios/coin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/animated_background.dart';
import 'package:app_habitcrew/Widgets/contrast_mode.dart';
import 'package:app_habitcrew/Widgets/app_theme.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  final _repository = AchievementRepository();
  final _achievementService = AchievementService.instance;
  List<AchievementCategory> _categories = [];
  bool _isLoading = true;
  String? _expandedCategoryId;
  String _filterMode = 'todos';

  // IDs de logros cuyas monedas ya han sido reclamadas (cargado desde Firestore)
  Set<String> _claimedIds = {};

  AppTheme get _t => AppTheme.fromContrast(ContrastMode.of(context));

  @override
  void initState() {
    super.initState();
    _loadData();
    CoinService.instance.coinsNotifier.addListener(_onCoinsChanged);
  }

  @override
  void dispose() {
    CoinService.instance.coinsNotifier.removeListener(_onCoinsChanged);
    super.dispose();
  }

  void _onCoinsChanged() => setState(() {});

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final (categories, claimedIds) =
          await AchievementService.instance.loadUserAchievements();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _claimedIds = claimedIds;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // ─── ESTADÍSTICAS CALCULADAS ─────────────────────────────────────

  int get _totalAchievements =>
      _categories.fold(0, (s, c) => s + c.totalAchievements);

  int get _unlockedAchievements =>
      _categories.fold(0, (s, c) => s + c.unlockedAchievements);

  int get _totalCoinsClaimed => _categories
      .expand((c) => c.achievements)
      .where((a) => a.isUnlocked && _claimedIds.contains(a.id))
      .fold(0, (s, a) => s + a.coinReward);

  int get _coinsToClaim => _categories
      .expand((c) => c.achievements)
      .where((a) => a.isUnlocked && !_claimedIds.contains(a.id))
      .fold(0, (s, a) => s + a.coinReward);

  AchievementCategory? get _bestCategory {
    if (_categories.isEmpty) return null;
    return _categories.reduce((a, b) =>
        a.completionPercentage >= b.completionPercentage ? a : b);
  }

  int get _longestStreak {
    // Solo considera logros de tipo 'racha' (no total_completados ni otros)
    for (final cat in _categories) {
      for (final a in cat.achievements) {
        if (a.conditionType == 'racha') return a.currentValue;
      }
    }
    return 0;
  }

  // Categorías filtradas según el modo activo
  List<AchievementCategory> get _filteredCategories {
    if (_filterMode == 'todos') return _categories;
    return _categories.map((cat) {
      final filtered = cat.achievements.where((a) {
        if (_filterMode == 'desbloqueados') return a.isUnlocked;
        if (_filterMode == 'por_reclamar') {
          return a.isUnlocked && !_claimedIds.contains(a.id);
        }
        return true;
      }).toList();
      return AchievementCategory(
        id: cat.id,
        name: cat.name,
        icon: cat.icon,
        achievements: filtered,
      );
    }).where((cat) => cat.achievements.isNotEmpty).toList();
  }

  Future<void> _claimCoins(Achievement achievement) async {
    if (_claimedIds.contains(achievement.id)) return;
    final success = await AchievementService.instance
        .claimAchievement(achievement.id, achievement.coinReward);
    if (!success) return;
    CoinService.instance.coinsNotifier.value += achievement.coinReward;
    setState(() => _claimedIds.add(achievement.id));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.monetization_on, color: Color(0xFFFFD700)),
            const SizedBox(width: 8),
            Text('+${achievement.coinReward} monedas reclamadas'),
          ],
        ),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _claimAll() async {
    final unclaimed = _categories
        .expand((c) => c.achievements)
        .where((a) => a.isUnlocked && !_claimedIds.contains(a.id))
        .toList();
    if (unclaimed.isEmpty) return;

    final ids = unclaimed.map((a) => a.id).toList();
    final total = unclaimed.fold(0, (s, a) => s + a.coinReward);
    final earned =
        await AchievementService.instance.claimAllAchievements(ids, total);
    if (earned == 0) return;

    CoinService.instance.coinsNotifier.value += earned;
    setState(() => _claimedIds.addAll(ids));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.monetization_on, color: Color(0xFFFFD700)),
            const SizedBox(width: 8),
            Text('+$earned monedas reclamadas (${unclaimed.length} logros)'),
          ],
        ),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Copia al portapapeles un mensaje listo para compartir
  void _shareAchievement(Achievement achievement) {
    final text = '🏆 ¡Acabo de desbloquear "${achievement.title}" en HabitCrew!\n'
        '${achievement.description}\n\n'
        '#HabitCrew #Logros';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text('¡Copiado! Pégalo donde quieras compartirlo 📋'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isContrast = ContrastMode.of(context);
    final t = AppTheme.fromContrast(isContrast);
    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Mis Logros',
            style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: t.textPrimary,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on,
                      color: Color(0xFFFFD700), size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${CoinService.instance.coins}',
                    style: TextStyle(
                      color: t.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF22C55E)))
            : RefreshIndicator(
                onRefresh: _loadData,
                color: const Color(0xFF22C55E),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildStatsSection(),
                    const SizedBox(height: 16),
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    _buildFilterBar(),
                    const SizedBox(height: 12),
                    ..._filteredCategories.map(_buildCategoryCard),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
      ),
    );
  }

  // ─── BARRA DE FILTROS ─────────────────────────────────────────────
  Widget _buildFilterBar() {
    const filters = [
      ('todos', 'Todos', Icons.apps),
      ('desbloqueados', 'Desbloqueados', Icons.lock_open),
      ('por_reclamar', 'Por reclamar', Icons.redeem),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _filterMode == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filterMode = f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF22C55E).withOpacity(0.25)
                      : Colors.white.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF22C55E).withOpacity(0.6)
                        : Colors.white.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      f.$3,
                      size: 14,
                      color: isSelected
                          ? const Color(0xFF22C55E)
                          : Colors.white60,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      f.$2,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? const Color(0xFF22C55E)
                            : Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── TIER BADGE (Bronce / Plata / Oro / Platino) ─────────────────
  Widget _buildTierBadge(int coins) {
    final Color color;
    final String label;
    final IconData icon;

    if (coins >= 500) {
      color = const Color(0xFF67E8F9);
      label = 'Platino';
      icon = Icons.diamond;
    } else if (coins >= 150) {
      color = const Color(0xFFFFD700);
      label = 'Oro';
      icon = Icons.workspace_premium;
    } else if (coins >= 50) {
      color = Colors.white70;
      label = 'Plata';
      icon = Icons.military_tech;
    } else {
      color = const Color(0xFFCD7F32);
      label = 'Bronce';
      icon = Icons.shield;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SECCIÓN DE ESTADÍSTICAS ─────────────────────────────────────
  Widget _buildStatsSection() {
    final t = _t;
    final best = _bestCategory;
    final pct = _totalAchievements > 0
        ? ((_unlockedAchievements / _totalAchievements) * 100).round()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Estadísticas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: t.textPrimary,
            ),
          ),
        ),
        // Fila de stats rápidas
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.emoji_events,
                iconColor: Colors.amber,
                value: '$_unlockedAchievements/$_totalAchievements',
                label: 'Logros',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.local_fire_department,
                iconColor: Colors.orangeAccent,
                value: '$_longestStreak días',
                label: 'Mejor racha',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.pie_chart,
                iconColor: Colors.lightGreen,
                value: '$pct%',
                label: 'Completado',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Fila de monedas
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.monetization_on,
                iconColor: const Color(0xFFFFD700),
                value: '$_totalCoinsClaimed 🪙',
                label: 'Reclamadas',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.redeem,
                iconColor: Colors.greenAccent,
                value: '$_coinsToClaim 🪙',
                label: 'Por reclamar',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildStatCard(
                icon: Icons.star,
                iconColor: Colors.purpleAccent,
                value: best?.name ?? '—',
                label: 'Mejor categoría',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    final t = _t;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: t.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.cardBorder),
        boxShadow: t.cardShadow,
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: t.textPrimary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: t.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── RESUMEN SUPERIOR ────────────────────────────────────────────
  Widget _buildSummaryCard() {
    final t = _t;
    final total = _totalAchievements;
    final unlocked = _unlockedAchievements;
    final percent = total > 0 ? ((unlocked / total) * 100).round() : 0;

    return Card(
      elevation: 3,
      color: t.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Progreso Total',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: t.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Desbloqueados', '$unlocked', Colors.amber),
                _buildStat('Total', '$total', const Color(0xFF22C55E)),
                _buildStat('Completado', '$percent%', Colors.lightGreen),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: total > 0 ? unlocked / total : 0,
                minHeight: 10,
                backgroundColor: t.progressBg,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF22C55E),
                ),
              ),
            ),
            if (_coinsToClaim > 0) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _claimAll,
                  icon: const Icon(Icons.redeem,
                      size: 18, color: Color(0xFFFFD700)),
                  label: Text(
                    'Reclamar todo · $_coinsToClaim monedas',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E).withValues(alpha: 0.25),
                    foregroundColor: Colors.white,
                    side: BorderSide(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.6)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    final t = _t;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: t.textMuted)),
      ],
    );
  }

  // ─── TARJETA DE CATEGORÍA ────────────────────────────────────────
  Widget _buildCategoryCard(AchievementCategory category) {
    final t = _t;
    final isExpanded = _expandedCategoryId == category.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: t.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() {
              _expandedCategoryId = isExpanded ? null : category.id;
            }),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        const Color(0xFF22C55E).withValues(alpha: 0.15),
                    child:
                        Icon(category.icon, color: const Color(0xFF22C55E)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: t.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${category.unlockedAchievements}/${category.totalAchievements} desbloqueados',
                          style: TextStyle(fontSize: 12, color: t.textMuted),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: category.completionPercentage,
                          backgroundColor: t.progressBg,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF22C55E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: t.textMuted,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: t.divider),
            ...category.achievements.map(_buildAchievementTile),
          ],
        ],
      ),
    );
  }

  // ─── LOGRO INDIVIDUAL ────────────────────────────────────────────
  Widget _buildAchievementTile(Achievement achievement) {
    final t = _t;
    final color = achievement.isUnlocked ? Colors.amber : t.textHint;
    final isClaimed = _claimedIds.contains(achievement.id);

    return InkWell(
      onTap: achievement.isUnlocked
          ? () => AchievementUnlockOverlay.show(context, achievement)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícono
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(achievement.icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título + tier + badge de monedas
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          achievement.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: achievement.isUnlocked ? t.textPrimary : t.textMuted,
                          ),
                        ),
                      ),
                      _buildTierBadge(achievement.coinReward),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on,
                                color: Color(0xFFFFD700), size: 12),
                            const SizedBox(width: 3),
                            Text(
                              '${achievement.coinReward}',
                              style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Descripción
                  Text(
                    achievement.description,
                    style: TextStyle(fontSize: 12, color: t.textMuted),
                  ),
                  const SizedBox(height: 8),
                  // Estado / progreso / reclamar / compartir
                  if (!achievement.isUnlocked) ...[
                    Text(
                      '${achievement.currentValue} / ${achievement.targetValue}',
                      style: TextStyle(fontSize: 11, color: t.textMuted),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: achievement.progress,
                      backgroundColor: t.progressBg,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF22C55E)),
                    ),
                  ] else if (isClaimed) ...[
                    Text(
                      '✅ Desbloqueado ${_formatRelativeDate(achievement.unlockedDate ?? DateTime.now())}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green[300],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '🪙 Monedas reclamadas · Toca para celebrar 🎉',
                            style: TextStyle(fontSize: 10, color: Colors.white24),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Botón Compartir
                        GestureDetector(
                          onTap: () => _shareAchievement(achievement),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blueAccent.withOpacity(0.4),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.share,
                                    size: 13,
                                    color: Colors.lightBlueAccent),
                                SizedBox(width: 4),
                                Text(
                                  'Compartir',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.lightBlueAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Text(
                      '✅ Desbloqueado ${_formatRelativeDate(achievement.unlockedDate ?? DateTime.now())}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green[300],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _claimCoins(achievement),
                            icon: const Icon(Icons.monetization_on,
                                size: 16, color: Color(0xFFFFD700)),
                            label: Text(
                              'Reclamar ${achievement.coinReward} monedas',
                              style: const TextStyle(fontSize: 13),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF22C55E).withValues(alpha: 0.2),
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.5),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Botón equipar insignia
                        ElevatedButton(
                          onPressed: () async {
                            await _achievementService.equiparInsignia(achievement.id);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('🏅 "${achievement.title}" equipada en tu perfil'),
                                  backgroundColor: const Color(0xFF22C55E),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5865F2).withValues(alpha: 0.2),
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: const Color(0xFF5865F2).withValues(alpha: 0.5),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Icon(Icons.shield, size: 16),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'hoy';
    if (diff.inDays == 1) return 'ayer';
    if (diff.inDays < 7) return 'hace ${diff.inDays} días';
    if (diff.inDays < 30) return 'hace ${(diff.inDays / 7).floor()} sem.';
    return 'el ${date.day}/${date.month}/${date.year}';
  }
}
