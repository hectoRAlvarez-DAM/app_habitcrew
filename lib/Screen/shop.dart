import 'package:app_habitcrew/Widgets/bottomMenu.dart';
import 'package:flutter/material.dart';

class Shop extends StatelessWidget {
  const Shop({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text('Hello World!'),
        ),
        bottomNavigationBar: BottomMenu(currentIndex: 3),
      ),
    );
  }
}