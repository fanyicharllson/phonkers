import 'package:flutter/material.dart';
import 'package:phonkers/view/screens/search_screen.dart';

// 🔔 Wrapper that automatically navigates to search when ready
class NotificationSearchWrapper extends StatefulWidget {
  final String phonkTitle;
  final Widget child;

  const NotificationSearchWrapper({
    super.key,
    required this.phonkTitle,
    required this.child,
  });

  @override
  State<NotificationSearchWrapper> createState() =>
      _NotificationSearchWrapperState();
}

class _NotificationSearchWrapperState extends State<NotificationSearchWrapper> {
  @override
  void initState() {
    super.initState();

    // Navigate to search after the main page is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateToSearch();
    });
  }

  void _navigateToSearch() {
    if (!mounted) return;

    debugPrint("Navigating to search for: ${widget.phonkTitle}");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(initialQuery: widget.phonkTitle),
      ),
    ).then((_) {
      // Show a snackbar when they return
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Searched trending phonk: ${widget.phonkTitle}"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
