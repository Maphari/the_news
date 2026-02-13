import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_news/model/highlight_model.dart';

/// Service for managing article highlights and notes
class NotesHighlightsService extends ChangeNotifier {
  static final NotesHighlightsService instance = NotesHighlightsService._init();
  NotesHighlightsService._init();

  static const String _highlightsKey = 'article_highlights';
  static const String _notesKey = 'article_notes';

  final Map<String, List<HighlightModel>> _highlightsByArticle = {};
  final Map<String, List<NoteModel>> _notesByArticle = {};

  // Getters
  List<HighlightModel> get allHighlights {
    return _highlightsByArticle.values.expand((list) => list).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<NoteModel> get allNotes {
    return _notesByArticle.values.expand((list) => list).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  int get totalHighlightsCount => allHighlights.length;
  int get totalNotesCount => allNotes.length;

  /// Initialize service and load saved data
  Future<void> initialize() async {
    try {
      log('📝 Initializing notes & highlights service...');
      await _loadHighlights();
      await _loadNotes();
      log('✅ Notes & highlights loaded: $totalHighlightsCount highlights, $totalNotesCount notes');
    } catch (e) {
      log('⚠️ Error initializing notes & highlights: $e');
    }
  }

  /// Load highlights from storage
  Future<void> _loadHighlights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final highlightsJson = prefs.getString(_highlightsKey);

      if (highlightsJson != null) {
        final Map<String, dynamic> data = jsonDecode(highlightsJson);
        _highlightsByArticle.clear();

        data.forEach((articleId, highlightsList) {
          final highlights = (highlightsList as List)
              .map((json) => HighlightModel.fromJson(json as Map<String, dynamic>))
              .toList();
          _highlightsByArticle[articleId] = highlights;
        });
      }
    } catch (e) {
      log('⚠️ Error loading highlights: $e');
    }
  }

