import 'package:flutter/material.dart';

class CommunityFeedHighlighter {
  static void highlightPost(String postId) {
    _highlightedPostId = postId;
    _highlightNotifier.value++;
  }

  static String? _highlightedPostId;
  static final ValueNotifier<int> _highlightNotifier = ValueNotifier(0);

  static bool shouldHighlight(String postId) => _highlightedPostId == postId;
  static ValueNotifier<int> get notifier => _highlightNotifier;
  static String? get highlightedPostId => _highlightedPostId;

  static void clearHighlight() {
    _highlightedPostId = null;
    _highlightNotifier.value++;
  }
}
