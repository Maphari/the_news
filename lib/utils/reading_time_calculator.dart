/// Utility class to calculate estimated reading time for articles
class ReadingTimeCalculator {
  // Average reading speed in words per minute (WPM)
  // Studies show average adult reads 200-250 WPM for comprehension
  static const int _averageWPM = 225;

  /// Calculate reading time in minutes for given text
  /// Returns a formatted string like "5 min read" or "< 1 min read"
  static String calculateReadingTime(String text) {
    if (text.isEmpty) return '< 1 min read';

    final wordCount = _countWords(text);
    final minutes = (wordCount / _averageWPM).ceil();

    if (minutes < 1) {
      return '< 1 min read';
    } else if (minutes == 1) {
      return '1 min read';
    } else {
      return '$minutes min read';
    }
  }

  /// Calculate reading time and return just the number
  static int calculateReadingMinutes(String text) {
    if (text.isEmpty) return 0;

    final wordCount = _countWords(text);
    final minutes = (wordCount / _averageWPM).ceil();

    return minutes < 1 ? 1 : minutes;
  }

  /// Count words in a text string
  static int _countWords(String text) {
    // Remove extra whitespace and split by spaces
    final words = text.trim().split(RegExp(r'\s+'));
    return words.where((word) => word.isNotEmpty).length;
  }

  /// Get reading time with custom WPM (for accessibility settings)
  static String calculateReadingTimeCustomWPM(String text, int customWPM) {
    if (text.isEmpty || customWPM <= 0) return '< 1 min read';

    final wordCount = _countWords(text);
    final minutes = (wordCount / customWPM).ceil();

    if (minutes < 1) {
      return '< 1 min read';
    } else if (minutes == 1) {
      return '1 min read';
    } else {
      return '$minutes min read';
    }
  }

  /// Get detailed reading stats
  static ReadingTimeStats getReadingStats(String text) {
    final wordCount = _countWords(text);
    final minutes = (wordCount / _averageWPM).ceil();
    final seconds = ((wordCount / _averageWPM) * 60).round();

    return ReadingTimeStats(
      wordCount: wordCount,
      estimatedMinutes: minutes < 1 ? 1 : minutes,
      estimatedSeconds: seconds,
      formattedTime: calculateReadingTime(text),
    );
  }
}

/// Model for detailed reading time statistics
class ReadingTimeStats {
  final int wordCount;
  final int estimatedMinutes;
  final int estimatedSeconds;
  final String formattedTime;

  const ReadingTimeStats({
    required this.wordCount,
    required this.estimatedMinutes,
    required this.estimatedSeconds,
    required this.formattedTime,
  });
}
