import 'dart:async';
import 'dart:convert';
import 'package:app_habitcrew/Widgets/animated_background.dart';
import 'package:app_habitcrew/Widgets/contrast_mode.dart';
import 'package:app_habitcrew/Widgets/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../servicios/habit_service.dart';
import '../servicios/achievement_service.dart';
import 'package:app_habitcrew/Screen/profile_theme_service.dart';
import 'package:app_habitcrew/Screen/edit_profile_screen.dart';
import 'package:app_habitcrew/Screen/settings_screen.dart';
import 'models/habit.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String _userName = '';
  String _userEmail = '';

  AppTheme get _t => AppTheme.fromContrast(ContrastMode.of(context));
  String _miembroDesde = '—';
  int _totalCompletados = 0;
  String _bio = '';

  final AchievementService _achievementService = AchievementService.instance;
  List<String> _insigniasEquipadas = [];
  List<String> _logrosDesbloqueados = [];
  StreamSubscription? _userSub;

  List<Map<String, dynamic>> _itemsCofre = [];
  String? _bannerEquipado;
  String? _fotoPerfil;

  final HabitService _habitService = HabitService();
  List<Habit> _habitos = [];
  StreamSubscription<List<Habit>>? _habitSub;
  int _mejorRacha = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatosUsuario();
    _habitSub = _habitService.obtenerHabitos().listen(
      (habitos) {
        if (mounted) setState(() => _habitos = habitos);
      },
      onError: (e) => debugPrint('Error stream hábitos perfil: $e'),
      cancelOnError: false,
    );
    // Stream para insignias, banner, avatar y racha global en tiempo real
    _userSub = _achievementService.streamUsuario().listen((doc) {
      if (!mounted) return;
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;
      final actual = (data['rachaGlobalActual'] as num?)?.toInt() ?? 0;
      final record = (data['recordRachaGlobal'] as num?)?.toInt() ?? 0;
      setState(() {
        _insigniasEquipadas = List<String>.from(data['insigniasEquipadas'] ?? []);
        _logrosDesbloqueados = List<String>.from(data['logrosDesbloqueados'] ?? []);
        _itemsCofre = List<Map<String, dynamic>>.from(data['itemsCofre'] ?? []);
        _bannerEquipado = data['bannerEquipado'] as String?;
        _fotoPerfil = data['fotoPerfil'] as String?;
        _bio = data['bio'] as String? ?? '';
        _userName = data['nom'] as String? ?? _userName;
        _mejorRacha = actual > record ? actual : record;
      });
    });
  }

  @override
  void dispose() {
    _habitSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }

  String _formatearFecha(DateTime fecha) {
    const meses = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    return '${meses[fecha.month - 1]} ${fecha.year}';
  }

  Future<void> _cargarDatosUsuario() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      if (mounted) setState(() => _userEmail = user.email ?? '');

      final docRef = FirebaseFirestore.instance.collection('usuaris').doc(user.uid);
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

      if (doc.exists && mounted) {
        final data = doc.data()!;
        final fechaRegistro = (data['data_registre'] as Timestamp?)?.toDate();
        final nom = data['nom'] as String?;
        setState(() {
          _userName = (nom != null && nom.isNotEmpty)
              ? nom
              : user.email?.split('@')[0] ?? 'Usuario';
          _miembroDesde = fechaRegistro != null ? _formatearFecha(fechaRegistro) : '—';
          _totalCompletados = (data['totalHabitosCompletados'] as num?)?.toInt() ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error cargando datos de usuario: $e');
      final user = FirebaseAuth.instance.currentUser;
      if (mounted && user != null) {
        setState(() {
          _userEmail = user.email ?? '';
          _userName = user.email?.split('@')[0] ?? 'Usuario';
        });
      }
    }
  }

  // ── Helpers de color según modo contraste ────────────────────────────────

  Color _textPrimary(bool isContrast) =>
      isContrast ? const Color(0xFF111111) : Colors.white;

  Color _textSecondary(bool isContrast) =>
      isContrast ? const Color(0xFF444444) : Colors.white70;

  Color _textMuted(bool isContrast) =>
      isContrast ? const Color(0xFF666666) : Colors.white54;

  Color _cardBackground(bool isContrast) =>
      isContrast ? const Color(0xFFF5F5F5) : const Color(0xFF2B2D31);

  Color _cardBorder(bool isContrast) =>
      isContrast ? const Color(0xFFDDDDDD) : Colors.white.withValues(alpha: 0.05);

  Color _dividerColor(bool isContrast) =>
      isContrast ? const Color(0xFFCCCCCC) : Colors.white24;

  Color _editButtonBg(bool isContrast) =>
      isContrast
          ? const Color(0xFFE8E8E8)
          : const Color(0xFF4E5058).withValues(alpha: 0.6);

  Color _sectionLabelColor(bool isContrast) =>
      isContrast ? const Color(0xFF555555) : Colors.white54;

  Color _insigniaBorder(bool isContrast) =>
      isContrast
          ? const Color(0xFF22C55E).withValues(alpha: 0.7)
          : const Color(0xFF22C55E).withValues(alpha: 0.4);

  Color _achievementCardBg(bool isContrast) =>
      isContrast ? const Color(0xFFEEEEEE) : Colors.white.withValues(alpha: 0.1);

  Color _achievementCardBorder(bool isContrast) =>
      isContrast ? const Color(0xFFCCCCCC) : Colors.white.withValues(alpha: 0.2);

  Color _gestButton(bool isContrast) =>
      isContrast
          ? const Color(0xFF22C55E).withValues(alpha: 0.12)
          : const Color(0xFF22C55E).withValues(alpha: 0.15);

  @override
  Widget build(BuildContext context) {
    final isContrast = ContrastMode.of(context);

    return AnimatedBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Banner
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isContrast
                            ? [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)]
                            : _getBannerColors(),
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            child: CustomPaint(painter: DiscordPatternPainter(isContrast: isContrast)),
                          ),
                        ),
                        if (!isContrast) ...[
                          if (_bannerEquipado == 'Beta')
                            Center(
                              child: Text(
                                'BETA',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white.withValues(alpha: 0.15),
                                  letterSpacing: 16,
                                ),
                              ),
                            )
                          else if (_bannerEquipado != null)
                            Center(
                              child: Opacity(
                                opacity: 0.3,
                                child: Text(
                                  ProfileThemeService.getBanner(_bannerEquipado)?.emoji ?? '',
                                  style: const TextStyle(fontSize: 80),
                                ),
                              ),
                            ),
                        ],
                        Positioned(
                          top: 12,
                          right: 12,
                          child: GestureDetector(
                            onTap: _abrirEditorPerfil,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isContrast
                                    ? Colors.white.withValues(alpha: 0.8)
                                    : Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.edit,
                                  color: isContrast ? const Color(0xFF333333) : Colors.white,
                                  size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Avatar
                  Positioned(
                    bottom: -50,
                    left: 20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isContrast ? const Color(0xFF333333) : Colors.white,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _fotoPerfil != null
                            ? _buildFotoWidget(_fotoPerfil!)
                            : _buildAvatarContent(size: 100),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 60),

              // Información de usuario
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _userName.isNotEmpty ? _userName : '...',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: _textPrimary(isContrast),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5865F2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'PRO',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF23A55A),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _userEmail.isNotEmpty ? _userEmail : '...',
                                  style: TextStyle(fontSize: 14, color: _textSecondary(isContrast)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (_bio.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              _bio,
                              style: TextStyle(
                                fontSize: 13,
                                color: isContrast
                                    ? const Color(0xFF555555)
                                    : Colors.white.withValues(alpha: 0.55),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: _editButtonBg(isContrast),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isContrast
                                  ? const Color(0xFFCCCCCC)
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: IconButton(
                            onPressed: _abrirEditorPerfil,
                            icon: Icon(Icons.edit,
                                color: isContrast ? const Color(0xFF333333) : Colors.white,
                                size: 20),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: _editButtonBg(isContrast),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isContrast
                                  ? const Color(0xFFCCCCCC)
                                  : Colors.white.withValues(alpha: 0.1),
                            ),
                          ),
                          child: IconButton(
                            onPressed: _abrirConfiguracion,
                            icon: Icon(Icons.settings,
                                color: isContrast ? const Color(0xFF333333) : Colors.white,
                                size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Insignias equipadas ──────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'INSIGNIAS',
                          style: TextStyle(
                            color: _sectionLabelColor(isContrast),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _mostrarSelectorInsignias(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _gestButton(isContrast),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Text(
                              'Gestionar',
                              style: TextStyle(color: Color(0xFF22C55E), fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _insigniasEquipadas.isEmpty
                        ? Text(
                            'Desbloquea logros y equipa hasta 3 insignias',
                            style: TextStyle(color: _textMuted(isContrast), fontSize: 13),
                          )
                        // FIX OVERFLOW: Wrap en lugar de Row para que las insignias hagan wrap
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _insigniasEquipadas.map((id) {
                              final def = AchievementService.getById(id);
                              if (def == null) return const SizedBox();
                              return _buildInsigniaChip(def, isContrast);
                            }).toList(),
                          ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Estadísticas reales
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _cardBackground(isContrast),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _cardBorder(isContrast)),
                    boxShadow: isContrast
                        ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Miembro desde', _miembroDesde, isContrast),
                      Divider(color: _dividerColor(isContrast), height: 16),
                      _buildInfoRow('Hábitos completados', '$_totalCompletados', isContrast),
                      Divider(color: _dividerColor(isContrast), height: 16),
                      _buildInfoRow('Mejor racha', '$_mejorRacha días', isContrast),
                      Divider(color: _dividerColor(isContrast), height: 16),
                      _buildInfoRow('Hábitos activos', '${_habitos.length}', isContrast),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Logros
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LOGROS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textSecondary(isContrast),
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.9,
                          children: [
                            _buildAchievementGrid('Madrugador', '7 días seguidos', Icons.wb_sunny, Colors.orange, 100, isContrast),
                            _buildAchievementGrid('En racha', '30 días de racha', Icons.local_fire_department, Colors.red, 80, isContrast),
                            _buildAchievementGrid('Social', '5 amigos', Icons.people, const Color.fromARGB(255, 8, 56, 95), 60, isContrast),
                            _buildAchievementGrid('Disciplina', '50 hábitos', Icons.auto_awesome, const Color.fromARGB(255, 49, 2, 58), 40, isContrast),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirConfiguracion() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => const SettingsScreen(),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _abrirEditorPerfil() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => EditProfileScreen(
          nombreActual: _userName,
          fotoActual: _fotoPerfil,
          bannerActual: _bannerEquipado,
          bioActual: _bio,
          itemsCofre: _itemsCofre,
        ),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  List<Color> _getBannerColors() {
    final theme = ProfileThemeService.getBanner(_bannerEquipado);
    return theme?.gradientColors ?? ProfileThemeService.defaultBanner.gradientColors;
  }

  Widget _buildFotoWidget(String foto) {
    try {
      if (foto.startsWith('data:image')) {
        final base64Data = foto.split(',').last;
        return Image.memory(base64Decode(base64Data), fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildAvatarContent(size: 100));
      }
      return Image.network(foto, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildAvatarContent(size: 100));
    } catch (_) {
      return _buildAvatarContent(size: 100);
    }
  }

  Widget _buildAvatarContent({required double size}) {
    return Container(
      color: const Color(0xFF5865F2),
      child: Center(
        child: Text(
          _userName.isNotEmpty ? _userName[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildInsigniaChip(dynamic def, bool isContrast) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isContrast ? const Color(0xFFF0FBF4) : const Color(0xFF2B2D31),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _insigniaBorder(isContrast)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(def.icon, color: const Color(0xFF22C55E), size: 14),
          const SizedBox(width: 4),
          Text(def.title,
              style: TextStyle(
                color: isContrast ? const Color(0xFF222222) : Colors.white,
                fontSize: 12,
              )),
        ],
      ),
    );
  }

  void _mostrarSelectorInsignias() {
    if (_logrosDesbloqueados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Desbloquea logros primero para equipar insignias'),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Selecciona insignias (máx. 3)',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Toca para equipar o desequipar',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _logrosDesbloqueados.map((id) {
                  final def = AchievementService.getById(id);
                  if (def == null) return const SizedBox();
                  final equipada = _insigniasEquipadas.contains(id);
                  return GestureDetector(
                    onTap: () async {
                      if (equipada) {
                        await _achievementService.desequiparInsignia(id);
                      } else {
                        await _achievementService.equiparInsignia(id);
                      }
                      setModalState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: equipada
                            ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: equipada ? const Color(0xFF22C55E) : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(def.icon, color: equipada ? const Color(0xFF22C55E) : Colors.white54, size: 16),
                          const SizedBox(width: 6),
                          Text(def.title,
                              style: TextStyle(color: equipada ? Colors.white : Colors.white54, fontSize: 13)),
                          if (equipada) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.check, color: Color(0xFF22C55E), size: 14),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isContrast) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: _textSecondary(isContrast), fontSize: 14)),
        Text(value,
            style: TextStyle(
              color: _textPrimary(isContrast),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            )),
      ],
    );
  }

  Widget _buildAchievementGrid(
      String title, String subtitle, IconData icon, Color color, int progress, bool isContrast) {
    return Container(
      decoration: BoxDecoration(
        color: _achievementCardBg(isContrast),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _achievementCardBorder(isContrast)),
        boxShadow: isContrast
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.3),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10, spreadRadius: 1),
              ],
            ),
            child: Icon(icon, color: isContrast ? color : Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(title,
              style: TextStyle(
                color: _textPrimary(isContrast),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(subtitle,
              style: TextStyle(color: _textSecondary(isContrast), fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Stack(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: isContrast ? const Color(0xFFDDDDDD) : Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress / 100,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color, bool isContrast, {VoidCallback? onTap}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isContrast ? const Color(0xFFCCCCCC) : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: ElevatedButton(
        onPressed: onTap ?? () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: isContrast ? const Color(0xFFF5F5F5) : Colors.white.withValues(alpha: 0.1),
          foregroundColor: _t.textPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class DiscordPatternPainter extends CustomPainter {
  final bool isContrast;
  const DiscordPatternPainter({this.isContrast = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isContrast
          ? Colors.black.withValues(alpha: 0.04)
          : Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double i = -size.height; i < size.width + size.height; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i - size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
