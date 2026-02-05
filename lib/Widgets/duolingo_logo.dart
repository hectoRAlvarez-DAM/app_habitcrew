import 'package:flutter/material.dart';
import 'app_colors.dart';

class DuolingoLogo extends StatelessWidget {
  final double size;
  final bool withText;

  const DuolingoLogo({
    Key? key,
    this.size = 100.0,
    this.withText = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo circular con gradiente
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: AppColors.colorfulGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 20.0,
                spreadRadius: 3.0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.check_circle_rounded,
              size: size * 0.5,
              color: Colors.white,
            ),
          ),
        ),
        
        if (withText) ...[
          const SizedBox(height: 20.0),
          // Nombre de la app con estilo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: AppColors.purpleBlueGradient,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentPurple.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'HABIT',
                  style: TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'CREW',
                  style: TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accentGreen,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2,
                        offset: const Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12.0),
          Text(
            'Construye hábitos increíbles',
            style: TextStyle(
              fontSize: 16.0,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}