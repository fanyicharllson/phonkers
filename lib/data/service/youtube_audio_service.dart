import 'package:flutter/material.dart';
import 'package:phonkers/data/service/youtube_api_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeAudioService {
  static final YoutubeExplode _ytExplode = YoutubeExplode();

  // Get audio stream URL from YouTube video
  static Future<String?> getAudioStreamUrl(String videoId) async {
    try {
      debugPrint('Getting manifest for video: $videoId');
      final manifest = await _ytExplode.videos.streamsClient.getManifest(
        videoId,
      );

      debugPrint('Audio streams count: ${manifest.audioOnly.length}');
      debugPrint('Muxed streams count: ${manifest.muxed.length}');

      // Get the best audio-only stream
      final audioStreams = manifest.audioOnly;
      if (audioStreams.isNotEmpty) {
        // Create a mutable copy and sort by bitrate
        final audioStreamsList = List.from(audioStreams);
        audioStreamsList.sort(
          (a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond),
        );
        final bestAudio = audioStreamsList.first;

        debugPrint(
          'Found audio stream for video $videoId: ${bestAudio.bitrate}',
        );
        debugPrint('Audio URL: ${bestAudio.url}');
        return bestAudio.url.toString();
      }

      // Fallback to mixed streams (video + audio)
      final muxedStreams = manifest.muxed;
      if (muxedStreams.isNotEmpty) {
        // Create a mutable copy and sort by bitrate
        final muxedStreamsList = List.from(muxedStreams);
        muxedStreamsList.sort(
          (a, b) => b.bitrate.bitsPerSecond.compareTo(a.bitrate.bitsPerSecond),
        );
        final bestMixed = muxedStreamsList.first;

        debugPrint(
          'Using mixed stream for video $videoId: ${bestMixed.bitrate}',
        );
        debugPrint('Mixed URL: ${bestMixed.url}');
        return bestMixed.url.toString();
      }

      debugPrint('No suitable streams found for video: $videoId');
      return null;
    } catch (e) {
      debugPrint('Error getting YouTube audio stream: $e');
      return null;
    }
  }

  // Search for a track and return the first video's audio URL
  static Future<Map<String, dynamic>?> searchAndGetAudioUrl(
    String artist,
    String title, {
    String additionalQuery = '',
  }) async {
    try {
      final query = '$title $artist $additionalQuery';
      final videos = await YouTubeApiService.searchVideos(
        query: query,
        maxResults: 1,
      );

      if (videos.isEmpty) {
        debugPrint('No YouTube videos found for: $query');
        return null;
      }

      final video = videos.first;
      final videoId = video['id']['videoId'];
      final audioUrl = await getAudioStreamUrl(videoId);

      if (audioUrl != null) {
        return {
          'audioUrl': audioUrl,
          'videoId': videoId,
          'title': video['snippet']['title'],
          'channelTitle': video['snippet']['channelTitle'],
          'thumbnail': video['snippet']['thumbnails']['medium']['url'],
        };
      }

      return null;
    } catch (e) {
      debugPrint('Error searching YouTube for audio: $e');
      return null;
    }
  }

  // Dispose resources
  static void dispose() {
    _ytExplode.close();
  }
}
