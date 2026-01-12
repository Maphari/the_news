import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/view/widgets/social_button_widget.dart';

class RegisterLoginBottomSectionWidget extends StatelessWidget {
  const RegisterLoginBottomSectionWidget({
    super.key,
    required this.formType,
    required this.onPressedGoogle,
    required this.onPressedApple,
    required this.whichPage,
    required this.whichPagePrompt,
    required this.toFormType,
  });

  final String formType;
  final String toFormType;
  final VoidCallback onPressedGoogle;
  final VoidCallback onPressedApple;
  final Widget whichPage;
  final String whichPagePrompt;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        //? Divider
        Row(
          children: [
            Expanded(child: Divider(color: KAppColors.getOnBackground(context).withValues(alpha: 0.6))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or $formType with',
                style: TextStyle(color: KAppColors.getOnBackground(context).withValues(alpha: 0.3), fontSize: 14),
              ),
            ),
            Expanded(child: Divider(color: KAppColors.getOnBackground(context).withValues(alpha: 0.6))),
          ],
        ),

        const SizedBox(height: 24),

        //? Social Sign Up Buttons
        Row(
          children: [
            SocialButtonWidget(
              buttonText: 'Google',
              imagePath: 'assets/image/google_icon.png',
              onPressed: onPressedGoogle,
              iconData: Icons.g_mobiledata,
            ),
            const SizedBox(width: 12),
            SocialButtonWidget(
              buttonText: 'Apple',
              imagePath: 'assets/image/apple_icon.png',
              onPressed: onPressedApple,
              iconData: Icons.apple,
            ),
          ],
        ),

        const SizedBox(height: 24),

        //? Login Link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(whichPagePrompt, style: TextStyle(color: KAppColors.getOnBackground(context).withValues(alpha: 0.3))),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => whichPage),
                );
              },
              child: Text(
                toFormType,
                style: TextStyle(
                  color: KAppColors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
