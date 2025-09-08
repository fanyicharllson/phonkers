import 'package:cloud_firestore/cloud_firestore.dart';

class Phonk {
  final String id;
  final String title;
  final String artist;
  final String? albumArt;
  final String? previewUrl;
  final int duration; // in milliseconds
  final String? spotifyUrl;
  final String? youtubeUrl;
  final String? albumName;
  final bool hasPreview;
  final int plays;
  final DateTime? uploadDate;
  final bool isNew;
  final String genre;
  final String source; // 'spotify' or 'local'

  Phonk({
    required this.id,
    required this.title,
    required this.artist,
    this.albumArt,
    this.previewUrl,
    this.duration = 0,
    this.spotifyUrl,
    this.youtubeUrl,
    this.albumName,
    this.hasPreview = false,
    this.plays = 0,
    this.uploadDate,
    this.isNew = false,
    this.genre = 'phonk',
    this.source = 'spotify',
  });

  // Create Phonk from Spotify track data
  factory Phonk.fromSpotify(Map<String, dynamic> spotifyTrack) {
    final artists =
        (spotifyTrack['artists'] as List?)
            ?.map((artist) => artist['name'] as String)
            .join(', ') ??
        'Unknown Artist';

    final albumImages = spotifyTrack['album']?['images'] as List?;
    String? albumArt;
    if (albumImages != null && albumImages.isNotEmpty) {
      albumArt = albumImages.first['url'] as String?;
    }

    final title = spotifyTrack['name'] as String;

    // Generate YouTube search URL for full track
    final youtubeQuery = Uri.encodeComponent('$title $artists phonk');
    final youtubeSearchUrl =
        'https://www.youtube.com/results?search_query=$youtubeQuery';

    return Phonk(
      id: spotifyTrack['id'] as String,
      title: title,
      artist: artists,
      albumArt: albumArt,
      previewUrl: spotifyTrack['preview_url'] as String?,
      duration: spotifyTrack['duration_ms'] as int? ?? 0,
      spotifyUrl: spotifyTrack['external_urls']?['spotify'] as String?,
      youtubeUrl: youtubeSearchUrl, // YouTube search URL
      albumName: spotifyTrack['album']?['name'] as String?,
      hasPreview: spotifyTrack['preview_url'] != null,
      plays: 0, // Default for new tracks
      uploadDate: DateTime.now(),
      isNew: true,
      genre: 'phonk',
      source: 'spotify',
    );
  }

  // Create Phonk from Firestore (for user favorites)
  factory Phonk.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Phonk(
      id: doc.id,
      title: data['title'] ?? '',
      artist: data['artist'] ?? '',
      albumArt: data['albumArt'],
      previewUrl: data['previewUrl'],
      duration: data['duration'] ?? 0,
      spotifyUrl: data['spotifyUrl'],
      youtubeUrl: data['youtubeUrl'],
      albumName: data['albumName'],
      hasPreview: data['hasPreview'] ?? false,
      plays: data['plays'] ?? 0,
      uploadDate: data['uploadDate']?.toDate(),
      isNew: data['isNew'] ?? false,
      genre: data['genre'] ?? 'phonk',
      source: data['source'] ?? 'spotify',
    );
  }

  // Create Phonk from YouTube video data
  factory Phonk.fromYouTube(Map<String, dynamic> video) {
    return Phonk(
      id: video['id']?['videoId'] ?? '',
      title: video['snippet']?['title'] ?? 'Unknown',
      artist: video['snippet']?['channelTitle'] ?? 'YouTube Artist',
      albumArt: video['snippet']?['thumbnails']?['medium']?['url'],
      previewUrl: null, // If you later resolve audio stream, set it here
      duration:
          0, // YouTube API doesn’t give duration in search results unless you call videos.list with part=contentDetails
      spotifyUrl: null,
      youtubeUrl:
          "https://www.youtube.com/watch?v=${video['id']?['videoId'] ?? ''}",
      albumName: null,
      hasPreview: false, // true only if you resolve playable preview
      plays: 0,
      uploadDate: DateTime.tryParse(video['snippet']?['publishedAt'] ?? ''),
      isNew: true,
      genre: 'phonk',
      source: 'youtube',
    );
  }

  // Convert to Firestore (for saving favorites)
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'artist': artist,
      'albumArt': albumArt,
      'previewUrl': previewUrl,
      'duration': duration,
      'spotifyUrl': spotifyUrl,
      'youtubeUrl': youtubeUrl,
      'albumName': albumName,
      'hasPreview': hasPreview,
      'plays': plays,
      'uploadDate': uploadDate,
      'isNew': isNew,
      'genre': genre,
      'source': source,
    };
  }

  // Convenience getters
  bool get hasSpotify => spotifyUrl != null;
  bool get hasYoutube => youtubeUrl != null;

  String get formattedDuration {
    final minutes = (duration / 60000).floor();
    final seconds = ((duration % 60000) / 1000).floor();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedPlays {
    if (plays >= 1000000) {
      return '${(plays / 1000000).toStringAsFixed(1)}M';
    } else if (plays >= 1000) {
      return '${(plays / 1000).toStringAsFixed(1)}K';
    }
    return plays.toString();
  }
}
