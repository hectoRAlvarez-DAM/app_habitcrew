import 'package:flutter/material.dart';
import 'dart:math';
import 'package:app_habitcrew/Widgets/contrast_mode.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
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
      duration: const Duration(seconds: 24),
    )..repeat();

    ondas.addAll([
      OndaLuz(0, 2.0, 3.0, const Color(0xFF22C55E), 0.40, 0.0),
      OndaLuz(1, 3.0, 3.2, const Color(0xFF16A34A), 0.32, 0.2),
      OndaLuz(2, 1.5, 2.8, const Color(0xFF4CAF50), 0.28, 0.4),
      OndaLuz(3, 2.5, 3.3, const Color(0xFF22C55E), 0.26, 0.6),
      OndaLuz(4, 1.8, 2.9, const Color(0xFF2E7D32), 0.24, 0.8),
    ]);

    for (int i = 0; i < 50; i++) {
      particulas.add(ParticulaLuz.aleatoria());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isContrast = ContrastMode.of(context);

    if (isContrast) {
      return Container(
        color: Colors.white,
        child: widget.child,
      );
    }

    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black,
                Color(0xFF041014),
                Color(0xFF022318),
                Color(0xFF063B2A),
              ],
              stops: [0.0, 0.3, 0.65, 1.0],
            ),
          ),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: OndasLoopPerfectoPainter(
              ondas: ondas,
              particulas: particulas,
              animation: _controller,
            ),
          ),
        ),
        Positioned.fill(
          child: Container(color: Colors.black.withOpacity(0.15)),
        ),
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
  final double frecuencia;
  final double grosor;
  final Color color;
  final double opacidad;
  final double fase;

  OndaLuz(this.offset, this.frecuencia, this.grosor, this.color, this.opacidad, this.fase);
}

class ParticulaLuz {
  final double baseX, baseY, tamano, opacidad, faseX, faseY, frecuenciaX, frecuenciaY, ampX, ampY;

  ParticulaLuz({
    required this.baseX, required this.baseY, required this.tamano,
    required this.opacidad, required this.faseX, required this.faseY,
    required this.frecuenciaX, required this.frecuenciaY,
    required this.ampX, required this.ampY,
  });

  factory ParticulaLuz.aleatoria() {
    final r = Random();
    return ParticulaLuz(
      baseX: r.nextDouble() * 400, baseY: r.nextDouble() * 800,
      tamano: 2 + r.nextDouble() * 6, opacidad: 0.2 + r.nextDouble() * 0.4,
      faseX: r.nextDouble() * 2 * pi, faseY: r.nextDouble() * 2 * pi,
      frecuenciaX: 0.5 + r.nextDouble(), frecuenciaY: 0.5 + r.nextDouble(),
      ampX: 10 + r.nextDouble() * 20, ampY: 10 + r.nextDouble() * 20,
    );
  }

  Offset posicion(double t) => Offset(
    baseX + sin(t * frecuenciaX + faseX) * ampX,
    baseY + cos(t * frecuenciaY + faseY) * ampY,
  );
}

class OndasLoopPerfectoPainter extends CustomPainter {
  final List<OndaLuz> ondas;
  final List<ParticulaLuz> particulas;
  final Animation<double> animation;

  OndasLoopPerfectoPainter({required this.ondas, required this.particulas, required this.animation})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value * 2 * pi;
    final centerY = size.height * 0.45;

    for (var onda in ondas) {
      final tiempo = t + onda.fase * pi;
      final yBase = centerY + (onda.offset - 2) * 40;
      final path = Path();
      double periodoEspacial = size.width * 0.8;

      for (double x = -50; x <= size.width + 50; x += 3) {
        double wave = 0;
        wave += sin(x * 2 * pi / periodoEspacial - tiempo * onda.frecuencia) * 35;
        wave += sin(x * 4 * pi / periodoEspacial + tiempo * onda.frecuencia * 0.7) * 25;
        wave += cos(x * 2 * pi / (periodoEspacial * 1.3) - tiempo * onda.frecuencia * 0.5) * 15;
        double ventana = (x < 0) ? 1.0 - (x.abs() / 50) : (x > size.width ? 1.0 - ((x - size.width) / 50) : 1.0);
        ventana = ventana.clamp(0.0, 1.0);
        double y = yBase + wave * ventana;
        if (x == -50) path.moveTo(x, y); else path.lineTo(x, y);
      }
      _drawWaveWithGlow(canvas, path, onda);
    }

    for (var p in particulas) {
      final pos = p.posicion(t);
      canvas.drawCircle(pos, p.tamano * 0.6, Paint()..color = const Color(0xFF22C55E).withOpacity(p.opacidad)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1));
      canvas.drawCircle(pos, p.tamano * 1.4, Paint()..color = const Color(0xFF22C55E).withOpacity(p.opacidad * 0.6)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawCircle(pos, p.tamano * 2.2, Paint()..color = const Color(0xFF22C55E).withOpacity(p.opacidad * 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }

    if (sin(t * 3) > 0.995) {
      canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.4), 120,
          Paint()..color = const Color(0xFF22C55E).withOpacity(0.04)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30));
    }
  }

  void _drawWaveWithGlow(Canvas canvas, Path path, OndaLuz onda) {
    final paint = Paint()..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    paint..color = onda.color.withOpacity(onda.opacidad)..strokeWidth = onda.grosor..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(path, paint);
    paint..color = onda.color.withOpacity(onda.opacidad * 0.6)..strokeWidth = onda.grosor * 1.8..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, paint);
    paint..color = onda.color.withOpacity(onda.opacidad * 0.35)..strokeWidth = onda.grosor * 3.5..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawPath(path, paint);
    paint..color = onda.color.withOpacity(onda.opacidad * 0.15)..strokeWidth = onda.grosor * 5..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}