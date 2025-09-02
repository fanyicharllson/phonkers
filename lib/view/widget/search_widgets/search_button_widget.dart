import 'package:flutter/material.dart';

class SearchButtonWidget extends StatelessWidget {
  final bool isSearching;
  final VoidCallback onPressed;
  final Animation<double> fadeAnimation;

  const SearchButtonWidget({
    super.key,
    required this.isSearching,
    required this.onPressed,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isSearching ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            disabledBackgroundColor: Colors.purple.withValues(alpha: 0.6),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 8,
            shadowColor: Colors.purple.withValues(alpha: 0.4),
          ),
          child: isSearching
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Searching...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                )
              : const Text(
                  'Search',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
}
