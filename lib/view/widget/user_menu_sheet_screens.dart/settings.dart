import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:phonkers/firebase_auth_service/auth_service.dart';
// import 'package:phonkers/firebase_auth_service/auth_state_manager.dart';
import 'package:phonkers/view/pages/welcome_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;
  double _volume = 0.8;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0B2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0B2E),
        foregroundColor: Colors.white,
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSettingsSection(
            title: 'General',
            children: [
              _buildSwitchTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Receive push notifications',
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
              ),
              _buildSwitchTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Use dark theme',
                value: _darkModeEnabled,
                onChanged: (value) {
                  setState(() => _darkModeEnabled = value);
                },
              ),
            ],
          ),

          const SizedBox(height: 30),

          _buildSettingsSection(
            title: 'Audio',
            children: [
              ListTile(
                leading: const Icon(
                  Icons.volume_up_outlined,
                  color: Colors.white70,
                ),
                title: const Text(
                  'Volume',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Slider(
                  value: _volume,
                  onChanged: (value) {
                    setState(() => _volume = value);
                  },
                  activeColor: Colors.purple,
                  inactiveColor: Colors.white24,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 0),
              ),
              _buildActionTile(
                icon: Icons.equalizer_outlined,
                title: 'Equalizer',
                subtitle: 'Adjust sound settings',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Equalizer coming soon!')),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 30),

          _buildSettingsSection(
            title: 'Account',
            children: [
              _buildActionTile(
                icon: Icons.security_outlined,
                title: 'Change Password',
                subtitle: 'Update your password',
                onTap: () => _showChangePasswordDialog(),
              ),
              _buildActionTile(
                icon: Icons.delete_outline,
                title: 'Delete Account',
                subtitle: 'Permanently delete your account',
                onTap: () => _showDeleteAccountDialog(),
                isDestructive: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.purple,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 15),
        ...children,
      ],
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        // activeColor: Colors.p
        activeThumbColor: Colors.purple,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.white70),
      title: Text(
        title,
        style: TextStyle(color: isDestructive ? Colors.red : Colors.white),
      ),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    // Reusable method to show styled SnackBar
    void showStyledSnackBar(String message, {bool isError = false}) {
      final snackBar = SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        duration: const Duration(seconds: 5),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    showDialog(
      context: context,
      builder: (context) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: const Color(0xFF2D1B47),
            title: const Text(
              'Change Password',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final currentPassword = currentPasswordController.text
                            .trim();
                        final newPassword = newPasswordController.text.trim();
                        final confirmPassword = confirmPasswordController.text
                            .trim();

                        if (newPassword != confirmPassword) {
                          showStyledSnackBar(
                            'New password and confirm password do not match.',
                            isError: true,
                          );
                          return;
                        }

                        if (newPassword.isEmpty || currentPassword.isEmpty) {
                          showStyledSnackBar(
                            'Please fill in all fields.',
                            isError: true,
                          );
                          return;
                        }

                        setState(() => isLoading = true);

                        try {
                          final user = authService.value.currentUser;
                          if (user == null) {
                            throw Exception('No user is currently signed in.');
                          }

                          await authService.value
                              .resetPasswordFromCurrentPassword(
                                currentPassword: currentPassword,
                                newPassword: newPassword,
                                email: user.email!,
                              );

                          Navigator.pop(context);
                          showStyledSnackBar('Password changed successfully.');
                        } on FirebaseAuthException catch (e) {
                          String message =
                              'Failed to change password. Please ensure your current password is correct and try again.';
                          if (e.code == 'wrong-password') {
                            message = 'Current password is incorrect.';
                          } else if (e.code == 'weak-password') {
                            message = 'The new password is too weak.';
                          }
                          showStyledSnackBar(message, isError: true);
                        } catch (e) {
                          showStyledSnackBar(
                            'Error: ${e.toString()}',
                            isError: true,
                          );
                        } finally {
                          if (mounted) setState(() => isLoading = false);
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Change'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    final passwordController = TextEditingController();

    void showStyledSnackBar(String message, {bool isError = false}) {
      final snackBar = SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        duration: const Duration(seconds: 3),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    showDialog(
      context: context,
      builder: (context) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: const Color(0xFF2D1B47),
            title: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.red),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Are you sure you want to delete your account? This action cannot be undone.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Enter your current password',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        final password = passwordController.text.trim();

                        if (password.isEmpty) {
                          showStyledSnackBar(
                            'Please enter your current password.',
                            isError: true,
                          );
                          return;
                        }

                        setState(() => isLoading = true);

                        try {
                          final user = authService.value.currentUser;
                          if (user == null) {
                            throw Exception('No user is currently signed in.');
                          }

                          await authService.value.deleteAccount(
                            email: user.email!,
                            password: password,
                          );

                          //clear any user searches
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('recent_searches');

                          // Navigator.pop(context);
                          showStyledSnackBar('Account deleted successfully.');
                          // Optionally navigate to login or welcome screen here
                          Navigator.of(context).popUntil(
                            (route) => route.isFirst,
                          ); // Pop all dialogs/pages
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const WelcomePage(),
                            ),
                          );
                        } on FirebaseAuthException catch (e) {
                          String message = 'Failed to delete account.';
                          if (e.code == 'wrong-password') {
                            message = 'Current password is incorrect.';
                          }
                          showStyledSnackBar(message, isError: true);
                        } catch (e) {
                          showStyledSnackBar(
                            'Error: ${e.toString()}',
                            isError: true,
                          );
                        } finally {
                          if (mounted) setState(() => isLoading = false);
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Delete'),
              ),
            ],
          ),
        );
      },
    );
  }
}
