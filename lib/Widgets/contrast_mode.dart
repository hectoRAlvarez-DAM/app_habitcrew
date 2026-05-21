import 'package:flutter/material.dart';

/// Notifier global para el modo contraste.
/// No requiere shared_preferences — el estado vive en memoria durante la sesión.
class ContrastModeNotifier extends ChangeNotifier {
  static final ContrastModeNotifier _instance = ContrastModeNotifier._internal();
  factory ContrastModeNotifier() => _instance;
  ContrastModeNotifier._internal();

  bool _isContrast = false;
  bool get isContrast => _isContrast;

  void toggle() {
    _isContrast = !_isContrast;
    notifyListeners();
  }
}

/// InheritedNotifier que propaga el modo contraste por el árbol de widgets.
/// Uso: ContrastMode.of(context) → true/false
class ContrastMode extends InheritedNotifier<ContrastModeNotifier> {
  const ContrastMode({
    Key? key,
    required ContrastModeNotifier notifier,
    required Widget child,
  }) : super(key: key, notifier: notifier, child: child);

  static bool of(BuildContext context) {
    final c = context.dependOnInheritedWidgetOfExactType<ContrastMode>();
    return c?.notifier?.isContrast ?? false;
  }
}
