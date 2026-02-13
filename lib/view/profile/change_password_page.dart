import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/view/widgets/app_back_button.dart';
import 'package:the_news/view/widgets/password_form_prefix_sufix_icon_widget.dart';
import 'package:the_news/view/widgets/show_message_widget.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  final _currentFocus = FocusNode();
  final _newFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    _currentFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  String? _validateCurrent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Current password is required';
    }
    return null;
  }

  String? _validateNew(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'New password is required';
    }

    final password = value.trim();
    if (password.length < 8 || password.length > 128) {
      return 'Password must be 8-128 characters';
    }
    final hasUpperCase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowerCase = RegExp(r'[a-z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    if (!hasUpperCase || !hasLowerCase || !hasNumber || !hasSpecial) {
      return 'Include uppercase, lowercase, number & special character';
    }

    if (password == _currentController.text.trim()) {
      return 'New password must be different';
    }

    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Confirm your new password';
    }
    if (value.trim() != _newController.text.trim()) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await AuthService.instance.changePassword(
        currentPassword: _currentController.text.trim(),
        newPassword: _newController.text.trim(),
        confirmPassword: _confirmController.text.trim(),
      );

      if (!mounted) return;
      successMessage(context: context, message: 'Password updated successfully');
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      errorMessage(context: context, message: error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = KAppColors.getBackground(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppBackButton(),
              const SizedBox(height: KDesignConstants.spacing12),
              Text(
                'Change Password',
                style: KAppTextStyles.headlineMedium.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: KDesignConstants.spacing6),
              Text(
                'Keep your account secure by updating your password.',
                style: KAppTextStyles.bodyMedium.copyWith(
                  color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: KDesignConstants.spacing16),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      PasswordFormPrefixSufixIconWidget(
                        controller: _currentController,
                        focusNode: _currentFocus,
                        labelText: 'Current Password',
                        hintText: 'Enter current password',
                        prefixIcon: Icons.lock_outline,
                        valiadate: _validateCurrent,
                      ),
                      const SizedBox(height: KDesignConstants.spacing12),
                      PasswordFormPrefixSufixIconWidget(
                        controller: _newController,
                        focusNode: _newFocus,
                        labelText: 'New Password',
                        hintText: 'Create a strong password',
                        prefixIcon: Icons.lock_reset,
                        valiadate: _validateNew,
                      ),
                      const SizedBox(height: KDesignConstants.spacing12),
                      PasswordFormPrefixSufixIconWidget(
                        controller: _confirmController,
                        focusNode: _confirmFocus,
                        labelText: 'Confirm Password',
                        hintText: 'Re-enter new password',
                        prefixIcon: Icons.verified_user_outlined,
                        valiadate: _validateConfirm,
                      ),
                      const SizedBox(height: KDesignConstants.spacing12),
                      Text(
                        'Password must be 8-128 characters and include uppercase, lowercase, number, and special character.',
                        style: KAppTextStyles.bodySmall.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: KDesignConstants.spacing20),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KAppColors.getPrimary(context),
                            foregroundColor: KAppColors.getOnBackground(context),
                            shape: RoundedRectangleBorder(
                              borderRadius: KBorderRadius.lg,
                            ),
                          ),
                          child: _isSubmitting
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      KAppColors.getOnBackground(context),
                                    ),
                                  ),
                                )
                              : Text(
                                  'Update Password',
                                  style: KAppTextStyles.titleMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: KDesignConstants.spacing12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
