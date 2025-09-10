import 'package:flutter/material.dart';
import 'package:phonkers/data/service/help_support_service.dart';
import 'package:phonkers/view/widget/network_widget/network_aware_mixin.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen>
    with NetworkAwareMixin {
  final HelpSupportService _helpSupportService = HelpSupportService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0B2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0B2E),
        foregroundColor: Colors.white,
        title: const Text('Help & Support'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHelpSection(
            title: 'Frequently Asked Questions',
            children: [
              _buildExpandableFAQ(
                question: 'How do I create a playlist?',
                answer:
                    'To create a playlist, go to your library, tap the "+" button, and select "Create Playlist". Give it a name and start adding your favorite phonk tracks!',
              ),
              _buildExpandableFAQ(
                question: 'How do I download music for offline listening?',
                answer:
                    'Premium users can download tracks by tapping the download icon next to any song. Downloaded music will be available in your offline library.',
              ),
              _buildExpandableFAQ(
                question: 'How do I reset my password?',
                answer:
                    'Go to Settings > Change Password, or use the "Forgot Password" option on the login screen to receive a reset email.',
              ),
              _buildExpandableFAQ(
                question: 'How do I cancel my subscription?',
                answer:
                    'You can manage your subscription in the app store where you originally purchased it, or contact our support team for assistance.',
              ),
            ],
          ),

          const SizedBox(height: 30),

          _buildHelpSection(
            title: 'Contact Us',
            children: [
              _buildContactOption(
                icon: Icons.email_outlined,
                title: 'Email Support',
                subtitle: 'charlseempire@gmail.com',
                onTap: () {
                  // TODO: Open email client
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Emailing Coming Soon!')),
                  );
                },
              ),
              _buildContactOption(
                icon: Icons.chat_bubble_outline,
                title: 'Live Chat',
                subtitle: 'Available 24/7',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Live chat coming soon!')),
                  );
                },
              ),
              _buildContactOption(
                icon: Icons.phone_outlined,
                title: 'Phone Support',
                subtitle: '+237 670242458',
                onTap: () {
                  // TODO: Open phone dialer
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Phone Support Coming Soon!')),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 30),

          _buildHelpSection(
            title: 'Resources',
            children: [
              _buildResourceOption(
                icon: Icons.article_outlined,
                title: 'User Guide',
                subtitle: 'Learn how to use Phonkers',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User guide coming soon!')),
                  );
                },
              ),
              _buildResourceOption(
                icon: Icons.video_library_outlined,
                title: 'Video Tutorials',
                subtitle: 'Watch step-by-step tutorials',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Video tutorials coming soon!'),
                    ),
                  );
                },
              ),
              _buildResourceOption(
                icon: Icons.feedback_outlined,
                title: 'Send Feedback',
                subtitle: 'Help us improve the app',
                onTap: () => _showFeedbackDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection({
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

  Widget _buildExpandableFAQ({
    required String question,
    required String answer,
  }) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(color: Colors.white)),
      iconColor: Colors.purple,
      collapsedIconColor: Colors.white54,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(answer, style: const TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    );
  }

  Widget _buildResourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: const Color(0xFF2D1B47),
            title: const Text(
              'Send Feedback',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: feedbackController,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Tell us what you think...',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.purple),
                    ),
                  ),
                ),
                if (isSubmitting)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: CircularProgressIndicator(color: Colors.purple),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        // Set loading state once here
                        setState(() {
                          isSubmitting = true;
                        });

                        await _submitFeedback(
                          context,
                          feedbackController.text.trim(),
                          // Pass empty functions since we're managing state here
                          () {}, // setSubmitting - already set above
                          () => setState(
                            () => isSubmitting = false,
                          ), // clearSubmitting
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Send'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitFeedback(
    BuildContext context,
    String feedback,
    VoidCallback setSubmitting,
    VoidCallback clearSubmitting,
  ) async {
    if (feedback.isEmpty) {
      clearSubmitting();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter your feedback before sending.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setSubmitting();

    try {
      await executeWithNetworkCheck<void>(
        action: () => _helpSupportService.saveFeedback(
          feedback: feedback,
          category: 'general',
        ),
      );

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Thank you for your feedback 😘! We\'ll review it soon.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send feedback: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      clearSubmitting();
    }
  }
}
