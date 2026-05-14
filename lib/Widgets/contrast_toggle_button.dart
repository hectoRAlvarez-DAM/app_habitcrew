import 'package:flutter/material.dart';
import 'contrast_mode.dart';

/// Botón flotante/icono para cambiar entre modo normal y modo contraste.
/// Úsalo en cualquier AppBar o pantalla:
///   ContrastToggleButton()
class ContrastToggleButton extends StatelessWidget {
  const ContrastToggleButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isContrast = ContrastMode.of(context);
    return IconButton(
      tooltip: isContrast ? 'Modo normal' : 'Modo contraste',
      onPressed: () => ContrastModeNotifier().toggle(),
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: Icon(
          isContrast ? Icons.brightness_7 : Icons.contrast,
          key: ValueKey(isContrast),
          color: isContrast ? const Color(0xFF22C55E) : Colors.white70,
          size: 22,
        ),
      ),
    );
  }
}