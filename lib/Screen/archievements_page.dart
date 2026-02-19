import 'package:app_habitcrew/Screen/models/archievement.dart';
import 'package:app_habitcrew/Screen/models/archievement_category.dart';
import 'package:app_habitcrew/repositories/archievement_repository.dart';
import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Logros'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  ..._categories.map(_buildCategoryCard),
                ],
              ),
            ),
    );
  }
  Widget _buildSummaryCard() {
    final total = _categories.fold<int>(0, (s, c) => s + c.totalAchievements);
    final unlocked = _categories.fold<int>(0, (s, c) => s + c.unlockedAchievements);
    final percent = total > 0 ? ((unlocked / total) * 100).round() : 0;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Progreso Total',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Desbloqueados', '$unlocked', Colors.amber),
                _buildStat('Total', '$total', Colors.blue),
                _buildStat('Completado', '$percent%', Colors.green),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: total > 0 ? unlocked / total : 0,
                minHeight: 10,
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildCategoryCard(AchievementCategory category) {
    final isExpanded = _expandedCategoryId == category.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    child: Icon(category.icon, color: Colors.blue),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(category.name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(
                          '${category.unlockedAchievements}/${category.totalAchievements} desbloqueados',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: category.completionPercentage,
                          backgroundColor: Colors.grey[200],
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            ...category.achievements.map(_buildAchievementTile),
          ],
        ],
      ),
    );
  }
  Widget _buildAchievementTile(Achievement achievement) {
    final color = achievement.isUnlocked ? Colors.amber : Colors.grey;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Icon(achievement.icon, color: color, size: 20),
      ),
      title: Text(
        achievement.title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: achievement.isUnlocked ? Colors.black87 : Colors.grey,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(achievement.description,
              style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 6),
          if (!achievement.isUnlocked) ...[
            Text(
              '${achievement.currentValue} / ${achievement.targetValue}',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: achievement.progress,
              backgroundColor: Colors.grey[200],
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ] else
            Text(
              '✅ Desbloqueado el ${_formatDate(achievement.unlockedDate!)}',
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.green[600],
                  fontStyle: FontStyle.italic),
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
