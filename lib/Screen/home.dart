import 'dart:async';
import 'package:app_habitcrew/Widgets/animated_background.dart';
import 'package:app_habitcrew/Widgets/contrast_mode.dart';
import 'package:app_habitcrew/Widgets/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../servicios/servei_auth.dart';
import '../servicios/habit_service.dart';
import '../servicios/achievement_service.dart';
import '../servicios/quest_service.dart';
import 'models/habit.dart';
import 'login_screen.dart';
import 'habit_detail_screen.dart';
import 'epic_panel.dart';

enum HabitFilter { diario, semanal, mensual }

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
  StreamSubscription? _userSub;
  int _rachaGlobal = 0;

  HabitFilter _filtroActivo = HabitFilter.diario;

  // Quest state
  final QuestService _questService = QuestService();
  List<DailyQuest> _misiones = [];
  List<int> _progresosQuests = [0, 0, 0];
  List<String> _cofresReclamados = [];
  bool _loadingQuests = true;

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
    AchievementService.instance.asignarInsigniaBeta();
    _misiones = _questService.obtenerMisionesDelDia();

    _habitSub = _habitService.obtenerHabitos().listen(
      (habitos) {
        if (mounted) {
          setState(() => _habitos = habitos);
          if (!_fadeController.isCompleted) _fadeController.forward();
          _actualizarProgresosQuests(habitos);
        }
      },
      onError: (e) => debugPrint('Error stream hábitos: $e'),
      cancelOnError: false,
    );

    _userSub = AchievementService.instance.streamUsuario().listen((doc) {
      if (!mounted) return;
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;
      final actual = (data['rachaGlobalActual'] as num?)?.toInt() ?? 0;
      final record = (data['recordRachaGlobal'] as num?)?.toInt() ?? 0;
      setState(() => _rachaGlobal = actual > record ? actual : record);
    });
  }

  @override
  void dispose() {
    _habitSub?.cancel();
    _userSub?.cancel();
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

  Future<void> _actualizarProgresosQuests(List<Habit> habitos) async {
    final habitosMap = habitos
        .map((h) => {
              'frecuencia': h.frecuencia,
              'fechaUltimoCompletado': h.fechaUltimoCompletado != null
                  ? Timestamp.fromDate(h.fechaUltimoCompletado!)
                  : null,
              'rachaActual': h.rachaActual,
              'esGrupal': h.esGrupal,
            })
        .toList();

    final estado = await _questService.obtenerEstadoMisiones();
    final progresos = await Future.wait(
      _misiones.map((q) => _questService.calcularProgreso(q, habitosMap)),
    );

    if (mounted) {
      setState(() {
        _progresosQuests = progresos;
        _cofresReclamados =
            List<String>.from(estado['cofresReclamados'] ?? []);
        _loadingQuests = false;
      });
    }
  }

  Future<void> _abrirCofre(DailyQuest quest, int index) async {
    final reward = await _questService.abrirCofre(quest.id);
    if (reward == null || !mounted) return;

    setState(() => _cofresReclamados.add(quest.id));
    _mostrarRecompensa(reward);
  }

  void _mostrarRecompensa(ChestReward reward) {
    String titulo;
    String subtitulo;
    String emoji;
    Color color;

    if (reward.type == RewardType.monedasSmall ||
        reward.type == RewardType.monedasBig) {
      titulo = '¡${reward.monedas} monedas!';
      subtitulo = 'Añadidas a tu cuenta';
      emoji = '🪙';
      color = const Color(0xFFFFD700);
    } else if (reward.type == RewardType.banner) {
      titulo = '¡Banner exclusivo!';
      subtitulo = reward.itemName ?? '';
      emoji = reward.itemEmoji ?? '🖼️';
      color = const Color(0xFF3B82F6);
} else {
      titulo = '¡Recompensa!';
      subtitulo = '';
      emoji = '🎁';
      color = const Color(0xFF22C55E);
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1923),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 2),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji animado
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.5, end: 1.0),
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Text(emoji,
                    style: const TextStyle(fontSize: 64)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  '¡Cofre abierto!',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                titulo,
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitulo,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('¡Genial!',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
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
    if (_filtroActivo == HabitFilter.semanal) {
      return _habitos
          .where((h) => h.frecuencia.toLowerCase() == 'semanal')
          .toList();
    } else if (_filtroActivo == HabitFilter.mensual) {
      return _habitos
          .where((h) => h.frecuencia.toLowerCase() == 'mensual')
          .toList();
    }
    return _habitos
        .where((h) => h.frecuencia.toLowerCase() == 'diario')
        .toList();
  }

  int get _mejorRacha => _rachaGlobal;

  int get _completadosHoy =>
      _habitosFiltrados.where((h) => h.completadoHoy).length;

  String get _labelCompletados {
    if (_filtroActivo == HabitFilter.semanal) return 'Esta semana';
    if (_filtroActivo == HabitFilter.mensual) return 'Este mes';
    return 'Completados hoy';
  }

  // ─── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isContrast = ContrastMode.of(context);
    final t = AppTheme.fromContrast(isContrast);
    return AnimatedBackground(
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── Header ──────────────────────────────────────────
            SliverToBoxAdapter(child: _buildHeader(t)),

            // ── Stats ───────────────────────────────────────────
            SliverToBoxAdapter(child: _buildStats(t)),

            // ── Barra de progreso del día ────────────────────────
            SliverToBoxAdapter(child: _buildDayProgress(t)),

            // ── Chips de filtro ──────────────────────────────────
            SliverToBoxAdapter(child: _buildFilterChips(t)),

            // ── Lista de hábitos ─────────────────────────────────
            SliverToBoxAdapter(child: _buildHabitList(t)),

            // ── Misiones diarias ─────────────────────────────────
            SliverToBoxAdapter(child: _buildMisionesSection(t)),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────

  Widget _buildHeader(AppTheme t) {
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
                      ? _buildShimmerText(t)
                      : Column(
                          key: ValueKey(_userName),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _saludoSegunHora(),
                              style: TextStyle(
                                fontSize: 14,
                                color: t.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _userName,
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: t.textPrimary,
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
                color: t.btnSecondaryBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: t.btnSecondaryBorder),
              ),
              child: Icon(Icons.menu, color: t.iconMuted, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerText(AppTheme t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 14,
          decoration: BoxDecoration(
            color: t.chipBg,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 160,
          height: 28,
          decoration: BoxDecoration(
            color: t.chipBg,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }

  // ─── Stats ──────────────────────────────────────────────────────

  Widget _buildStats(AppTheme t) {
    final filtrados = _habitosFiltrados;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(t,
              emoji: '✅',
              value: '$_completadosHoy/${filtrados.length}',
              label: _labelCompletados,
              color: const Color(0xFF22C55E),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(t,
              emoji: '🔥',
              value: '$_mejorRacha',
              label: 'Mejor racha',
              color: const Color(0xFFF97316),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(t,
              emoji: '📋',
              value: '${filtrados.length}',
              label: 'Hábitos',
              color: const Color(0xFF3B82F6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(AppTheme t, {
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
              color: t.textMuted,
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

  Widget _buildDayProgress(AppTheme t) {
    final filtrados = _habitosFiltrados;
    if (filtrados.isEmpty) return const SizedBox(height: 20);
    final progreso = _completadosHoy / filtrados.length;
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
                  color: t.textSecondary,
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
                backgroundColor: t.progressBg,
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

  Widget _buildFilterChips(AppTheme t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 0, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildChip(t, HabitFilter.diario, 'Diarios', '📅'),
            const SizedBox(width: 8),
            _buildChip(t, HabitFilter.semanal, 'Semanales', '🗓️'),
            const SizedBox(width: 8),
            _buildChip(t, HabitFilter.mensual, 'Mensuales', '📆'),
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(AppTheme t, HabitFilter filtro, String label, String emoji) {
    final isActive = _filtroActivo == filtro;
    return GestureDetector(
      onTap: () => setState(() => _filtroActivo = filtro),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? t.tabActiveBg : t.tabInactiveBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? t.accent : t.chipBorder,
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
                color: isActive ? t.tabActiveText : t.tabInactiveText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Lista de hábitos ────────────────────────────────────────────

  Widget _buildHabitList(AppTheme t) {
    final habitos = _habitosFiltrados;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: habitos.isEmpty
            ? _buildEmptyState(t)
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
                      child: _buildHabitItem(t, entry.value),
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }

  Widget _buildEmptyState(AppTheme t) {
    String mensaje;
    if (_filtroActivo == HabitFilter.semanal) {
      mensaje = 'No tienes hábitos semanales';
    } else if (_filtroActivo == HabitFilter.mensual) {
      mensaje = 'No tienes hábitos mensuales';
    } else {
      mensaje = 'No tienes hábitos diarios';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: t.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: t.cardBorder),
      ),
      child: Column(
        children: [
          const Text('🌱', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          Text(
            mensaje,
            style: TextStyle(color: t.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Crea uno desde la pestaña +',
            style: TextStyle(color: t.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitItem(AppTheme t, Habit habit) {
    final completed = habit.completadoHoy;
    final animando = _habitosAnimando.contains(habit.id);

    return GestureDetector(
      onLongPress: () => _abrirDetalle(habit),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: completed ? const Color(0xFF22C55E).withValues(alpha: 0.08) : t.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: completed ? const Color(0xFF22C55E).withValues(alpha: 0.3) : t.cardBorder,
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
                      color: completed ? const Color(0xFF22C55E).withValues(alpha: 0.15) : t.chipBg,
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
                                  color: completed ? t.textMuted : t.textPrimary,
                                  decoration: completed
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  decorationColor: t.textMuted,
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
                                color: t.chipBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                habit.frecuencia,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: t.textMuted,
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
                                    color: t.chipBorder,
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

  // ─── Misiones diarias ────────────────────────────────────────────

  Widget _buildMisionesSection(AppTheme t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('⚔️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    'Misiones del día',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: t.textPrimary,
                    ),
                  ),
                ],
              ),
              // Contador de cofres disponibles
              Builder(builder: (_) {
                final disponibles = _misiones.where((q) {
                  final idx = _misiones.indexOf(q);
                  final completada =
                      _progresosQuests.length > idx &&
                          _progresosQuests[idx] >= q.targetValue;
                  final reclamada = _cofresReclamados.contains(q.id);
                  return completada && !reclamada;
                }).length;
                if (disponibles == 0) return const SizedBox();
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color:
                            const Color(0xFFFFD700).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('📦',
                          style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '$disponibles cofre${disponibles > 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          _loadingQuests
              ? const Center(
                  child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                      color: Color(0xFF22C55E), strokeWidth: 2),
                ))
              : Column(
                  children: _misiones.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final quest = entry.value;
                    final progreso = _progresosQuests.length > idx
                        ? _progresosQuests[idx]
                        : 0;
                    final completada = progreso >= quest.targetValue;
                    final reclamada = _cofresReclamados.contains(quest.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildQuestCard(t,
                        quest: quest,
                        progreso: progreso,
                        completada: completada,
                        reclamada: reclamada,
                        index: idx,
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildQuestCard(AppTheme t, {
    required DailyQuest quest,
    required int progreso,
    required bool completada,
    required bool reclamada,
    required int index,
  }) {
    final color = reclamada
        ? Colors.white.withValues(alpha: 0.3)
        : completada
            ? const Color(0xFFFFD700)
            : const Color(0xFF22C55E);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: reclamada ? t.overlay : completada ? const Color(0xFFFFD700).withValues(alpha: 0.06) : t.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: reclamada ? t.cardBorder : completada ? const Color(0xFFFFD700).withValues(alpha: 0.3) : t.cardBorder,
        ),
      ),
      child: Row(
        children: [
          // Emoji
          Text(quest.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          // Info + barra
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        quest.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: reclamada ? t.textMuted : t.textPrimary,
                          decoration: reclamada
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: t.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  quest.description,
                  style: TextStyle(fontSize: 11, color: t.textMuted),
                ),
                const SizedBox(height: 8),
                // Barra de progreso
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: (progreso / quest.targetValue).clamp(0.0, 1.0),
                    ),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (_, val, __) => LinearProgressIndicator(
                      value: val,
                      minHeight: 5,
                      backgroundColor: t.progressBg,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$progreso / ${quest.targetValue}',
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Cofre
          if (reclamada)
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: t.cardBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('✅', style: TextStyle(fontSize: 18)),
              ),
            )
          else if (completada)
            GestureDetector(
              onTap: () => _abrirCofre(quest, index),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (_, scale, child) =>
                    Transform.scale(scale: scale, child: child),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700)
                            .withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('📦', style: TextStyle(fontSize: 20)),
                  ),
                ),
              ),
            )
          else
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: t.overlay,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.cardBorder),
              ),
              child: Center(
                child: Text(
                  '🔒',
                  style: TextStyle(fontSize: 18, color: t.textMuted),
                ),
              ),
            ),
        ],
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