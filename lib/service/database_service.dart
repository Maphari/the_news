import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:the_news/model/reading_session_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('the_news.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE reading_sessions (
        id $idType,
        articleId $textType,
        articleTitle $textType,
        category $textType,
        sentiment $textType,
        sentimentPositive $realType,
        sentimentNegative $realType,
        sentimentNeutral $realType,
        startTime $textType,
        endTime TEXT,
        durationSeconds $integerType,
        scrollDepthPercent $integerType,
        wasBookmarked $integerType,
        wasShared $integerType
      )
    ''');

    // Create index for faster queries
    await db.execute('''
      CREATE INDEX idx_article_id ON reading_sessions(articleId)
    ''');

    await db.execute('''
      CREATE INDEX idx_start_time ON reading_sessions(startTime)
    ''');
  }

  // Insert a new reading session
  Future<ReadingSessionModel> createSession(
      ReadingSessionModel session) async {
    final db = await instance.database;
    final id = await db.insert('reading_sessions', session.toMap());
    return session.copyWith(id: id);
  }

  // Update an existing session
  Future<int> updateSession(ReadingSessionModel session) async {
    final db = await instance.database;
    return db.update(
      'reading_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  // Get session by ID
  Future<ReadingSessionModel?> getSession(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'reading_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return ReadingSessionModel.fromMap(maps.first);
    }
    return null;
  }

  // Get all sessions
  Future<List<ReadingSessionModel>> getAllSessions() async {
    final db = await instance.database;
    final result = await db.query(
      'reading_sessions',
      orderBy: 'startTime DESC',
    );

    return result.map((map) => ReadingSessionModel.fromMap(map)).toList();
  }

  // Get sessions for a specific article
  Future<List<ReadingSessionModel>> getSessionsByArticle(
      String articleId) async {
    final db = await instance.database;
    final result = await db.query(
      'reading_sessions',
      where: 'articleId = ?',
      whereArgs: [articleId],
      orderBy: 'startTime DESC',
    );

    return result.map((map) => ReadingSessionModel.fromMap(map)).toList();
  }

  // Get sessions within a date range
  Future<List<ReadingSessionModel>> getSessionsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await instance.database;
    final result = await db.query(
      'reading_sessions',
      where: 'startTime BETWEEN ? AND ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'startTime DESC',
    );

    return result.map((map) => ReadingSessionModel.fromMap(map)).toList();
  }

  // Alias for getSessionsByDateRange
  Future<List<ReadingSessionModel>> getSessionsBetweenDates(
    DateTime start,
    DateTime end,
  ) async {
    return getSessionsByDateRange(start, end);
  }

  // Get today's sessions
  Future<List<ReadingSessionModel>> getTodaySessions() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return getSessionsByDateRange(startOfDay, endOfDay);
  }

  // Get total reading time (in seconds)
  Future<int> getTotalReadingTime() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(durationSeconds) as total FROM reading_sessions',
    );

    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as int;
    }
    return 0;
  }

  // Get total reading time for today (in seconds)
  Future<int> getTodayReadingTime() async {
    final sessions = await getTodaySessions();
    return sessions.fold<int>(
      0,
      (sum, session) => sum + session.durationSeconds,
    );
  }

  // Get total articles read count
  Future<int> getTotalArticlesRead() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(DISTINCT articleId) as count FROM reading_sessions',
    );

    if (result.isNotEmpty) {
      return result.first['count'] as int;
    }
    return 0;
  }

  // Get today's articles read count
  Future<int> getTodayArticlesRead() async {
    final sessions = await getTodaySessions();
    final uniqueArticles = <String>{};
    for (var session in sessions) {
      uniqueArticles.add(session.articleId);
    }
    return uniqueArticles.length;
  }

  // Get good news ratio (percentage of positive articles)
  Future<double> getGoodNewsRatio() async {
    final db = await instance.database;
    final totalResult = await db.rawQuery(
      'SELECT COUNT(DISTINCT articleId) as count FROM reading_sessions',
    );
    final positiveResult = await db.rawQuery(
      'SELECT COUNT(DISTINCT articleId) as count FROM reading_sessions WHERE sentiment = ?',
      ['positive'],
    );

    final total = totalResult.first['count'] as int;
    final positive = positiveResult.first['count'] as int;

    if (total == 0) return 0.0;
    return positive / total;
  }

  // Get category breakdown
  Future<Map<String, int>> getCategoryBreakdown() async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT category, COUNT(*) as count FROM reading_sessions GROUP BY category',
    );

    final breakdown = <String, int>{};
    for (var row in result) {
      breakdown[row['category'] as String] = row['count'] as int;
    }
    return breakdown;
  }

  // Get current reading streak (consecutive days)
  Future<int> getCurrentStreak() async {
    final db = await instance.database;

    // Get all distinct dates with reading sessions, ordered by date DESC
    final result = await db.rawQuery('''
      SELECT DISTINCT DATE(startTime) as reading_date
      FROM reading_sessions
      ORDER BY reading_date DESC
    ''');

    if (result.isEmpty) return 0;

    int streak = 0;
    DateTime? previousDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var row in result) {
      final dateStr = row['reading_date'] as String;
      final date = DateTime.parse(dateStr);
      final readingDate = DateTime(date.year, date.month, date.day);

      if (streak == 0) {
        // First iteration - check if it's today or yesterday
        if (readingDate.isAtSameMomentAs(today) ||
            readingDate.isAtSameMomentAs(today.subtract(const Duration(days: 1)))) {
          streak = 1;
          previousDate = readingDate;
        } else {
          // No recent reading activity
          break;
        }
      } else {
        // Check if this date is consecutive with the previous date
        final expectedDate = previousDate!.subtract(const Duration(days: 1));
        if (readingDate.isAtSameMomentAs(expectedDate)) {
          streak++;
          previousDate = readingDate;
        } else {
          // Streak broken
          break;
        }
      }
    }

    return streak;
  }

  // Delete a session
  Future<int> deleteSession(int id) async {
    final db = await instance.database;
    return await db.delete(
      'reading_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete all sessions (for testing/reset)
  Future<int> deleteAllSessions() async {
    final db = await instance.database;
    return await db.delete('reading_sessions');
  }

  // Close database
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}
