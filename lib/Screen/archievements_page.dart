import 'package:app_habitcrew/Screen/models/archievement.dart';
import 'package:app_habitcrew/Screen/models/archievement_category.dart';
import 'package:app_habitcrew/Widgets/achivement_unlock_overlay.dart';
import 'package:flutter/material.dart';
import '../repositories/achievement_repository.dart';
import '../widgets/animated_background.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  final _repository = AchievementRepository();
  List<AchievementCategory> _categories = [];
  bool _isLoading = true;
  String? _expandedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final categories = await _repository.getCategories();
    setState(() {
      _categories = categories;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Mis Logros',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF22C55E),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                color: const Color(0xFF22C55E),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 16),
                    ..._categories.map(_buildCategoryCard),
                  ],
                ),
              ),
      ),
    );
  }

  // ─── RESUMEN SUPERIOR ───────────────────────────────────────────
  Widget _buildSummaryCard() {
    final total =
        _categories.fold<int>(0, (s, c) => s + c.totalAchievements);
    final unlocked =
        _categories.fold<int>(0, (s, c) => s + c.unlockedAchievements);
    final percent =
        total > 0 ? ((unlocked / total) * 100).round() : 0;

    return Card(
      elevation: 3,
      color: Colors.white.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Progreso Total',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF22C55E),
                ),
              ),
            ),

            // ─── BOTÓN DE PRUEBA ──────────────────────────────────
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  final dummyAchievement = Achievement(
                    id: 'test',
                    title: 'Racha de 7 días',
                    description:
                        'Mantuviste un hábito durante 7 días seguidos',
                    icon: Icons.local_fire_department,
                    isUnlocked: true,
                    unlockedDate: DateTime.now(),
                    currentValue: 7,
                    targetValue: 7,
                    categoryId: '1',
                  );
                  AchievementUnlockOverlay.show(context, dummyAchievement);
                },
                icon: const Icon(Icons.emoji_events),
                label: const Text('🧪 Simular logro'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            // ──────────────────────────────────────────────────────
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white60),
        ),
      ],
    );
  }

  // ─── TARJETA DE CATEGORÍA ────────────────────────────────────────
  Widget _buildCategoryCard(AchievementCategory category) {
    final isExpanded = _expandedCategoryId == category.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withOpacity(0.08),
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
                        const Color(0xFF22C55E).withOpacity(0.15),
                    child: Icon(category.icon, color: const Color(0xFF22C55E)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${category.unlockedAchievements}/${category.totalAchievements} desbloqueados',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: category.completionPercentage,
                          backgroundColor: Colors.white12,
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
                    color: Colors.white60,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: Colors.white12),
            ...category.achievements.map(_buildAchievementTile),
          ],
        ],
      ),
    );
  }

  // ─── LOGRO INDIVIDUAL ────────────────────────────────────────────
  Widget _buildAchievementTile(Achievement achievement) {
    final color =
        achievement.isUnlocked ? Colors.amber : Colors.white38;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Icon(achievement.icon, color: color, size: 20),
      ),
      title: Text(
        achievement.title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: achievement.isUnlocked ? Colors.white : Colors.white38,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            achievement.description,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 6),
          if (!achievement.isUnlocked) ...[
            Text(
              '${achievement.currentValue} / ${achievement.targetValue}',
              style: const TextStyle(fontSize: 11, color: Colors.white38),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: achievement.progress,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF22C55E),
              ),
            ),
          ] else
            Text(
              '✅ Desbloqueado el ${_formatDate(achievement.unlockedDate!)}',
              style: TextStyle(
                fontSize: 11,
                color: Colors.green[300],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
      isThreeLine: true,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
