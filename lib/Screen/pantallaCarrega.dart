import 'package:app_habitcrew/Screen/MainScreen.dart';
import 'package:flutter/material.dart';

class Pantallacarrega extends StatefulWidget {
  const Pantallacarrega({super.key});

  @override
  State<Pantallacarrega> createState() => _PantallacarregaState();
}

class _PantallacarregaState extends State<Pantallacarrega> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<Offset> _positionAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _positionAnimation = Tween<Offset>(
      begin: const Offset(0.0, -2.0),
      end: const Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.bounceOut,
    ));
    
    _controller.forward();
    
    
    Future.delayed(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context, 
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SlideTransition(
              position: _positionAnimation,
              child: Container(
                width: 400,
                height: 400,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.transparent,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/habitCrewCarga.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                      const Icon(Icons.image, size: 50),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Cargando...',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
