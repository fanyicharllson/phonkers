// widgets/playback_options_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:phonkers/data/model/phonk.dart';
import 'package:phonkers/data/service/phonk_service.dart';

class PlaybackOptionsBottomSheet extends StatelessWidget {
  final Phonk phonk;

  const PlaybackOptionsBottomSheet({super.key, required this.phonk});

  static void show(BuildContext context, Phonk phonk) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => PlaybackOptionsBottomSheet(phonk: phonk),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A0B2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              "Listen to ${phonk.title}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            Text(
              "by ${phonk.artist}",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 20),

            if (phonk.hasYoutube) ...[
              _buildOptionTile(
                context,
                icon: Icons.play_arrow,
                iconColor: Colors.red,
                title: "Play on YouTube",
                subtitle: "Full track • Opens YouTube app",
                onTap: () => _playOnYouTube(context),
              ),
              const SizedBox(height: 8),
            ],

            if (phonk.hasSpotify) ...[
              _buildOptionTile(
                context,
                icon: Icons.music_note,
                iconColor: Colors.green,
                title: "Play on Spotify",
                subtitle: "Full track • Opens Spotify app",
                onTap: () => _playOnSpotify(context),
              ),
              const SizedBox(height: 8),
            ],

            // Cancel button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05), //! This line
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white30,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _playOnYouTube(BuildContext context) async {
    Navigator.pop(context);

    try {
      final searchQuery = '${phonk.artist} ${phonk.title} phonk';

      // Method 1: Try YouTube app intent first
      final youtubeAppUrl =
          'vnd.youtube://results?search_query=${Uri.encodeComponent(searchQuery)}';

      try {
        final Uri youtubeAppUri = Uri.parse(youtubeAppUrl);

        if (await canLaunchUrl(youtubeAppUri)) {
          await launchUrl(youtubeAppUri, mode: LaunchMode.externalApplication);

          // Increment play count and show success message
          await PhonkService().incrementPlayCount(phonk.id);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Opening "${phonk.title}" on YouTube'),
                    ),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return; // Success, exit early
        }
      } catch (e) {
        print('YouTube app launch failed: $e');
      }

      // Method 2: Fallback to web browser
      final webUrl =
          'https://www.youtube.com/results?search_query=${Uri.encodeComponent(searchQuery)}';
      final Uri webUri = Uri.parse(webUrl);

      print('Trying web browser: $webUrl');

      await launchUrl(
        webUri,
        mode:
            LaunchMode.externalApplication, // This will open in default browser
      );

      print('Successfully launched in browser');

      // Increment play count
      await PhonkService().incrementPlayCount(phonk.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.open_in_browser,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text('Opening "${phonk.title}" in browser')),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('All launch methods failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Could not open YouTube automatically! Please ensure you have a browser or the YouTube app installed.',
                ),
                SizedBox(height: 4),
                Text(
                  'Search for: ${phonk.artist} - ${phonk.title}',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            backgroundColor: Colors.red[800],
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _playOnSpotify(BuildContext context) async {
    Navigator.pop(context);

    try {
      if (phonk.spotifyUrl != null) {
        // Create Spotify app deep link
        String spotifyAppUrl;
        if (phonk.spotifyUrl!.contains('track/')) {
          // Extract track ID for app deep link
          final trackId = phonk.spotifyUrl!
              .split('track/')
              .last
              .split('?')
              .first;
          spotifyAppUrl = 'spotify:track:$trackId';
        } else {
          // Fallback to the original URL
          spotifyAppUrl = phonk.spotifyUrl!;
        }

        // Method 1: Try Spotify app first
        try {
          final Uri spotifyAppUri = Uri.parse(spotifyAppUrl);
          print('Trying Spotify app: $spotifyAppUrl');

          if (await canLaunchUrl(spotifyAppUri)) {
            await launchUrl(
              spotifyAppUri,
              mode: LaunchMode.externalApplication,
            );

            print('Successfully launched Spotify app');

            // Increment play count and show success message
            await PhonkService().incrementPlayCount(phonk.id);

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(
                        Icons.music_note,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Opening "${phonk.title}" on Spotify'),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            return; // Success, exit early
          }
        } catch (e) {
          print('Spotify app launch failed: $e');
        }

        // Method 2: Fallback to Spotify Web Player
        try {
          final Uri spotifyWebUri = Uri.parse(phonk.spotifyUrl!);
          print('Trying Spotify web: ${phonk.spotifyUrl!}');

          await launchUrl(
            spotifyWebUri,
            mode: LaunchMode.externalApplication, // Opens in browser
          );

          print('Successfully launched Spotify in browser');

          // Increment play count
          await PhonkService().incrementPlayCount(phonk.id);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(
                      Icons.open_in_browser,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Opening "${phonk.title}" in Spotify Web Player',
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green[700],
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          print('Spotify web launch failed: $e');
          throw e; // Re-throw to trigger the catch block below
        }
      } else {
        throw Exception('No Spotify URL available');
      }
    } catch (e) {
      print('All Spotify launch methods failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Could not open Spotify'),
                SizedBox(height: 4),
                Text(
                  'Install Spotify app or search: ${phonk.artist} - ${phonk.title}',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
            backgroundColor: Colors.red[800],
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'GET APP',
              textColor: Colors.white,
              onPressed: () async {
                // Open Spotify download page
                final Uri playStoreUri = Uri.parse(
                  'https://play.google.com/store/apps/details?id=com.spotify.music',
                );
                try {
                  await launchUrl(
                    playStoreUri,
                    mode: LaunchMode.externalApplication,
                  );
                } catch (e) {
                  print('Could not open Play Store: $e');
                }
              },
            ),
          ),
        );
      }
    }
  }
}
