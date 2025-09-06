import 'package:flutter/material.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final Animation<double> profileFadeAnimation;
  final Animation<Offset> profileSlideAnimation;

  const ProfileHeaderWidget({
    super.key,
    required this.profileFadeAnimation,
    required this.profileSlideAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: profileSlideAnimation,
      child: FadeTransition(
        opacity: profileFadeAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.withValues(alpha: 0.2),
                Colors.purple.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.purple.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person,
                color: Colors.purple,
                size: 24,
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  "My Profile",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}