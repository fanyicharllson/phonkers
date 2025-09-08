import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:phonkers/users/profile/profile_change_detector.dart';
import 'package:phonkers/users/profile/profile_service.dart';
import 'package:phonkers/view/widget/network_widget/network_aware_mixin.dart';
import 'package:phonkers/view/widget/network_widget/network_status_widget.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with NetworkAwareMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  final bool _isUploadingImage = false;
  bool _hasNetworkConnection = true;
  bool _isSavingProfile = false;
  ProfileChangeDetector? _changeDetector;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkNetworkAndLoad();
  }

  Future<void> _checkNetworkAndLoad() async {
    final hasInternet = await hasInternetConnection();
    if (!mounted) return;
    setState(() {
      _hasNetworkConnection = hasInternet;
    });

    if (hasInternet) {
      _loadUserData();
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Load user data from ProfileService
        final profileData = await ProfileService.getUserProfile();

        final username = profileData?['username'] ?? user.displayName ?? '';
        final email = profileData?['email'] ?? user.email ?? '';
        final imageUrl = profileData?['profileImageUrl'] ?? user.photoURL;

        _usernameController.text = username;
        _emailController.text = email;

        // Always initialize change detector
        _changeDetector = ProfileChangeDetector(
          originalUsername: username,
          originalImageUrl: imageUrl,
        );
      } else {
        // No user logged in, still initialize with defaults
        _changeDetector = ProfileChangeDetector(
          originalUsername: '',
          originalImageUrl: null,
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        }); // trigger rebuild
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error loading profile data: ${e.toString()}');
        // Still initialize to prevent infinite loading
        _changeDetector = ProfileChangeDetector(
          originalUsername: '',
          originalImageUrl: null,
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onUsernameChanged(String value) {
    if (_changeDetector != null) {
      _changeDetector!.updateUsername(value);
      setState(() {}); // Trigger rebuild to update save button state
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2D1B47),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Profile Picture',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white70),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => _selectImage(ImageSource.gallery),
            ),
            //! Tobe implemented*****************************************
            // ListTile(
            //   leading: const Icon(Icons.camera_alt, color: Colors.white70),
            //   title: const Text(
            //     'Take Photo',
            //     style: TextStyle(color: Colors.white),
            //   ),
            //   onTap: () => _selectImage(ImageSource.camera),
            // ),
            //! Tobe implemented*****************************************
            if (_changeDetector?.hasImage == true)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Remove Photo',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfileImage();
                },
              ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.white54),
              title: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white54),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (!mounted) return; // prevent setState on disposed widget

      Navigator.pop(context); // now safely close the bottom sheet

      if (pickedFile != null && _changeDetector != null) {
        _changeDetector!.setNewImage(File(pickedFile.path));
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error selecting image: ${e.toString()}');
      }
    }
  }

  void _removeProfileImage() {
    if (_changeDetector != null) {
      _changeDetector!.removeImage();
      setState(() {});
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _changeDetector == null) return;

    // Start showing loading immediately
    setState(() => _isSavingProfile = true);

    try {
      final hasInternet = await hasInternetConnection();
      if (!hasInternet) {
        if (mounted) {
          setState(() {
            _hasNetworkConnection = false;
            _isSavingProfile = false; // stop spinner if no internet
          });
        }
        return;
      }

      await ProfileService.updateUserProfile(
        username: _usernameController.text.trim(),
        imageFile: _changeDetector!.newImageFile,
        existingImageUrl: _changeDetector!.currentImageUrl,
        removeImage: _changeDetector!.imageRemoved,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Error updating profile: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    print("Error that occured: $message");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _discardChanges() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B47),
        title: const Text(
          'Discard Changes?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasChanges = _changeDetector?.hasChanges ?? false;

    return PopScope(
      canPop: !hasChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && hasChanges) {
          _discardChanges();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A0B2E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A0B2E),
          foregroundColor: Colors.white,
          title: const Text('Edit Profile'),
          elevation: 0,
          actions: [
            if (hasChanges)
              TextButton(
                onPressed: () => _changeDetector?.reset(),
                child: const Text(
                  'Reset',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
          ],
        ),
        body: !_hasNetworkConnection
            ? NetworkStatusWidget(
                onRetry: _checkNetworkAndLoad,
                message:
                    'Internet connection is required to load and save your profile.',
              )
            : _changeDetector == null || _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.purple),
                    SizedBox(height: 16),
                    Text(
                      'Phonker is loading your profile! please wait...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // Profile Picture Section
                      _buildProfilePicture(),

                      const SizedBox(height: 40),

                      // Username Field
                      _buildUsernameField(),

                      const SizedBox(height: 20),

                      // Email Field (Read-only)
                      _buildEmailField(),

                      const SizedBox(height: 40),

                      // Save Button (only show when there are changes)
                      if (hasChanges) _buildSaveButton(),

                      // Changes indicator
                      if (hasChanges)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange.shade300,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'You have unsaved changes',
                                style: TextStyle(
                                  color: Colors.orange.shade300,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProfilePicture() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.purple.withValues(alpha: 0.3),
          backgroundImage: _changeDetector!.currentImageProvider,
          child: !_changeDetector!.hasImage
              ? const Icon(Icons.person, size: 60, color: Colors.white70)
              : null,
        ),
        if (_isUploadingImage)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Colors.purple,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.purple,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isUploadingImage ? null : _pickImage,
              icon: const Icon(Icons.camera_alt, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsernameField() {
    return TextFormField(
      controller: _usernameController,
      style: const TextStyle(color: Colors.white),
      onChanged: _onUsernameChanged,
      decoration: InputDecoration(
        labelText: 'Username',
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.person_outline, color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.purple),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a username';
        }
        if (value.trim().length < 3) {
          return 'Username must be at least 3 characters';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      enabled: false,
      style: const TextStyle(color: Colors.white54),
      decoration: InputDecoration(
        labelText: 'Email',
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.email_outlined, color: Colors.white54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSavingProfile ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSavingProfile
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Saving...'),
                ],
              )
            : const Text('Save Changes'),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
