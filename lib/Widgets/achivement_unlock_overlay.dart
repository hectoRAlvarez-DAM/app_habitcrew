import 'dart:math';
import 'package:app_habitcrew/Screen/models/archievement.dart';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../widgets/animated_background.dart';

class AchievementUnlockOverlay {
  static OverlayEntry? _overlayEntry;

  static void show(BuildContext context, Achievement achievement) {
    _overlayEntry?.remove();

    late ConfettiController confettiLeft;
    late ConfettiController confettiRight;

    confettiLeft =
        ConfettiController(duration: const Duration(seconds: 4));
    confettiRight =
        ConfettiController(duration: const Duration(seconds: 4));

    _overlayEntry = OverlayEntry(
      builder: (context) => _AchievementOverlayContent(
        achievement: achievement,
        confettiLeft: confettiLeft,
        confettiRight: confettiRight,
        onClose: () {
          confettiLeft.stop();
          confettiRight.stop();
          _overlayEntry?.remove();
          _overlayEntry = null;
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    Future.delayed(const Duration(milliseconds: 200), () {
      confettiLeft.play();
      confettiRight.play();
    });
  }
}

class _AchievementOverlayContent extends StatefulWidget {
  final Achievement achievement;
  final ConfettiController confettiLeft;
  final ConfettiController confettiRight;
  final VoidCallback onClose;

  const _AchievementOverlayContent({
    required this.achievement,
    required this.confettiLeft,
    required this.confettiRight,
    required this.onClose,
  });

  @override
  State<_AchievementOverlayContent> createState() =>
      _AchievementOverlayContentState();
}

class _AchievementOverlayContentState
    extends State<_AchievementOverlayContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _iconController;
  late Animation<double> _iconScale;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _iconScale = CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeIn,
    );
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _iconController.forward();
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [

        // ─── AnimatedBackground como fondo ──────────────────────
        FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: widget.onClose,
            child: AnimatedBackground(
              child: Container(
                color: Colors.black.withOpacity(0.45),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),

        // ─── Confetti IZQUIERDO ──────────────────────────────────
        Align(
          alignment: Alignment.topLeft,
          child: ConfettiWidget(
            confettiController: widget.confettiLeft,
            blastDirection: 0.5,
            numberOfParticles: 25,
            gravity: 0.2,
            emissionFrequency: 0.05,
            maxBlastForce: 25,
            minBlastForce: 10,
            colors: const [
              Color(0xFF22C55E),
              Colors.amber,
              Colors.white,
              Colors.lightGreen,
              Colors.teal,
              Colors.greenAccent,
            ],
            shouldLoop: false,
          ),
        ),

        // ─── Confetti DERECHO ────────────────────────────────────
        Align(
          alignment: Alignment.topRight,
          child: ConfettiWidget(
            confettiController: widget.confettiRight,
            blastDirection: pi - 0.5,
            numberOfParticles: 25,
            gravity: 0.2,
            emissionFrequency: 0.05,
            maxBlastForce: 25,
            minBlastForce: 10,
            colors: const [
              Color(0xFF22C55E),
              Colors.amber,
              Colors.white,
              Colors.lightGreen,
              Colors.teal,
              Colors.greenAccent,
            ],
            shouldLoop: false,
          ),
        ),

        // ─── Card del logro ──────────────────────────────────────
        Center(
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _iconController,
              curve: Curves.easeOutBack,
            )),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF22C55E),
                        const Color(0xFF16A34A),
                        const Color(0xFF4CAF50),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF22C55E).withOpacity(0.4),
                        blurRadius: 25,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF041014),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        // ─── Ícono animado ──────────────────────
                        ScaleTransition(
                          scale: _iconScale,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF22C55E),
                                  Color(0xFF16A34A),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF22C55E)
                                      .withOpacity(0.5),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.achievement.icon,
                              color: Colors.white,
                              size: 44,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ─── Etiqueta ───────────────────────────
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF22C55E).withOpacity(0.3),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_open,
                                  color: Color(0xFF22C55E), size: 14),
                              SizedBox(width: 6),
                              Text(
                                '¡Logro desbloqueado!',
                                style: TextStyle(
                                  color: Color(0xFF22C55E),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ─── Título ─────────────────────────────
                        Text(
                          widget.achievement.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // ─── Descripción ────────────────────────
                        Text(
                          widget.achievement.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ─── Botón cerrar ───────────────────────
                        SizedBox(
                          width: double.infinity,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF22C55E),
                                  Color(0xFF16A34A),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF22C55E)
                                      .withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: widget.onClose,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                '¡Genial!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
