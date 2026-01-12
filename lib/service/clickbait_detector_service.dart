class ClickbaitDetectorService {
  static final ClickbaitDetectorService instance = ClickbaitDetectorService._init();

  ClickbaitDetectorService._init();

  // Clickbait indicator keywords and patterns
  final List<String> _clickbaitKeywords = [
    'you won\'t believe',
    'shocking',
    'this is why',
    'the reason will shock you',
    'what happened next',
    'doctors hate',
    'one weird trick',
    'they don\'t want you to know',
    'will blow your mind',
    'the truth about',
    'you\'ve been doing it wrong',
    'this will change everything',
    'the secret to',
    'find out why',
    'here\'s what',
    'number',
    'reasons why',
    'things you need to know',
  ];

  final List<String> _sensationalWords = [
    'shocking',
    'amazing',
    'unbelievable',
    'incredible',
    'stunning',
    'mind-blowing',
    'jaw-dropping',
    'outrageous',
    'devastating',
    'explosive',
    'bombshell',
    'scandal',
    'controversial',
  ];

  // Detect if a title is clickbait
  bool isClickbait(String title) {
    final lowerTitle = title.toLowerCase();

    // Check for clickbait keywords
    for (final keyword in _clickbaitKeywords) {
      if (lowerTitle.contains(keyword)) {
        return true;
      }
    }

    // Check for excessive capitalization
    final words = title.split(' ');
    final capitalizedWords = words.where((word) {
      if (word.isEmpty) return false;
      return word == word.toUpperCase() && word.length > 1;
    }).length;

    if (capitalizedWords > words.length * 0.3) {
      return true;
    }

    // Check for multiple sensational words
    int sensationalCount = 0;
    for (final word in _sensationalWords) {
      if (lowerTitle.contains(word)) {
        sensationalCount++;
      }
    }
    if (sensationalCount >= 2) {
      return true;
    }

    // Check for excessive punctuation (!!!, ???, etc.)
    final exclamationCount = title.split('!').length - 1;
    final questionCount = title.split('?').length - 1;
    if (exclamationCount > 2 || questionCount > 1) {
      return true;
    }

    return false;
  }

  // Get clickbait score (0-100)
  int getClickbaitScore(String title) {
    int score = 0;
    final lowerTitle = title.toLowerCase();

    // Clickbait keywords (+30 points each)
    for (final keyword in _clickbaitKeywords) {
      if (lowerTitle.contains(keyword)) {
        score += 30;
      }
    }

    // Sensational words (+10 points each)
    for (final word in _sensationalWords) {
      if (lowerTitle.contains(word)) {
        score += 10;
      }
    }

    // Excessive capitalization (+20 points)
    final words = title.split(' ');
    final capitalizedWords = words.where((word) {
      if (word.isEmpty) return false;
      return word == word.toUpperCase() && word.length > 1;
    }).length;

    if (capitalizedWords > words.length * 0.3) {
      score += 20;
    }

    // Excessive punctuation (+15 points)
    final exclamationCount = title.split('!').length - 1;
    final questionCount = title.split('?').length - 1;
    if (exclamationCount > 2 || questionCount > 1) {
      score += 15;
    }

    // Numbers in title (listicles) (+10 points)
    if (RegExp(r'\b\d+\b').hasMatch(lowerTitle)) {
      score += 10;
    }

    return score.clamp(0, 100);
  }

  // Rewrite clickbait title to be more neutral
  String rewriteClickbait(String title, String? description) {
    String rewritten = title;

    // Remove excessive punctuation
    rewritten = rewritten.replaceAll(RegExp(r'!{2,}'), '');
    rewritten = rewritten.replaceAll(RegExp(r'\?{2,}'), '?');

    // Replace clickbait phrases with neutral ones
    final replacements = {
      'you won\'t believe': 'Report:',
      'shocking': 'notable',
      'this is why': 'Here\'s why',
      'the reason will shock you': '',
      'what happened next': 'subsequent events',
      'doctors hate': 'medical professionals discuss',
      'one weird trick': 'method',
      'they don\'t want you to know': '',
      'will blow your mind': 'may interest you',
      'the truth about': 'Facts about',
      'you\'ve been doing it wrong': 'alternative approach to',
      'this will change everything': 'significant development in',
      'the secret to': 'approach to',
      'find out why': 'explanation for',
      'here\'s what': 'update on',
    };

    for (final entry in replacements.entries) {
      final pattern = RegExp(entry.key, caseSensitive: false);
      rewritten = rewritten.replaceAll(pattern, entry.value);
    }

    // Remove sensational words at the start
    for (final word in _sensationalWords) {
      final pattern = RegExp('^$word\\s+', caseSensitive: false);
      rewritten = rewritten.replaceFirst(pattern, '');
    }

    // Clean up spacing
    rewritten = rewritten.replaceAll(RegExp(r'\s+'), ' ').trim();

    // If the rewrite is too short or unclear, use description
    if (rewritten.length < 20 && description != null && description.isNotEmpty) {
      // Take first sentence from description
      final sentences = description.split(RegExp(r'[.!?]'));
      if (sentences.isNotEmpty) {
        rewritten = sentences.first.trim();
      }
    }

    // Capitalize first letter
    if (rewritten.isNotEmpty) {
      rewritten = rewritten[0].toUpperCase() + rewritten.substring(1);
    }

    return rewritten;
  }

  // Get neutral title
  String getNeutralTitle(String title, String? description) {
    if (!isClickbait(title)) {
      return title;
    }
    return rewriteClickbait(title, description);
  }

  // Get title with clickbait indicator
  String getTitleWithIndicator(String title, String? description) {
    if (!isClickbait(title)) {
      return title;
    }

    final score = getClickbaitScore(title);
    String indicator;

    if (score >= 70) {
      indicator = '[CLICKBAIT] ';
    } else if (score >= 40) {
      indicator = '[SENSATIONAL] ';
    } else {
      indicator = '';
    }

    return '$indicator${rewriteClickbait(title, description)}';
  }
}
