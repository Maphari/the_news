import 'package:flutter/material.dart';
import 'package:the_news/service/offline_reading_service.dart';
import 'dart:async';

class BackgroundDownloadService extends ChangeNotifier {
  static final instance = BackgroundDownloadService._init();
  BackgroundDownloadService._init();

  final OfflineReadingService _offlineService = OfflineReadingService.instance;
  Timer? _downloadTimer;
  bool _isDownloading = false;

  bool get isDownloading => _isDownloading;

  void startAutoDownload() {
    _downloadTimer?.cancel();

    _downloadTimer = Timer.periodic(const Duration(minutes: 30), (_) async {
      if (_offlineService.autoDownloadOnWiFi) {
        await _downloadQueuedArticles();
      }
    });
  }

  Future<void> _downloadQueuedArticles() async {
    if (_isDownloading) return;

    _isDownloading = true;
    notifyListeners();

    // Download logic here

    _isDownloading = false;
    notifyListeners();
  }

  void stopAutoDownload() {
    _downloadTimer?.cancel();
  }

  @override
  void dispose() {
    _downloadTimer?.cancel();
    super.dispose();
  }
}