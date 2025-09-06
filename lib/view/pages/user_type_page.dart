import 'package:flutter/material.dart';
import 'package:phonkers/data/service/user_service.dart';
import 'package:phonkers/view/pages/main_page.dart';
import 'package:phonkers/view/widget/toast_util.dart';

class UserTypePage extends StatefulWidget {
  final String musicPreference;

  const UserTypePage({super.key, required this.musicPreference});

  @override
  State<UserTypePage> createState() => _UserTypePageState();
}

class _UserTypePageState extends State<UserTypePage> {
  String? selectedUserType;
  bool isLoading = false;

  final List<Map<String, dynamic>> userTypes = [
    {
      'type': 'artist',
      'label': 'Artists',
      'description': 'Create and share your phonk music',
      'icon': Icons.mic,
      'color': const Color(0xFFE879F9),
    },
    {
      'type': 'producer',
      'label': 'Producers',
      'description': 'Produce beats and instrumentals',
      'icon': Icons.equalizer,
      'color': const Color(0xFF06B6D4),
    },
    {
      'type': 'collector',
      'label': 'Collectors',
      'description': 'Curate and collect music',
      'icon': Icons.library_music,
      'color': const Color(0xFF10B981),
    },
    {
      'type': 'fan',
      'label': 'Fans',
      'description': 'Discover and enjoy phonk music',
      'icon': Icons.favorite,
      'color': const Color(0xFFF59E0B),
    },
    {
      'type': 'dj',
      'label': 'DJs',
      'description': 'Mix and perform phonk sets',
      'icon': Icons.headphones,
      'color': const Color(0xFFEF4444),
    },
  ];

  void _handleUserTypeSelection(String userType) {
    setState(() {
      selectedUserType = userType;
    });
  }

  void _handleContinue() async {
    if (selectedUserType == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      // Save user data to Firebase
      await UserService.saveUserData({
        'musicPreference': widget.musicPreference,
        'userType': selectedUserType!,
      });

      if (mounted) {
        ToastUtil.showToast(context, "Preference Saved!", background: Colors.deepPurple);
      }

      if (mounted) {
        // Navigate to auth page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
                  "What describes you best?",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Choose your role in the phonk community",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),

                const SizedBox(height: 40),

                // User Type Cards
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: userTypes.map((userType) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildUserTypeCard(userType),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Continue Button
                if (selectedUserType != null) ...[
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
                      onPressed: isLoading ? null : _handleContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
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

  Widget _buildUserTypeCard(Map<String, dynamic> userType) {
    final bool isSelected = selectedUserType == userType['type'];

    return GestureDetector(
      onTap: () => _handleUserTypeSelection(userType['type']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    userType['color'].withValues(alpha: 0.2),
                    userType['color'].withValues(alpha: 0.1),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? userType['color']
                : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: userType['color'].withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: userType['color'].withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(userType['icon'], color: userType['color'], size: 24),
            ),

            const SizedBox(width: 16),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userType['label'],
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userType['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Selection Indicator
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: userType['color'],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}
