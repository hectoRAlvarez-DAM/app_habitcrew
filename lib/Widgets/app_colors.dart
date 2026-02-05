import 'package:flutter/material.dart';

class AppColors {
  // Colores principales inspirados en Duolingo
  static const Color primary = Color(0xFF58CC02); // Verde Duolingo
  static const Color primaryLight = Color(0xFF7CFF33);
  static const Color primaryDark = Color(0xFF1CB0F6); // Azul para degradados
  
  // Colores de acento
  static const Color accentGreen = Color(0xFF5BCE00);
  static const Color accentBlue = Color(0xFF1CB0F6);
  static const Color accentPurple = Color(0xFF9C5BFF);
  static const Color accentOrange = Color(0xFFFF9500);
  static const Color accentPink = Color(0xFFFF69B4);
  static const Color accentYellow = Color(0xFFFFD166);
  
  // Colores de fondo
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF7F9FC);
  static const Color backgroundGrey = Color(0xFFF2F2F7);
  
  // Colores de texto
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF4A4A4A);
  static const Color textLight = Color(0xFF8E8E93);
  static const Color textWhite = Color(0xFFFFFFFF);
  
  // Colores de elementos UI
  static const Color border = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x20000000);
  static const Color error = Color(0xFFFF3B30);
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  
  // Colores para hábitos
  static const List<Color> habitColors = [
    Color(0xFFFF6B6B), // Rojo
    Color(0xFF4ECDC4), // Turquesa
    Color(0xFFFFD166), // Amarillo
    Color(0xFF06D6A0), // Verde
    Color(0xFF118AB2), // Azul
    Color(0xFF9D4EDD), // Púrpura
    Color(0xFFFF9A76), // Naranja
    Color(0xFFFF69B4), // Rosa
  ];
  
  // Degradados
  static LinearGradient get primaryGradient => LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get buttonGradient => LinearGradient(
    colors: [accentGreen, primary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  static LinearGradient get colorfulGradient => LinearGradient(
    colors: [accentGreen, accentBlue, accentPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // AÑADE ESTE GRADIENTE QUE FALTA:
  static LinearGradient get purpleBlueGradient => LinearGradient(
    colors: [accentPurple, accentBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get backgroundGradient => LinearGradient(
    colors: [
      Color(0xFFF7F9FC).withOpacity(0.8),
      Color(0xFFE3F2FD).withOpacity(0.6),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static LinearGradient get cardGradient => LinearGradient(
    colors: [
      Colors.white.withOpacity(0.9),
      Colors.white.withOpacity(0.7),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get accentButtonGradient => LinearGradient(
    colors: [accentPurple, accentBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: shadow,
      blurRadius: 20.0,
      spreadRadius: 0.0,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: primary.withOpacity(0.3),
      blurRadius: 15.0,
      spreadRadius: 2.0,
      offset: const Offset(0, 5),
    ),
  ];
}