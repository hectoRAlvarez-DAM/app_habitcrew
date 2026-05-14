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
      isShopItem: true,
    ),
    'Noche estrellada': BannerTheme(
      nombre: 'Noche estrellada',
      emoji: '🌙',
      gradientColors: [Color(0xFF0A0A2E), Color(0xFF16213E), Color(0xFF0F3460)],
      accentColor: Color(0xFF4A90D9),
      isShopItem: true,
    ),
    'Bosque': BannerTheme(
      nombre: 'Bosque',
      emoji: '🌲',
      gradientColors: [Color(0xFF1B4332), Color(0xFF2D6A4F), Color(0xFF40916C)],
      accentColor: Color(0xFF52B788),
      isShopItem: true,
    ),
    'Océano': BannerTheme(
      nombre: 'Océano',
      emoji: '🌊',
      gradientColors: [Color(0xFF03045E), Color(0xFF0077B6), Color(0xFF00B4D8)],
      accentColor: Color(0xFF90E0EF),
      isShopItem: true,
    ),

    // ─── Banners de tienda (nuevos) ──────────────────────────────
    'Sakura': BannerTheme(
      nombre: 'Sakura',
      emoji: '🌸',
      gradientColors: [Color(0xFFFFB7C5), Color(0xFFFF8FAB), Color(0xFFD6336C)],
      accentColor: Color(0xFFFF8FAB),
      isShopItem: true,
    ),
    'Desierto': BannerTheme(
      nombre: 'Desierto',
      emoji: '🏜️',
      gradientColors: [Color(0xFFE8B86D), Color(0xFFC0622A), Color(0xFF7B2D00)],
      accentColor: Color(0xFFE8B86D),
      isShopItem: true,
    ),
    'Neón': BannerTheme(
      nombre: 'Neón',
      emoji: '⚡',
      gradientColors: [Color(0xFF0D0221), Color(0xFF6B0FA8), Color(0xFF00F5FF)],
      accentColor: Color(0xFF00F5FF),
      isShopItem: true,
    ),
    'Ártico': BannerTheme(
      nombre: 'Ártico',
      emoji: '❄️',
      gradientColors: [Color(0xFFE8F4FD), Color(0xFF90CCF4), Color(0xFF2980B9)],
      accentColor: Color(0xFF90CCF4),
      isShopItem: true,
    ),
    'Otoño': BannerTheme(
      nombre: 'Otoño',
      emoji: '🍂',
      gradientColors: [Color(0xFF8B4513), Color(0xFFD2691E), Color(0xFFDAA520)],
      accentColor: Color(0xFFDAA520),
      isShopItem: true,
    ),
    'Medianoche': BannerTheme(
      nombre: 'Medianoche',
      emoji: '🌃',
      gradientColors: [Color(0xFF000000), Color(0xFF0A0A2E), Color(0xFF1A237E)],
      accentColor: Color(0xFF3F51B5),
      isShopItem: true,
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

  // ─── Helpers ────────────────────────────────────────────────────

  /// Todos los banners disponibles en la tienda (no exclusivos de cofre)
  static List<MapEntry<String, BannerTheme>> get shopBanners =>
      banners.entries.where((e) => e.value.isShopItem).toList();

  static BannerTheme? getBanner(String? nombre) {
    if (nombre == null) return null;
    return banners[nombre];
  }

  /// Banner por defecto (el de Discord que ya teníamos)
  static const BannerTheme defaultBanner = BannerTheme(
    nombre: 'Default',
    emoji: '',
    gradientColors: [Color(0xFF5865F2), Color(0xFF404EED), Color(0xFF23272A)],
    accentColor: Color(0xFF5865F2),
  );
}

// ─── Modelos ─────────────────────────────────────────────────────────

class BannerTheme {
  final String nombre;
  final String emoji;
  final List<Color> gradientColors;
  final Color accentColor;
  final bool isExclusive;
  final bool isShopItem;

  const BannerTheme({
    required this.nombre,
    required this.emoji,
    required this.gradientColors,
    required this.accentColor,
    this.isExclusive = false,
    this.isShopItem = false,
  });
}