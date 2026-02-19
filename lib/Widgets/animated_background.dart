// Widgets/animated_background.dart
import 'package:flutter/material.dart';
import 'dart:math';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  
  const AnimatedBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<OndaLuz> ondas = [];
  final List<ParticulaLuz> particulas = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Crear ondas de luz PS3 - horizontales en el centro
    ondas.addAll([
      OndaLuz(
        offset: 0,
        amplitud: 0,
        frecuencia: 0.0,
        velocidad: 0.25,
        grosor: 3.0,
        color: const Color(0xFF22C55E),
        opacidad: 0.4,
        delayFactor: 0.0,
      ),
      OndaLuz(
        offset: 1,
        amplitud: 0,
        frecuencia: 0.0,
        velocidad: 0.32,
        grosor: 3.2,
        color: const Color(0xFF16A34A),
        opacidad: 0.32,
        delayFactor: 0.12,
      ),
      OndaLuz(
        offset: 2,
        amplitud: 0,
        frecuencia: 0.0,
        velocidad: 0.18,
        grosor: 2.8,
        color: const Color(0xFF4CAF50),
        opacidad: 0.28,
        delayFactor: 0.24,
      ),
      OndaLuz(
        offset: 3,
        amplitud: 0,
        frecuencia: 0.0,
        velocidad: 0.28,
        grosor: 3.3,
        color: const Color(0xFF22C55E),
        opacidad: 0.26,
        delayFactor: 0.36,
      ),
      OndaLuz(
        offset: 4,
        amplitud: 0,
        frecuencia: 0.0,
        velocidad: 0.22,
        grosor: 2.9,
        color: const Color(0xFF2E7D32),
        opacidad: 0.24,
        delayFactor: 0.48,
      ),
    ]);

    // Crear partículas de luz (más visibles)
    for (int i = 0; i < 50; i++) {
      particulas.add(ParticulaLuz.aleatoria());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fondo negro profundo con tonos verdes sutiles
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black,
                const Color(0xFF041014), // verde-negro muy oscuro
                const Color(0xFF022318), // verde oscuro
                const Color(0xFF063B2A), // verde moderado
              ],
              stops: const [0.0, 0.3, 0.65, 1.0],
            ),
          ),
        ),
        
        // Capa de ondas y partículas
        Positioned.fill(
          child: CustomPaint(
            painter: OndasPS3Painter(
              ondas: ondas,
              particulas: particulas,
              animation: _controller,
            ),
          ),
        ),
        
        // Overlay muy sutil oscuro para integrar las ondas
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.15),
          ),
        ),
        
        // Contenido
        widget.child,
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class OndaLuz {
  final double offset;
  final double amplitud;
  final double frecuencia;
  final double velocidad;
  final double grosor;
  final Color color;
  final double opacidad;
  final double delayFactor;

  OndaLuz({
    required this.offset,
    required this.amplitud,
    required this.frecuencia,
    required this.velocidad,
    required this.grosor,
    required this.color,
    required this.opacidad,
    required this.delayFactor,
  });
}

class ParticulaLuz {
  double x, y;
  double tamano;
  double opacidad;
  double velocidadX;
  double velocidadY;

  ParticulaLuz({
    required this.x,
    required this.y,
    required this.tamano,
    required this.opacidad,
    required this.velocidadX,
    required this.velocidadY,
  });

  factory ParticulaLuz.aleatoria() {
    final random = Random();
    return ParticulaLuz(
      x: random.nextDouble() * 400,
      y: random.nextDouble() * 800,
      tamano: 2 + random.nextDouble() * 6, // Partículas más grandes
      opacidad: 0.2 + random.nextDouble() * 0.4, // Más opacas
      velocidadX: (random.nextDouble() - 0.5) * 0.3,
      velocidadY: (random.nextDouble() - 0.5) * 0.2,
    );
  }

