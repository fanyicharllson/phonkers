import 'package:flutter/material.dart';
import 'package:phonkers/view/pages/user_type_page.dart';
import 'package:phonkers/view/widget/choice_card.dart';

class WelcomeInfoPage extends StatefulWidget {
  const WelcomeInfoPage({super.key});

  @override
  State<WelcomeInfoPage> createState() => _WelcomeInfoPageState();
}

class _WelcomeInfoPageState extends State<WelcomeInfoPage> {
  String? selectedChoice;
  bool showMusicSuggestions = false;

  void _handleChoice(String choice) {
    setState(() {
      selectedChoice = choice;
      // Show music suggestions if user doesn't like phonk
      showMusicSuggestions = choice == "dont_like";
    });
  }

  void _handleContinue() {
    if (selectedChoice != null) {
      debugPrint("User choice: $selectedChoice");
      // Navigate to next page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UserTypePage(musicPreference: selectedChoice!),
        ),
      );
    }
  }

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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Logo Section
                SizedBox(
                  height: 100,
                  child: Center(
                    child: Image.asset(
                      "assets/icon/dark_phonkers_logo.png",
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Question Section
                const Text(
                  "Tell us about your music taste",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "This helps us personalize your experience",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),

                const SizedBox(height: 40),

                // Choice Cards
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Love Phonk Option
                        ChoiceCard(
                          text: "I love phonk music! 🔥",
                          icon: Icons.favorite,
                          color: Colors.purple,
                          isSelected: selectedChoice == "love_phonk",
                          onTap: () => _handleChoice("love_phonk"),
                        ),

                        // Like Phonk Option
                        ChoiceCard(
                          text: "I like phonk music",
                          icon: Icons.thumb_up,
                          color: Colors.blue,
                          isSelected: selectedChoice == "like_phonk",
                          onTap: () => _handleChoice("like_phonk"),
                        ),

                        // New to Phonk Option
                        ChoiceCard(
                          text: "I'm new to phonk, let's explore!",
                          icon: Icons.explore,
                          color: Colors.orange,
                          isSelected: selectedChoice == "new_to_phonk",
                          onTap: () => _handleChoice("new_to_phonk"),
                        ),

                        // Don't Like Phonk Option
                        ChoiceCard(
                          text: "I don't like phonk music",
                          icon: Icons.music_off,
                          color: Colors.grey,
                          isSelected: selectedChoice == "dont_like",
                          onTap: () => _handleChoice("dont_like"),
                        ),

                        // Music Suggestions (shown when user doesn't like phonk)
                        if (showMusicSuggestions) ...[
                          const SizedBox(height: 20),

                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  "No worries! What music do you enjoy?",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),

                                const SizedBox(height: 16),

                                // Genre suggestions
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _buildGenreChip(
                                      "Hip Hop",
                                      Icons.music_note,
                                    ),
                                    _buildGenreChip(
                                      "Electronic",
                                      Icons.electrical_services,
                                    ),
                                    _buildGenreChip("Rock", Icons.music_video),
                                    _buildGenreChip("Pop", Icons.queue_music),
                                    _buildGenreChip("Jazz", Icons.piano),
                                    _buildGenreChip("Other", Icons.more_horiz),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                Text(
                                  "We'll still give you access to explore phonk, you might discover something new! 😊",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withValues(alpha: 0.7),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Continue Button
                if (selectedChoice != null) ...[
                  const SizedBox(height: 20),

                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.purple, Colors.deepPurple],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _handleContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        "Continue",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGenreChip(String genre, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            genre,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
