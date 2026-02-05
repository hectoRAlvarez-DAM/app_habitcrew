import 'package:app_habitcrew/Widgets/bottomMenu.dart';
import 'package:flutter/material.dart';

class Create extends StatelessWidget {
  const Create({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text('Hello World!'),
        ),
        bottomNavigationBar: BottomMenu(currentIndex: 2),
      ),
    );
  }
}