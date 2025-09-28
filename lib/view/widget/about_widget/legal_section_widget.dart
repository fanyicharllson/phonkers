import 'package:flutter/material.dart';

class LegalSectionWidget extends StatelessWidget {
  const LegalSectionWidget({super.key});

  void _showLegalDocument(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B47),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Text(content, style: const TextStyle(color: Colors.white70)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.purple)),
          ),
        ],
      ),
    );
  }

  String _getPrivacyPolicyContent() {
    return '''
Phonkers Privacy Policy

Last updated: ${DateTime.now().year}

1. Information We Collect
We collect information you provide directly to us, such as when you create an account, use our services, or contact us for support.

2. How We Use Your Information
We use the information we collect to provide, maintain, and improve our services, process transactions, and communicate with you.

3. Information Sharing
We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy.

4. Data Security
We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.

5. Your Rights
You have the right to access, update, or delete your personal information. Contact us if you wish to exercise these rights.

For questions about this privacy policy, please contact us at charlseempire@gmail.com.
''';
  }

  String _getTermsOfServiceContent() {
    return '''
Phonkers Terms of Service

Last updated: ${DateTime.now().year}

1. Acceptance of Terms
By using Phonkers, you agree to be bound by these Terms of Service and all applicable laws and regulations.

2. Use License
You may use our app for personal, non-commercial use in accordance with these terms.

3. User Content
You retain ownership of content you submit but grant us a license to use it in connection with our services.

4. Prohibited Uses
You may not use our service for any unlawful purpose or to violate any international, federal, state, or local law or regulation.

5. Disclaimer
The information on this app is provided on an 'as is' basis. We disclaim all warranties, express or implied.

6. Limitations
In no event shall Phonkers be liable for any indirect, incidental, special, consequential, or punitive damages.

For questions about these terms, please contact us at charlseempire@gmail.com.
''';
  }

  @override
  Widget build(BuildContext context) {
    final legalItems = [
      {
        'icon': Icons.privacy_tip,
        'title': 'Privacy Policy',
        'subtitle': 'How we handle your data',
        'content': _getPrivacyPolicyContent(),
      },
      {
        'icon': Icons.gavel,
        'title': 'Terms of Service',
        'subtitle': 'Rules and guidelines for using Phonkers',
        'content': _getTermsOfServiceContent(),
      },
      {
        'icon': Icons.copyright,
        'title': 'Licenses',
        'subtitle': 'Third-party licenses and attributions',
        'content':
            'Open source licenses and acknowledgments for third-party libraries used in Phonkers will be listed here.',
      },
      {
        'icon': Icons.info,
        'title': 'Copyright Information',
        'subtitle': 'Intellectual property rights',
        'content':
            'All content and materials available through Phonkers are protected by copyright laws. Music content is licensed from respective copyright holders.',
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.policy, color: Colors.purple, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Legal Information',
                style: TextStyle(
                  color: Colors.purple,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...legalItems
              .map(
                (item) => _buildLegalItem(
                  context,
                  item['icon'] as IconData,
                  item['title'] as String,
                  item['subtitle'] as String,
                  item['content'] as String,
                ),
              )
              ,
        ],
      ),
    );
  }

  Widget _buildLegalItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    String content,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLegalDocument(context, title, content),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.purple, size: 20),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
