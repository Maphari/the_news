import 'package:the_news/model/news_article_model.dart';

class SolutionDetectorService {
  static final SolutionDetectorService instance = SolutionDetectorService._init();

  SolutionDetectorService._init();

  // Keywords indicating solution-focused content
  final List<String> _solutionKeywords = [
    'solution',
    'how to',
    'guide',
    'tips',
    'help',
    'improve',
    'better',
    'success',
    'achievement',
    'progress',
    'innovation',
    'breakthrough',
    'recovery',
    'heal',
    'overcome',
    'resolve',
    'fix',
    'action plan',
    'strategy',
    'initiative',
    'program',
    'effort',
    'collaboration',
    'partnership',
    'agreement',
    'reform',
    'new approach',
    'development',
    'advancement',
  ];

  // Keywords indicating constructive/positive focus
  final List<String> _constructiveKeywords = [
    'build',
    'create',
    'launch',
    'introduce',
    'implement',
    'establish',
    'develop',
    'grow',
    'expand',
    'unite',
    'cooperate',
    'support',
    'assist',
    'aid',
    'donate',
    'contribute',
    'volunteer',
    'community',
    'together',
    'collective',
  ];

  // Check if article is solution-focused
  bool isSolutionFocused(ArticleModel article) {
    final titleLower = article.title.toLowerCase();
    final descriptionLower = article.description.toLowerCase();
    final contentLower = article.content.toLowerCase();

    int solutionScore = 0;

    // Check title for solution keywords (weighted more heavily)
    for (final keyword in _solutionKeywords) {
      if (titleLower.contains(keyword)) {
        solutionScore += 3;
      }
    }

    for (final keyword in _constructiveKeywords) {
      if (titleLower.contains(keyword)) {
        solutionScore += 2;
      }
    }

    // Check description
    for (final keyword in _solutionKeywords) {
      if (descriptionLower.contains(keyword)) {
        solutionScore += 2;
      }
    }

    for (final keyword in _constructiveKeywords) {
      if (descriptionLower.contains(keyword)) {
        solutionScore += 1;
      }
    }

    // Check content
    for (final keyword in _solutionKeywords) {
      if (contentLower.contains(keyword)) {
        solutionScore += 1;
      }
    }

    // Check sentiment (positive sentiment supports solution focus)
    if (article.sentiment.toLowerCase() == 'positive') {
      solutionScore += 2;
    }

    // Article is solution-focused if score is 5 or higher
    return solutionScore >= 5;
  }

  // Get solution type badge
  SolutionBadgeType? getSolutionBadgeType(ArticleModel article) {
    if (!isSolutionFocused(article)) {
      return null;
    }

    final titleLower = article.title.toLowerCase();
    final descriptionLower = article.description.toLowerCase();
    final combined = '$titleLower $descriptionLower';

    // Determine specific type of solution
    if (_containsAny(combined, ['how to', 'guide', 'tips', 'tutorial', 'step'])) {
      return SolutionBadgeType.howTo;
    } else if (_containsAny(combined, ['innovation', 'breakthrough', 'new approach', 'revolutionary'])) {
      return SolutionBadgeType.innovation;
    } else if (_containsAny(combined, ['community', 'together', 'collective', 'unite', 'volunteer'])) {
      return SolutionBadgeType.community;
    } else if (_containsAny(combined, ['success', 'achievement', 'progress', 'improvement'])) {
      return SolutionBadgeType.progress;
    } else if (_containsAny(combined, ['recovery', 'heal', 'overcome', 'resolve'])) {
      return SolutionBadgeType.recovery;
    } else {
      return SolutionBadgeType.general;
    }
  }

  bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  // Get badge label
  String getBadgeLabel(SolutionBadgeType type) {
    switch (type) {
      case SolutionBadgeType.howTo:
        return 'How-To';
      case SolutionBadgeType.innovation:
        return 'Innovation';
      case SolutionBadgeType.community:
        return 'Community Action';
      case SolutionBadgeType.progress:
        return 'Progress';
      case SolutionBadgeType.recovery:
        return 'Recovery';
      case SolutionBadgeType.general:
        return 'Solution-Focused';
    }
  }

  // Get badge icon
  String getBadgeIcon(SolutionBadgeType type) {
    switch (type) {
      case SolutionBadgeType.howTo:
        return '📚';
      case SolutionBadgeType.innovation:
        return '💡';
      case SolutionBadgeType.community:
        return '🤝';
      case SolutionBadgeType.progress:
        return '📈';
      case SolutionBadgeType.recovery:
        return '🌱';
      case SolutionBadgeType.general:
        return '✨';
    }
  }
}

enum SolutionBadgeType {
  howTo,       // Guides, tutorials, practical advice
  innovation,  // Breakthroughs, new approaches
  community,   // Community action, collaboration
  progress,    // Success stories, achievements
  recovery,    // Healing, overcoming challenges
  general,     // General solution-focused content
}
