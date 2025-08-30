import 'package:flutter/material.dart';
import 'package:phonkers/firebase_auth_service/auth_state_manager.dart';
import 'package:phonkers/view/pages/auth_page.dart';
import 'package:phonkers/view/pages/main_page.dart';
import 'package:phonkers/view/pages/welcome_info_page.dart';
import 'package:phonkers/view/pages/welcome_page.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phonkers',
      debugShowCheckedModeBanner: false,
      routes: {
        '/main': (context) => MainPage(),
        '/welcome': (context) => const WelcomePage(),
        '/welcome-info': (context) => const WelcomeInfoPage(),
        '/auth': (context) => const AuthPage(),
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const AuthStateManager(),
    );
  }
}
