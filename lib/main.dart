import 'package:app_habitcrew/Screen/archievements_page.dart';
import 'package:app_habitcrew/Screen/home.dart';
import 'package:app_habitcrew/Screen/pantallaCarrega.dart';
import 'package:flutter/material.dart';
import 'Screen/login_screen.dart';
import 'Screen/profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      home: const LoginScreen(),
    );
  }
}