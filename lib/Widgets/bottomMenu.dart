import 'package:flutter/material.dart';
import 'dart:math' as math;

// CLIPPER PARA LOS ARCOS (Forma de montaña redondeada)
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
    {'icon': Icons.home_filled, 'label': 'INICIO'},
    {'icon': Icons.emoji_events, 'label': 'LOGROS'},
    {'icon': Icons.add_circle_outline, 'label': 'CREAR'},
    {'icon': Icons.shopping_bag_outlined, 'label': 'TIENDA'},
    {'icon': Icons.person_outline, 'label': 'PERFILS'},
  ];

  // FÓRMULA BEZIER CÚBICA (Sincroniza iconos y línea con el fondo)
  double _getBezierY(double t, double side, double peak) {
    return math.pow(1 - t, 3) * side + 
           3 * math.pow(1 - t, 2) * t * peak + 
           3 * (1 - t) * math.pow(t, 2) * peak + 
           math.pow(t, 3) * side;
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double screenWidth = MediaQuery.of(context).size.width;
    
    const double visualHeight = 85.0; 
    const double blackSectionHeight = 22.0; 
    const double curveIntensity = 16.0; 
    final double totalHeight = visualHeight + bottomPadding;

    double blackSideY = visualHeight - blackSectionHeight;
    double blackPeakY = blackSideY - curveIntensity;

    double itemWidth = screenWidth / _menuItems.length;
    double lineX = (currentIndex * itemWidth) + (itemWidth / 2) - 16;
    double t = currentIndex / (_menuItems.length - 1);
    
    // Posición Y de la línea blanca
    double lineY = _getBezierY(t, blackSideY, blackPeakY) - 8.0;

    return Container(
      height: totalHeight,
      // IMPORTANTE: Color transparente para que no salga el cuadro blanco arriba
      color: Colors.transparent, 
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // CAPA 0: FONDO GRIS (ARCO SUPERIOR)
          ClipPath(
            clipper: PsArcClipper(sideHeight: curveIntensity, peakHeight: 0),
            child: Container(
              height: totalHeight,
              width: double.infinity,
              color: const Color(0xFF222222).withOpacity(0.9),
            ),
          ),

          // CAPA 1: FONDO NEGRO (ARCO INFERIOR)
          ClipPath(
            clipper: PsArcClipper(
              sideHeight: blackSideY, 
              peakHeight: blackPeakY,
            ),
            child: Container(
              height: totalHeight,
              width: double.infinity,
              color: const Color(0xFF050505),
            ),
          ),

          // CAPA 2: LÍNEA BLANCA INDICADORA
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            left: lineX,
            top: lineY, 
            child: Container(
              width: 32,
              height: 2.2,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.white.withOpacity(0.6), blurRadius: 6),
                ],
              ),
            ),
          ),

          // CAPA 3: ICONOS (CON CLIC Y POSICIÓN ELEVADA)
          Positioned(
            top: 5, 
            left: 0,
            right: 0,
            child: Row(
              children: List.generate(_menuItems.length, (index) {
                final bool isActive = currentIndex == index;
                double tIcon = index / (_menuItems.length - 1);
                double vOffset = _getBezierY(tIcon, curveIntensity, 0);

                return Expanded(
                  child: Transform.translate(
                    // Elevamos los iconos: vOffset - 10
                    offset: Offset(0, vOffset - 10), 
                    child: GestureDetector(
                      onTap: () => onTabChange(index),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        height: 55, 
                        alignment: Alignment.center,
                        color: Colors.transparent, 
                        child: Icon(
                          _menuItems[index]['icon'],
                          color: isActive ? Colors.white : Colors.white24,
                          size: 26, 
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // CAPA 4: TEXTO DINÁMICO
          Positioned(
            bottom: bottomPadding + 3,
            left: 0,
            right: 0,
            height: blackSectionHeight,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _menuItems[currentIndex]['label'],
                  key: ValueKey(currentIndex),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}