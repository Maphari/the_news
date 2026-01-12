import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:the_news/model/daily_digest_model.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:the_news/service/notification_navigation_service.dart';

/// Service for managing push notifications and local notifications
class NotificationService {
  static final NotificationService instance = NotificationService._init();
  NotificationService._init();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  bool _isInitialized = false;
  String? _fcmToken;
  String? _backendBaseUrl;

  // Notification preferences
  bool _breakingNewsEnabled = true;
  bool _dailyDigestEnabled = true;
  bool _publisherUpdatesEnabled = true;
  bool _commentRepliesEnabled = true;

  // Getters
  String? get fcmToken => _fcmToken;
  bool get breakingNewsEnabled => _breakingNewsEnabled;
  bool get dailyDigestEnabled => _dailyDigestEnabled;
  bool get publisherUpdatesEnabled => _publisherUpdatesEnabled;
  bool get commentRepliesEnabled => _commentRepliesEnabled;

  /// Initialize notification service
  Future<void> initialize({String? backendBaseUrl}) async {
    if (_isInitialized) return;

    try {
      log('📱 Initializing notification service...');

      if (backendBaseUrl != null) {
        _backendBaseUrl = backendBaseUrl;
      }

      // Load preferences
      await _loadPreferences();

      // Request permissions
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize Firebase Cloud Messaging
      await _initializeFirebaseMessaging();

      // Create notification channels
      await _createNotificationChannels();

      _isInitialized = true;
      log('✅ Notification service initialized');
    } catch (e) {
      log('⚠️ Error initializing notification service: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      // Request iOS permissions
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      log('📱 Notification permission status: ${settings.authorizationStatus}');

      // Get FCM token for this device
      _fcmToken = await _firebaseMessaging.getToken();
      log('📱 FCM Token: $_fcmToken');

      // Listen to token refresh
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        log('🔄 FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        _sendTokenToBackend(newToken);
      });
    } catch (e) {
      log('⚠️ Error requesting permissions: $e');
    }
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      log('✅ Local notifications initialized');
    } catch (e) {
      log('⚠️ Error initializing local notifications: $e');
    }
  }

  /// Initialize Firebase Cloud Messaging
  Future<void> _initializeFirebaseMessaging() async {
    try {
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      log('✅ Firebase Cloud Messaging initialized');
    } catch (e) {
      log('⚠️ Error initializing FCM: $e');
    }
  }

  /// Handle foreground message
  void _handleForegroundMessage(RemoteMessage message) async {
    log('📨 Foreground message received: ${message.notification?.title}');

    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? 'The News',
        body: message.notification!.body ?? '',
        payload: message.data.toString(),
      );

      // Save to notification history
      final userId = message.data['userId'] as String?;
      if (userId != null) {
        await saveNotificationToHistory(
          userId: userId,
          type: message.data['type'] ?? 'general',
          title: message.notification!.title ?? 'The News',
          body: message.notification!.body ?? '',
          imageUrl: message.notification?.android?.imageUrl ?? message.notification?.apple?.imageUrl,
          articleId: message.data['articleId'],
          commentId: message.data['commentId'],
          publisherId: message.data['publisherId'],
        );
      }
    }
  }

  /// Send comprehensive digest notification with action buttons
  Future<void> sendDigestNotification(DailyDigest digest) async {
    try {
      // Build preview of top 3 stories
      final topItems = digest.items.take(3).toList();
      final itemsPreview = StringBuffer();
      for (var i = 0; i < topItems.length; i++) {
        itemsPreview.writeln('${i + 1}. ${topItems[i].headline}');
      }

      final fullBody = itemsPreview.toString().trim() +
          (digest.items.length > 3 ? '\n\n...and ${digest.items.length - 3} more stories' : '');

      // Android notification with action buttons and expanded content
      const androidDetails = AndroidNotificationDetails(
        'daily_digest_channel',
        'Daily Digest',
        channelDescription: 'Notifications for your daily news digest',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(''),
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            'read_now',
            'Read Now',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'listen',
            'Listen',
            showsUserInterface: true,
          ),
        ],
      );

      // iOS notification with action buttons
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'digest_category',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        0,
        '📰 ${digest.title}',
        fullBody,
        notificationDetails,
        payload: jsonEncode({
          'type': 'digest',
          'id': digest.digestId,
          'itemCount': digest.items.length,
          'estimatedMinutes': digest.estimatedReadingMinutes,
        }),
      );

      log('📨 Enhanced digest notification sent with ${digest.items.length} stories');
    } catch (e) {
      log('⚠️ Error sending digest notification: $e');
      // Fallback to simple notification
      final itemsPreview = digest.items
          .take(3)
          .map((item) => '• ${item.headline}')
          .join('\n');

      await _showLocalNotification(
        title: digest.title,
        body: itemsPreview,
        payload: jsonEncode({'type': 'digest', 'id': digest.digestId}),
      );
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    log('👆 Notification tapped: ${response.payload}');

    // Handle action button taps
    if (response.actionId != null && response.actionId!.isNotEmpty) {
      NotificationNavigationService.instance.handleNotificationAction(
        response.actionId!,
        response.payload,
      );
    } else {
      // Handle regular notification tap
      NotificationNavigationService.instance.handleNotificationTap(response.payload);
    }
  }

  /// Handle message opened app
  void _handleMessageOpenedApp(RemoteMessage message) {
    log('📬 Message opened app: ${message.notification?.title}');

    // Convert RemoteMessage data to payload format
    final payload = jsonEncode({
      'type': message.data['type'] ?? 'general',
      'articleId': message.data['articleId'],
      'commentId': message.data['commentId'],
      'publisherId': message.data['publisherId'],
      ...message.data,
    });

    NotificationNavigationService.instance.handleNotificationTap(payload);
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'daily_digest_channel',
        'Daily Digest',
        channelDescription: 'Notifications for your daily news digest',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
        details,
        payload: payload,
      );

      log('✅ Local notification shown: $title');
    } catch (e) {
      log('⚠️ Error showing local notification: $e');
    }
  }

  /// Schedule daily digest notification
  Future<void> scheduleDailyDigestNotification(DigestSettings settings) async {
    if (!settings.enableNotifications) {
      await cancelDailyDigestNotification();
      return;
    }

    try {
      // Cancel any existing scheduled notification
      await cancelDailyDigestNotification();

      // For daily frequency, schedule at preferred time
      if (settings.frequency == DigestFrequency.daily ||
          settings.frequency == DigestFrequency.twiceDaily) {
        await _scheduleDailyNotification(settings.preferredTime);

        // If twice daily, schedule evening notification too
        if (settings.frequency == DigestFrequency.twiceDaily) {
          final eveningTime = TimeOfDay(
            hour: settings.preferredTime.hour + 12 > 23
                ? settings.preferredTime.hour - 12
                : settings.preferredTime.hour + 12,
            minute: settings.preferredTime.minute,
          );
          await _scheduleDailyNotification(eveningTime, notificationId: 1);
        }
      }

      log('✅ Daily digest notification scheduled');
    } catch (e) {
      log('⚠️ Error scheduling daily digest notification: $e');
    }
  }

  /// Schedule notification at specific time daily
  Future<void> _scheduleDailyNotification(
    TimeOfDay time, {
    int notificationId = 0,
  }) async {
    try {
      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // If time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      const androidDetails = AndroidNotificationDetails(
        'daily_digest_channel',
        'Daily Digest',
        channelDescription: 'Daily news digest notifications',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.zonedSchedule(
        notificationId,
        'Your Daily Digest is Ready',
        'Tap to read your personalized news summary',
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      log('📅 Scheduled notification for ${time.toFormattedString()}');
    } catch (e) {
      log('⚠️ Error scheduling notification: $e');
    }
  }

  /// Cancel daily digest notification
  Future<void> cancelDailyDigestNotification() async {
    try {
      await _localNotifications.cancel(0); // Morning notification
      await _localNotifications.cancel(1); // Evening notification
      log('🔕 Daily digest notifications cancelled');
    } catch (e) {
      log('⚠️ Error cancelling notifications: $e');
    }
  }

  /// Show digest ready notification
  Future<void> showDigestReadyNotification({
    required String title,
    required int itemCount,
    required int estimatedMinutes,
  }) async {
    await _showLocalNotification(
      title: title,
      body: '$itemCount stories • $estimatedMinutes min read',
      payload: 'digest_ready',
    );
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      log('🔕 All notifications cancelled');
    } catch (e) {
      log('⚠️ Error cancelling all notifications: $e');
    }
  }

  // ==================== ENHANCED FEATURES ====================

  /// Create Android notification channels
  Future<void> _createNotificationChannels() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    const breakingNewsChannel = AndroidNotificationChannel(
      'breaking_news',
      'Breaking News',
      description: 'Important breaking news alerts',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    const publisherChannel = AndroidNotificationChannel(
      'publisher_updates',
      'Publisher Updates',
      description: 'Updates from followed publishers',
      importance: Importance.high,
      playSound: true,
    );

    const commentChannel = AndroidNotificationChannel(
      'comment_replies',
      'Comment Replies',
      description: 'Replies to your comments',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await androidPlugin.createNotificationChannel(breakingNewsChannel);
    await androidPlugin.createNotificationChannel(publisherChannel);
    await androidPlugin.createNotificationChannel(commentChannel);
    log('✅ Notification channels created');
  }

  /// Load notification preferences from local storage
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _breakingNewsEnabled = prefs.getBool('notif_breaking_news') ?? true;
      _dailyDigestEnabled = prefs.getBool('notif_daily_digest') ?? true;
      _publisherUpdatesEnabled = prefs.getBool('notif_publisher_updates') ?? true;
      _commentRepliesEnabled = prefs.getBool('notif_comment_replies') ?? true;
      log('✅ Notification preferences loaded');
    } catch (e) {
      log('⚠️ Error loading preferences: $e');
    }
  }

  /// Save notification preferences to local storage
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notif_breaking_news', _breakingNewsEnabled);
      await prefs.setBool('notif_daily_digest', _dailyDigestEnabled);
      await prefs.setBool('notif_publisher_updates', _publisherUpdatesEnabled);
      await prefs.setBool('notif_comment_replies', _commentRepliesEnabled);
    } catch (e) {
      log('⚠️ Error saving preferences: $e');
    }
  }

  /// Update notification preferences
  Future<void> updatePreferences({
    bool? breakingNews,
    bool? dailyDigest,
    bool? publisherUpdates,
    bool? commentReplies,
    String? userId,
  }) async {
    if (breakingNews != null) _breakingNewsEnabled = breakingNews;
    if (dailyDigest != null) _dailyDigestEnabled = dailyDigest;
    if (publisherUpdates != null) _publisherUpdatesEnabled = publisherUpdates;
    if (commentReplies != null) _commentRepliesEnabled = commentReplies;

    await _savePreferences();

    // Sync with backend
    if (userId != null && _backendBaseUrl != null) {
      await _syncPreferencesWithBackend(userId);
    }

    log('✅ Notification preferences updated');
  }

  /// Sync preferences with backend
  Future<void> _syncPreferencesWithBackend(String userId) async {
    if (_backendBaseUrl == null) return;

    try {
      await http.post(
        Uri.parse('$_backendBaseUrl/notifications/preferences'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'breakingNews': _breakingNewsEnabled,
          'dailyDigest': _dailyDigestEnabled,
          'publisherUpdates': _publisherUpdatesEnabled,
          'commentReplies': _commentRepliesEnabled,
        }),
      );
      log('✅ Preferences synced with backend');
    } catch (e) {
      log('⚠️ Error syncing preferences: $e');
    }
  }

  /// Register FCM token with backend
  Future<bool> registerToken(String userId) async {
    if (_fcmToken == null) {
      log('❌ No FCM token available');
      return false;
    }

    return await _sendTokenToBackend(_fcmToken!, userId: userId);
  }

  /// Send FCM token to backend
  Future<bool> _sendTokenToBackend(String token, {String? userId}) async {
    if (_backendBaseUrl == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_backendBaseUrl/notifications/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'userId': userId,
          'platform': 'mobile',
        }),
      );

      if (response.statusCode == 200) {
        log('✅ FCM token registered with backend');
        return true;
      } else {
        log('❌ Failed to register FCM token: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      log('⚠️ Error sending token to backend: $e');
      return false;
    }
  }

  /// Unregister FCM token (on logout)
  Future<void> unregisterToken(String userId) async {
    if (_fcmToken == null || _backendBaseUrl == null) return;

    try {
      await http.post(
        Uri.parse('$_backendBaseUrl/notifications/unregister'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': _fcmToken,
          'userId': userId,
        }),
      );
      log('✅ FCM token unregistered');
    } catch (e) {
      log('⚠️ Error unregistering token: $e');
    }
  }

  /// Subscribe to topic (for breaking news)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      log('✅ Subscribed to topic: $topic');
    } catch (e) {
      log('⚠️ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      log('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      log('⚠️ Error unsubscribing from topic: $e');
    }
  }

  /// Show breaking news notification
  Future<void> showBreakingNewsNotification({
    required String title,
    required String body,
    String? articleId,
    String? imageUrl,
  }) async {
    if (!_breakingNewsEnabled) {
      log('⏭️ Breaking news notifications disabled');
      return;
    }

    // Download and prepare image if provided
    BigPictureStyleInformation? bigPictureStyle;
    if (imageUrl != null) {
      try {
        bigPictureStyle = BigPictureStyleInformation(
          FilePathAndroidBitmap(await _downloadAndSaveImage(imageUrl, 'breaking_news')),
          largeIcon: FilePathAndroidBitmap(await _downloadAndSaveImage(imageUrl, 'breaking_news_icon')),
          contentTitle: '🚨 $title',
          summaryText: body,
          htmlFormatContentTitle: true,
          htmlFormatSummaryText: true,
        );
      } catch (e) {
        log('⚠️ Error loading notification image: $e');
      }
    }

    final androidDetails = AndroidNotificationDetails(
      'breaking_news',
      'Breaking News',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      enableLights: true,
      color: Color(0xFFD32F2F),
      playSound: true,
      styleInformation: bigPictureStyle ?? BigTextStyleInformation(body),
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'read_article',
          'Read Article',
          showsUserInterface: true,
          icon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        ),
        AndroidNotificationAction(
          'share',
          'Share',
          showsUserInterface: false,
        ),
        AndroidNotificationAction(
          'dismiss',
          'Dismiss',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      '🚨 $title',
      body,
      details,
      payload: jsonEncode({'type': 'breaking_news', 'articleId': articleId}),
    );

    log('🚨 Breaking news notification shown');
  }

  /// Show publisher update notification
  Future<void> showPublisherUpdateNotification({
    required String publisherName,
    required String title,
    required String articleId,
    String? imageUrl,
  }) async {
    if (!_publisherUpdatesEnabled) {
      log('⏭️ Publisher update notifications disabled');
      return;
    }

    // Download and prepare image if provided
    BigPictureStyleInformation? bigPictureStyle;
    if (imageUrl != null) {
      try {
        bigPictureStyle = BigPictureStyleInformation(
          FilePathAndroidBitmap(await _downloadAndSaveImage(imageUrl, 'publisher_${DateTime.now().millisecondsSinceEpoch}')),
          contentTitle: '📰 New from $publisherName',
          summaryText: title,
          htmlFormatContentTitle: true,
          htmlFormatSummaryText: true,
        );
      } catch (e) {
        log('⚠️ Error loading notification image: $e');
      }
    }

    final androidDetails = AndroidNotificationDetails(
      'publisher_updates',
      'Publisher Updates',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: bigPictureStyle ?? BigTextStyleInformation(title),
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'read_now',
          'Read Now',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'save_later',
          'Save for Later',
          showsUserInterface: false,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      '📰 New from $publisherName',
      title,
      details,
      payload: jsonEncode({'type': 'publisher_update', 'articleId': articleId}),
    );

    log('📰 Publisher update notification shown');
  }

  /// Show comment reply notification
  Future<void> showCommentReplyNotification({
    required String commenterName,
    required String replyText,
    required String articleId,
    required String commentId,
  }) async {
    if (!_commentRepliesEnabled) {
      log('⏭️ Comment reply notifications disabled');
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'comment_replies',
      'Comment Replies',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'reply',
          'Reply',
          showsUserInterface: true,
          inputs: <AndroidNotificationActionInput>[
            AndroidNotificationActionInput(
              label: 'Reply to $commenterName',
            ),
          ],
        ),
        const AndroidNotificationAction(
          'view_comment',
          'View Comment',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'mark_read',
          'Mark as Read',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      '💬 $commenterName replied',
      replyText,
      details,
      payload: jsonEncode({
        'type': 'comment_reply',
        'articleId': articleId,
        'commentId': commentId,
      }),
    );

    log('💬 Comment reply notification shown');
  }

  /// Get all notification preferences
  Map<String, bool> getPreferences() {
    return {
      'breakingNews': _breakingNewsEnabled,
      'dailyDigest': _dailyDigestEnabled,
      'publisherUpdates': _publisherUpdatesEnabled,
      'commentReplies': _commentRepliesEnabled,
    };
  }

  /// Save notification to history
  Future<void> saveNotificationToHistory({
    required String userId,
    required String type,
    required String title,
    required String body,
    String? imageUrl,
    String? articleId,
    String? commentId,
    String? publisherId,
  }) async {
    if (_backendBaseUrl == null) return;

    try {
      final response = await http.post(
        Uri.parse('$_backendBaseUrl/notifications/history'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'type': type,
          'title': title,
          'body': body,
          'imageUrl': imageUrl,
          'articleId': articleId,
          'commentId': commentId,
          'publisherId': publisherId,
        }),
      );

      if (response.statusCode == 200) {
        log('💾 Notification saved to history');
      } else {
        log('⚠️ Failed to save notification to history: ${response.statusCode}');
      }
    } catch (e) {
      log('⚠️ Error saving notification to history: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount(String userId) async {
    if (_backendBaseUrl == null) return 0;

    try {
      final response = await http.get(
        Uri.parse('$_backendBaseUrl/notifications/history/$userId/unread-count'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['unreadCount'] ?? 0;
      }
    } catch (e) {
      log('⚠️ Error getting unread count: $e');
    }
    return 0;
  }

  /// Download and save image for notification
  Future<String> _downloadAndSaveImage(String url, String fileName) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName.jpg';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      return filePath;
    } catch (e) {
      log('⚠️ Error downloading notification image: $e');
      rethrow;
    }
  }

  /// Show grouped notification for publisher updates
  Future<void> showGroupedPublisherNotifications({
    required String publisherName,
    required List<Map<String, String>> articles,
  }) async {
    if (!_publisherUpdatesEnabled || articles.isEmpty) return;

    final summaryText = articles.length == 1
        ? articles.first['title']!
        : '${articles.length} new articles from $publisherName';

    final inboxLines = articles
        .map((article) => article['title']!)
        .toList();

    final androidDetails = AndroidNotificationDetails(
      'publisher_updates',
      'Publisher Updates',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      groupKey: 'publisher_$publisherName',
      setAsGroupSummary: true,
      styleInformation: InboxStyleInformation(
        inboxLines,
        contentTitle: '📰 $publisherName',
        summaryText: summaryText,
      ),
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'view_all',
          'View All',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'mark_read',
          'Mark All Read',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: 'publisher_updates',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      publisherName.hashCode, // Use publisher name hash as stable ID
      '📰 New from $publisherName',
      summaryText,
      details,
      payload: jsonEncode({
        'type': 'grouped_publisher_update',
        'publisherName': publisherName,
        'count': articles.length,
      }),
    );

    log('📰 Grouped ${articles.length} notifications for $publisherName');
  }

  /// Show grouped notification for breaking news
  Future<void> showGroupedBreakingNews({
    required List<Map<String, String>> newsItems,
  }) async {
    if (!_breakingNewsEnabled || newsItems.isEmpty) return;

    final summaryText = newsItems.length == 1
        ? newsItems.first['title']!
        : '${newsItems.length} breaking news alerts';

    final inboxLines = newsItems
        .map((item) => item['title']!)
        .toList();

    final androidDetails = AndroidNotificationDetails(
      'breaking_news',
      'Breaking News',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      enableLights: true,
      color: const Color(0xFFD32F2F),
      playSound: true,
      groupKey: 'breaking_news_group',
      setAsGroupSummary: true,
      styleInformation: InboxStyleInformation(
        inboxLines,
        contentTitle: '🚨 Breaking News',
        summaryText: summaryText,
      ),
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'view_all',
          'View All',
          showsUserInterface: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
      threadIdentifier: 'breaking_news',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      999999, // Stable ID for breaking news group
      '🚨 Breaking News',
      summaryText,
      details,
      payload: jsonEncode({
        'type': 'grouped_breaking_news',
        'count': newsItems.length,
      }),
    );

    log('🚨 Grouped ${newsItems.length} breaking news notifications');
  }

  /// Show grouped notification for comment replies
  Future<void> showGroupedCommentReplies({
    required List<Map<String, String>> replies,
  }) async {
    if (!_commentRepliesEnabled || replies.isEmpty) return;

    final summaryText = replies.length == 1
        ? '${replies.first['commenterName']} replied to your comment'
        : '${replies.length} new replies to your comments';

    final inboxLines = replies
        .map((reply) => '${reply['commenterName']}: ${reply['text']}')
        .toList();

    final androidDetails = AndroidNotificationDetails(
      'comment_replies',
      'Comment Replies',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      groupKey: 'comment_replies_group',
      setAsGroupSummary: true,
      styleInformation: InboxStyleInformation(
        inboxLines,
        contentTitle: '💬 Comment Replies',
        summaryText: summaryText,
      ),
      actions: const <AndroidNotificationAction>[
        AndroidNotificationAction(
          'view_all',
          'View All',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'mark_read',
          'Mark All Read',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      threadIdentifier: 'comment_replies',
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      888888, // Stable ID for comment replies group
      '💬 Comment Replies',
      summaryText,
      details,
      payload: jsonEncode({
        'type': 'grouped_comment_replies',
        'count': replies.length,
      }),
    );

    log('💬 Grouped ${replies.length} comment reply notifications');
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('📨 Background message received: ${message.notification?.title}');
}
