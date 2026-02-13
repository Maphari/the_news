import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/view/widgets/k_app_bar.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/service/auth_service.dart';
import 'package:the_news/service/feedback_service.dart';
import 'package:the_news/view/widgets/pill_tab.dart';

class FeedbackFormPage extends StatefulWidget {
  const FeedbackFormPage({super.key});

  @override
  State<FeedbackFormPage> createState() => _FeedbackFormPageState();
}

class _FeedbackFormPageState extends State<FeedbackFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final AuthService _authService = AuthService();
  final FeedbackService _feedbackService = FeedbackService.instance;

  FeedbackType _selectedType = FeedbackType.general;
  bool _isSubmitting = false;
  String? _userId;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final userData = await _authService.getCurrentUser();
    if (userData != null && mounted) {
      setState(() {
        _userId = userData['id'] ?? userData['userId'];
        _userEmail = userData['email'];
      });
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final success = await _feedbackService.submitFeedback(
        userId: _userId ?? 'anonymous',
        userEmail: _userEmail ?? '',
        type: _selectedType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      if (mounted) {
        setState(() => _isSubmitting = false);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you for your feedback!'),
              backgroundColor: KAppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit feedback. Please try again.'),
              backgroundColor: KAppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: KAppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KAppColors.getBackground(context),
      appBar: KAppBar(
        backgroundColor: KAppColors.getBackground(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: KAppColors.getOnBackground(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Send Feedback',
          style: KAppTextStyles.headlineSmall.copyWith(
            color: KAppColors.getOnBackground(context),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: KDesignConstants.paddingMd,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: KAppColors.getPrimary(context).withValues(alpha: 0.08),
                borderRadius: KBorderRadius.lg,
                border: Border.all(
                  color: KAppColors.getPrimary(context).withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.feedback_outlined,
                    size: 48,
                    color: KAppColors.getPrimary(context),
                  ),
                  const SizedBox(height: KDesignConstants.spacing12),
                  Text(
                    'We value your feedback',
                    style: KAppTextStyles.titleLarge.copyWith(
                      color: KAppColors.getOnBackground(context),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: KDesignConstants.spacing8),
                  Text(
                    'Help us improve The News by sharing your thoughts, reporting bugs, or suggesting new features.',
                    style: KAppTextStyles.bodyMedium.copyWith(
                      color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing24),

            // Feedback Type
            Text(
              'Feedback Type',
              style: KAppTextStyles.titleMedium.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FeedbackType.values.map((type) {
                final isSelected = _selectedType == type;
                return PillTabContainer(
                  selected: isSelected,
                  onTap: () => setState(() => _selectedType = type),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTypeIcon(type),
                        size: 16,
                        color: isSelected
                            ? KAppColors.getOnPrimary(context)
                            : KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getTypeLabel(type),
                        style: KAppTextStyles.labelMedium.copyWith(
                          color: isSelected
                              ? KAppColors.getOnPrimary(context)
                              : KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: KDesignConstants.spacing24),

            // Title Field
            Text(
              'Title',
              style: KAppTextStyles.titleMedium.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing8),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Brief summary of your feedback',
                filled: true,
                fillColor: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: KBorderRadius.md,
                  borderSide: BorderSide(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: KBorderRadius.md,
                  borderSide: BorderSide(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: KBorderRadius.md,
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                if (value.trim().length < 5) {
                  return 'Title must be at least 5 characters';
                }
                return null;
              },
              maxLength: 100,
            ),
            const SizedBox(height: KDesignConstants.spacing16),

            // Description Field
            Text(
              'Description',
              style: KAppTextStyles.titleMedium.copyWith(
                color: KAppColors.getOnBackground(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: KDesignConstants.spacing8),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                hintText: 'Provide more details about your feedback...',
                filled: true,
                fillColor: KAppColors.getOnBackground(context).withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: KBorderRadius.md,
                  borderSide: BorderSide(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: KBorderRadius.md,
                  borderSide: BorderSide(
                    color: KAppColors.getOnBackground(context).withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: KBorderRadius.md,
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 8,
              maxLength: 1000,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please provide a description';
                }
                if (value.trim().length < 20) {
                  return 'Description must be at least 20 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: KDesignConstants.spacing24),

            // Submit Button
            FilledButton(
              onPressed: _isSubmitting ? null : _submitFeedback,
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: KDesignConstants.paddingVerticalMd,
                shape: RoundedRectangleBorder(
                  borderRadius: KBorderRadius.md,
                ),
              ),
              child: _isSubmitting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send, size: 20),
                        const SizedBox(width: KDesignConstants.spacing8),
                        Text(
                          'Submit Feedback',
                          style: KAppTextStyles.titleMedium.copyWith(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: KDesignConstants.spacing16),

            // Privacy Note
            Container(
              padding: KDesignConstants.paddingSm,
              decoration: BoxDecoration(
                color: KAppColors.info.withValues(alpha: 0.1),
                borderRadius: KBorderRadius.md,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: KAppColors.info,
                  ),
                  const SizedBox(width: KDesignConstants.spacing12),
                  Expanded(
                    child: Text(
                      'Your feedback helps us improve. We may contact you for follow-up questions.',
                      style: KAppTextStyles.bodySmall.copyWith(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return Icons.bug_report;
      case FeedbackType.feature:
        return Icons.lightbulb_outline;
      case FeedbackType.improvement:
        return Icons.trending_up;
      case FeedbackType.general:
        return Icons.chat_bubble_outline;
    }
  }

  String _getTypeLabel(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return 'Bug Report';
      case FeedbackType.feature:
        return 'Feature Request';
      case FeedbackType.improvement:
        return 'Improvement';
      case FeedbackType.general:
        return 'General';
    }
  }

  Color _getTypeColor(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return KAppColors.error;
      case FeedbackType.feature:
        return KAppColors.purple;
      case FeedbackType.improvement:
        return KAppColors.warning;
      case FeedbackType.general:
        return KAppColors.info;
    }
  }
}
