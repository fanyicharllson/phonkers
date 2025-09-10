import 'package:flutter/material.dart';

class CommunityNavigationService {
  static final ValueNotifier<bool> _shouldNavigateNotifier = ValueNotifier(
    false,
  );

  static ValueNotifier<bool> get shouldNavigateNotifier =>
      _shouldNavigateNotifier;

  static void navigateToCommunity() {
    _shouldNavigateNotifier.value = true;
  }

  static void clearNavigation() {
    _shouldNavigateNotifier.value = false;
  }
}
