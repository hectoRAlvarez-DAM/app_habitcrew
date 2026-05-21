import 'package:flutter/material.dart';
import 'package:app_habitcrew/Widgets/animated_background.dart';
import 'package:app_habitcrew/Widgets/contrast_mode.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isContrast = ContrastMode.of(context);

    final textPrimary = isContrast ? const Color(0xFF111111) : Colors.white;
    final textSecondary = isContrast ? const Color(0xFF555555) : Colors.white54;
    final cardBg = isContrast ? const Color(0xFFF5F5F5) : Colors.white.withValues(alpha: 0.06);
    final cardBorder = isContrast ? const Color(0xFFDDDDDD) : Colors.white.withValues(alpha: 0.12);
    final backBg = isContrast ? const Color(0xFFE8E8E8) : Colors.white.withValues(alpha: 0.08);
    final backBorder = isContrast ? const Color(0xFFCCCCCC) : Colors.white.withValues(alpha: 0.1);
    final divider = isContrast ? const Color(0xFFE0E0E0) : Colors.white.withValues(alpha: 0.08);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: backBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: backBorder),
                        ),
                        child: Icon(Icons.arrow_back, color: textPrimary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Configuración',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Sección Apariencia ───────────────────
                      _SectionLabel(text: 'APARIENCIA', color: textSecondary),
                      const SizedBox(height: 10),

                      _SettingsCard(
                        bg: cardBg,
                        border: cardBorder,
                        child: _ContrastToggleRow(
                          isContrast: isContrast,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Sección Cuenta ───────────────────────
                      _SectionLabel(text: 'CUENTA', color: textSecondary),
                      const SizedBox(height: 10),

                      _SettingsCard(
                        bg: cardBg,
                        border: cardBorder,
                        child: Column(
                          children: [
                            _SettingsRow(
                              icon: Icons.person_outline,
                              iconColor: const Color(0xFF22C55E),
                              label: 'Editar perfil',
                              textColor: textPrimary,
                              onTap: () => Navigator.pop(context),
                            ),

                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Sección Sesión ───────────────────────
                      _SectionLabel(text: 'SESIÓN', color: textSecondary),
                      const SizedBox(height: 10),

                      _SettingsCard(
                        bg: cardBg,
                        border: cardBorder,
                        child: _SettingsRow(
                          icon: Icons.logout,
                          iconColor: Colors.redAccent,
                          label: 'Cerrar sesión',
                          textColor: Colors.redAccent,
                          onTap: () => _confirmarCerrarSesion(context),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarCerrarSesion(BuildContext context) {
    final isContrast = ContrastMode.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isContrast ? Colors.white : const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cerrar sesión',
            style: TextStyle(color: isContrast ? const Color(0xFF111111) : Colors.white)),
        content: Text('¿Seguro que quieres cerrar sesión?',
            style: TextStyle(color: isContrast ? const Color(0xFF555555) : Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: TextStyle(color: isContrast ? const Color(0xFF555555) : Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
            },
            child: const Text('Cerrar sesión',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const _SectionLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  final Color bg;
  final Color border;
  const _SettingsCard({required this.child, required this.bg, required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color textColor;
  final VoidCallback onTap;
  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 15, color: textColor, fontWeight: FontWeight.w500)),
            ),
            Icon(Icons.chevron_right,
                color: textColor.withValues(alpha: 0.4), size: 20),
          ],
        ),
      ),
    );
  }
}

/// Fila especial con Switch para el modo contraste — se reconstruye sola.
class _ContrastToggleRow extends StatelessWidget {
  final bool isContrast;
  final Color textPrimary;
  final Color textSecondary;
  const _ContrastToggleRow({
    required this.isContrast,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isContrast ? Icons.brightness_7 : Icons.contrast,
              color: const Color(0xFF22C55E),
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Modo contraste',
                    style: TextStyle(
                        fontSize: 15,
                        color: textPrimary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('Fondo blanco, colores legibles',
                    style: TextStyle(fontSize: 12, color: textSecondary)),
              ],
            ),
          ),
          Switch(
            value: isContrast,
            onChanged: (_) => ContrastModeNotifier().toggle(),
            activeColor: const Color(0xFF22C55E),
          ),
        ],
      ),
    );
  }
}