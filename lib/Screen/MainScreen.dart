// main_screen.dart
import 'package:flutter/material.dart';
import 'package:app_habitcrew/Screen/home.dart';
import 'package:app_habitcrew/Screen/archievements_page.dart';
import 'package:app_habitcrew/Screen/create.dart';
import 'package:app_habitcrew/Screen/shop.dart';
import 'package:app_habitcrew/Screen/profile.dart';
import 'package:app_habitcrew/Widgets/bottomMenu.dart';
import 'package:app_habitcrew/servicios/coin_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const Home(),
    const AchievementsPage(),
    const Create(),
    const Shop(),
    const Profile(),
  ];

  @override
  void initState() {
    super.initState();
    // Cargar monedas del usuario desde Firestore al entrar
    CoinService.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Importante: No usamos la propiedad bottomNavigationBar aquí
      body: Stack(
        children: [
          // CAPA 1: LA PÁGINA ACTUAL
          // Usamos Positioned.fill para que la página ocupe TODA la pantalla, 
          // pasando por debajo del menú.
          Positioned.fill(
            child: _pages[_currentIndex],
          ),

          // CAPA 2: EL MENÚ FLOTANTE
          Align(
            alignment: Alignment.bottomCenter,
            child: BottomMenu(
              currentIndex: _currentIndex,
              onTabChange: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}