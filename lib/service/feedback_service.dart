import 'dart:developer';
import 'package:the_news/core/network/api_client.dart';

/// Feedback types
enum FeedbackType {
  bug,
  feature,
  improvement,
  general,
}

/// Service for managing user feedback
/// Uses ApiClient for all network requests following clean architecture
class FeedbackService {
  static final FeedbackService instance = FeedbackService._init();
  FeedbackService._init();

  final _api = ApiClient.instance;

  /// Submit feedback
  Future<bool> submitFeedback({
    required String userId,
    required String userEmail,
    required FeedbackType type,
    required String title,
    required String description,
  }) async {
    try {
      log('📝 Submitting feedback: $title');

      final response = await _api.post(
        'feedback',
        body: {
          'userId': userId,
          'userEmail': userEmail,
          'type': _feedbackTypeToString(type),
          'title': title,
          'description': description,
          'platform': 'mobile',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          log('✅ Feedback submitted successfully');
          return true;
        }
      }

      log('⚠️ Failed to submit feedback: ${_api.getErrorMessage(response)}');
      return false;
    } catch (e) {
      log('⚠️ Error submitting feedback: $e');
      return false;
    }
  }

  /// Get feedback history for a user
  Future<List<Map<String, dynamic>>> getFeedbackHistory(String userId) async {
    try {
      log('📥 Fetching feedback history');

      final response = await _api.get('feedback/user/$userId');

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          final List<dynamic> feedbackList = data['feedback'] ?? [];
          return feedbackList.cast<Map<String, dynamic>>();
        }
      }

      log('⚠️ Failed to fetch feedback history: ${_api.getErrorMessage(response)}');
      return [];
    } catch (e) {
      log('⚠️ Error fetching feedback history: $e');
      return [];
    }
  }

  /// Convert FeedbackType enum to string
  String _feedbackTypeToString(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return 'bug';
      case FeedbackType.feature:
        return 'feature';
      case FeedbackType.improvement:
        return 'improvement';
      case FeedbackType.general:
        return 'general';
    }
  }

  /// Convert string to FeedbackType enum
  FeedbackType _stringToFeedbackType(String type) {
    switch (type.toLowerCase()) {
      case 'bug':
        return FeedbackType.bug;
      case 'feature':
        return FeedbackType.feature;
      case 'improvement':
        return FeedbackType.improvement;
      default:
        return FeedbackType.general;
    }
  }
}
