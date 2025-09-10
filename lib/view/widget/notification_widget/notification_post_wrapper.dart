import 'package:flutter/material.dart';
import 'package:phonkers/view/screens/community_screen.dart';
import 'package:phonkers/view/widget/community_widget/community_feed_highlighter.dart';
import 'package:phonkers/view/widget/community_widget/community_navigation_service.dart';

class NotificationPostWrapper extends StatefulWidget {
  final String postId;
  final Widget child;

  const NotificationPostWrapper({
    super.key,
    required this.postId,
    required this.child,
  });

  @override
  State<NotificationPostWrapper> createState() =>
      _NotificationPostWrapperState();
}

class _NotificationPostWrapperState extends State<NotificationPostWrapper> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Delay until after first frame so MainPage is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleNotificationNavigation();
    });
  }

  void _handleNotificationNavigation() async {
    // First, highlight the post
    CommunityFeedHighlighter.highlightPost(widget.postId);

    // Then trigger navigation to community screen
    CommunityNavigationService.navigateToCommunity();

    debugPrint("Using but Navigator.push to redorect to community screen...");
    // Navigate directly to CommunityScreen using MaterialPageRoute
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CommunityScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
