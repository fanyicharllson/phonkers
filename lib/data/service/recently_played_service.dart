import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:phonkers/data/model/phonk.dart';
import 'dart:convert';

class RecentlyPlayedTrack {
  final String trackId;
  final String title;
  final String artist;
  final DateTime playedAt;
  final String? previewUrl;
  final String? spotifyUrl;
  final String? youtubeUrl;
  final int plays;
  final int? duration;
  final String? imageUrl;

  RecentlyPlayedTrack({
    required this.trackId,
    required this.title,
    required this.artist,
    required this.playedAt,
    this.previewUrl,
    this.spotifyUrl,
    this.youtubeUrl,
    this.plays = 0,
    this.duration,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'trackId': trackId,
      'title': title,
      'artist': artist,
      'playedAt': playedAt.toIso8601String(),
      'previewUrl': previewUrl,
      'spotifyUrl': spotifyUrl,
      'youtubeUrl': youtubeUrl,
      'playCount': plays,
      'duration': duration,
      'imageUrl': imageUrl,
    };
  }

  factory RecentlyPlayedTrack.fromJson(Map<String, dynamic> json) {
    return RecentlyPlayedTrack(
      trackId: json['trackId'] ?? '',
      title: json['title'] ?? 'Unknown Title',
      artist: json['artist'] ?? 'Unknown Artist',
      playedAt: DateTime.parse(json['playedAt']),
      previewUrl: json['previewUrl'],
      spotifyUrl: json['spotifyUrl'],
      youtubeUrl: json['youtubeUrl'],
      plays: json['plays'] ?? 0,
      duration: json['duration'],
      imageUrl: json['imageUrl'],
    );
  }

  factory RecentlyPlayedTrack.fromPhonk(Phonk phonk) {
    return RecentlyPlayedTrack(
      trackId: phonk.id,
      title: phonk.title,
      artist: phonk.artist,
      playedAt: DateTime.now(),
      previewUrl: phonk.previewUrl,
      spotifyUrl: phonk.spotifyUrl,
      youtubeUrl: phonk.youtubeUrl,
      plays: phonk.plays,
      duration: phonk.duration,
      imageUrl: phonk.previewUrl,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(playedAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  String get formattedDuration {
    if (duration == null) return '0:30'; // Default preview duration
    final dur = Duration(milliseconds: duration!);
    final minutes = dur.inMinutes;
    final seconds = dur.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

class RecentlyPlayedService {
  static const String _keyRecentlyPlayed = 'recently_played_tracks';
  static const int _maxRecentTracks = 50; // Keep last 50 tracks

  // Add a track to recently played
  Future<void> addTrack(Phonk phonk) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentlyPlayedJson = prefs.getString(_keyRecentlyPlayed) ?? '[]';
      final List<dynamic> recentlyPlayedList = json.decode(recentlyPlayedJson);

      // Convert to RecentlyPlayedTrack objects
      final List<RecentlyPlayedTrack> recentTracks = recentlyPlayedList
          .map((trackJson) => RecentlyPlayedTrack.fromJson(trackJson))
          .toList();

      // Remove if already exists (to avoid duplicates and move to top)
      recentTracks.removeWhere((track) => track.trackId == phonk.id);

      // Add new track at the beginning
      recentTracks.insert(0, RecentlyPlayedTrack.fromPhonk(phonk));

      // Keep only the most recent tracks
      if (recentTracks.length > _maxRecentTracks) {
        recentTracks.removeRange(_maxRecentTracks, recentTracks.length);
      }

      // Convert back to JSON and save
      final updatedJson = json.encode(
        recentTracks.map((track) => track.toJson()).toList(),
      );
      await prefs.setString(_keyRecentlyPlayed, updatedJson);
    } catch (e) {
      debugPrint('Error adding track to recently played: $e');
    }
  }

  // Get recently played tracks
  Future<List<RecentlyPlayedTrack>> getRecentlyPlayed({int limit = 10}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentlyPlayedJson = prefs.getString(_keyRecentlyPlayed) ?? '[]';
      final List<dynamic> recentlyPlayedList = json.decode(recentlyPlayedJson);

      final List<RecentlyPlayedTrack> recentTracks = recentlyPlayedList
          .map((trackJson) => RecentlyPlayedTrack.fromJson(trackJson))
          .toList();

      // Return limited number of tracks
      return recentTracks.take(limit).toList();
    } catch (e) {
      debugPrint('Error getting recently played tracks: $e');
      return [];
    }
  }

  // Clear all recently played tracks
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyRecentlyPlayed);
    } catch (e) {
      debugPrint('Error clearing recently played: $e');
    }
  }

  // Remove a specific track from recently played
  Future<void> removeTrack(String trackId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentlyPlayedJson = prefs.getString(_keyRecentlyPlayed) ?? '[]';
      final List<dynamic> recentlyPlayedList = json.decode(recentlyPlayedJson);

      final List<RecentlyPlayedTrack> recentTracks = recentlyPlayedList
          .map((trackJson) => RecentlyPlayedTrack.fromJson(trackJson))
          .toList();

      // Remove the specific track
      recentTracks.removeWhere((track) => track.trackId == trackId);

      // Save updated list
      final updatedJson = json.encode(
        recentTracks.map((track) => track.toJson()).toList(),
      );
      await prefs.setString(_keyRecentlyPlayed, updatedJson);
    } catch (e) {
      debugPrint('Error removing track from recently played: $e');
    }
  }

  // Get total count of recently played tracks
  Future<int> getRecentlyPlayedCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentlyPlayedJson = prefs.getString(_keyRecentlyPlayed) ?? '[]';
      final List<dynamic> recentlyPlayedList = json.decode(recentlyPlayedJson);
      return recentlyPlayedList.length;
    } catch (e) {
      debugPrint('Error getting recently played count: $e');
      return 0;
    }
  }

  // Check if a track is in recently played
  Future<bool> isTrackInRecentlyPlayed(String trackId) async {
    try {
      final recentTracks = await getRecentlyPlayed(limit: _maxRecentTracks);
      return recentTracks.any((track) => track.trackId == trackId);
    } catch (e) {
      debugPrint('Error checking if track is in recently played: $e');
      return false;
    }
  }
}
