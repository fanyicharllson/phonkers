import 'package:flutter/material.dart';
import 'package:phonkers/view/pages/welcome_info_page.dart';
import 'package:phonkers/view/widget/animations.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Animated Logo - Using ScaleAnimation
                ScaleAnimation(
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.elasticOut,
                  child: GlowAnimation(
                    glowColor: Colors.purple,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(75),
                        border: Border.all(
                          color: Colors.purple.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.music_note,
                          size: 80,
                          color: Colors.purple,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // Animated Text Section - Using StaggerAnimation
                StaggerAnimation(
                  initialDelay: const Duration(milliseconds: 1800),
                  staggerDelay: const Duration(milliseconds: 300),
                  animationType: AnimationType.slideUp,
                  children: [
                    const Text(
                      "Welcome to",
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white70,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [Colors.purple, Colors.deepPurple],
                      ).createShader(bounds),
                      child: const Text(
                        "PHONKERS",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 3.0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      "Dive into the dark beats\nExperience phonk like never before",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),

                const Spacer(flex: 3),

                // Animated Button - Using AnimatedButton
                AnimatedButton(
                  text: "Let's Get Started",
                  delay: const Duration(milliseconds: 2800),
                  icon: Icons.arrow_forward,
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return WelcomeInfoPage();
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
