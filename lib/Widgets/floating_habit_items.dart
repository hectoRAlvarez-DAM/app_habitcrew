import 'package:flutter/material.dart';
import 'app_colors.dart';

class FloatingHabitItems extends StatefulWidget {
  final int count;
  
  const FloatingHabitItems({Key? key, this.count = 12}) : super(key: key);

  @override
  _FloatingHabitItemsState createState() => _FloatingHabitItemsState();
}

class _FloatingHabitItemsState extends State<FloatingHabitItems>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    // Crear animaciones para cada elemento
    for (int i = 0; i < widget.count; i++) {
      _animations.add(Tween<double>(
        begin: -50.0 + (i * 20.0),
        end: 50.0 - (i * 20.0),
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(i / widget.count, 1.0, curve: Curves.easeInOut),
        ),
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: List.generate(widget.count, (index) {
            return AnimatedBuilder(
              animation: _animations[index],
              builder: (context, child) {
                return Positioned(
                  left: _animations[index].value,
                  top: (MediaQuery.of(context).size.height / widget.count) * index,
                  child: Transform.rotate(
                    angle: _animations[index].value * 0.01,
                    child: Opacity(
                      opacity: 0.1 + (index * 0.05),
                      child: Container(
                        width: 30 + (index * 2.0),
                        height: 30 + (index * 2.0),
                        decoration: BoxDecoration(
                          color: AppColors.habitColors[index % AppColors.habitColors.length],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.habitColors[index % AppColors.habitColors.length]
                                  .withOpacity(0.3),
                              blurRadius: 10.0,
                              spreadRadius: 2.0,
                            ),
                          ],
                        ),
                        child: Icon(
                          _getIconForIndex(index),
                          color: Colors.white.withOpacity(0.8),
                          size: 16 + (index * 1.0),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }

  IconData _getIconForIndex(int index) {
    List<IconData> icons = [
      Icons.fitness_center,
      Icons.book,
      Icons.water_drop,
      Icons.self_improvement,
      Icons.alarm,
      Icons.eco,
      Icons.music_note,
      Icons.brush,
      Icons.code,
      Icons.lightbulb,
      Icons.local_dining,
      Icons.nights_stay,
    ];
    return icons[index % icons.length];
  }
}