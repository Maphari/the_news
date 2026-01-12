import 'package:flutter/material.dart';

enum AchievementType {
  readingStreak,
  articlesRead,
  timeSpent,
  goodNewsRatio,
  categoryExplorer,
  earlyBird,
  nightOwl,
  speedReader,
  deepReader,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final AchievementType type;
  final int targetValue;
  final int currentValue;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;
  double get progress => (currentValue / targetValue).clamp(0.0, 1.0);
  int get progressPercent => (progress * 100).toInt();

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    IconData? icon,
    Color? color,
    AchievementType? type,
    int? targetValue,
    int? currentValue,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.toString(),
      'targetValue': targetValue,
      'currentValue': currentValue,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  static Achievement fromMap(Map<String, dynamic> map, IconData icon, Color color) {
    return Achievement(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      icon: icon,
      color: color,
      type: AchievementType.values.firstWhere(
        (e) => e.toString() == map['type'],
      ),
      targetValue: map['targetValue'] as int,
      currentValue: map['currentValue'] as int,
      unlockedAt: map['unlockedAt'] != null
          ? DateTime.parse(map['unlockedAt'] as String)
          : null,
    );
  }
}

class ReadingStreak {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastReadDate;
  final List<DateTime> readDates;

  ReadingStreak({
    required this.currentStreak,
    required this.longestStreak,
    this.lastReadDate,
    required this.readDates,
  });

  bool get isActiveToday {
    if (lastReadDate == null) return false;
    final today = DateTime.now();
    final last = lastReadDate!;
    return today.year == last.year &&
        today.month == last.month &&
        today.day == last.day;
  }

  bool get streakAtRisk {
    if (lastReadDate == null) return true;
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final last = lastReadDate!;
    return yesterday.year == last.year &&
        yesterday.month == last.month &&
        yesterday.day == last.day;
  }

  Map<String, dynamic> toMap() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastReadDate': lastReadDate?.toIso8601String(),
      'readDates': readDates.map((d) => d.toIso8601String()).toList(),
    };
  }

  static ReadingStreak fromMap(Map<String, dynamic> map) {
    return ReadingStreak(
      currentStreak: map['currentStreak'] as int,
      longestStreak: map['longestStreak'] as int,
      lastReadDate: map['lastReadDate'] != null
          ? DateTime.parse(map['lastReadDate'] as String)
          : null,
      readDates: (map['readDates'] as List)
          .map((d) => DateTime.parse(d as String))
          .toList(),
    );
  }
}
