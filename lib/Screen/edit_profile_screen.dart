import 'dart:convert';
import 'package:app_habitcrew/Widgets/animated_background.dart';
import 'package:flutter/material.dart';
import 'package:app_habitcrew/Widgets/contrast_mode.dart';
import 'package:app_habitcrew/Widgets/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../servicios/photo_service.dart';
import 'profile_theme_service.dart';
import '../servicios/shop_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String nombreActual;
  final String? fotoActual;
  final String? bannerActual;
  final String? bioActual;
  final List<Map<String, dynamic>> itemsCofre;

  const EditProfileScreen({
    super.key,
    required this.nombreActual,
    this.fotoActual,
    this.bannerActual,
    this.bioActual,
    required this.itemsCofre,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {

  AppTheme get _t => AppTheme.fromContrast(ContrastMode.of(context));


  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _bioController;

  final PhotoService _photoService = PhotoService();

  String? _foto;
  String? _banner;
  bool _subiendoFoto = false;
  bool _guardando = false;
  Set<String> _purchasedShopBanners = {};

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.nombreActual);
    _bioController = TextEditingController(text: widget.bioActual ?? '');
    _foto = widget.fotoActual;
    _banner = widget.bannerActual;
    _loadShopBanners();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadShopBanners() async {
    final names = await ShopService.instance.loadPurchasedBannerNames();
    if (mounted) setState(() => _purchasedShopBanners = names);
  }

  List<Map<String, dynamic>> get _bannersCofre =>
      widget.itemsCofre.where((i) => i['tipo'] == 'banner').toList();

  List<Color> get _bannerColors {
    final theme = ProfileThemeService.getBanner(_banner);
    return theme?.gradientColors ??
        ProfileThemeService.defaultBanner.gradientColors;
  }

  // ─── Guardar cambios ────────────────────────────────────────────

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final nombre = _nombreController.text.trim();
      final bio = _bioController.text.trim();

      await FirebaseFirestore.instance.collection('usuaris').doc(uid).update({
        'nom': nombre,
        'bio': bio,
        'bannerEquipado': _banner,
      });

      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  // ─── Foto ────────────────────────────────────────────────────────

  Future<void> _subirFoto(ImageSource source) async {
    setState(() => _subiendoFoto = true);
    final resultado = await _photoService.seleccionarYSubirFoto(
      source: source,
      context: context,
    );
    if (mounted) {
      setState(() {
        _subiendoFoto = false;
        if (resultado != null) _foto = resultado;
      });
      if (resultado == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo subir la foto. Prueba con una imagen más pequeña.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _eliminarFoto() async {
    setState(() => _subiendoFoto = true);
    await _photoService.eliminarFoto();
    if (mounted) {
      setState(() {
        _subiendoFoto = false;
        _foto = null;
      });
    }
  }

  void _mostrarOpcionesFoto() {
    final t = _t;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Foto de perfil',
                style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _opcion(
              icon: Icons.photo_library_rounded,
              label: 'Elegir de la galería',
              color: const Color(0xFF3B82F6),
              onTap: () async {
                Navigator.pop(ctx);
                await _subirFoto(ImageSource.gallery);
              },
            ),
            if (_photoService.camaraDisponible) ...[
              const SizedBox(height: 10),
              _opcion(
                icon: Icons.camera_alt_rounded,
                label: 'Hacer una foto',
                color: const Color(0xFF22C55E),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _subirFoto(ImageSource.camera);
                },
              ),
            ],
            if (_foto != null) ...[
              const SizedBox(height: 10),
              _opcion(
                icon: Icons.delete_rounded,
                label: 'Eliminar foto',
                color: Colors.red,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _eliminarFoto();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Banner ──────────────────────────────────────────────────────

  void _mostrarSelectorBanner() {
    final t = _t;
    // Banners: default + cofre + tienda comprados
    final cofreNames = _bannersCofre.map((i) => i['nombre'] as String?).toList();
    final shopNames = ProfileThemeService.shopBanners
        .where((e) => _purchasedShopBanners.contains(e.key))
        .map((e) => e.key as String?)
        .toList();
    final disponibles = [
      null,
      ...cofreNames,
      ...shopNames.where((n) => !cofreNames.contains(n)),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Elige tu banner',
                  style: TextStyle(
                      color: t.textPrimary,
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
                  final isSelected = _banner == nombre;
                  return GestureDetector(
                    onTap: () {
                      setModal(() {});
                      setState(() => _banner = nombre);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      width: 100,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors:
                              theme?.gradientColors ?? [Colors.grey.shade800],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF22C55E)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (nombre == 'Beta')
                              Text('BETA',
                                  style: TextStyle(
                                      color: t.textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 3))
                            else if (theme?.emoji.isNotEmpty == true)
                              Text(theme!.emoji,
                                  style: TextStyle(fontSize: 16)),
                            Text(
                              nombre ?? 'Default',
                              style: TextStyle(
                                  color: t.textSecondary, fontSize: 9),
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
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isContrast = ContrastMode.of(context);
    final t = AppTheme.fromContrast(isContrast);
    return AnimatedBackground(
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // ── Banner con avatar encima ─────────────────
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Banner
                      GestureDetector(
                        onTap: _mostrarSelectorBanner,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _bannerColors,
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Patrón de fondo
                              Positioned.fill(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                  child: CustomPaint(
                                    painter: _BannerPatternPainter(),
                                  ),
                                ),
                              ),
                              // Texto/emoji del banner
                              if (_banner == 'Beta')
                                Center(
                                  child: Text(
                                    'BETA',
                                    style: TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white.withValues(
                                        alpha: 0.15,
                                      ),
                                      letterSpacing: 16,
                                    ),
                                  ),
                                )
                              else if (_banner != null)
                                Center(
                                  child: Opacity(
                                    opacity: 0.25,
                                    child: Text(
                                      ProfileThemeService.getBanner(
                                            _banner,
                                          )?.emoji ??
                                          '',
                                      style:
                                          TextStyle(fontSize: 80),
                                    ),
                                  ),
                                ),
                              // Botón cambiar banner
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit,
                                          color: t.textSecondary,
                                          size: 12),
                                      SizedBox(width: 4),
                                      Text('Banner',
                                          style: TextStyle(
                                              color: t.textSecondary,
                                              fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ),
                              // Botón volver
                              Positioned(
                                top: 12,
                                left: 12,
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.4,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.arrow_back,
                                        color: Colors.white, size: 20),
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
                          onTap: _mostrarOpcionesFoto,
                          child: Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: _subiendoFoto
                                      ? Container(
                                          color: Colors.black54,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: Color(0xFF22C55E),
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      : _foto != null
                                      ? _buildFotoWidget(
                                          _foto!,
                                          fit: BoxFit.cover,
                                        )
                                      : _buildAvatarFallback(),
                                ),
                              ),
                              // Icono cámara
                              if (!_subiendoFoto)
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF22C55E),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(Icons.camera_alt,
                                        color: Colors.white, size: 13),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 70),

                  // ── Formulario ────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre
                        _buildLabel('NOMBRE DE USUARIO'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nombreController,
                          style: TextStyle(
                              color: _t.textPrimary, fontSize: 15),
                          maxLength: 30,
                          decoration: _inputDeco('Tu nombre'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'El nombre no puede estar vacío';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Biografía
                        _buildLabel('BIOGRAFÍA'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _bioController,
                          style: TextStyle(
                              color: _t.textPrimary, fontSize: 15),
                          maxLength: 150,
                          maxLines: 3,
                          decoration: _inputDeco('Cuéntanos algo sobre ti...'),
                        ),

                        const SizedBox(height: 20),

                        const SizedBox(height: 32),

                        // Botón guardar
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _guardando ? null : _guardar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _guardando
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Guardar cambios',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
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

  // ─── Helpers ─────────────────────────────────────────────────────

  Widget _buildFotoWidget(String foto, {BoxFit fit = BoxFit.cover}) {
    try {
      if (foto.startsWith('data:image')) {
        final base64Data = foto.split(',').last;
        return Image.memory(
          base64Decode(base64Data),
          fit: fit,
          errorBuilder: (_, __, ___) => _buildAvatarFallback(),
        );
      }
      // Fallback para URLs antiguas
      return Image.network(
        foto,
        fit: fit,
        errorBuilder: (_, __, ___) => _buildAvatarFallback(),
      );
    } catch (_) {
      return _buildAvatarFallback();
    }
  }

  Widget _buildAvatarFallback() {
    final t = _t;
    return Container(
      color: const Color(0xFF5865F2),
      child: Center(
        child: Text(
          widget.nombreActual.isNotEmpty
              ? widget.nombreActual[0].toUpperCase()
              : '?',
          style: TextStyle(
            color: t.textPrimary,
            fontSize: 38,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    final t = _t;
    return Text(
      text,
      style: TextStyle(
        color: t.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  InputDecoration _inputDeco(String hint) {
    final t = _t;
    return InputDecoration(
      hintText: hint,
      hintStyle:
          TextStyle(color: t.textMuted),
      filled: true,
      fillColor: t.inputBg,
      counterStyle: TextStyle(
          color: t.textMuted, fontSize: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: t.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: t.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF22C55E)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Widget _opcion({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: _t.textPrimary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// Patrón de fondo del banner
class _BannerPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double i = -size.height; i < size.width + size.height; i += 30) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
