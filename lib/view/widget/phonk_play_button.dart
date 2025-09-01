// widgets/phonk_play_button.dart - Alternative version
import 'package:flutter/material.dart';
import 'package:phonkers/data/model/phonk.dart';
import 'package:phonkers/data/service/audio_player_service.dart';

class PhonkPlayButton extends StatelessWidget {
  final Phonk phonk;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const PhonkPlayButton({
    super.key,
    required this.phonk,
    this.onTap,
    this.onLongPress,
  });

  // Check if this phonk is completely unplayable
  // You'd need to add this field to your Phonk model or determine it somehow
  bool get _isCompletelyUnplayable {
    // This is just an example - I'll need to implement this logic
    // based on your data model. For example, you might have:
    // return phonk.isBlocked || phonk.isUnavailable || etc.
    return false; // For now, assume all are playable
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Phonk?>(
      stream: AudioPlayerService.currentPhonkStream,
      builder: (context, currentPhonkSnapshot) {
        final isCurrentPhonk = currentPhonkSnapshot.data?.id == phonk.id;

        return StreamBuilder<bool>(
          stream: AudioPlayerService.isPlayingStream,
          builder: (context, isPlayingSnapshot) {
            final isPlaying = isPlayingSnapshot.data ?? false;
            final showPause = isCurrentPhonk && isPlaying;

            return StreamBuilder<bool>(
              stream: AudioPlayerService.isLoadingStream,
              builder: (context, isLoadingSnapshot) {
                final isLoading = isLoadingSnapshot.data ?? false;
                final isCurrentPhonkLoading = isCurrentPhonk && isLoading;

                // Determine icon based on playability and current state
                IconData iconToUse;
                Color buttonColor;

                if (showPause) {
                  iconToUse = Icons.pause;
                  buttonColor = phonk.hasPreview
                      ? Colors.green
                      : Colors.purple[600]!;
                } else if (_isCompletelyUnplayable) {
                  iconToUse = Icons.open_in_new;
                  buttonColor = Colors.red[600]!; // Red for unplayable
                } else {
                  iconToUse = Icons.play_arrow;
                  buttonColor = phonk.hasPreview
                      ? Colors.green
                      : Colors.purple[600]!;
                }

                return GestureDetector(
                  onTap: isCurrentPhonkLoading ? null : onTap,
                  onLongPress: isCurrentPhonk ? onLongPress : null,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: buttonColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: buttonColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: isCurrentPhonkLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(iconToUse, color: Colors.white, size: 24),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
