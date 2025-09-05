import 'package:flutter/material.dart';

class UserTypeSelector extends StatelessWidget {
  final String selectedType;
  final Function(String) onTypeChanged;

  const UserTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final userTypes = [
      {
        'type': 'all',
        'label': 'All',
        'icon': Icons.people_alt,
        'color': const Color(0xFF9F7AEA),
      },
      {
        'type': 'artist',
        'label': 'Artists',
        'icon': Icons.mic,
        'color': const Color(0xFFE879F9),
      },
      {
        'type': 'producer',
        'label': 'Producers',
        'icon': Icons.equalizer,
        'color': const Color(0xFF06B6D4),
      },
      {
        'type': 'collector',
        'label': 'Collectors',
        'icon': Icons.library_music,
        'color': const Color(0xFF10B981),
      },
      {
        'type': 'fan',
        'label': 'Fans',
        'icon': Icons.favorite,
        'color': const Color(0xFFF59E0B),
      },
      {
        'type': 'dj',
        'label': 'DJs',
        'icon': Icons.headphones,
        'color': const Color(0xFFEF4444),
      },
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: userTypes.length,
        itemBuilder: (context, index) {
          final userType = userTypes[index];
          final isSelected = selectedType == userType['type'];
          final color = userType['color'] as Color;

          return GestureDetector(
            onTap: () => onTypeChanged(userType['type'] as String),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withValues(alpha: 0.3),
                          color.withValues(alpha: 0.1),
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.08),
                          Colors.white.withValues(alpha: 0.04),
                        ],
                      ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : Colors.white.withValues(alpha: 0.2),
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    userType['icon'] as IconData,
                    color: isSelected ? color : Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    userType['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}