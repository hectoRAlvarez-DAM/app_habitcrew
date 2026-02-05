import 'package:flutter/material.dart';
import 'app_colors.dart';

class ColorDotsDecorator extends StatelessWidget {
  final int count;
  final double dotSize;
  final double spacing;
  
  const ColorDotsDecorator({
    Key? key,
    this.count = 8,
    this.dotSize = 12.0,
    this.spacing = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing / 2,
      alignment: WrapAlignment.center,
      children: List.generate(
        count,
        (index) => Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            color: AppColors.habitColors[index % AppColors.habitColors.length],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.habitColors[index % AppColors.habitColors.length]
                    .withOpacity(0.4),
                blurRadius: 4.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}