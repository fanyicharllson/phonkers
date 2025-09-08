import 'package:flutter/material.dart';
import 'package:phonkers/data/model/phonk.dart';

class FeaturedPhonkInfo extends StatefulWidget {
  final Phonk phonk;
  final bool isCurrentlyPlaying;

  const FeaturedPhonkInfo({
    super.key,
    required this.phonk,
    required this.isCurrentlyPlaying,
  });

  @override
  State<FeaturedPhonkInfo> createState() => _FeaturedPhonkInfoState();
}

class _FeaturedPhonkInfoState extends State<FeaturedPhonkInfo>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _scrollAnimationController;
  bool _shouldScroll = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollAnimationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfScrollNeeded();
    });
  }

  @override
  void didUpdateWidget(FeaturedPhonkInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phonk.title != widget.phonk.title) {
      _scrollAnimationController.reset();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkIfScrollNeeded();
      });
    }
  }

  void _checkIfScrollNeeded() {
    if (_scrollController.hasClients) {
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      _shouldScroll = maxScrollExtent > 0;

      if (_shouldScroll && widget.isCurrentlyPlaying) {
        _startScrollAnimation();
      }
    }
  }

  void _startScrollAnimation() {
    if (!_shouldScroll || !_scrollController.hasClients) return;

    _scrollAnimationController.addListener(() {
      if (_scrollController.hasClients) {
        final maxScrollExtent = _scrollController.position.maxScrollExtent;
        final scrollPosition =
            _scrollAnimationController.value * maxScrollExtent;
        _scrollController.jumpTo(scrollPosition);
      }
    });

    _scrollAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scrollable title
        SizedBox(
          height: widget.isCurrentlyPlaying
              ? 50
              : 45, // More height when playing for better visibility
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics:
                const NeverScrollableScrollPhysics(), // Disable manual scrolling
            child: Text(
              widget.phonk.title.toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: widget.isCurrentlyPlaying ? 22 : 20,
                fontWeight: FontWeight.bold,
                shadows: widget.isCurrentlyPlaying
                    ? [
                        const Shadow(
                          color: Colors.black54,
                          offset: Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: Text(
                "${widget.phonk.artist} • ${_formatPlayCount(widget.phonk.plays)} plays",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: widget.isCurrentlyPlaying
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.isCurrentlyPlaying) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.equalizer, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  String _formatPlayCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
