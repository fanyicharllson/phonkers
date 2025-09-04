// profile_change_detector.dart
import 'dart:io';
import 'package:flutter/material.dart';

class ProfileChangeDetector {
  final String originalUsername;
  final String? originalImageUrl;

  String currentUsername;
  String? currentImageUrl;
  File? newImageFile;
  bool imageRemoved;

  ProfileChangeDetector({required this.originalUsername, this.originalImageUrl})
    : currentUsername = originalUsername,
      currentImageUrl = originalImageUrl,
      newImageFile = null,
      imageRemoved = false;

  /// Check if any changes have been made
  bool get hasChanges {
    // Check username change
    if (currentUsername.trim() != originalUsername.trim()) {
      return true;
    }

    // Check if new image was selected
    if (newImageFile != null) {
      return true;
    }

    // Check if image was removed
    if (imageRemoved && originalImageUrl != null) {
      return true;
    }

    return false;
  }

  /// Update username and check for changes
  void updateUsername(String username) {
    currentUsername = username;
  }

  /// Set new image file
  void setNewImage(File imageFile) {
    newImageFile = imageFile;
    imageRemoved = false; // Reset removal flag
  }

  /// Mark image as removed
  void removeImage() {
    newImageFile = null;
    currentImageUrl = null;
    imageRemoved = true;
  }

  /// Reset to original values
  void reset() {
    currentUsername = originalUsername;
    currentImageUrl = originalImageUrl;
    newImageFile = null;
    imageRemoved = false;
  }

  /// Get current display image
  ImageProvider? get currentImageProvider {
    if (newImageFile != null) {
      return FileImage(newImageFile!);
    }
    if (!imageRemoved && currentImageUrl != null) {
      return NetworkImage(currentImageUrl!);
    }
    return null;
  }

  /// Check if currently has any image
  bool get hasImage {
    return newImageFile != null || (!imageRemoved && currentImageUrl != null);
  }
}
