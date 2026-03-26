import 'package:app_habitcrew/Screen/MainScreen.dart';
import 'package:app_habitcrew/Screen/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';

class Pantallacarrega extends StatefulWidget {
  const Pantallacarrega({super.key});

  @override
  State<Pantallacarrega> createState() => _PantallacarregaState();
}

class _PantallacarregaState extends State<Pantallacarrega> {
  
  @override
  void initState() {
    super.initState();
    
    Future.delayed(const Duration(seconds: 4), () {
      // Verificar si hay un usuario logueado
      User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (mounted) {
        if (currentUser != null) {
          // Usuario logueado, ir a MainScreen
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        } else {
          // No hay usuario logueado, ir a LoginScreen
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animación con tonos de verde más suaves
            PlayAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 3),
              curve: Curves.easeInOut,
              builder: (context, value, child) {
                return Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.3 + (value * 0.7),
                      colors: [
                        // Tonos de verde mucho más suaves con opacidades reducidas
                        Colors.green.withOpacity(0.25 * value),  // Muy sutil
                        Colors.green.withOpacity(0.15 * value),
                        Colors.green.withOpacity(0.05 * value),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 0.7, 1.0],
                    ),
                  ),
                  child: Opacity(
                    opacity: value,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/habitCrewCargaNBG.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.image, size: 50, color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
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