import 'package:flutter/material.dart';
import 'package:the_news/constant/theme/default_theme.dart';
import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/register_login_success_model.dart';
import 'package:the_news/service/article_access_service.dart';
import 'package:the_news/service/calm_mode_service.dart';
import 'package:the_news/service/engagement_service.dart';
import 'package:the_news/service/realtime_engagement_service.dart';
import 'package:the_news/view/widgets/reading_time_badge.dart';
import 'card_components/live_badge.dart';
import 'card_components/author_row.dart';
import 'card_components/action_buttons.dart';

// Card color theme model
class CardColorTheme {
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;
  final Color buttonColor;

  const CardColorTheme({
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.buttonColor,
  });
}

class FeaturedNewsCard extends StatefulWidget {
  const FeaturedNewsCard({
    super.key,
    required this.article,
    this.isBackground = false,
    this.user,
    this.cardIndex = 0,
    this.showActionButtons = false, // New parameter to control action buttons visibility
    this.height,
    this.width,
  });

  final ArticleModel article;
  final bool isBackground;
  final RegisterLoginUserSuccessModel? user;
  final int cardIndex;
  final bool showActionButtons;
  final double? height;
  final double? width;

  @override
  State<FeaturedNewsCard> createState() => _FeaturedNewsCardState();
}

class _FeaturedNewsCardState extends State<FeaturedNewsCard> {
  final EngagementService _engagementService = EngagementService.instance;
  final RealtimeEngagementService _realtimeEngagementService = RealtimeEngagementService.instance;

