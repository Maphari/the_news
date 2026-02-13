import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/social_post_model.dart';
import 'package:the_news/service/social_features_backend_service.dart';
import 'package:the_news/view/widgets/app_back_button.dart';
import 'package:the_news/view/widgets/k_app_bar.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _headingController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _articleUrlController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _headingController.dispose();
    _textController.dispose();
    _articleUrlController.dispose();
    super.dispose();
  }

  bool _isValidHttpUrl(String value) {
    final parsed = Uri.tryParse(value);
    if (parsed == null) return false;
    return (parsed.scheme == 'http' || parsed.scheme == 'https') &&
        (parsed.host.isNotEmpty);
  }

  Future<void> _submit() async {
    final heading = _headingController.text.trim();
    final text = _textController.text.trim();
    final articleUrl = _articleUrlController.text.trim();
    if (_isPosting) return;
    if (heading.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Heading is required')),
      );
      return;
    }
    if (articleUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Article link is required')),
      );
      return;
    }
    if (articleUrl.isNotEmpty && !_isValidHttpUrl(articleUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Use a valid article link (https://...)')),
      );
      return;
    }
    setState(() => _isPosting = true);
    SocialPost? post;
    try {
      post = await SocialFeaturesBackendService.instance.createNetworkPost(
        text: text,
        heading: heading,
        articleUrl: articleUrl,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPosting = false);
      final message = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message.isEmpty ? 'Could not publish post right now' : message)),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _isPosting = false);
    if (post == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not publish post right now')),
      );
      return;
    }
    Navigator.pop<SocialPost>(context, post);
  }

  @override
  Widget build(BuildContext context) {
    final onBackground = KAppColors.getOnBackground(context);
    return Scaffold(
      backgroundColor: KAppColors.getBackground(context),
      appBar: KAppBar(
        title: Text(
          'Create Post',
          style: KAppTextStyles.titleLarge.copyWith(
            color: onBackground,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: AppBackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: KDesignConstants.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Write a clear heading and attach a news article link',
              style: KAppTextStyles.bodyMedium.copyWith(
                color: onBackground.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _headingController,
              textInputAction: TextInputAction.next,
              maxLength: 160,
              decoration: InputDecoration(
                labelText: 'Heading',
                hintText: 'What is this post about?',
                border: OutlineInputBorder(borderRadius: KBorderRadius.md),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _articleUrlController,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Article link',
                hintText: 'https://example.com/article',
                border: OutlineInputBorder(borderRadius: KBorderRadius.md),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _textController,
                autofocus: true,
                maxLength: 600,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'Add context or your take...',
                  alignLabelWithHint: true,
                  contentPadding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                  border: OutlineInputBorder(borderRadius: KBorderRadius.md),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isPosting ? null : _submit,
                child: _isPosting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Publish Post'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
