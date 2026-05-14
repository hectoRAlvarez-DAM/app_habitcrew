// Widgets/glassmorphism_card.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:app_habitcrew/Widgets/contrast_mode.dart';

class GlassmorphismCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  const GlassmorphismCard({
    Key? key,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isContrast = ContrastMode.of(context);

    if (isContrast) {
      // Modo contraste: tarjeta blanca limpia, sin blur ni sombra oscura
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color ?? Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFDDDDDD)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      );
    }

    // Modo normal: glassmorphism original
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF22C55E).withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.white.withValues(alpha: 0.02),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class GlassmorphismSection extends StatelessWidget {
  final String titulo;
  final Widget contenido;
  final VoidCallback? onVerTodos;

  const GlassmorphismSection({
    Key? key,
    required this.titulo,
    required this.contenido,
    this.onVerTodos,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isContrast = ContrastMode.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isContrast
                      ? const Color(0xFF111111)
                      : const Color(0xFFE6F7EA),
                ),
              ),
              if (onVerTodos != null)
                TextButton(
                  onPressed: onVerTodos,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF22C55E),
                  ),
                  child: const Text('Ver todos'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: contenido,
        ),
      ],
    );
  }
}