import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phonkers/data/service/notification_service.dart';
import 'package:phonkers/data/service/user_service.dart';
import 'package:phonkers/firebase_auth_service/auth_service.dart';
import 'package:phonkers/notification_search_wrapper.dart';
import 'package:phonkers/view/pages/auth_page.dart';
import 'package:phonkers/view/pages/email_check_page.dart';
import 'package:phonkers/view/pages/main_page.dart';
import 'package:phonkers/view/pages/welcome_info_page.dart';
import 'package:phonkers/view/pages/welcome_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import your main.dart to access the pending notification

class AuthStateManager extends StatefulWidget {
  const AuthStateManager({super.key});

  @override
  State<AuthStateManager> createState() => _AuthStateManagerState();
}

class _AuthStateManagerState extends State<AuthStateManager> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.value.authStateChanges,
      builder: (context, snapshot) {
        // Still loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint("Currently showing loading...");
          return const LoadingScreen();
        }

        // No user signed in - show welcome or auth based on first time
        if (snapshot.data == null) {
          return FutureBuilder<bool>(
            future: _isFirstTime(),
            builder: (context, firstTimeSnapshot) {
              if (firstTimeSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const LoadingScreen();
              }

              if (firstTimeSnapshot.data == true) {
                // First time user - show welcome page first
                debugPrint("First time user - showing welcome page");
                return const WelcomePage();
              } else {
                // Returning user without account - directly show auth
                debugPrint("Returning user without auth - showing auth page");
                return const AuthPage();
              }
            },
          );
        }

        // User signed in - check email verification first
        User user = snapshot.data!;

        if (!user.emailVerified) {
          debugPrint("User email not verified - showing email check");
          return EmailCheckPage(email: user.email ?? '');
        }

        // Email verified - check if user profile is complete
        return FutureBuilder<bool>(
          future: UserService.isProfileComplete(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const LoadingScreen(message: "Checking profile...");
            }

            // If profile is not complete, redirect to onboarding flow
            if (profileSnapshot.data != true) {
              debugPrint("User profile incomplete - showing welcome info");
              return const WelcomeInfoPage();
            }

            // 🔔 Check if we have a pending notification from app startup
            final pendingPhonkTitle = NotificationService.pendingPhonkTitle;
            if (pendingPhonkTitle != null) {
              debugPrint("Found pending notification for: $pendingPhonkTitle");

              // Clear the pending notification
              NotificationService.clearPendingPhonk();

              // Show search screen instead of main page
              return NotificationSearchWrapper(
                phonkTitle: pendingPhonkTitle,
                child: const MainPage(),
              );
            }

            // User signed in, verified, and profile complete - go to main app
            debugPrint(
              "User authenticated and profile complete - showing main page",
            );
            return const MainPage();
          },
        );
      },
    );
  }

  /// Check if it's user's first time visiting the app
  Future<bool> _isFirstTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstTime = prefs.getBool('first_time') ?? true;

    if (isFirstTime) {
      await prefs.setBool('first_time', false);
      debugPrint("Marked first_time as false");
    }

    return isFirstTime;
  }
}

// Enhanced loading screen with more context
class LoadingScreen extends StatelessWidget {
  final String? message;

  const LoadingScreen({super.key, this.message});

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
                message ?? "Phonkers loading...",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
