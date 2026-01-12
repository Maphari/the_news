import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';

class MindfulMomentCard extends StatelessWidget {
  const MindfulMomentCard({super.key});

  static final List<Map<String, String>> _moments = [
    {
      'quote': 'Stay informed, not overwhelmed',
      'tip': 'Remember to take breaks between articles',
    },
    {
      'quote': 'Knowledge is power, balance is wisdom',
      'tip': 'Focus on understanding, not just reading',
    },
    {
      'quote': 'Every story has multiple perspectives',
      'tip': 'Seek diverse sources for complete picture',
    },
    {
      'quote': 'News is important, but so is your peace',
      'tip': 'Limit reading time to protect your wellbeing',
    },
    {
      'quote': 'Be curious, not anxious',
      'tip': 'Approach news with curiosity, not fear',
    },
    {
      'quote': 'You don\'t need to know everything',
      'tip': 'It\'s okay to skip stories that drain you',
    },
    {
      'quote': 'Quality over quantity',
      'tip': 'Read fewer articles, but read them well',
    },
  ];

  Map<String, String> _getTodaysMoment() {
    final today = DateTime.now();
    final dayOfYear = today.difference(DateTime(today.year, 1, 1)).inDays;
    final index = dayOfYear % _moments.length;
    return _moments[index];
  }

  @override
  Widget build(BuildContext context) {
    final moment = _getTodaysMoment();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KAppColors.primary.withValues(alpha: 0.15),
            KAppColors.tertiary.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: KAppColors.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  KAppColors.primary.withValues(alpha: 0.3),
                  KAppColors.tertiary.withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.spa_outlined,
              color: KAppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mindful Moment',
                  style: KAppTextStyles.labelMedium.copyWith(
                    color: KAppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  moment['quote']!,
                  style: KAppTextStyles.titleMedium.copyWith(
                    color: KAppColors.getOnBackground(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: KAppColors.getOnBackground(context).withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        moment['tip']!,
                        style: KAppTextStyles.bodySmall.copyWith(
                          color: KAppColors.getOnBackground(context).withValues(alpha: 0.7),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
