import 'package:flutter/material.dart';
import 'dart:math' as math;

class PsArcClipper extends CustomClipper<Path> {
  final double sideHeight; 
  final double peakHeight; 

  PsArcClipper({required this.sideHeight, required this.peakHeight});

  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, sideHeight);
    path.cubicTo(
      size.width * 0.35, peakHeight, 
      size.width * 0.65, peakHeight, 
      size.width, sideHeight,        
    );
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

class BottomMenu extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChange;

  const BottomMenu({
    super.key,
    required this.currentIndex,
    required this.onTabChange,
  });

  final List<Map<String, dynamic>> _menuItems = const [
    {'icon': Icons.home_filled, 'label': 'HOME'},
    {'icon': Icons.emoji_events, 'label': 'QUEST'},
    {'icon': Icons.add_circle_outline, 'label': 'CREATE'},
    {'icon': Icons.shopping_bag_outlined, 'label': 'SHOP'},
    {'icon': Icons.person_outline, 'label': 'PROFILE'},
  ];

  // --- CURVA MENOS PRONUNCIADA ---
  double _getCurveOffset(double t, double intensity) {
    // Reducimos el factor de 4.0 a 3.2 para que la curva sea más plana y encaje con el CubicTo
    return 3.2 * intensity * math.pow(t - 0.5, 2);
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    
    // CONFIGURACIÓN SOLICITADA
    const double visualHeight = 85.0; 
    const double blackSectionHeight = 15.0; 
    const double curveIntensity = 20.0; 
    
    final double totalHeight = visualHeight + bottomPadding;

    return Container(
      height: totalHeight, 
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none, 
        children: [
          // FONDO GRIS
          ClipPath(
            clipper: PsArcClipper(
              sideHeight: curveIntensity, 
              peakHeight: 0,             
            ),
            child: Container(
              height: totalHeight,
              width: double.infinity,
              color: const Color(0xFF222222),
            ),
          ),

          // FONDO NEGRO
          ClipPath(
            clipper: PsArcClipper(
              sideHeight: (totalHeight - (blackSectionHeight + bottomPadding)), 
              peakHeight: (totalHeight - (blackSectionHeight + bottomPadding) - curveIntensity),
            ),
            child: Container(
              height: totalHeight,
              width: double.infinity,
              color: const Color(0xFF050505),
            ),
          ),

          // CONTENIDO
          SizedBox(
            height: totalHeight,
            child: Stack(
              children: [
                // ICONOS
                Positioned(
                  top: 22, // Subido un poco para centrar mejor en el gris
                  left: 0,
                  right: 0,
                  child: Row(
                    children: List.generate(_menuItems.length, (index) {
                      final bool isActive = currentIndex == index;
                      double t = index / (_menuItems.length - 1);
                      // Usamos un 80% de la intensidad para que la curva sea más suave que el borde
                      double vOffset = _getCurveOffset(t, curveIntensity * 0.8);

                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onTabChange(index),
                          child: Transform.translate(
                            offset: Offset(0, vOffset),
                            child: Icon(
                              _menuItems[index]['icon'],
                              color: isActive ? Colors.white : Colors.white24,
                              size: 24,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // LÍNEA INDICADORA
                AnimatedAlign(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment(
                    (currentIndex / (_menuItems.length - 1)) * 2 - 1,
                    0, 
                  ),
                  child: FractionallySizedBox(
                    widthFactor: 1 / _menuItems.length,
                    child: Builder(
                      builder: (context) {
                        double t = currentIndex / (_menuItems.length - 1);
                        double lineVOffset = _getCurveOffset(t, curveIntensity * 0.8);

                        return Transform.translate(
                          // Ajustado el offset base para que la línea no quede hundida
                          offset: Offset(0, (visualHeight - blackSectionHeight - 16) + lineVOffset),
                          child: Center(
                            child: Container(
                              width: 32,
                              height: 2,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }
                    ),
                  ),
                ),

                // TEXTO
                Positioned(
                  bottom: bottomPadding + 2, // Ajuste sutil para que el texto no toque el borde
                  left: 0,
                  right: 0,
                  height: blackSectionHeight,
                  child: Center(
                    child: Text(
                      _menuItems[currentIndex]['label'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
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
}