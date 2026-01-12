import 'package:the_news/model/news_article_model.dart';
import 'package:the_news/model/reading_session_model.dart';
import 'package:the_news/service/database_service.dart';
import 'package:the_news/service/achievements_service.dart';

class ReadingTrackerService {
  static final ReadingTrackerService instance = ReadingTrackerService._init();
  final DatabaseService _db = DatabaseService.instance;

  // Current active session
  ReadingSessionModel? _currentSession;
  DateTime? _sessionStartTime;

  ReadingTrackerService._init();

  // Start tracking a reading session
  Future<void> startReadingSession(ArticleModel article) async {
    // If there's an active session, end it first
    if (_currentSession != null) {
      await endReadingSession();
    }

    _sessionStartTime = DateTime.now();

    final session = ReadingSessionModel(
      articleId: article.articleId,
      articleTitle: article.title,
      category: article.category.isNotEmpty ? article.category.first : 'General',
      sentiment: article.sentiment,
      sentimentPositive: article.sentimentStats.positive,
      sentimentNegative: article.sentimentStats.negative,
      sentimentNeutral: article.sentimentStats.neutral,
      startTime: _sessionStartTime!,
    );

    _currentSession = await _db.createSession(session);
  }

  // Update scroll depth during reading
  Future<void> updateScrollDepth(int scrollPercent) async {
    if (_currentSession == null) return;

    final updatedSession = _currentSession!.copyWith(
      scrollDepthPercent: scrollPercent,
    );

    await _db.updateSession(updatedSession);
    _currentSession = updatedSession;
  }

  // Mark article as bookmarked
  Future<void> markAsBookmarked(bool isBookmarked) async {
    if (_currentSession == null) return;

    final updatedSession = _currentSession!.copyWith(
      wasBookmarked: isBookmarked,
    );

    await _db.updateSession(updatedSession);
    _currentSession = updatedSession;
  }

  // Mark article as shared
  Future<void> markAsShared() async {
    if (_currentSession == null) return;

    final updatedSession = _currentSession!.copyWith(
      wasShared: true,
    );

    await _db.updateSession(updatedSession);
    _currentSession = updatedSession;
  }

  // End the current reading session
  Future<void> endReadingSession() async {
    if (_currentSession == null || _sessionStartTime == null) return;

    final endTime = DateTime.now();
    final duration = endTime.difference(_sessionStartTime!).inSeconds;

    // Only save sessions that lasted at least 3 seconds (to avoid accidental clicks)
    if (duration >= 3) {
      final updatedSession = _currentSession!.copyWith(
        endTime: endTime,
        durationSeconds: duration,
      );

      await _db.updateSession(updatedSession);

      // Update reading streak and check for unlocked achievements
      await AchievementsService.instance.updateStreak();
    } else {
      // Delete very short sessions
      if (_currentSession!.id != null) {
        await _db.deleteSession(_currentSession!.id!);
      }
    }

    _currentSession = null;
    _sessionStartTime = null;
  }

  // Get comprehensive reading statistics
  Future<ReadingStatsModel> getReadingStats() async {
    final totalArticles = await _db.getTotalArticlesRead();
    final totalTime = await _db.getTotalReadingTime();
    final todayArticles = await _db.getTodayArticlesRead();
    final todayTime = await _db.getTodayReadingTime();
    final goodNewsRatio = await _db.getGoodNewsRatio();
    final categories = await _db.getCategoryBreakdown();
    final recentSessions = await _db.getAllSessions();

    final averageTime = totalArticles > 0
        ? (totalTime / totalArticles) / 60.0
        : 0.0;

    return ReadingStatsModel(
      totalArticlesRead: totalArticles,
      totalReadingTimeSeconds: totalTime,
      averageReadingTimeMinutes: averageTime,
      articlesReadToday: todayArticles,
      readingTimeToday: todayTime,
      goodNewsRatio: goodNewsRatio,
      categoriesRead: categories,
      recentSessions: recentSessions.take(10).toList(),
    );
  }

  // Get quick stats for header display
  Future<Map<String, dynamic>> getQuickStats() async {
    final todayArticles = await _db.getTodayArticlesRead();
    final todayTime = await _db.getTodayReadingTime();
    final goodNewsRatio = await _db.getGoodNewsRatio();

    return {
      'articlesReadToday': todayArticles,
      'readingTimeToday': todayTime,
      'goodNewsRatio': goodNewsRatio,
    };
  }

  // Check if article has been read before
  Future<bool> hasReadArticle(String articleId) async {
    final sessions = await _db.getSessionsByArticle(articleId);
    return sessions.isNotEmpty;
  }

  // Get reading time for specific article
  Future<int> getArticleReadingTime(String articleId) async {
    final sessions = await _db.getSessionsByArticle(articleId);
    return sessions.fold<int>(
      0,
      (sum, session) => sum + session.durationSeconds,
    );
  }

  // Get current session duration (for live display)
  int getCurrentSessionDuration() {
    if (_sessionStartTime == null) return 0;
    return DateTime.now().difference(_sessionStartTime!).inSeconds;
  }

  // Check if currently tracking a session
  bool get isTracking => _currentSession != null;

  // Get current session
  ReadingSessionModel? get currentSession => _currentSession;

  // Check if daily reading limit is reached
  Future<bool> isDailyLimitReached(int limitMinutes) async {
    final todayTime = await _db.getTodayReadingTime();
    final todayMinutes = todayTime ~/ 60;
    return todayMinutes >= limitMinutes;
  }

  // Get reading time remaining for the day (in seconds)
  Future<int> getRemainingReadingTime(int limitMinutes) async {
    final todayTime = await _db.getTodayReadingTime();
    final limitSeconds = limitMinutes * 60;
    final remaining = limitSeconds - todayTime;
    return remaining > 0 ? remaining : 0;
  }

  // Get percentage of daily limit used
  Future<double> getDailyLimitPercentage(int limitMinutes) async {
    final todayTime = await _db.getTodayReadingTime();
    final limitSeconds = limitMinutes * 60;
    if (limitSeconds == 0) return 0.0;
    final percentage = (todayTime / limitSeconds) * 100;
    return percentage.clamp(0.0, 100.0);
  }
}
