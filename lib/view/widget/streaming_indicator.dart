// widgets/streaming_indicators.dart
import 'package:flutter/material.dart';
import 'package:phonkers/data/model/phonk.dart';

class StreamingIndicators extends StatelessWidget {
  final Phonk phonk;

  const StreamingIndicators({
    super.key,
    required this.phonk,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (phonk.hasPreview) ...[
          _buildIndicator(
            'S',
            Colors.green,
            'Spotify Preview',
          ),
          if (phonk.hasYoutube) const SizedBox(width: 2),
        ],
        if (phonk.hasYoutube)
          _buildIndicator(
            'Y',
            Colors.red,
            'YouTube Full Track',
          ),
      ],
    );
  }

  Widget _buildIndicator(String letter, Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            letter,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}