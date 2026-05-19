import 'package:flutter/material.dart';

/// Colores centralizados para modo normal (oscuro) y modo contraste (blanco).
/// Uso: final t = AppTheme.of(context);
class AppTheme {
  final bool isContrast;
  const AppTheme._(this.isContrast);

  static AppTheme of(BuildContext context) {
    // Se importa desde contrast_mode.dart en cada pantalla
    // pero también se puede pasar isContrast directamente
    return AppTheme._(false);
  }

  static AppTheme fromContrast(bool isContrast) => AppTheme._(isContrast);

  // ── Fondos ──────────────────────────────────────────────────────
  Color get scaffoldBg     => isContrast ? Colors.white          : Colors.transparent;
  Color get cardBg         => isContrast ? const Color(0xFFF5F5F5) : Colors.white.withOpacity(0.05);
  Color get cardBgStrong   => isContrast ? const Color(0xFFEEEEEE) : const Color(0xFF2B2D31);
  Color get cardBorder     => isContrast ? const Color(0xFFDDDDDD) : Colors.white.withOpacity(0.1);
  Color get inputBg        => isContrast ? const Color(0xFFF0F0F0) : Colors.white.withOpacity(0.07);
  Color get chipBg         => isContrast ? const Color(0xFFE8E8E8) : Colors.white.withOpacity(0.06);
  Color get chipBorder     => isContrast ? const Color(0xFFCCCCCC) : Colors.white.withOpacity(0.1);
  Color get divider        => isContrast ? const Color(0xFFDDDDDD) : Colors.white.withOpacity(0.08);
  Color get overlay        => isContrast ? Colors.black.withOpacity(0.04) : Colors.white.withOpacity(0.04);

  // ── Textos ──────────────────────────────────────────────────────
  Color get textPrimary    => isContrast ? const Color(0xFF111111) : Colors.white;
  Color get textSecondary  => isContrast ? const Color(0xFF444444) : Colors.white70;
  Color get textMuted      => isContrast ? const Color(0xFF777777) : Colors.white38;
  Color get textHint       => isContrast ? const Color(0xFF999999) : Colors.white24;

  // ── Acento verde principal ───────────────────────────────────────
  Color get accent         => const Color(0xFF22C55E);
  Color get accentLight    => isContrast
      ? const Color(0xFF22C55E).withOpacity(0.15)
      : const Color(0xFF22C55E).withOpacity(0.12);
  Color get accentBorder   => const Color(0xFF22C55E).withOpacity(0.3);

  // ── Iconos ──────────────────────────────────────────────────────
  Color get iconPrimary    => isContrast ? const Color(0xFF333333) : Colors.white;
  Color get iconMuted      => isContrast ? const Color(0xFF888888) : Colors.white38;

  // ── Botón de fondo claro (edit, back, etc.) ─────────────────────
  Color get btnSecondaryBg => isContrast ? const Color(0xFFE8E8E8) : Colors.white.withOpacity(0.08);
  Color get btnSecondaryBorder => isContrast ? const Color(0xFFCCCCCC) : Colors.white.withOpacity(0.1);

  // ── Shadow ──────────────────────────────────────────────────────
  List<BoxShadow> get cardShadow => isContrast
      ? [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))]
      : [];

  // ── TabBar / chips activos ───────────────────────────────────────
  Color get tabActiveBg    => const Color(0xFF22C55E);
  Color get tabActiveText  => Colors.white;
  Color get tabInactiveBg  => isContrast ? const Color(0xFFE8E8E8) : Colors.white.withOpacity(0.06);
  Color get tabInactiveText => isContrast ? const Color(0xFF555555) : Colors.white.withOpacity(0.6);

  // ── Barra de progreso ────────────────────────────────────────────
  Color get progressBg     => isContrast ? const Color(0xFFDDDDDD) : Colors.white.withOpacity(0.08);

  // ── Label de sección ────────────────────────────────────────────
  Color get sectionLabel   => isContrast ? const Color(0xFF666666) : Colors.white54;
}
