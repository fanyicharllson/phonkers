import 'package:flutter/material.dart';

class LibraryLoginPrompt extends StatelessWidget {
  const LibraryLoginPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Colors.purple.withValues(alpha: 0.3),
                Colors.pink.withValues(alpha: 0.3),
              ],
            ),
          ),
          child: const Icon(
            Icons.account_circle_outlined,
            size: 64,
            color: Colors.purpleAccent,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Sign in to access your library',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Create an account to save your\nfavorite phonk tracks',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white60, fontSize: 16),
        ),
      ],
    );
  }
}
