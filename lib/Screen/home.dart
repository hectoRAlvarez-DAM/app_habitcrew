// home.dart
import 'package:app_habitcrew/Widgets/animated_background.dart';
import 'package:app_habitcrew/Widgets/glassmorphism_card.dart';
import 'package:flutter/material.dart';

// Widget auxiliar para las secciones con título
class GlassmorphismSection extends StatelessWidget {
  final String titulo;
  final Widget contenido;
  final VoidCallback? onVerTodos;

  const GlassmorphismSection({
    super.key,
    required this.titulo,
    required this.contenido,
    this.onVerTodos,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              if (onVerTodos != null)
                TextButton(
                  onPressed: onVerTodos,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                  ),
                  child: Text(
                    'Ver todos',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: contenido,
        ),
      ],
    );
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header con texto oscuro
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '¡Hola, Arnau! 👋',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tu progreso diario',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                        GlassmorphismCard(
                          padding: const EdgeInsets.all(0),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF22C55E),
                                  Color(0xFF16A34A),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                '😊',
                                style: TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Tarjeta de resumen de XP
                    GlassmorphismCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildXpStat('Nivel', '12', '⭐'),
                            _buildXpStat('XP Total', '2,450', '🔥'),
                            _buildXpStat('Racha', '15', '📆'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              
              // Sección Tu progreso
              GlassmorphismSection(
                titulo: 'Tu progreso',
                contenido: Column(
                  children: [
                    _buildProgressCard(
                      icon: Icons.emoji_events_rounded,
                      title: 'Rachas individuales',
                      value: '15 días',
                      progress: 0.5,
                      color: const Color(0xFF22C55E),
                      xp: '+230 XP',
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    _buildProgressCard(
                      icon: Icons.people_rounded,
                      title: 'Desafío grupal',
                      value: '1/3 completados',
                      progress: 0.33,
                      color: const Color(0xFFF97316),
                      xp: '+40 XP',
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Sección Hábitos de hoy
              GlassmorphismSection(
                titulo: 'Hábitos de hoy',
                onVerTodos: () {
                  // Navegar a la pantalla de hábitos
                },
                contenido: Column(
                  children: [
                    _buildHabitItem(
                      'Meditar',
                      '🌅',
                      true,
                      () {},
                    ),
                    _buildHabitItem(
                      'Beber agua',
                      '💧',
                      false,
                      () {},
                    ),
                    _buildHabitItem(
                      'Leer 30 min',
                      '📚',
                      false,
                      () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Sección Acciones rápidas
              GlassmorphismSection(
                titulo: 'Acciones rápidas',
                contenido: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickAction(
                            'Nuevo reto',
                            '✨',
                            const Color(0xFF22C55E),
                            () {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickAction(
                            'Ver stats',
                            '📊',
                            const Color(0xFF3B82F6),
                            () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickAction(
                            'Tienda XP',
                            '🏆',
                            const Color(0xFFF97316),
                            () {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickAction(
                            'Amigos',
                            '👥',
                            const Color(0xFFA855F7),
                            () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildXpStat(String label, String value, String emoji) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCard({
    required IconData icon,
    required String title,
    required String value,
    required double progress,
    required Color color,
    required String xp,
    required VoidCallback onTap,
  }) {
    return GlassmorphismCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    xp,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.grey[800]!,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitItem(String title, String emoji, bool completed, VoidCallback onTap) {
    return GlassmorphismCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: completed 
                ? const Color(0xFF22C55E).withOpacity(0.14)
                : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: completed ? Colors.grey[500] : Colors.white,
                decoration: completed ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (completed)
            const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 24)
          else
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[700]!),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String title, String emoji, Color color, VoidCallback onTap) {
    return GlassmorphismCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}