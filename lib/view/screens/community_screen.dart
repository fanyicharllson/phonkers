import 'package:flutter/material.dart';
import 'package:phonkers/view/widget/community_widget/community_feed.dart';
import 'package:phonkers/view/widget/community_widget/community_header.dart';
import 'package:phonkers/view/widget/community_widget/floating_chat_button.dart';
import 'package:phonkers/view/widget/community_widget/user_type_selector.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  String _selectedUserType = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _onUserTypeChanged(String userType) {
    setState(() {
      _selectedUserType = userType;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A0F),
              Color(0xFF1A0B2E),
              Color(0xFF2D1B4E),
              Color(0xFF0A0A0F),
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Compact Header Section - Much smaller
              const CommunityHeader(),
              UserTypeSelector(
                selectedType: _selectedUserType,
                onTypeChanged: _onUserTypeChanged,
              ),

              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A0B2E).withValues(alpha: 0.9),
                  border: const Border(
                    bottom: BorderSide(color: Color(0xFF9F7AEA), width: 0.5),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF9F7AEA),
                  indicatorWeight: 3,
                  labelColor: const Color(0xFF9F7AEA),
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.access_time, size: 20),
                      text: 'Recent',
                    ),
                    Tab(
                      icon: Icon(Icons.trending_up, size: 20),
                      text: 'Trending',
                    ),
                    Tab(icon: Icon(Icons.star, size: 20), text: 'Artists'),
                  ],
                ),
              ),

              // Tab Content - This is the key fix
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      CommunityFeed(
                        key: const ValueKey('recent'),
                        userType: _selectedUserType,
                        feedType: 'recent',
                      ),
                      CommunityFeed(
                        key: const ValueKey('trending'),
                        userType: _selectedUserType,
                        feedType: 'trending',
                      ),
                      CommunityFeed(
                        key: const ValueKey('artists'),
                        userType: _selectedUserType,
                        feedType: 'artists',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: const FloatingChatButton(),
    );
  }
}
