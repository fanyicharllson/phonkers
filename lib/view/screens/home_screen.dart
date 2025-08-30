import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:phonkers/view/home_screen_widgets/discover_section.dart';
import 'package:phonkers/view/home_screen_widgets/featured_phonk_card.dart';
import 'package:phonkers/view/home_screen_widgets/home_header.dart';
import 'package:phonkers/view/home_screen_widgets/recently_played_section.dart';
import 'package:phonkers/view/home_screen_widgets/trending_phonk_section.dart';

// Home Screen Widget
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0A0F), Color(0xFF1A0B2E), Color(0xFF0A0A0F)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              HomeHeader(user: user),

              const SizedBox(height: 24),

              // Featured Phonk
              const FeaturedPhonkCard(),

              const SizedBox(height: 32),

              // Trending Section
              const TrendingSection(),

              const SizedBox(height: 32),

              // Recently Played
              const RecentlyPlayedSection(),

              const SizedBox(height: 32),

              // Discover Section
              const DiscoverSection(),

              const SizedBox(height: 100), // Bottom padding for nav bar
            ],
          ),
        ),
      ),
    );
  }
}