  // Get theme-aware card color variations
  List<CardColorTheme> _getCardThemes(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      // Dark mode themes
      return [
        CardColorTheme(
          backgroundColor: Color(0xFFFFE8E5), // Soft coral/pink
          textColor: Colors.black,
          accentColor: Color(0xFFFF6B6B),
          buttonColor: Color(0xFFD64545),
        ),
        CardColorTheme(
          backgroundColor: Color(0xFFFFF2C5), // Light yellow
          textColor: Colors.black,
          accentColor: Color(0xFFFFD93D),
          buttonColor: Color(0xFFE5C135),
        ),
        CardColorTheme(
          backgroundColor: Color(0xFFE0F1FF), // Light blue
          textColor: Colors.black,
          accentColor: Color(0xFF6BCF7F),
          buttonColor: Color(0xFF5BB56F),
        ),
        CardColorTheme(
          backgroundColor: Color(0xFFE8F5E9), // Soft green
          textColor: Colors.black,
          accentColor: Color(0xFF4CAF50),
          buttonColor: Color(0xFF388E3C),
        ),
      ];
    } else {
      // Light mode themes
      return [
        CardColorTheme(
          backgroundColor: Color(0xFFFFE8E5), // Soft coral/pink
          textColor: Colors.black,
          accentColor: Color(0xFFFF6B6B),
          buttonColor: Color(0xFFD64545),
        ),
        CardColorTheme(
          backgroundColor: Color(0xFFE3F2FD), // Soft blue
          textColor: Colors.black,
          accentColor: Color(0xFF2196F3),
          buttonColor: Color(0xFF1976D2),
        ),
        CardColorTheme(
          backgroundColor: Color(0xFFF3E5F5), // Soft purple
          textColor: Colors.black,
          accentColor: Color(0xFF9C27B0),
          buttonColor: Color(0xFF7B1FA2),
        ),
        CardColorTheme(
          backgroundColor: Color(0xFFE8F5E9), // Soft green
          textColor: Colors.black,
          accentColor: Color(0xFF4CAF50),
          buttonColor: Color(0xFF388E3C),
        ),
      ];
    }
  }

  CardColorTheme _getTheme(BuildContext context) {
    final themes = _getCardThemes(context);
    return themes[widget.cardIndex % themes.length];
  }

  @override
  void initState() {
    super.initState();
    // Load engagement data and start real-time listener when card is displayed
    if (!widget.isBackground && widget.user != null) {
      _engagementService.getEngagement(widget.article.articleId, userId: widget.user!.userId);
      // Start real-time listener for automatic updates
      _realtimeEngagementService.listenToArticleEngagement(
        widget.article.articleId,
        userId: widget.user!.userId,
      );
    }
  }

  @override
  void dispose() {
    // Stop real-time listener when card is removed
    if (!widget.isBackground) {
      _realtimeEngagementService.stopListeningToArticle(widget.article.articleId);
    }
    super.dispose();
  }

  Future<void> _navigateToArticleDetail(BuildContext context) async {
    await ArticleAccessService.instance.navigateToArticle(context, widget.article);
  }

  @override
  Widget build(BuildContext context) {
    final double defaultHeight = MediaQuery.of(context).size.height * 0.65;
    final double cardHeight = widget.height ?? defaultHeight;
    final double cardWidth = widget.width ?? double.infinity;
    final wellnessScore = CalmModeService.instance.getArticleWellnessScore(widget.article);

    return GestureDetector(
      onTap: widget.isBackground ? null : () => _navigateToArticleDetail(context),
      child: Container(
        height: cardHeight,
        width: cardWidth,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: widget.isBackground ? KAppColors.secondary : _getTheme(context).backgroundColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: widget.isBackground
            ? const SizedBox.expand()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header Row ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const LiveBadge(),
                          const SizedBox(height: 8),
                          WellnessScoreBadge(score: wellnessScore),
                        ],
                      ),
                      if (widget.article.imageUrl != null)
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              widget.article.imageUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: _getTheme(context).accentColor.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    color: _getTheme(context).textColor.withValues(alpha: 0.5),
                                    size: 24,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // --- Title ---
                  Text(
                    widget.article.title,
                    style: KAppTextStyles.displaySmall.copyWith(
                      color: _getTheme(context).textColor,
                      fontSize: 30,
                      height: 1.5,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // --- Date & Reading Time ---
                  Row(
                    children: [
                      Text(
                        'Published ${widget.article.pubDate.toLocal().toString().split(' ')[0]}',
                        style: KAppTextStyles.bodySmall.copyWith(
                          color: _getTheme(context).textColor.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ReadingTimeCardBadge(
                        text: widget.article.content,
                        backgroundColor: _getTheme(context).textColor.withValues(alpha: 0.1),
                        textColor: _getTheme(context).textColor.withValues(alpha: 0.7),
                      ),
                    ],
                  ),

                  // --- Flexible Space 1 ---
                  // const Spacer(),
                  const SizedBox(height: 12),

                  // --- Author Info ---
                  AuthorRow(
                    authorName: widget.article.sourceName,
                    sourceIcon: widget.article.sourceIcon,
                    avatarColor: _getTheme(context).accentColor,
                    user: widget.user,
                    textColor: _getTheme(context).textColor,
                  ),
                  const SizedBox(height: 16),

                  // --- Description ---
                  Text(
                    widget.article.description,
                    style: KAppTextStyles.bodyLarge.copyWith(
                      color: _getTheme(context).textColor.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const Spacer(),

                  // --- Bottom Action Buttons ---
                  if (widget.showActionButtons && widget.user != null)
                    ActionButtons(
                      article: widget.article,
                      user: widget.user!,
                      buttonColor: _getTheme(context).buttonColor,
                    ),
                ],
              ),
      ),
    );
  }
}

class WellnessScoreBadge extends StatelessWidget {
  final int score;

  const WellnessScoreBadge({super.key, required this.score});

  Color _getScoreColor(int score) {
    if (score > 70) return const Color(0xFF10B981); // Green
    if (score > 40) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Red
  }

  IconData _getScoreIcon(int score) {
    if (score > 70) return Icons.sentiment_very_satisfied;
    if (score > 40) return Icons.sentiment_neutral;
    return Icons.sentiment_very_dissatisfied;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getScoreColor(score).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getScoreColor(score).withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getScoreIcon(score), color: _getScoreColor(score), size: 14),
          const SizedBox(width: 4),
          Text(
            'Score: $score',
            style: TextStyle(
              color: _getScoreColor(score),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
