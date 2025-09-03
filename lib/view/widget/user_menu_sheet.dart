import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:phonkers/view/widget/user_menu_sheet_screens.dart/about_screen.dart';
import 'package:phonkers/view/widget/user_menu_sheet_screens.dart/edit_profile_screen.dart';
import 'package:phonkers/view/widget/user_menu_sheet_screens.dart/help_support_screen.dart';
import 'package:phonkers/view/widget/user_menu_sheet_screens.dart/settings.dart';

class UserMenuSheet extends StatefulWidget {
  const UserMenuSheet({super.key});

  @override
  State<UserMenuSheet> createState() => _UserMenuSheetState();
}

class _UserMenuSheetState extends State<UserMenuSheet> {
  bool _isSigningOut = false;

  Future<void> _handleSignOut() async {
    setState(() => _isSigningOut = true);

    try {
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/auth', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSigningOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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

            _buildMenuItem(Icons.person_outline, "Edit Profile", () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            }),
            _buildMenuItem(Icons.settings_outlined, "Settings", () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            }),
            _buildMenuItem(Icons.help_outline, "Help & Support", () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HelpSupportScreen(),
                ),
              );
            }),
            _buildMenuItem(Icons.info_outline, "About Phonkers", () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            }),

            const Divider(color: Colors.white24),

            _buildMenuItem(
              Icons.logout,
              "Sign Out",
              _isSigningOut ? null : _handleSignOut,
              isDestructive: true,
              isLoading: _isSigningOut,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    VoidCallback? onTap, {
    bool isDestructive = false,
    bool isLoading = false,
  }) {
    return ListTile(
      leading: isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              ),
            )
          : Icon(icon, color: isDestructive ? Colors.red : Colors.white70),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      enabled: !isLoading,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    );
  }
}
