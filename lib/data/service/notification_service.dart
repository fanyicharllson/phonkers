import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// 🔔 Enhanced Notification Model with postId support
class PhonkNotification {
  final String id;
  final String title;
  final String phonkTitle;
  final DateTime timestamp;
  final bool isRead;
  final String type; // 'trending', 'new_release', 'new_post', etc.
  final String? userId;
  final String? postId; // Add postId field
  final String? username;

  PhonkNotification({
    required this.id,
    required this.title,
    required this.phonkTitle,
    required this.timestamp,
    this.isRead = false,
    this.type = 'trending',
    this.userId,
    this.postId, // Include postId in constructor
    this.username,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'phonkTitle': phonkTitle,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'type': type,
      'userId': userId,
      'postId': postId, // Include in JSON
      'username': username,
    };
  }

  factory PhonkNotification.fromJson(Map<String, dynamic> json) {
    return PhonkNotification(
      id: json['id'],
      title: json['title'],
      phonkTitle: json['phonkTitle'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      isRead: json['isRead'] ?? false,
      type: json['type'] ?? 'trending',
      userId: json['userId'],
      postId: json['postId'], // Include from JSON
      username: json['username'],
    );
  }

  PhonkNotification copyWith({bool? isRead}) {
    return PhonkNotification(
      id: id,
      title: title,
      phonkTitle: phonkTitle,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      type: type,
      userId: userId,
      postId: postId, // Preserve postId in copyWith
      username: username,
    );
  }
}

// 🔔 Enhanced Notification Service
class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  List<PhonkNotification> _notifications = [];
  static String? _pendingPhonkTitle;
  static String? _pendingPostId;

  // Getters
  List<PhonkNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  static String? get pendingPhonkTitle => _pendingPhonkTitle;
  static String? get pendingPostId => _pendingPostId;

  // Initialize service
  Future<void> initialize() async {
    await _loadNotifications();
  }

  // 🔔 Add new notification (enhanced to properly handle postId)
  Future<void> addNotification({
    required String title,
    required String phonkTitle,
    String type = 'trending',
    String? postId,
    String? userId,
    String? username,
  }) async {
    final notification = PhonkNotification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      phonkTitle: phonkTitle,
      timestamp: DateTime.now(),
      type: type,
      postId: postId, // Properly store postId
      userId: userId,
      username: username,
    );

    _notifications.insert(0, notification); // Add to top

    // Keep only last 50 notifications
    if (_notifications.length > 50) {
      _notifications = _notifications.take(50).toList();
    }

    await _saveNotifications();
    notifyListeners();

    debugPrint(
      "Added notification: $title - $phonkTitle${postId != null ? ' (PostID: $postId)' : ''}",
    );
  }

  // 🔔 Enhanced community post notification method
  Future<void> addNewPostNotification({
    required String authorUsername,
    required String postContent,
    required String postId,
    required String authorId,
  }) async {
    await addNotification(
      title: '$authorUsername shared a new post',
      phonkTitle: postContent.length > 50
          ? '${postContent.substring(0, 47)}...'
          : postContent,
      type: 'new_post',
      postId: postId, // Pass the postId
      userId: authorId,
      username: authorUsername,
    );
  }

  // 🔔 Get postId from notification
  String? getPostId(String notificationId) {
    final notification = _notifications.firstWhere(
      (n) => n.id == notificationId,
      orElse: () => PhonkNotification(
        id: '',
        title: '',
        phonkTitle: '',
        timestamp: DateTime.now(),
      ),
    );
    return notification.postId;
  }

  // 🔔 Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
      notifyListeners();
    }
  }

  // 🔔 Mark all as read
  Future<void> markAllAsRead() async {
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    await _saveNotifications();
    notifyListeners();
  }

  // 🔔 Clear all notifications
  Future<void> clearAll() async {
    _notifications.clear();
    await _saveNotifications();
    notifyListeners();
  }

  // 🔔 Delete specific notification
  Future<void> deleteNotification(String notificationId) async {
    _notifications.removeWhere((n) => n.id == notificationId);
    await _saveNotifications();
    notifyListeners();
  }

  // 🔔 Pending notification methods (for app startup)
  static void setPendingPhonk(String phonkTitle) {
    _pendingPhonkTitle = phonkTitle;
    debugPrint("Set pending phonk: $phonkTitle");
  }

  static void clearPendingPhonk() {
    debugPrint("Cleared pending phonk: $_pendingPhonkTitle");
    _pendingPhonkTitle = null;
  }

  static void setPendingPost(String postId) {
    _pendingPostId = postId;
    debugPrint("Set pending post: $postId");
  }

  static void clearPendingPost() {
    debugPrint("Cleared pending post: $_pendingPostId");
    _pendingPostId = null;
  }

  // 🔔 Get time ago string
  String getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  // 🔔 Private methods for persistence
  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _notifications.map((n) => n.toJson()).toList();
    await prefs.setString('phonk_notifications', jsonEncode(jsonList));
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('phonk_notifications');

      if (jsonString != null) {
        final jsonList = jsonDecode(jsonString) as List;
        _notifications = jsonList
            .map((json) => PhonkNotification.fromJson(json))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading notifications: $e");
      _notifications = [];
    }
  }
}
