import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class MoodTrackingService {
  static final MoodTrackingService instance = MoodTrackingService._init();
  static Database? _database;

  MoodTrackingService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mood_tracking.db');
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
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE mood_entries (
        id $idType,
        articleId $textType,
        preReadingMood $textType,
        preReadingIntensity $integerType,
        postReadingMood TEXT,
        postReadingIntensity INTEGER,
        timestamp $textType,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_timestamp ON mood_entries(timestamp)
    ''');
  }

  // Insert pre-reading mood
  Future<int> savePreReadingMood({
    required String articleId,
    required String mood,
    required int intensity,
    String? notes,
  }) async {
    final db = await instance.database;
    return await db.insert('mood_entries', {
      'articleId': articleId,
      'preReadingMood': mood,
      'preReadingIntensity': intensity,
      'timestamp': DateTime.now().toIso8601String(),
      'notes': notes ?? '',
    });
  }

  // Update with post-reading mood
  Future<int> savePostReadingMood({
    required int entryId,
    required String mood,
    required int intensity,
    String? notes,
  }) async {
    final db = await instance.database;
    return await db.update(
      'mood_entries',
      {
        'postReadingMood': mood,
        'postReadingIntensity': intensity,
        'notes': notes ?? '',
      },
      where: 'id = ?',
      whereArgs: [entryId],
    );
  }

  // Get mood entries for a specific article
  Future<List<Map<String, dynamic>>> getMoodEntriesForArticle(
      String articleId) async {
    final db = await instance.database;
    return await db.query(
      'mood_entries',
      where: 'articleId = ?',
      whereArgs: [articleId],
      orderBy: 'timestamp DESC',
    );
  }

  // Get all mood entries
  Future<List<Map<String, dynamic>>> getAllMoodEntries() async {
    final db = await instance.database;
    return await db.query(
      'mood_entries',
      orderBy: 'timestamp DESC',
    );
  }

  // Get mood trends (last 7 days)
  Future<Map<String, dynamic>> getMoodTrends() async {
    final db = await instance.database;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    final result = await db.query(
      'mood_entries',
      where: 'timestamp >= ? AND postReadingMood IS NOT NULL',
      whereArgs: [sevenDaysAgo.toIso8601String()],
      orderBy: 'timestamp DESC',
    );

    if (result.isEmpty) {
      return {
        'averagePreIntensity': 0.0,
        'averagePostIntensity': 0.0,
        'moodImprovement': 0.0,
        'totalEntries': 0,
      };
    }

    double totalPreIntensity = 0;
    double totalPostIntensity = 0;
    int positiveChanges = 0;
    int negativeChanges = 0;

    for (var entry in result) {
      final preIntensity = entry['preReadingIntensity'] as int;
      final postIntensity = entry['postReadingIntensity'] as int? ?? 0;

      totalPreIntensity += preIntensity;
      totalPostIntensity += postIntensity;

      if (postIntensity > preIntensity) {
        positiveChanges++;
      } else if (postIntensity < preIntensity) {
        negativeChanges++;
      }
    }

    final avgPreIntensity = totalPreIntensity / result.length;
    final avgPostIntensity = totalPostIntensity / result.length;
    final moodChange = avgPostIntensity - avgPreIntensity;

    return {
      'averagePreIntensity': avgPreIntensity,
      'averagePostIntensity': avgPostIntensity,
      'moodImprovement': moodChange,
      'totalEntries': result.length,
      'positiveChanges': positiveChanges,
      'negativeChanges': negativeChanges,
    };
  }

  // Close database
  Future<void> close() async {
    final db = await instance.database;
    await db.close();
  }
}

// Mood options
class MoodOption {
  final String label;
  final String emoji;
  final String value;

  const MoodOption({
    required this.label,
    required this.emoji,
    required this.value,
  });
}

class MoodOptions {
  static const List<MoodOption> options = [
    MoodOption(label: 'Calm', emoji: '😌', value: 'calm'),
    MoodOption(label: 'Happy', emoji: '😊', value: 'happy'),
    MoodOption(label: 'Curious', emoji: '🤔', value: 'curious'),
    MoodOption(label: 'Neutral', emoji: '😐', value: 'neutral'),
    MoodOption(label: 'Worried', emoji: '😟', value: 'worried'),
    MoodOption(label: 'Anxious', emoji: '😰', value: 'anxious'),
    MoodOption(label: 'Sad', emoji: '😢', value: 'sad'),
    MoodOption(label: 'Frustrated', emoji: '😤', value: 'frustrated'),
  ];
}
