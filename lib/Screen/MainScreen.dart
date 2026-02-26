// main_screen.dart
import 'package:flutter/material.dart';
import 'package:app_habitcrew/Screen/home.dart';
import 'package:app_habitcrew/Screen/quests.dart';
import 'package:app_habitcrew/Screen/create.dart';
import 'package:app_habitcrew/Screen/shop.dart';
import 'package:app_habitcrew/Screen/profile.dart';
import 'package:app_habitcrew/Widgets/bottomMenu.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Lista de las pantallas (SIN SCAFFOLD)
  final List<Widget> _pages = [
    const Home(),
    const Quests(),
    const Create(),
    const Shop(),
    const Profile(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],  // ← Aquí se muestra la pantalla actual
      bottomNavigationBar: BottomMenu(
        currentIndex: _currentIndex,
        onTabChange: (index) {
          setState(() {
            _currentIndex = index;  // ← Cambia el índice y se actualiza la pantalla
          });
        },
      ),
    );
  }
}