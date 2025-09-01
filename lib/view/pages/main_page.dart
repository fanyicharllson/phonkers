import 'package:flutter/material.dart';
import 'package:phonkers/data/service/audio_player_service.dart';
import 'package:phonkers/view/screens/community_screen.dart';
import 'package:phonkers/view/screens/home_screen.dart';
import 'package:phonkers/view/screens/library_screen.dart';
import 'package:phonkers/view/screens/profile_screen.dart';
import 'package:phonkers/view/screens/search_screen.dart';
import 'package:phonkers/view/widget/custom_bottom_navbar.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    AudioPlayerService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: const [
              HomeScreen(),
              SearchScreen(),
              LibraryScreen(),
              CommunityScreen(),
              ProfileScreen(),
            ],
          ),
          
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    AudioPlayerService.dispose();
    super.dispose();
  }
}
