import 'dart:developer';
import 'package:the_news/core/network/api_client.dart';

/// Service to export user data from backend
class AccountExportService {
  static final AccountExportService instance = AccountExportService._init();
  AccountExportService._init();

  final ApiClient _api = ApiClient.instance;

  Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      final response = await _api.get(
        'users/$userId/export',
        requiresAuth: true,
        timeout: const Duration(seconds: 30),
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true) {
          return data['export'] as Map<String, dynamic>;
        }
      }

      throw Exception(_api.getErrorMessage(response));
    } catch (e) {
      log('⚠️ Export error: $e');
      rethrow;
    }
  }
}