  /// Load notes from storage
  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_notesKey);

      if (notesJson != null) {
        final Map<String, dynamic> data = jsonDecode(notesJson);
        _notesByArticle.clear();

        data.forEach((articleId, notesList) {
          final notes = (notesList as List)
              .map((json) => NoteModel.fromJson(json as Map<String, dynamic>))
              .toList();
          _notesByArticle[articleId] = notes;
        });
      }
    } catch (e) {
      log('⚠️ Error loading notes: $e');
    }
  }

  /// Save highlights to storage
  Future<void> _saveHighlights() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _highlightsByArticle.map(
        (articleId, highlights) => MapEntry(
          articleId,
          highlights.map((h) => h.toJson()).toList(),
        ),
      );
      await prefs.setString(_highlightsKey, jsonEncode(data));
      log('💾 Highlights saved');
    } catch (e) {
      log('⚠️ Error saving highlights: $e');
    }
  }

  /// Save notes to storage
  Future<void> _saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _notesByArticle.map(
        (articleId, notes) => MapEntry(
          articleId,
          notes.map((n) => n.toJson()).toList(),
        ),
      );
      await prefs.setString(_notesKey, jsonEncode(data));
      log('💾 Notes saved');
    } catch (e) {
      log('⚠️ Error saving notes: $e');
    }
  }

  // ==================== HIGHLIGHTS ====================

  /// Get highlights for a specific article
  List<HighlightModel> getHighlightsForArticle(String articleId) {
    return _highlightsByArticle[articleId] ?? [];
  }

  /// Add a new highlight
  Future<void> addHighlight(HighlightModel highlight) async {
    final articleHighlights = _highlightsByArticle[highlight.articleId] ?? [];
    articleHighlights.add(highlight);
    _highlightsByArticle[highlight.articleId] = articleHighlights;

    notifyListeners();
    await _saveHighlights();
    final previewLength = highlight.highlightedText.length < 30
        ? highlight.highlightedText.length
        : 30;
    log('✨ Highlight added: "${highlight.highlightedText.substring(0, previewLength)}..."');
  }

  /// Update an existing highlight
  Future<void> updateHighlight(HighlightModel highlight) async {
    final articleHighlights = _highlightsByArticle[highlight.articleId];
    if (articleHighlights == null) return;

    final index = articleHighlights.indexWhere((h) => h.highlightId == highlight.highlightId);
    if (index != -1) {
      articleHighlights[index] = highlight;
      notifyListeners();
      await _saveHighlights();
      log('📝 Highlight updated');
    }
  }

  /// Delete a highlight
  Future<void> deleteHighlight(String articleId, String highlightId) async {
    final articleHighlights = _highlightsByArticle[articleId];
    if (articleHighlights == null) return;

    articleHighlights.removeWhere((h) => h.highlightId == highlightId);
    if (articleHighlights.isEmpty) {
      _highlightsByArticle.remove(articleId);
    }

    notifyListeners();
    await _saveHighlights();
    log('🗑️ Highlight deleted');
  }

  /// Search highlights by text
  List<HighlightModel> searchHighlights(String query) {
    if (query.trim().isEmpty) return allHighlights;

    final lowerQuery = query.toLowerCase();
    return allHighlights.where((highlight) {
      return highlight.highlightedText.toLowerCase().contains(lowerQuery) ||
          highlight.articleTitle.toLowerCase().contains(lowerQuery) ||
          (highlight.note?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Get highlights by color
  List<HighlightModel> getHighlightsByColor(HighlightColor color) {
    return allHighlights.where((h) => h.color == color).toList();
  }

  // ==================== NOTES ====================

  /// Get notes for a specific article
  List<NoteModel> getNotesForArticle(String articleId) {
    return _notesByArticle[articleId] ?? [];
  }

  /// Add a new note
  Future<void> addNote(NoteModel note) async {
    final articleNotes = _notesByArticle[note.articleId] ?? [];
    articleNotes.add(note);
    _notesByArticle[note.articleId] = articleNotes;

    notifyListeners();
    await _saveNotes();
    log('📝 Note added for article: ${note.articleTitle}');
  }

  /// Update an existing note
  Future<void> updateNote(NoteModel note) async {
    final articleNotes = _notesByArticle[note.articleId];
    if (articleNotes == null) return;

    final index = articleNotes.indexWhere((n) => n.noteId == note.noteId);
    if (index != -1) {
      articleNotes[index] = note.copyWith(updatedAt: DateTime.now());
      notifyListeners();
      await _saveNotes();
      log('📝 Note updated');
    }
  }

  /// Delete a note
  Future<void> deleteNote(String articleId, String noteId) async {
    final articleNotes = _notesByArticle[articleId];
    if (articleNotes == null) return;

    articleNotes.removeWhere((n) => n.noteId == noteId);
    if (articleNotes.isEmpty) {
      _notesByArticle.remove(articleId);
    }

    notifyListeners();
    await _saveNotes();
    log('🗑️ Note deleted');
  }

  /// Search notes by text
  List<NoteModel> searchNotes(String query) {
    if (query.trim().isEmpty) return allNotes;

    final lowerQuery = query.toLowerCase();
    return allNotes.where((note) {
      return note.content.toLowerCase().contains(lowerQuery) ||
          note.articleTitle.toLowerCase().contains(lowerQuery) ||
          note.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  /// Get notes by tag
  List<NoteModel> getNotesByTag(String tag) {
    return allNotes.where((n) => n.tags.contains(tag)).toList();
  }

  /// Get all unique tags
  List<String> getAllTags() {
    final tags = <String>{};
    for (final notesList in _notesByArticle.values) {
      for (final note in notesList) {
        tags.addAll(note.tags);
      }
    }
    return tags.toList()..sort();
  }

  // ==================== EXPORT ====================

  /// Export all highlights and notes as JSON
  String exportAsJson() {
    final data = {
      'highlights': allHighlights.map((h) => h.toJson()).toList(),
      'notes': allNotes.map((n) => n.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
    return jsonEncode(data);
  }

  /// Export highlights and notes as formatted text
  String exportAsText() {
    final buffer = StringBuffer();
    buffer.writeln('MY HIGHLIGHTS & NOTES');
    buffer.writeln('=' * 50);
    buffer.writeln('Exported: ${DateTime.now().toString()}');
    buffer.writeln();

    // Export highlights
    buffer.writeln('HIGHLIGHTS ($totalHighlightsCount)');
    buffer.writeln('-' * 50);
    for (final highlight in allHighlights) {
      buffer.writeln();
      buffer.writeln('Article: ${highlight.articleTitle}');
      buffer.writeln('Color: ${highlight.color.label}');
      buffer.writeln('Text: "${highlight.highlightedText}"');
      if (highlight.note != null) {
        buffer.writeln('Note: ${highlight.note}');
      }
      buffer.writeln('Date: ${highlight.createdAt}');
      buffer.writeln();
    }

    // Export notes
    buffer.writeln();
    buffer.writeln('NOTES ($totalNotesCount)');
    buffer.writeln('-' * 50);
    for (final note in allNotes) {
      buffer.writeln();
      buffer.writeln('Article: ${note.articleTitle}');
      buffer.writeln('Content: ${note.content}');
      if (note.tags.isNotEmpty) {
        buffer.writeln('Tags: ${note.tags.join(", ")}');
      }
      buffer.writeln('Created: ${note.createdAt}');
      if (note.updatedAt != null) {
        buffer.writeln('Updated: ${note.updatedAt}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Clear all highlights and notes
  Future<void> clearAll() async {
    _highlightsByArticle.clear();
    _notesByArticle.clear();
    notifyListeners();
    await _saveHighlights();
    await _saveNotes();
    log('🗑️ All highlights and notes cleared');
  }
}
