import 'package:app_habitcrew/Screen/MainScreen.dart';
import 'package:app_habitcrew/Widgets/contrast_mode.dart';
import 'package:flutter/material.dart';
import 'Screen/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ContrastMode(
      notifier: ContrastModeNotifier(),
      child: AnimatedBuilder(
        animation: ContrastModeNotifier(),
        builder: (context, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.hasData) return const MainScreen();
                return const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}