import 'dart:async';
import 'package:app_habitcrew/Widgets/animated_background.dart';
import 'package:app_habitcrew/Widgets/glassmorphism_card.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../servicios/servei_auth.dart';
import '../servicios/habit_service.dart';
import 'models/habit.dart';
import 'login_screen.dart';
import 'habit_detail_screen.dart';
import 'epic_panel.dart';

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
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
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

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String _userName = '';
  bool _isLoadingName = true;

  final HabitService _habitService = HabitService();
  List<Habit> _habitos = [];
  StreamSubscription<List<Habit>>? _habitSub;

  @override
  void initState() {
    super.initState();
    _cargarNombreUsuario();
    _habitService.crearHabitosDefecto();
    _habitSub = _habitService.obtenerHabitos().listen(
      (habitos) {
        if (mounted) setState(() => _habitos = habitos);
      },
      onError: (e) => debugPrint('Error stream hábitos: $e'),
      cancelOnError: false,
    );
  }

  @override
  void dispose() {
    _habitSub?.cancel();
    super.dispose();
  }

  Future<void> _cargarNombreUsuario() async {
    if (!mounted) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) setState(() => _isLoadingName = false);
        return;
      }

      final docRef =
          FirebaseFirestore.instance.collection('usuaris').doc(user.uid);
      var doc = await docRef.get();

      if (!doc.exists) {
        final nomFallback = user.email?.split('@')[0] ?? 'Usuario';
        await docRef.set({
          'uid': user.uid,
          'email': user.email ?? '',
          'nom': nomFallback,
          'data_registre': FieldValue.serverTimestamp(),
          'totalHabitosCompletados': 0,
        });
        doc = await docRef.get();
        await _habitService.crearHabitosDefecto();
      }

      if (mounted) {
        final nom = doc.data()?['nom'] as String?;
        setState(() {
          _userName = (nom != null && nom.isNotEmpty)
              ? nom
              : user.email?.split('@')[0] ?? 'Usuario';
          _isLoadingName = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando nombre: $e');
      final user = FirebaseAuth.instance.currentUser;
      if (mounted) {
        setState(() {
          _userName = user?.email?.split('@')[0] ?? 'Usuario';
          _isLoadingName = false;
        });
      }
    }
  }

  Future<void> _cerrarSesion() async {
    await ServeiAuth().ferLogout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _abrirDetalle(Habit habit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitDetailScreen(habit: habit),
      ),
    );
  }

  // Filtra hábitos por frecuencia
  List<Habit> get _habitosDiarios =>
      _habitos.where((h) => h.frecuencia.toLowerCase() == 'diario').toList();
  List<Habit> get _habitosSemanales =>
      _habitos.where((h) => h.frecuencia.toLowerCase() == 'semanal').toList();
  List<Habit> get _habitosMensuales =>
      _habitos.where((h) => h.frecuencia.toLowerCase() == 'mensual').toList();

  int get _mejorRacha => _habitos.isEmpty
      ? 0
      : _habitos.map((h) => h.rachaActual).reduce((a, b) => a > b ? a : b);

  int get _completadosHoy =>
      _habitos.where((h) => h.completadoHoy).length;

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
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
                            _isLoadingName
                                ? const SizedBox(
                                    width: 150,
                                    height: 36,
                                    child: LinearProgressIndicator(
                                      color: Colors.white,
                                      backgroundColor: Colors.grey,
                                    ),
                                  )
                                : Text(
                                    '¡Hola, $_userName! 👋',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tu progreso diario',
                              style: TextStyle(fontSize: 15, color: Colors.grey),
                            ),
                          ],
                        ),
                        GlassmorphismCard(
                          onTap: () {
                            showGeneralDialog(
                              context: context,
                              barrierDismissible: false,
                              barrierColor: Colors.transparent,
                              pageBuilder: (_, __, ___) =>
                                  const EpicPanel(),
                            );
                          },
                          padding: const EdgeInsets.all(10),
                          child: const Icon(Icons.menu,
                              color: Colors.white70, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Stats
                    GlassmorphismCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildXpStat('Hoy',
                                '${_completadosHoy}/${_habitos.length}', '✅'),
                            _buildXpStat(
                                'Mejor racha', '$_mejorRacha días', '🔥'),
                            _buildXpStat(
                                'Hábitos', '${_habitos.length}', '📋'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // ── Sección DIARIOS ──────────────────────────────────
              if (_habitosDiarios.isNotEmpty) ...[
                GlassmorphismSection(
                  titulo: '📅 Diarios',
                  contenido: Column(
                    children: _habitosDiarios
                        .map((habit) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildHabitItem(habit),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Sección SEMANALES ────────────────────────────────
              if (_habitosSemanales.isNotEmpty) ...[
                GlassmorphismSection(
                  titulo: '🗓️ Semanales',
                  contenido: Column(
                    children: _habitosSemanales
                        .map((habit) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildHabitItem(habit),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── Sección MENSUALES ────────────────────────────────
              if (_habitosMensuales.isNotEmpty) ...[
                GlassmorphismSection(
                  titulo: '📆 Mensuales',
                  contenido: Column(
                    children: _habitosMensuales
                        .map((habit) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _buildHabitItem(habit),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Estado vacío
              if (_habitos.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildEmptyHabits(),
                ),
                const SizedBox(height: 20),
              ],

              // Acciones rápidas
              GlassmorphismSection(
                titulo: 'Acciones rápidas',
                contenido: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickAction(
                              'Nuevo reto', '✨', const Color(0xFF22C55E), () {}),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickAction(
                              'Ver stats', '📊', const Color(0xFF3B82F6), () {}),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickAction('Tienda XP', '🏆',
                              const Color(0xFFF97316), () {}),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickAction(
                              'Amigos', '👥', const Color(0xFFA855F7), () {}),
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

  Widget _buildEmptyHabits() {
    return GlassmorphismCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          const Text(
            'No tienes hábitos todavía',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Crea uno desde la pestaña +',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
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
          child: Text(emoji, style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
      ],
    );
  }

  Widget _buildHabitItem(Habit habit) {
    final completed = habit.completadoHoy;
    return GestureDetector(
      onLongPress: () => _abrirDetalle(habit),
      child: GlassmorphismCard(
        onTap: () => _habitService.toggleCompletado(habit),
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
              child: Text(habit.emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          habit.nombre,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: completed ? Colors.grey[500] : Colors.white,
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      // Badge grupal
                      if (habit.esGrupal)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.people,
                              color: Color(0xFF3B82F6), size: 12),
                        ),
                    ],
                  ),
                  if (habit.rachaActual > 0)
                    Text(
                      '🔥 ${habit.rachaActual} días de racha',
                      style: TextStyle(fontSize: 11, color: Colors.orange[300]),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (completed)
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF22C55E), size: 24)
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
      ),
    );
  }

  Widget _buildQuickAction(
      String title, String emoji, Color color, VoidCallback onTap) {
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
                fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}