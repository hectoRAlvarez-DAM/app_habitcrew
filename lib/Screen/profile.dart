import 'dart:async';
import 'package:app_habitcrew/Widgets/animated_background.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../servicios/habit_service.dart';
import '../servicios/achievement_service.dart';
import 'package:app_habitcrew/Screen/profile_theme_service.dart';
import 'models/habit.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String _userName = '';
  String _userEmail = '';
  String _miembroDesde = '—';
  int _totalCompletados = 0;

  final AchievementService _achievementService = AchievementService();
  List<String> _insigniasEquipadas = [];
  List<String> _logrosDesbloqueados = [];
  StreamSubscription? _userSub;

  // Items del cofre y equipados
  List<Map<String, dynamic>> _itemsCofre = [];
  String? _bannerEquipado;
  String? _avatarEquipado;

  final HabitService _habitService = HabitService();
  List<Habit> _habitos = [];
  StreamSubscription<List<Habit>>? _habitSub;

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
    // Stream para insignias, banner y avatar en tiempo real
    _userSub = _achievementService.streamUsuario().listen((doc) {
      if (!mounted) return;
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) return;
      setState(() {
        _insigniasEquipadas = List<String>.from(data['insigniasEquipadas'] ?? []);
        _logrosDesbloqueados = List<String>.from(data['logrosDesbloqueados'] ?? []);
        _itemsCofre = List<Map<String, dynamic>>.from(data['itemsCofre'] ?? []);
        _bannerEquipado = data['bannerEquipado'] as String?;
        _avatarEquipado = data['avatarEquipado'] as String?;
      });
    });
  }

  @override
  void dispose() {
    _habitSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }

  int get _mejorRacha => _habitos.isEmpty
      ? 0
      : _habitos.map((h) => h.rachaActual).reduce((a, b) => a > b ? a : b);

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

      // El email siempre viene de Firebase Auth
      if (mounted) setState(() => _userEmail = user.email ?? '');

      final docRef = FirebaseFirestore.instance
          .collection('usuaris')
          .doc(user.uid);
      var doc = await docRef.get();

      // Si no existe el documento, lo creamos
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
        final fechaRegistro =
            (data['data_registre'] as Timestamp?)?.toDate();
        final nom = data['nom'] as String?;
        setState(() {
          _userName = (nom != null && nom.isNotEmpty)
              ? nom
              : user.email?.split('@')[0] ?? 'Usuario';
          _miembroDesde =
              fechaRegistro != null ? _formatearFecha(fechaRegistro) : '—';
          _totalCompletados =
              (data['totalHabitosCompletados'] as num?)?.toInt() ?? 0;
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Banner dinámico
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () => _mostrarSelectorBanner(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _getBannerColors(),
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                                painter: DiscordPatternPainter()),
                          ),
                          // Contenido del banner
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
                          // Botón de cambiar banner
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.edit, color: Colors.white70, size: 12),
                                  SizedBox(width: 4),
                                  Text('Banner', style: TextStyle(color: Colors.white70, fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Avatar
                  Positioned(
                    bottom: -50,
                    left: 20,
                    child: GestureDetector(
                      onTap: () => _mostrarSelectorAvatar(),
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _buildAvatarContent(size: 100),
                        ),
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
                              Text(
                                _userName.isNotEmpty ? _userName : '...',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5865F2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'PRO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                              Text(
                                _userEmail.isNotEmpty ? _userEmail : '...',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF4E5058).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.edit,
                            color: Colors.white, size: 20),
                      ),
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
                        const Text(
                          'INSIGNIAS',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _mostrarSelectorInsignias(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              'Gestionar',
                              style: TextStyle(
                                  color: Color(0xFF22C55E), fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _insigniasEquipadas.isEmpty
                        ? Text(
                            'Desbloquea logros y equipa hasta 3 insignias',
                            style: TextStyle(
                                color: Colors.white38, fontSize: 13),
                          )
                        : Row(
                            children: _insigniasEquipadas.map((id) {
                              final def = AchievementService.getById(id);
                              if (def == null) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _buildInsigniaChip(def),
                              );
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
                    color: const Color(0xFF2B2D31),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow('Miembro desde', _miembroDesde),
                      const Divider(color: Colors.white24, height: 16),
                      _buildInfoRow(
                          'Hábitos completados', '$_totalCompletados'),
                      const Divider(color: Colors.white24, height: 16),
                      _buildInfoRow('Mejor racha', '$_mejorRacha días'),
                      const Divider(color: Colors.white24, height: 16),
                      _buildInfoRow(
                          'Hábitos activos', '${_habitos.length}'),
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
                    const Text(
                      'LOGROS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount =
                            constraints.maxWidth > 600 ? 4 : 2;
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.9,
                          children: [
                            _buildAchievementGrid('Madrugador',
                                '7 días seguidos', Icons.wb_sunny,
                                Colors.orange, 100),
                            _buildAchievementGrid('En racha',
                                '30 días de racha',
                                Icons.local_fire_department,
                                Colors.red, 80),
                            _buildAchievementGrid('Social', '5 amigos',
                                Icons.people,
                                const Color.fromARGB(255, 8, 56, 95), 60),
                            _buildAchievementGrid('Disciplina', '50 hábitos',
                                Icons.auto_awesome,
                                const Color.fromARGB(255, 49, 2, 58), 40),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildActionButton(
                        'Configuración', Icons.settings, Colors.grey),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers visuales ───────────────────────────────────────────

  List<Color> _getBannerColors() {
    final theme = ProfileThemeService.getBanner(_bannerEquipado);
    return theme?.gradientColors ??
        ProfileThemeService.defaultBanner.gradientColors;
  }

  Widget _buildAvatarContent({required double size}) {
    final avatarTheme = ProfileThemeService.getAvatar(_avatarEquipado);
    if (avatarTheme != null) {
      return Container(
        color: avatarTheme.backgroundColor,
        child: Center(
          child: _avatarEquipado == 'Beta'
              ? Text(
                  'β',
                  style: TextStyle(
                    fontSize: size * 0.42,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -2,
                  ),
                )
              : Text(avatarTheme.emoji,
                  style: TextStyle(fontSize: size * 0.45)),
        ),
      );
    }
    return Container(
      color: ProfileThemeService.defaultAvatarColor,
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

  void _mostrarSelectorBanner() {
    // Combinar banners del cofre + default
    final disponibles = [
      null, // Default
      ..._itemsCofre
          .where((i) => i['tipo'] == 'banner')
          .map((i) => i['nombre'] as String?),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Elige tu banner',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: disponibles.map((nombre) {
                final theme = nombre != null
                    ? ProfileThemeService.getBanner(nombre)
                    : ProfileThemeService.defaultBanner;
                final isEquipado = _bannerEquipado == nombre;
                return GestureDetector(
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (nombre == null) {
                      await _achievementService.desequiparBanner();
                    } else {
                      await _achievementService.equiparBanner(nombre);
                    }
                  },
                  child: Container(
                    width: 100,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: theme?.gradientColors ??
                            [Colors.grey.shade800],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isEquipado
                            ? const Color(0xFF22C55E)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (theme?.emoji.isNotEmpty == true)
                            Text(theme!.emoji,
                                style: const TextStyle(fontSize: 18)),
                          Text(
                            nombre ?? 'Default',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 9),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _mostrarSelectorAvatar() {
    final disponibles = [
      null, // Default (inicial)
      ..._itemsCofre
          .where((i) => i['tipo'] == 'avatar')
          .map((i) => i['nombre'] as String?),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Elige tu avatar',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: disponibles.map((nombre) {
                final theme = nombre != null
                    ? ProfileThemeService.getAvatar(nombre)
                    : null;
                final isEquipado = _avatarEquipado == nombre;
                return GestureDetector(
                  onTap: () async {
                    Navigator.pop(ctx);
                    if (nombre == null) {
                      await _achievementService.desequiparAvatar();
                    } else {
                      await _achievementService.equiparAvatar(nombre);
                    }
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme?.backgroundColor ??
                          ProfileThemeService.defaultAvatarColor,
                      border: Border.all(
                        color: isEquipado
                            ? const Color(0xFF22C55E)
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: theme != null
                          ? Text(theme.emoji,
                              style: const TextStyle(fontSize: 28))
                          : Text(
                              _userName.isNotEmpty
                                  ? _userName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInsigniaChip(dynamic def) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF2B2D31),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(def.icon, color: const Color(0xFF22C55E), size: 14),
          const SizedBox(width: 4),
          Text(def.title,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
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
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Selecciona insignias (máx. 3)',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Toca para equipar o desequipar',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: equipada
                            ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: equipada
                              ? const Color(0xFF22C55E)
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(def.icon,
                              color: equipada
                                  ? const Color(0xFF22C55E)
                                  : Colors.white54,
                              size: 16),
                          const SizedBox(width: 6),
                          Text(def.title,
                              style: TextStyle(
                                  color: equipada
                                      ? Colors.white
                                      : Colors.white54,
                                  fontSize: 13)),
                          if (equipada) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.check,
                                color: Color(0xFF22C55E), size: 14),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6), fontSize: 14)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildAchievementGrid(String title, String subtitle, IconData icon,
      Color color, int progress) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
                BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 1),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text(subtitle,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
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
                    color: Colors.white.withValues(alpha: 0.2),
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

  Widget _buildActionButton(String text, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(text,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class DiscordPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double i = -size.height; i < size.width + size.height; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i - size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}