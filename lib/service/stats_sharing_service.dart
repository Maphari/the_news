import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:the_news/model/reading_session_model.dart';
import 'package:the_news/service/reading_tracker_service.dart';

class StatsSharingService {
  static final StatsSharingService instance = StatsSharingService._init();
  final ReadingTrackerService _tracker = ReadingTrackerService.instance;

  StatsSharingService._init();

  // Share today's reading stats
  Future<void> shareTodayStats() async {
    final stats = await _tracker.getQuickStats();
    final articlesRead = stats['articlesReadToday'] as int;
    final readingTime = stats['readingTimeToday'] as int;
    final goodNewsRatio = stats['goodNewsRatio'] as double;

    final text =
        '''
📰 My Mindful News Stats Today

📖 Articles Read: $articlesRead
⏱️ Reading Time: ${readingTime ~/ 60} min
😊 Good News Ratio: ${(goodNewsRatio * 100).toInt()}%

Building healthier news habits! 🌱

#MindfulNews #MindfulReading
''';

    await Share.share(text);
  }

  // Share weekly wellness report
  Future<void> shareWeeklyReport({
    required int totalArticles,
    required int totalMinutes,
    required int daysActive,
    required double goodNewsRatio,
    required int currentStreak,
    required String wellnessScore,
  }) async {
    final text =
        '''
📊 My Weekly Mindful News Report

✨ Wellness Score: $wellnessScore

📖 Articles Read: $totalArticles
⏱️ Total Time: $totalMinutes min
📅 Active Days: $daysActive/7
😊 Positive Content: ${(goodNewsRatio * 100).toInt()}%
🔥 Current Streak: $currentStreak days

Making mindful reading a habit! 🌱

#MindfulNews #WellnessJourney
''';

    await Share.share(text);
  }

  // Share achievement unlock
  Future<void> shareAchievement({
    required String title,
    required String description,
  }) async {
    final text =
        '''
🏆 Achievement Unlocked!

$title
$description

Building better news habits with Mindful News! 🌱

#MindfulNews #Achievement
''';

    await Share.share(text);
  }

  // Share reading streak
  Future<void> shareStreak({
    required int currentStreak,
    required int longestStreak,
  }) async {
    final emoji = currentStreak >= 30
        ? '🔥🔥🔥'
        : currentStreak >= 7
        ? '🔥🔥'
        : '🔥';

    final text =
        '''
$emoji Reading Streak Achievement!

Current Streak: $currentStreak days
Longest Streak: $longestStreak days

Consistency is key to mindful reading! 📚

#MindfulNews #ReadingStreak #Consistency
''';

    await Share.share(text);
  }

  // Generate stats card image (for future enhancement)
  Future<void> shareStatsAsImage(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/mindful_news_stats.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(pngBytes);

      await Share.shareXFiles([
        XFile(imagePath),
      ], text: 'My Mindful News Stats 📊');
    } catch (e) {
      debugPrint('Error sharing stats as image: $e');
    }
  }

  // Get shareable text for stats
  String getShareableStatsText(ReadingStatsModel stats) {
    return '''
📊 My Mindful News Journey

📚 Total Articles: ${stats.totalArticlesRead}
⏱️ Total Time: ${(stats.totalReadingTimeSeconds / 3600).toStringAsFixed(1)} hours
📈 Average: ${stats.averageReadingTimeMinutes.toStringAsFixed(1)} min per article
😊 Good News Ratio: ${(stats.goodNewsRatio * 100).toInt()}%

Today's Activity:
📖 ${stats.articlesReadToday} articles
⏱️ ${(stats.readingTimeToday / 60).toInt()} minutes

Building healthier news consumption habits! 🌱

#MindfulNews #WellnessJourney
''';
  }
}
