import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:phonkers/view/widget/user_menu_sheet.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.purple),
          );
        }

        final userData = snapshot.data!.data() ?? {};
        final username = userData['username'] ?? user.displayName ?? "Phonker";
        final profileImageUrl = userData['profileImageUrl'] as String?;

        return _buildHeader(context, username, profileImageUrl);
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String username,
    String? profileImageUrl,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Greeting + Username
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Good ${_getTimeOfDay()},",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                username,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Notifications & Profile
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.purple,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Profile Image / Default Icon
              GestureDetector(
                onTap: () => _showUserMenu(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.purple.withValues(alpha: 0.15),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: profileImageUrl != null && profileImageUrl.isNotEmpty
                        ? Image.network(
                            profileImageUrl,
                            fit: BoxFit.cover,
                            key: ValueKey(profileImageUrl), // 👈 ensures reload
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                color: Colors.white,
                              );
                            },
                          )
                        : const Icon(Icons.person, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "morning";
    if (hour < 17) return "afternoon";
    return "evening";
  }

  void _showUserMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const UserMenuSheet(),
    );
  }
}
