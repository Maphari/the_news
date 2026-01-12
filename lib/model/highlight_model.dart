/// Model for text highlights in articles
class HighlightModel {
  final String highlightId;
  final String articleId;
  final String articleTitle;
  final String highlightedText;
  final int startIndex;
  final int endIndex;
  final HighlightColor color;
  final DateTime createdAt;
  final String? note;

  const HighlightModel({
    required this.highlightId,
    required this.articleId,
    required this.articleTitle,
    required this.highlightedText,
    required this.startIndex,
    required this.endIndex,
    required this.color,
    required this.createdAt,
    this.note,
  });

  HighlightModel copyWith({
    String? highlightId,
    String? articleId,
    String? articleTitle,
    String? highlightedText,
    int? startIndex,
    int? endIndex,
    HighlightColor? color,
    DateTime? createdAt,
    String? note,
  }) {
    return HighlightModel(
      highlightId: highlightId ?? this.highlightId,
      articleId: articleId ?? this.articleId,
      articleTitle: articleTitle ?? this.articleTitle,
      highlightedText: highlightedText ?? this.highlightedText,
      startIndex: startIndex ?? this.startIndex,
      endIndex: endIndex ?? this.endIndex,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'highlightId': highlightId,
      'articleId': articleId,
      'articleTitle': articleTitle,
      'highlightedText': highlightedText,
      'startIndex': startIndex,
      'endIndex': endIndex,
      'color': color.name,
      'createdAt': createdAt.toIso8601String(),
      'note': note,
    };
  }

  factory HighlightModel.fromJson(Map<String, dynamic> json) {
    return HighlightModel(
      highlightId: json['highlightId'] as String,
      articleId: json['articleId'] as String,
      articleTitle: json['articleTitle'] as String,
      highlightedText: json['highlightedText'] as String,
      startIndex: json['startIndex'] as int,
      endIndex: json['endIndex'] as int,
      color: HighlightColor.values.firstWhere(
        (e) => e.name == json['color'],
        orElse: () => HighlightColor.yellow,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      note: json['note'] as String?,
    );
  }
}

/// Available highlight colors
enum HighlightColor {
  yellow(0xFFFFEB3B, 'Yellow', 'Bright and clear'),
  green(0xFF4CAF50, 'Green', 'Important points'),
  blue(0xFF2196F3, 'Blue', 'Key concepts'),
  pink(0xFFE91E63, 'Pink', 'Questions'),
  orange(0xFFFF9800, 'Orange', 'To review');

  final int colorValue;
  final String label;
  final String description;

  const HighlightColor(this.colorValue, this.label, this.description);

  /// Get Color object from int value
  int get value => colorValue;
}

/// Model for article notes
class NoteModel {
  final String noteId;
  final String articleId;
  final String articleTitle;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> tags;

  const NoteModel({
    required this.noteId,
    required this.articleId,
    required this.articleTitle,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.tags = const [],
  });

  NoteModel copyWith({
    String? noteId,
    String? articleId,
    String? articleTitle,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
  }) {
    return NoteModel(
      noteId: noteId ?? this.noteId,
      articleId: articleId ?? this.articleId,
      articleTitle: articleTitle ?? this.articleTitle,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'noteId': noteId,
      'articleId': articleId,
      'articleTitle': articleTitle,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'tags': tags,
    };
  }

  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      noteId: json['noteId'] as String,
      articleId: json['articleId'] as String,
      articleTitle: json['articleTitle'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}
