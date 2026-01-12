import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:the_news/model/achievement_model.dart';
import 'package:the_news/service/database_service.dart';

class AchievementsService {
  static final AchievementsService instance = AchievementsService._init();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final DatabaseService _db = DatabaseService.instance;

  static const String _streakKey = 'reading_streak';
  static const String _achievementsKey = 'achievements';

  ReadingStreak? _currentStreak;
  List<Achievement>? _achievements;

  AchievementsService._init();

  // Initialize achievements
  Future<void> initialize() async {
    await _loadStreak();
    await _loadAchievements();
  }

  // Get all available achievements
  List<Achievement> get allAchievements {
    if (_achievements != null) return _achievements!;
    return _getDefaultAchievements();
  }

  List<Achievement> _getDefaultAchievements() {
    return [
      // Reading Streak Achievements
      Achievement(
        id: 'streak_3',
        title: 'Three Day Streak',
        description: 'Read mindfully for 3 days in a row',
        icon: Icons.local_fire_department,
        color: const Color(0xFFFFA726),
        type: AchievementType.readingStreak,
        targetValue: 3,
        currentValue: _currentStreak?.currentStreak ?? 0,
      ),
      Achievement(
        id: 'streak_7',
        title: 'Weekly Warrior',
        description: 'Read mindfully for 7 days in a row',
        icon: Icons.local_fire_department,
        color: const Color(0xFFFF5722),
        type: AchievementType.readingStreak,
        targetValue: 7,
        currentValue: _currentStreak?.currentStreak ?? 0,
      ),
      Achievement(
        id: 'streak_30',
        title: 'Monthly Master',
        description: 'Read mindfully for 30 days in a row',
        icon: Icons.local_fire_department,
        color: const Color(0xFFD32F2F),
        type: AchievementType.readingStreak,
        targetValue: 30,
        currentValue: _currentStreak?.currentStreak ?? 0,
      ),

      // Articles Read Achievements
      Achievement(
        id: 'articles_10',
        title: 'Getting Started',
        description: 'Read 10 articles',
        icon: Icons.menu_book,
        color: const Color(0xFF4CAF50),
        type: AchievementType.articlesRead,
        targetValue: 10,
        currentValue: 0,
      ),
      Achievement(
        id: 'articles_50',
        title: 'Well Informed',
        description: 'Read 50 articles',
        icon: Icons.menu_book,
        color: const Color(0xFF388E3C),
        type: AchievementType.articlesRead,
        targetValue: 50,
        currentValue: 0,
      ),
      Achievement(
        id: 'articles_100',
        title: 'News Enthusiast',
        description: 'Read 100 articles',
        icon: Icons.menu_book,
        color: const Color(0xFF2E7D32),
        type: AchievementType.articlesRead,
        targetValue: 100,
        currentValue: 0,
      ),

      // Good News Ratio Achievements
      Achievement(
        id: 'good_news_50',
        title: 'Positive Outlook',
        description: '50% or more of articles are positive',
        icon: Icons.wb_sunny,
        color: const Color(0xFFFFEB3B),
        type: AchievementType.goodNewsRatio,
        targetValue: 50,
        currentValue: 0,
      ),
      Achievement(
        id: 'good_news_75',
        title: 'Optimist',
        description: '75% or more of articles are positive',
        icon: Icons.wb_sunny,
        color: const Color(0xFFFFC107),
        type: AchievementType.goodNewsRatio,
        targetValue: 75,
        currentValue: 0,
      ),

      // Time Spent Achievements
      Achievement(
        id: 'time_60',
        title: 'One Hour',
        description: 'Spend 60 minutes reading',
        icon: Icons.access_time,
        color: const Color(0xFF2196F3),
        type: AchievementType.timeSpent,
        targetValue: 60,
        currentValue: 0,
      ),
      Achievement(
        id: 'time_300',
        title: 'Five Hours',
        description: 'Spend 5 hours reading',
        icon: Icons.access_time,
        color: const Color(0xFF1976D2),
        type: AchievementType.timeSpent,
        targetValue: 300,
        currentValue: 0,
      ),

      // Category Explorer
      Achievement(
        id: 'categories_5',
        title: 'Well Rounded',
        description: 'Read articles from 5 different categories',
        icon: Icons.explore,
        color: const Color(0xFF9C27B0),
        type: AchievementType.categoryExplorer,
        targetValue: 5,
        currentValue: 0,
      ),

      // Time-based Achievements
      Achievement(
        id: 'early_bird',
        title: 'Early Bird',
        description: 'Read 10 articles before 9 AM',
        icon: Icons.wb_twilight,
        color: const Color(0xFFFF9800),
        type: AchievementType.earlyBird,
        targetValue: 10,
        currentValue: 0,
      ),
      Achievement(
        id: 'night_owl',
        title: 'Night Owl',
        description: 'Read 10 articles after 9 PM',
        icon: Icons.nightlight_round,
        color: const Color(0xFF673AB7),
        type: AchievementType.nightOwl,
        targetValue: 10,
        currentValue: 0,
      ),

      // Reading Depth Achievements
      Achievement(
        id: 'deep_reader',
        title: 'Deep Reader',
        description: 'Read 10 articles with 100% scroll depth',
        icon: Icons.trending_down,
        color: const Color(0xFF00BCD4),
        type: AchievementType.deepReader,
        targetValue: 10,
        currentValue: 0,
      ),
    ];
  }

