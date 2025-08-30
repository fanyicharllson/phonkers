import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserMenuSheet extends StatelessWidget {
  const UserMenuSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A0B2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 20),

            _buildMenuItem(Icons.person_outline, "Edit Profile", () {}),
            _buildMenuItem(Icons.settings_outlined, "Settings", () {}),
            _buildMenuItem(Icons.help_outline, "Help & Support", () {}),
            _buildMenuItem(Icons.info_outline, "About Phonkers", () {}),

            const Divider(color: Colors.white24),

            _buildMenuItem(Icons.logout, "Sign Out", () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
            }, isDestructive: true),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    );
  }
}
