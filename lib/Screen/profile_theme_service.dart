import 'package:flutter/material.dart';

/// Define el aspecto visual de cada banner y avatar disponible.
/// Preparado para añadir animaciones en el futuro.
class ProfileThemeService {

  // ─── Banners ────────────────────────────────────────────────────

  static const Map<String, BannerTheme> banners = {
    // Banner Beta exclusivo
    'Beta': BannerTheme(
      nombre: 'Beta',
      emoji: '🚀',
      gradientColors: [Color(0xFF000000), Color(0xFF0A0A0A), Color(0xFF111111)],
      accentColor: Color(0xFFFFFFFF),
      isExclusive: true,
    ),

    // Banners de tienda (no exclusivos)
    'Atardecer': BannerTheme(
      nombre: 'Atardecer',
      emoji: '🌅',
      gradientColors: [Color(0xFFFF6B35), Color(0xFFFF8C42), Color(0xFF1A0A00)],
      accentColor: Color(0xFFFF6B35),
    ),
    'Noche estrellada': BannerTheme(
      nombre: 'Noche estrellada',
      emoji: '🌙',
      gradientColors: [Color(0xFF0A0A2E), Color(0xFF16213E), Color(0xFF0F3460)],
      accentColor: Color(0xFF4A90D9),
    ),
    'Bosque': BannerTheme(
      nombre: 'Bosque',
      emoji: '🌲',
      gradientColors: [Color(0xFF1B4332), Color(0xFF2D6A4F), Color(0xFF40916C)],
      accentColor: Color(0xFF52B788),
    ),
    'Océano': BannerTheme(
      nombre: 'Océano',
      emoji: '🌊',
      gradientColors: [Color(0xFF03045E), Color(0xFF0077B6), Color(0xFF00B4D8)],
      accentColor: Color(0xFF90E0EF),
    ),

    // Banners exclusivos del cofre
    'Aurora boreal': BannerTheme(
      nombre: 'Aurora boreal',
      emoji: '🌌',
      gradientColors: [Color(0xFF0D1B2A), Color(0xFF006466), Color(0xFF4CAF50)],
      accentColor: Color(0xFF00E5FF),
      isExclusive: true,
    ),
    'Tormenta eléctrica': BannerTheme(
      nombre: 'Tormenta eléctrica',
      emoji: '⛈️',
      gradientColors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF533483)],
      accentColor: Color(0xFFFFD700),
      isExclusive: true,
    ),
    'Volcán': BannerTheme(
      nombre: 'Volcán',
      emoji: '🌋',
      gradientColors: [Color(0xFF0D0D0D), Color(0xFF6B1A1A), Color(0xFFFF4500)],
      accentColor: Color(0xFFFF6B35),
      isExclusive: true,
    ),
    'Galaxia espiral': BannerTheme(
      nombre: 'Galaxia espiral',
      emoji: '🌀',
      gradientColors: [Color(0xFF0A0015), Color(0xFF2D0057), Color(0xFF6A0DAD)],
      accentColor: Color(0xFFBF5AF2),
      isExclusive: true,
    ),
    'Fondo del mar': BannerTheme(
      nombre: 'Fondo del mar',
      emoji: '🌊',
      gradientColors: [Color(0xFF000814), Color(0xFF001D3D), Color(0xFF003566)],
      accentColor: Color(0xFF48CAE4),
      isExclusive: true,
    ),
  };

  // ─── Avatares ────────────────────────────────────────────────────

  static const Map<String, AvatarTheme> avatars = {
    // Avatar Beta exclusivo
    'Beta': AvatarTheme(
      nombre: 'Beta',
      emoji: 'β',
      backgroundColor: Color(0xFF000000),
      isExclusive: true,
    ),

    // Avatares de tienda
    'Aventurero': AvatarTheme(
      nombre: 'Aventurero',
      emoji: '🧭',
      backgroundColor: Color(0xFFFFB703),
      isExclusive: false,
    ),
    'Mago': AvatarTheme(
      nombre: 'Mago',
      emoji: '🧙',
      backgroundColor: Color(0xFF7B2FBE),
      isExclusive: false,
    ),
    'Guerrero': AvatarTheme(
      nombre: 'Guerrero',
      emoji: '⚔️',
      backgroundColor: Color(0xFFE63946),
      isExclusive: false,
    ),
    'Explorador': AvatarTheme(
      nombre: 'Explorador',
      emoji: '🗺️',
      backgroundColor: Color(0xFF2A9D8F),
      isExclusive: false,
    ),

    // Avatares exclusivos del cofre
    'Ninja': AvatarTheme(
      nombre: 'Ninja',
      emoji: '🥷',
      backgroundColor: Color(0xFF1A1A2E),
      isExclusive: true,
    ),
    'Astronauta': AvatarTheme(
      nombre: 'Astronauta',
      emoji: '👨‍🚀',
      backgroundColor: Color(0xFF03045E),
      isExclusive: true,
    ),
    'Robot': AvatarTheme(
      nombre: 'Robot',
      emoji: '🤖',
      backgroundColor: Color(0xFF2B2D42),
      isExclusive: true,
    ),
    'Zorro': AvatarTheme(
      nombre: 'Zorro',
      emoji: '🦊',
      backgroundColor: Color(0xFFE85D04),
      isExclusive: true,
    ),
    'Dragón': AvatarTheme(
      nombre: 'Dragón',
      emoji: '🐉',
      backgroundColor: Color(0xFF6B1A1A),
      isExclusive: true,
    ),
  };

  // ─── Helpers ────────────────────────────────────────────────────

  static BannerTheme? getBanner(String? nombre) {
    if (nombre == null) return null;
    return banners[nombre];
  }

  static AvatarTheme? getAvatar(String? nombre) {
    if (nombre == null) return null;
    return avatars[nombre];
  }

  /// Banner por defecto (el de Discord que ya teníamos)
  static const BannerTheme defaultBanner = BannerTheme(
    nombre: 'Default',
    emoji: '',
    gradientColors: [Color(0xFF5865F2), Color(0xFF404EED), Color(0xFF23272A)],
    accentColor: Color(0xFF5865F2),
  );

  /// Avatar por defecto (inicial del nombre)
  static const Color defaultAvatarColor = Color(0xFF5865F2);
}

// ─── Modelos ─────────────────────────────────────────────────────────

class BannerTheme {
  final String nombre;
  final String emoji;
  final List<Color> gradientColors;
  final Color accentColor;
  final bool isExclusive;

  const BannerTheme({
    required this.nombre,
    required this.emoji,
    required this.gradientColors,
    required this.accentColor,
    this.isExclusive = false,
  });
}

class AvatarTheme {
  final String nombre;
  final String emoji;
  final Color backgroundColor;
  final bool isExclusive;

  const AvatarTheme({
    required this.nombre,
    required this.emoji,
    required this.backgroundColor,
    this.isExclusive = false,
  });
}