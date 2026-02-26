import 'package:flutter/material.dart';
import 'dart:math';

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

    // Duración que coincide con el período de las ondas
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24), // Múltiplo de los períodos
    )..repeat();

    // Ondas con períodos específicos para que el loop sea perfecto
    ondas.addAll([
      OndaLuz(0, 2.0, 3.0, const Color(0xFF22C55E), 0.40, 0.0),  // período: 2π/2 = π
      OndaLuz(1, 3.0, 3.2, const Color(0xFF16A34A), 0.32, 0.2),  // período: 2π/3
      OndaLuz(2, 1.5, 2.8, const Color(0xFF4CAF50), 0.28, 0.4),  // período: 2π/1.5
      OndaLuz(3, 2.5, 3.3, const Color(0xFF22C55E), 0.26, 0.6),  // período: 2π/2.5
      OndaLuz(4, 1.8, 2.9, const Color(0xFF2E7D32), 0.24, 0.8),  // período: 2π/1.8
    ]);

    // Partículas con movimiento periódico
    for (int i = 0; i < 50; i++) {
      particulas.add(ParticulaLuz.aleatoria());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Fondo
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

        // Ondas + partículas con loop perfecto
        Positioned.fill(
          child: CustomPaint(
            painter: OndasLoopPerfectoPainter(
              ondas: ondas,
              particulas: particulas,
              animation: _controller,
            ),
          ),
        ),

        // Overlay
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

///////////////////////////////////////////////////////////////////////////
// MODELOS
///////////////////////////////////////////////////////////////////////////

class OndaLuz {
  final double offset;
  final double frecuencia; // Cambié velocidad por frecuencia
  final double grosor;
  final Color color;
  final double opacidad;
  final double fase;

  OndaLuz(
    this.offset,
    this.frecuencia,
    this.grosor,
    this.color,
    this.opacidad,
    this.fase,
  );
}

class ParticulaLuz {
  final double baseX, baseY;
  final double tamano;
  final double opacidad;
  final double faseX, faseY;
  final double frecuenciaX, frecuenciaY; // Cambié amp por frecuencia
  final double ampX, ampY;

  ParticulaLuz({
    required this.baseX,
    required this.baseY,
    required this.tamano,
    required this.opacidad,
    required this.faseX,
    required this.faseY,
    required this.frecuenciaX,
    required this.frecuenciaY,
    required this.ampX,
    required this.ampY,
  });

  factory ParticulaLuz.aleatoria() {
    final r = Random();
    return ParticulaLuz(
      baseX: r.nextDouble() * 400,
      baseY: r.nextDouble() * 800,
      tamano: 2 + r.nextDouble() * 6,
      opacidad: 0.2 + r.nextDouble() * 0.4,
      faseX: r.nextDouble() * 2 * pi,
      faseY: r.nextDouble() * 2 * pi,
      frecuenciaX: 0.5 + r.nextDouble(),  // Frecuencias aleatorias
      frecuenciaY: 0.5 + r.nextDouble(),
      ampX: 10 + r.nextDouble() * 20,
      ampY: 10 + r.nextDouble() * 20,
    );
  }

  Offset posicion(double t) {
    return Offset(
      baseX + sin(t * frecuenciaX + faseX) * ampX,
      baseY + cos(t * frecuenciaY + faseY) * ampY,
    );
  }
}

///////////////////////////////////////////////////////////////////////////
// PAINTER CON LOOP PERFECTO
///////////////////////////////////////////////////////////////////////////

class OndasLoopPerfectoPainter extends CustomPainter {
  final List<OndaLuz> ondas;
  final List<ParticulaLuz> particulas;
  final Animation<double> animation;

  OndasLoopPerfectoPainter({
    required this.ondas,
    required this.particulas,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    // t va de 0 a 2π en la duración de la animación
    final t = animation.value * 2 * pi;
    final centerY = size.height * 0.45;

    ///////////////////////////////
    // ONDAS CON LOOP PERFECTO
    ///////////////////////////////
    for (var onda in ondas) {
      // El tiempo es periódico: cuando t = 2π, volvemos al estado inicial
      final tiempo = t + onda.fase * pi;
      final yBase = centerY + (onda.offset - 2) * 40;

      final path = Path();
      
      // Para asegurar que el principio y final conecten perfectamente,
      // dibujamos la onda en un espacio que es múltiplo del período espacial
      double periodoEspacial = size.width * 0.8; // Período espacial de la onda
      
      for (double x = -50; x <= size.width + 50; x += 3) {
        // Usamos funciones que son periódicas tanto en espacio como en tiempo
        // Cuando t = 2π, sin(t) = sin(0) = 0, así que el estado es idéntico
        
        double wave = 0;
        
        // Componente 1: Período espacial = periodoEspacial
        // Período temporal = 2π/frecuencia
        wave += sin(x * 2 * pi / periodoEspacial - tiempo * onda.frecuencia) * 35;
        
        // Componente 2: Período espacial = periodoEspacial * 0.5
        wave += sin(x * 4 * pi / periodoEspacial + tiempo * onda.frecuencia * 0.7) * 25;
        
        // Componente 3: Período espacial = periodoEspacial * 1.3
        wave += cos(x * 2 * pi / (periodoEspacial * 1.3) - tiempo * onda.frecuencia * 0.5) * 15;
        
        // Aseguramos que la onda sea continua en los bordes
        // Multiplicamos por una ventana que es 1 en el centro y 0 en los bordes
        double ventana = 1.0;
        if (x < 0) {
          ventana = 1.0 - (x.abs() / 50);
        } else if (x > size.width) {
          ventana = 1.0 - ((x - size.width) / 50);
        }
        ventana = ventana.clamp(0.0, 1.0);
        
        double y = yBase + wave * ventana;

        if (x == -50) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      // Dibujamos la onda
      _drawWaveWithGlow(canvas, path, onda, t);
    }

    ///////////////////////////////
    // PARTÍCULAS CON LOOP PERFECTO
    ///////////////////////////////
    for (var p in particulas) {
      final pos = p.posicion(t);

      final core = Paint()
        ..color = const Color(0xFF22C55E).withOpacity(p.opacidad)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

      final mid = Paint()
        ..color = const Color(0xFF22C55E).withOpacity(p.opacidad * 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      final outer = Paint()
        ..color = const Color(0xFF22C55E).withOpacity(p.opacidad * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(pos, p.tamano * 0.6, core);
      canvas.drawCircle(pos, p.tamano * 1.4, mid);
      canvas.drawCircle(pos, p.tamano * 2.2, outer);
    }

    ///////////////////////////////
    // DESTELLOS PERIÓDICOS CON LOOP PERFECTO
    ///////////////////////////////
    // Cuando t = 2π, sin(3t) = sin(6π) = 0, igual que al inicio
    if (sin(t * 3) > 0.995) {
      final flash = Paint()
        ..color = const Color(0xFF22C55E).withOpacity(0.04)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.4),
        120,
        flash,
      );
    }
  }

  void _drawWaveWithGlow(Canvas canvas, Path path, OndaLuz onda, double t) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // La opacidad también puede ser periódica si queremos
    double opacidadBase = onda.opacidad;
    
    // Capa principal
    paint
      ..color = onda.color.withOpacity(opacidadBase)
      ..strokeWidth = onda.grosor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(path, paint);

    // Capas de glow
    paint
      ..color = onda.color.withOpacity(opacidadBase * 0.6)
      ..strokeWidth = onda.grosor * 1.8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, paint);

    paint
      ..color = onda.color.withOpacity(opacidadBase * 0.35)
      ..strokeWidth = onda.grosor * 3.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawPath(path, paint);

    paint
      ..color = onda.color.withOpacity(opacidadBase * 0.15)
      ..strokeWidth = onda.grosor * 5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}