  // Load streak from storage
  Future<void> _loadStreak() async {
    final streakData = await _storage.read(key: _streakKey);
    if (streakData != null) {
      final map = json.decode(streakData);
      _currentStreak = ReadingStreak.fromMap(map);
    } else {
      _currentStreak = ReadingStreak(
        currentStreak: 0,
        longestStreak: 0,
        readDates: [],
      );
    }
  }

  // Load achievements from storage
  Future<void> _loadAchievements() async {
    final achievementsData = await _storage.read(key: _achievementsKey);
    if (achievementsData != null) {
      // Load saved achievements
      // For now, use defaults
      _achievements = _getDefaultAchievements();
    } else {
      _achievements = _getDefaultAchievements();
    }
  }

  // Get current streak
  ReadingStreak get currentStreak {
    return _currentStreak ??
        ReadingStreak(currentStreak: 0, longestStreak: 0, readDates: []);
  }

  // Update streak when user reads
  Future<void> updateStreak() async {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    _currentStreak ??= ReadingStreak(
      currentStreak: 0,
      longestStreak: 0,
      readDates: [],
    );

    // Check if already read today
    if (_currentStreak!.isActiveToday) {
      return;
    }

    // Check if streak continues
    int newStreak;
    if (_currentStreak!.streakAtRisk || _currentStreak!.lastReadDate == null) {
      newStreak = _currentStreak!.currentStreak + 1;
    } else {
      newStreak = 1; // Streak broken, start over
    }

    final newLongest = newStreak > _currentStreak!.longestStreak
        ? newStreak
        : _currentStreak!.longestStreak;

    final newDates = List<DateTime>.from(_currentStreak!.readDates)
      ..add(todayDate);

    _currentStreak = ReadingStreak(
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastReadDate: todayDate,
      readDates: newDates,
    );

    // Save to storage
    await _storage.write(
      key: _streakKey,
      value: json.encode(_currentStreak!.toMap()),
    );

    // Check for streak achievements
    await _checkAchievements();
  }

  // Check and unlock achievements
  Future<void> _checkAchievements() async {
    // Ensure achievements are loaded
    if (_achievements == null) {
      await _loadAchievements();
    }

    final totalArticles = await _db.getTotalArticlesRead();
    final totalTime = await _db.getTotalReadingTime();
    final goodNewsRatio = await _db.getGoodNewsRatio();
    final categories = await _db.getCategoryBreakdown();

    for (var achievement in _achievements!) {
      if (achievement.isUnlocked) continue;

      bool shouldUnlock = false;

      switch (achievement.type) {
        case AchievementType.readingStreak:
          shouldUnlock =
              _currentStreak!.currentStreak >= achievement.targetValue;
          achievement = achievement.copyWith(
            currentValue: _currentStreak!.currentStreak,
          );
          break;

        case AchievementType.articlesRead:
          shouldUnlock = totalArticles >= achievement.targetValue;
          achievement = achievement.copyWith(currentValue: totalArticles);
          break;

        case AchievementType.timeSpent:
          final totalMinutes = totalTime ~/ 60;
          shouldUnlock = totalMinutes >= achievement.targetValue;
          achievement = achievement.copyWith(currentValue: totalMinutes);
          break;

        case AchievementType.goodNewsRatio:
          final ratio = (goodNewsRatio * 100).toInt();
          shouldUnlock = ratio >= achievement.targetValue;
          achievement = achievement.copyWith(currentValue: ratio);
          break;

        case AchievementType.categoryExplorer:
          shouldUnlock = categories.length >= achievement.targetValue;
          achievement = achievement.copyWith(currentValue: categories.length);
          break;

        default:
          break;
      }

      if (shouldUnlock) {
        achievement = achievement.copyWith(unlockedAt: DateTime.now());
      }
    }

    // Save achievements
    await _saveAchievements();
  }

  // Save achievements to storage
  Future<void> _saveAchievements() async {
    final achievementsMap = _achievements!.map((a) => a.toMap()).toList();
    await _storage.write(
      key: _achievementsKey,
      value: json.encode(achievementsMap),
    );
  }

  // Get unlocked achievements
  List<Achievement> get unlockedAchievements {
    return allAchievements.where((a) => a.isUnlocked).toList();
  }

  // Get locked achievements
  List<Achievement> get lockedAchievements {
    return allAchievements.where((a) => !a.isUnlocked).toList();
  }

  // Get recently unlocked achievements (last 7 days)
  List<Achievement> get recentlyUnlocked {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    return unlockedAchievements
        .where((a) => a.unlockedAt!.isAfter(sevenDaysAgo))
        .toList()
      ..sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!));
  }
}
