import 'package:flutter/material.dart';
import 'package:the_news/constant/design_constants.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/view/perspectives/multi_perspective_page.dart';
import 'package:the_news/view/digest/daily_digest_page.dart';

class QuickActionsBar extends StatelessWidget {
  const QuickActionsBar({
    super.key,
    required this.user,
  });

  final RegisterLoginUserSuccessModel user;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionButton(
              icon: Icons.auto_awesome,
              label: 'Multi-View',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MultiPerspectivePage(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: KDesignConstants.spacing12),
          Expanded(
            child: _QuickActionButton(
              icon: Icons.summarize_outlined,
              label: 'Daily Digest',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DailyDigestPage(userId: user.userId),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: KBorderRadius.lg,
        child: Container(
          decoration: BoxDecoration(
            color: KAppColors.getOnBackground(context).withValues(alpha: 0.06),
            borderRadius: KBorderRadius.lg,
            border: Border.all(
              color: KAppColors.getOnBackground(context).withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: KAppColors.getPrimary(context),
              ),
              const SizedBox(width: KDesignConstants.spacing8),
              Text(
                label,
                style: KAppTextStyles.labelLarge.copyWith(
                  color: KAppColors.getOnBackground(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
