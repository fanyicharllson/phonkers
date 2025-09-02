import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phonkers/firebase_auth_service/auth_service.dart';
import 'package:phonkers/view/pages/auth_page.dart';
import 'package:phonkers/view/pages/email_check_page.dart';
import 'package:phonkers/view/pages/main_page.dart';
import 'package:phonkers/view/pages/welcome_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStateManager extends StatefulWidget {
  const AuthStateManager({super.key});

  @override
  State<AuthStateManager> createState() => _AuthStateManagerState();
}

class _AuthStateManagerState extends State<AuthStateManager> {
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    // Show loading for at least 3 second, then allow auth stream
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const LoadingScreen();
    }

    return StreamBuilder<User?>(
      stream: authService.value.authStateChanges,
      builder: (context, snapshot) {
        // Still loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          print("Currently showing loading...");
          return const LoadingScreen();
        }

        // No user signed in
        if (snapshot.data == null) {
          return FutureBuilder<bool>(
            future: _isFirstTime(),
            builder: (context, firstTimeSnapshot) {
              if (firstTimeSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const LoadingScreen();
              }

              // First time user - show welcome flow
              if (firstTimeSnapshot.data == true) {
                return const WelcomePage();
              } else {
                // Returning user without account - show auth
                return const AuthPage();
              }
            },
          );
        }

        // User signed in - check email verification
        User user = snapshot.data!;
        if (!user.emailVerified) {
          return EmailCheckPage(email: user.email ?? '');
        }

        // User signed in and verified - go to main app
        return const MainPage(); // Your main phonk app screen
      },
    );
  }

  Future<bool> _isFirstTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('first_time') ?? true;

    if (isFirstTime) {
      await prefs.setBool('first_time', false);
    }

    return isFirstTime;
  }
}

// Simple loading screen
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A0F), Color(0xFF1A0B2E), Color(0xFF0A0A0F)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Your logo
              Image.asset(
                "assets/icon/dark_phonkers_logo.png",
                height: 100,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 40),

              const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),

              const SizedBox(height: 20),

              Text(
                "Phonker Preparing, please wait...",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
