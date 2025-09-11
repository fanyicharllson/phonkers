import 'package:flutter/material.dart';
import 'package:phonkers/view/widget/about_widget/app_info_widget.dart';
import 'package:phonkers/view/widget/about_widget/app_statistics_widget.dart';
import 'package:phonkers/view/widget/about_widget/features_section_widget.dart';
import 'package:phonkers/view/widget/about_widget/founder_profile_widget.dart';
import 'package:phonkers/view/widget/about_widget/legal_section_widget.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0B2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A0B2E),
        foregroundColor: Colors.white,
        title: const Text('About Phonkers'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // App Info Section
            const AppInfoWidget(),

            const SizedBox(height: 40),

            // App Statistics
            const AppStatisticsWidget(),

            const SizedBox(height: 40),

            // Features Section
            const FeaturesSectionWidget(),

            const SizedBox(height: 40),

            // Founder Profile Section
            const FounderProfileWidget(),

            const SizedBox(height: 40),

            // Legal Section
            const LegalSectionWidget(),

            const SizedBox(height: 40),

            // Copyright
            Text(
              '© ${DateTime.now().year} Phonkers. All rights reserved.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
