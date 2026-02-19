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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accentGreen, AppColors.accentBlue, AppColors.accentPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
    );
  }
}