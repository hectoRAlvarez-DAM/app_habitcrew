import 'package:app_habitcrew/Screen/archievements_page.dart';
import 'package:app_habitcrew/Screen/home.dart';
import 'package:flutter/material.dart';
import 'Screen/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      home: const AchievementsPage(),
    );
  }
}