  void mover(double delta, double screenWidth, double screenHeight) {
    x += velocidadX * delta * 30;
    y += velocidadY * delta * 30;

    if (x < 0) x = screenWidth;
    if (x > screenWidth) x = 0;
    if (y < 0) y = screenHeight;
    if (y > screenHeight) y = 0;
  }
}

class OndasPS3Painter extends CustomPainter {
  final List<OndaLuz> ondas;
  final List<ParticulaLuz> particulas;
  final Animation<double> animation;

  OndasPS3Painter({
    required this.ondas,
    required this.particulas,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height * 0.45;
    
    // Dibujar ondas horizontales con efecto infinito
    for (var onda in ondas) {
      final paint = Paint()
        ..color = onda.color.withOpacity(onda.opacidad)
        ..style = PaintingStyle.stroke
        ..strokeWidth = onda.grosor
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final double tiempo = (animation.value * 2 * pi + (onda.delayFactor * 2 * pi));
      final double yOffset = centerY + (onda.offset - 2) * 40;
      
      // Efecto de desplazamiento horizontal infinito
      final double horizontalShift = (tiempo * onda.velocidad * 200) % (size.width + 200);
      
      // Crear onda con desplazamiento infinito
      final path = Path();
      double prevY = 0;
      
      for (double x = -200; x <= size.width + 200; x += 2) {
        // Componentes de onda para movimiento orgánico
        double wave1 = sin((x * 0.012) - tiempo * 0.5) * 42;
        double wave2 = sin((x * 0.008 + tiempo * 0.25)) * 28;
        double wave3 = cos((x * 0.005 - tiempo * 0.35)) * 18;
        
        // Aplicar el desplazamiento infinito
        double xShifted = (x - horizontalShift);
        while (xShifted > size.width) xShifted -= (size.width + 200);
        while (xShifted < -200) xShifted += (size.width + 200);
        
        double y = yOffset + wave1 + wave2 + wave3;
        
        if (x == -200) {
          path.moveTo(xShifted, y);
        } else {
          // Interpolación suave entre puntos
          path.quadraticBezierTo(xShifted - 1, (prevY + y) / 2, xShifted, y);
        }
        prevY = y;
      }

      // Primera capa principal con blur
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawPath(path, paint);

      // Segunda capa más gruesa y difusa
      paint
        ..color = onda.color.withOpacity(onda.opacidad * 0.6)
        ..strokeWidth = onda.grosor * 1.8
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(path, paint);

      // Tercera capa muy suave para efecto glow
      paint
        ..color = onda.color.withOpacity(onda.opacidad * 0.35)
        ..strokeWidth = onda.grosor * 3.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
      canvas.drawPath(path, paint);

      // Cuarta capa ultra suave
      paint
        ..color = onda.color.withOpacity(onda.opacidad * 0.15)
        ..strokeWidth = onda.grosor * 5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
      canvas.drawPath(path, paint);
    }

    // Dibujar partículas con movimiento más natural
    for (var particula in particulas) {
      particula.mover(animation.value, size.width, size.height);
      
      // Centro de la partícula
      final paintCore = Paint()
        ..color = const Color(0xFF22C55E).withOpacity(particula.opacidad)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
      canvas.drawCircle(
        Offset(particula.x, particula.y),
        particula.tamano * 0.6,
        paintCore,
      );

      // Glow intermedio
      final paintMid = Paint()
        ..color = const Color(0xFF22C55E).withOpacity(particula.opacidad * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(
        Offset(particula.x, particula.y),
        particula.tamano * 1.4,
        paintMid,
      );

      // Glow exterior
      final paintOuter = Paint()
        ..color = const Color(0xFF22C55E).withOpacity(particula.opacidad * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(
        Offset(particula.x, particula.y),
        particula.tamano * 2.2,
        paintOuter,
      );
    }

    // Destellos ocasionales muy sutiles
    final random = Random((animation.value * 100).toInt());
    if (random.nextDouble() > 0.96) {
      final flashPaint = Paint()
        ..color = const Color(0xFF22C55E).withOpacity(0.04)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
      
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        60 + random.nextDouble() * 120,
        flashPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}