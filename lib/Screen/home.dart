import 'dart:async';
import 'package:app_habitcrew/Widgets/animated_background.dart';
import 'package:app_habitcrew/Widgets/glassmorphism_card.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../servicios/servei_auth.dart';
import '../servicios/habit_service.dart';
import '../servicios/achievement_service.dart';
import 'models/habit.dart';
import 'login_screen.dart';
import 'habit_detail_screen.dart';
import 'epic_panel.dart';

// ─── Filtros disponibles ────────────────────────────────────────────
enum HabitFilter { todos, diario, semanal, mensual }

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  String _userName = '';
  bool _isLoadingName = true;

  final HabitService _habitService = HabitService();
  List<Habit> _habitos = [];
  StreamSubscription<List<Habit>>? _habitSub;

  HabitFilter _filtroActivo = HabitFilter.todos;

  // Controlador de animación para la entrada del contenido
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Para animar el check al completar
  final Set<String> _habitosAnimando = {};

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _cargarNombreUsuario();
    _habitService.crearHabitosDefecto();
    AchievementService().asignarInsigniaBeta();

    _habitSub = _habitService.obtenerHabitos().listen(
      (habitos) {
        if (mounted) {
          setState(() => _habitos = habitos);
          if (!_fadeController.isCompleted) _fadeController.forward();
        }
      },
      onError: (e) => debugPrint('Error stream hábitos: $e'),
      cancelOnError: false,
    );
  }

  @override
  void dispose() {
    _habitSub?.cancel();
    _fadeController.dispose();
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
      PageRouteBuilder(
        pageBuilder: (_, animation, __) =>
            HabitDetailScreen(habit: habit),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  Future<void> _toggleHabito(Habit habit) async {
    setState(() => _habitosAnimando.add(habit.id));
    await _habitService.toggleCompletado(habit);
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _habitosAnimando.remove(habit.id));
  }

  // ─── Filtrado ────────────────────────────────────────────────────

  List<Habit> get _habitosFiltrados {
    if (_filtroActivo == HabitFilter.diario) {
      return _habitos
          .where((h) => h.frecuencia.toLowerCase() == 'diario')
          .toList();
    } else if (_filtroActivo == HabitFilter.semanal) {
      return _habitos
          .where((h) => h.frecuencia.toLowerCase() == 'semanal')
          .toList();
    } else if (_filtroActivo == HabitFilter.mensual) {
      return _habitos
          .where((h) => h.frecuencia.toLowerCase() == 'mensual')
          .toList();
    }
    return List.from(_habitos);
  }

  int get _mejorRacha => _habitos.isEmpty
      ? 0
      : _habitos.map((h) => h.rachaActual).reduce((a, b) => a > b ? a : b);

  int get _completadosHoy => _habitos.where((h) => h.completadoHoy).length;

  // ─── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────────
            SliverToBoxAdapter(child: _buildHeader()),

            // ── Stats ───────────────────────────────────────────
            SliverToBoxAdapter(child: _buildStats()),

            // ── Barra de progreso del día ────────────────────────
            SliverToBoxAdapter(child: _buildDayProgress()),

            // ── Chips de filtro ──────────────────────────────────
            SliverToBoxAdapter(child: _buildFilterChips()),

            // ── Lista de hábitos ─────────────────────────────────
            SliverToBoxAdapter(child: _buildHabitList()),

            // ── Acciones rápidas ─────────────────────────────────
            SliverToBoxAdapter(child: _buildQuickActions()),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Saludo con shimmer mientras carga
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _isLoadingName
                      ? _buildShimmerText()
                      : Column(
                          key: ValueKey(_userName),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _saludoSegunHora(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.5),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _userName,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 6),
                // Fecha actual
                Text(
                  _fechaFormateada(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Botón menú
          GestureDetector(
            onTap: () {
              showGeneralDialog(
                context: context,
                barrierDismissible: false,
                barrierColor: Colors.transparent,
                pageBuilder: (_, __, ___) => const EpicPanel(),
              );
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: const Icon(Icons.menu,
                  color: Colors.white70, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 160,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }

  // ─── Stats ──────────────────────────────────────────────────────

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              emoji: '✅',
              value: '$_completadosHoy/${_habitos.length}',
              label: 'Completados hoy',
              color: const Color(0xFF22C55E),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              emoji: '🔥',
              value: '$_mejorRacha',
              label: 'Mejor racha',
              color: const Color(0xFFF97316),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              emoji: '📋',
              value: '${_habitos.length}',
              label: 'Hábitos',
              color: const Color(0xFF3B82F6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String emoji,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─── Barra de progreso del día ───────────────────────────────────

  Widget _buildDayProgress() {
    if (_habitos.isEmpty) return const SizedBox(height: 20);
    final progreso =
        _habitos.isEmpty ? 0.0 : _completadosHoy / _habitos.length;
    final porcentaje = (progreso * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso del día',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$porcentaje%',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF22C55E),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progreso),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progreso == 1.0
                      ? const Color(0xFF22C55E)
                      : const Color(0xFF22C55E).withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
          if (progreso == 1.0) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.celebration,
                    color: Color(0xFF22C55E), size: 14),
                SizedBox(width: 4),
                Text(
                  '¡Todos los hábitos completados!',
                  style: TextStyle(
                      color: Color(0xFF22C55E),
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── Chips de filtro ─────────────────────────────────────────────

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 0, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildChip(HabitFilter.todos, 'Todos', '🗂️'),
            const SizedBox(width: 8),
            _buildChip(HabitFilter.diario, 'Diarios', '📅'),
            const SizedBox(width: 8),
            _buildChip(HabitFilter.semanal, 'Semanales', '🗓️'),
            const SizedBox(width: 8),
            _buildChip(HabitFilter.mensual, 'Mensuales', '📆'),
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(HabitFilter filtro, String label, String emoji) {
    final isActive = _filtroActivo == filtro;
    return GestureDetector(
      onTap: () => setState(() => _filtroActivo = filtro),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF22C55E)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive
                ? const Color(0xFF22C55E)
                : Colors.white.withValues(alpha: 0.1),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Lista de hábitos ────────────────────────────────────────────

  Widget _buildHabitList() {
    final habitos = _habitosFiltrados;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: habitos.isEmpty
            ? _buildEmptyState()
            : Column(
                key: ValueKey(_filtroActivo),
                children: habitos.asMap().entries.map((entry) {
                  return TweenAnimationBuilder<double>(
                    key: ValueKey(entry.value.id),
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(
                        milliseconds: 300 + entry.key * 60),
                    curve: Curves.easeOutCubic,
                    builder: (_, value, child) => Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildHabitItem(entry.value),
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String mensaje;
    if (_filtroActivo == HabitFilter.diario) {
      mensaje = 'No tienes hábitos diarios';
    } else if (_filtroActivo == HabitFilter.semanal) {
      mensaje = 'No tienes hábitos semanales';
    } else if (_filtroActivo == HabitFilter.mensual) {
      mensaje = 'No tienes hábitos mensuales';
    } else {
      mensaje = 'No tienes hábitos todavía';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          Text(
            mensaje,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Crea uno desde la pestaña +',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitItem(Habit habit) {
    final completed = habit.completadoHoy;
    final animando = _habitosAnimando.contains(habit.id);

    return GestureDetector(
      onLongPress: () => _abrirDetalle(habit),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: completed
              ? const Color(0xFF22C55E).withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: completed
                ? const Color(0xFF22C55E).withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.1),
            width: completed ? 1.5 : 1,
          ),
          boxShadow: completed
              ? [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _toggleHabito(habit),
            splashColor:
                const Color(0xFF22C55E).withValues(alpha: 0.1),
            highlightColor:
                const Color(0xFF22C55E).withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Emoji con fondo animado
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: completed
                          ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(habit.emoji,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: AnimatedDefaultTextStyle(
                                duration:
                                    const Duration(milliseconds: 300),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: completed
                                      ? Colors.white.withValues(alpha: 0.4)
                                      : Colors.white,
                                  decoration: completed
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  decorationColor: Colors.white38,
                                ),
                                child: Text(habit.nombre),
                              ),
                            ),
                            if (habit.esGrupal)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.people,
                                    color: Color(0xFF3B82F6), size: 11),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            // Frecuencia badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                habit.frecuencia,
                                style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                            if (habit.rachaActual > 0) ...[
                              const SizedBox(width: 6),
                              Text(
                                '🔥 ${habit.rachaActual}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange[300]),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Checkbox animado
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.elasticOut,
                    child: animando
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF22C55E),
                            ),
                          )
                        : completed
                            ? const Icon(
                                key: ValueKey('done'),
                                Icons.check_circle_rounded,
                                color: Color(0xFF22C55E),
                                size: 28,
                              )
                            : Container(
                                key: const ValueKey('empty'),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white
                                        .withValues(alpha: 0.2),
                                    width: 2,
                                  ),
                                ),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Acciones rápidas ────────────────────────────────────────────

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acciones rápidas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickAction(
                    'Nuevo reto', '✨', const Color(0xFF22C55E), () {}),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickAction(
                    'Ver stats', '📊', const Color(0xFF3B82F6), () {}),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickAction(
                    'Amigos', '👥', const Color(0xFFA855F7), () {}),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
      String title, String emoji, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────

  String _saludoSegunHora() {
    final hora = DateTime.now().hour;
    if (hora < 12) return 'Buenos días,';
    if (hora < 19) return 'Buenas tardes,';
    return 'Buenas noches,';
  }

  String _fechaFormateada() {
    const dias = [
      'Lunes', 'Martes', 'Miércoles', 'Jueves',
      'Viernes', 'Sábado', 'Domingo'
    ];
    const meses = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    final ahora = DateTime.now();
    return '${dias[ahora.weekday - 1]}, ${ahora.day} de ${meses[ahora.month - 1]}';
  }
}