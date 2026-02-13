import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/view/widgets/k_app_bar.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/user_profile_model.dart';
import 'package:the_news/service/social_features_backend_service.dart';
import 'package:the_news/view/widgets/show_message_widget.dart';
import 'package:the_news/utils/image_utils.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final SocialFeaturesBackendService _socialService = SocialFeaturesBackendService.instance;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _usernameController;
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  late TextEditingController _avatarUrlController;
  late TextEditingController _websiteController;
  late TextEditingController _xController;
  late TextEditingController _instagramController;
  late TextEditingController _linkedinController;

  bool _isLoading = false;

  InputDecoration _fieldDecoration(BuildContext context, String hintText, {Widget? prefix}) {
    final border = OutlineInputBorder(
      borderRadius: KBorderRadius.md,
      borderSide: BorderSide(
        color: KAppColors.getOnBackground(context).withValues(alpha: 0.12),
      ),
    );

    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefix,
      filled: true,
      fillColor: KAppColors.getOnBackground(context).withValues(alpha: 0.04),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: KAppColors.getPrimary(context), width: 2),
      ),
      errorBorder: border,
      focusedErrorBorder: border.copyWith(
        borderSide: BorderSide(color: KAppColors.getPrimary(context), width: 2),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.profile.username);
    _displayNameController = TextEditingController(text: widget.profile.displayName);
    _bioController = TextEditingController(text: widget.profile.bio ?? '');
    _avatarUrlController = TextEditingController(text: widget.profile.avatarUrl ?? '');
    _websiteController = TextEditingController(text: widget.profile.socialLinks['website'] ?? '');
    _xController = TextEditingController(text: widget.profile.socialLinks['x'] ?? '');
    _instagramController = TextEditingController(text: widget.profile.socialLinks['instagram'] ?? '');
    _linkedinController = TextEditingController(text: widget.profile.socialLinks['linkedin'] ?? '');
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    _avatarUrlController.dispose();
    _websiteController.dispose();
    _xController.dispose();
    _instagramController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedProfile = widget.profile.copyWith(
        username: _usernameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim(),
        avatarUrl: _avatarUrlController.text.trim(),
        socialLinks: {
          'website': _websiteController.text.trim(),
          'x': _xController.text.trim(),
          'instagram': _instagramController.text.trim(),
          'linkedin': _linkedinController.text.trim(),
        },
      );

      await _socialService.updateUserProfile(updatedProfile);

      if (!mounted) return;

      successMessage(context: context, message: 'Profile updated successfully!');
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      if (!mounted) return;
      errorMessage(context: context, message: 'Failed to update profile: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAvatarImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 640,
        maxHeight: 640,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final base64Data = base64Encode(bytes);
      final dataUrl = 'data:image/jpeg;base64,$base64Data';

      if (mounted) {
        setState(() {
          _avatarUrlController.text = dataUrl;
        });
      }
    } catch (e) {
      if (!mounted) return;
      errorMessage(context: context, message: 'Failed to pick image: ${e.toString()}');
    }
  }

  void _showAvatarActions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: KAppColors.getBackground(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: KDesignConstants.spacing16,
              vertical: KDesignConstants.spacing12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.photo_library_outlined, color: KAppColors.getOnBackground(context)),
                  title: Text('Choose from gallery', style: KAppTextStyles.bodyLarge),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickAvatarImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_camera_outlined, color: KAppColors.getOnBackground(context)),
                  title: Text('Take a photo', style: KAppTextStyles.bodyLarge),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickAvatarImage(ImageSource.camera);
                  },
                ),
                if (_avatarUrlController.text.trim().isNotEmpty)
                  ListTile(
                    leading: Icon(Icons.delete_outline, color: KAppColors.error),
                    title: Text(
                      'Remove photo',
                      style: KAppTextStyles.bodyLarge.copyWith(color: KAppColors.error),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _avatarUrlController.text = '';
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final avatarProvider = resolveImageProvider(_avatarUrlController.text);

    return Scaffold(
      backgroundColor: KAppColors.getBackground(context),
      appBar: KAppBar(
        backgroundColor: KAppColors.getBackground(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: KAppColors.getOnBackground(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: KAppTextStyles.headlineSmall.copyWith(
            color: KAppColors.getOnBackground(context),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isLoading)
            Center(
              child: Padding(
                padding: KDesignConstants.paddingHorizontalMd,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(KAppColors.getPrimary(context)),
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                'Save',
                style: TextStyle(
                  color: KAppColors.getPrimary(context),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: KDesignConstants.paddingLg,
          children: [
            // Avatar Preview
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: KAppColors.getPrimary(context).withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: KAppColors.getPrimary(context).withValues(alpha: 0.2),
                      backgroundImage: avatarProvider,
                      child: avatarProvider == null
                          ? Text(
                              _displayNameController.text.isNotEmpty
                                  ? _displayNameController.text[0].toUpperCase()
                                  : 'U',
                              style: KAppTextStyles.displayMedium.copyWith(
                                color: KAppColors.getPrimary(context),
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: KAppColors.getPrimary(context),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: KAppColors.getBackground(context),
                          width: 3,
                        ),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: KAppColors.darkOnBackground, size: 20),
                        onPressed: _showAvatarActions,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing32),

            // Username Field
            Text(
              'Username',
              style: KAppTextStyles.bodyLarge.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing8),
            TextFormField(
              controller: _usernameController,
              decoration: _fieldDecoration(context, 'Enter username').copyWith(
                prefixText: '@',
                prefixStyle: TextStyle(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Username is required';
                }
                if (value.length < 3) {
                  return 'Username must be at least 3 characters';
                }
                if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                  return 'Username can only contain letters, numbers, and underscores';
                }
                return null;
              },
            ),
            const SizedBox(height: KDesignConstants.spacing24),

            // Display Name Field
            Text(
              'Display Name',
              style: KAppTextStyles.bodyLarge.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing8),
            TextFormField(
              controller: _displayNameController,
              decoration: _fieldDecoration(context, 'Enter display name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Display name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: KDesignConstants.spacing24),

            // Bio Field
            Text(
              'Bio',
              style: KAppTextStyles.bodyLarge.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing8),
            TextFormField(
              controller: _bioController,
              maxLines: 4,
              maxLength: 160,
              decoration: _fieldDecoration(context, 'Tell us about yourself...'),
            ),
            const SizedBox(height: KDesignConstants.spacing24),

            Text(
              'Social Links',
              style: KAppTextStyles.bodyLarge.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing8),
            TextFormField(
              controller: _websiteController,
              decoration: _fieldDecoration(context, 'Website URL'),
            ),
            const SizedBox(height: KDesignConstants.spacing12),
            TextFormField(
              controller: _xController,
              decoration: _fieldDecoration(context, 'X / Twitter'),
            ),
            const SizedBox(height: KDesignConstants.spacing12),
            TextFormField(
              controller: _instagramController,
              decoration: _fieldDecoration(context, 'Instagram'),
            ),
            const SizedBox(height: KDesignConstants.spacing12),
            TextFormField(
              controller: _linkedinController,
              decoration: _fieldDecoration(context, 'LinkedIn'),
            ),
            const SizedBox(height: KDesignConstants.spacing32),

            // Save Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: KAppColors.getPrimary(context),
                  foregroundColor: KAppColors.darkOnBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: KBorderRadius.md,
                  ),
                  disabledBackgroundColor: KAppColors.getPrimary(context).withValues(alpha: 0.5),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(KAppColors.darkOnBackground),
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
