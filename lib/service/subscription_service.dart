import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:the_news/core/network/api_client.dart';
import 'package:the_news/model/subscription_model.dart';

class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService instance = SubscriptionService._init();

  static const String _subscriptionKey = 'user_subscription';
  static const String _plansKey = 'subscription_plans';

  final _api = ApiClient.instance;
  UserSubscription? _currentSubscription;
  List<SubscriptionPlan> _availablePlans = [];
  bool _plansLoaded = false;

  SubscriptionService._init();

  // Getters
  List<SubscriptionPlan> get availablePlans => _availablePlans.isNotEmpty
      ? _availablePlans
      : SubscriptionPlan.allPlans; // Fallback to hardcoded plans

  List<SubscriptionPlan> get paidPlans => availablePlans.where((p) => !p.isFree).toList();
  UserSubscription? get currentSubscription => _currentSubscription;

  /// Load subscription plans from backend with local cache fallback
  Future<void> loadSubscriptionPlans() async {
    if (_plansLoaded) return; // Don't reload if already loaded

    try {
      // Load from local cache first (instant)
      await _loadPlansFromCache();
      notifyListeners();

      // Then fetch from backend
      log('📥 Fetching subscription plans from backend');

      final response = await _api.get(
        'subscriptions/plans',
        timeout: const Duration(seconds: 10),
      );

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true && data['plans'] != null) {
          final List<dynamic> plansJson = data['plans'];
          _availablePlans = plansJson
              .map((json) => SubscriptionPlan.fromJson(json as Map<String, dynamic>))
              .toList();

          // Save to cache
          await _savePlansToCache();
          _plansLoaded = true;
          log('✅ Loaded ${_availablePlans.length} subscription plans from backend');
          notifyListeners();
        }
      } else {
        log('⚠️ Backend plans unavailable, using ${_availablePlans.isEmpty ? "default" : "cached"} plans');
      }
    } catch (e) {
      log('⚠️ Error loading subscription plans: $e');
      // Use cached or default plans
      if (_availablePlans.isEmpty) {
        _availablePlans = SubscriptionPlan.allPlans;
      }
    }
  }

  /// Load plans from local cache
  Future<void> _loadPlansFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_plansKey);

      if (cached != null) {
        final List<dynamic> plansJson = jsonDecode(cached);
        _availablePlans = plansJson
            .map((json) => SubscriptionPlan.fromJson(json as Map<String, dynamic>))
            .toList();
        log('💾 Loaded ${_availablePlans.length} plans from cache');
      }
    } catch (e) {
      log('⚠️ Error loading plans from cache: $e');
    }
  }

  /// Save plans to local cache
  Future<void> _savePlansToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final plansJson = _availablePlans.map((p) => p.toJson()).toList();
      await prefs.setString(_plansKey, jsonEncode(plansJson));
      log('💾 Saved ${_availablePlans.length} plans to cache');
    } catch (e) {
      log('⚠️ Error saving plans to cache: $e');
    }
  }

  // Initialize subscription for new user
  Future<void> initializeForUser(String userId) async {
    // Load subscription plans first
    await loadSubscriptionPlans();

    try {
      // Try to load from backend first
      log('📥 Loading subscription from backend for user: $userId');
      final response = await _api.get('subscriptions/$userId');

      if (_api.isSuccess(response)) {
        final data = _api.parseJson(response);
        if (data['success'] == true && data['subscription'] != null) {
          _currentSubscription = UserSubscription.fromJson(data['subscription']);

          // If user is on free tier and hasn't used trial, automatically upgrade them
          if (_currentSubscription!.planId == 'free' &&
              _currentSubscription!.status == SubscriptionStatus.inactive &&
              _currentSubscription!.trialStartDate == null) {
            final now = DateTime.now();
            final trialEnd = now.add(const Duration(days: 7));

            _currentSubscription = _currentSubscription!.copyWith(
              planId: 'premium_monthly',
              status: SubscriptionStatus.trial,
              trialStartDate: now,
              trialEndDate: trialEnd,
            );
            await _saveSubscription();
            log('✨ Upgraded existing free user to 7-day trial');
          } else {
            await _checkAndUpdateSubscriptionStatus();
          }

          log('✅ Loaded subscription from backend');
          return;
        }
      }
    } catch (e) {
      log('⚠️ Error loading from backend: $e');
    }

    // Fall back to local storage
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_subscriptionKey);

    if (stored != null) {
      _currentSubscription = UserSubscription.fromJson(jsonDecode(stored));

      // If user is on free tier and hasn't used trial, automatically upgrade them
      if (_currentSubscription!.planId == 'free' &&
          _currentSubscription!.status == SubscriptionStatus.inactive &&
          _currentSubscription!.trialStartDate == null) {
        final now = DateTime.now();
        final trialEnd = now.add(const Duration(days: 7));

        _currentSubscription = _currentSubscription!.copyWith(
          planId: 'premium_monthly',
          status: SubscriptionStatus.trial,
          trialStartDate: now,
          trialEndDate: trialEnd,
        );
        await _saveSubscription();
        log('✨ Upgraded existing free user to 7-day trial');
      } else {
        await _checkAndUpdateSubscriptionStatus();
      }

      log('💾 Loaded subscription from local storage');
    } else {
      // New user - automatically start 7-day free trial
      final now = DateTime.now();
      final trialEnd = now.add(const Duration(days: 7));

      _currentSubscription = UserSubscription(
        userId: userId,
        planId: 'premium_monthly',
        status: SubscriptionStatus.trial,
        trialStartDate: now,
        trialEndDate: trialEnd,
        lastResetDate: now,
      );
      await _saveSubscription();
      log('✨ Created new subscription with 7-day free trial');
    }
  }

  // Start 7-day free trial
  Future<bool> startFreeTrial(String userId) async {
    if (_currentSubscription == null) {
      await initializeForUser(userId);
    }

    // Check if user already had a trial
    if (_currentSubscription!.trialStartDate != null) {
      return false; // Already used trial
    }

    final now = DateTime.now();
    final trialEnd = now.add(const Duration(days: 7));

    _currentSubscription = _currentSubscription!.copyWith(
      planId: 'premium_monthly',
      status: SubscriptionStatus.trial,
      trialStartDate: now,
      trialEndDate: trialEnd,
    );

    await _saveSubscription();
    return true;
  }

  // Activate paid subscription
  Future<void> activatePaidSubscription({
    required String planId,
    required String transactionId,
  }) async {
    final now = DateTime.now();
    final plan = SubscriptionPlan.allPlans.firstWhere((p) => p.id == planId);

    DateTime endDate;
    if (plan.billingPeriod == 'yearly') {
      endDate = now.add(const Duration(days: 365));
    } else {
      endDate = now.add(const Duration(days: 30));
    }

    _currentSubscription = _currentSubscription!.copyWith(
      planId: planId,
      status: SubscriptionStatus.active,
      subscriptionStartDate: now,
      subscriptionEndDate: endDate,
      transactionId: transactionId,
    );

    await _saveSubscription();
  }

  // Cancel subscription (remains active until end date)
  Future<void> cancelSubscription() async {
    _currentSubscription = _currentSubscription!.copyWith(
      status: SubscriptionStatus.cancelled,
    );
    await _saveSubscription();
  }

  // Track article read (for free tier limit)
  Future<bool> trackArticleRead() async {
    if (_currentSubscription == null) return false;

    // Reset daily count if it's a new day
    await _checkDailyReset();

    // Premium users and trial users have unlimited access
    if (canAccessPremiumFeatures) {
      return true;
    }

    // Check free tier limit
    if (_currentSubscription!.hasReachedDailyLimit) {
      return false; // Limit reached
    }

    _currentSubscription = _currentSubscription!.copyWith(
      dailyArticleCount: _currentSubscription!.dailyArticleCount + 1,
    );

    await _saveSubscription();
    return true;
  }

  // Check if subscription needs status update
  Future<void> _checkAndUpdateSubscriptionStatus() async {
    if (_currentSubscription == null) return;

    final now = DateTime.now();

    // Check if trial expired
    if (_currentSubscription!.status == SubscriptionStatus.trial &&
        _currentSubscription!.trialEndDate != null &&
        now.isAfter(_currentSubscription!.trialEndDate!)) {
      _currentSubscription = _currentSubscription!.copyWith(
        status: SubscriptionStatus.expired,
        planId: 'free',
      );
      await _saveSubscription();
    }

    // Check if paid subscription expired
    if (_currentSubscription!.status == SubscriptionStatus.active &&
        _currentSubscription!.subscriptionEndDate != null &&
        now.isAfter(_currentSubscription!.subscriptionEndDate!)) {
      _currentSubscription = _currentSubscription!.copyWith(
        status: SubscriptionStatus.expired,
        planId: 'free',
      );
      await _saveSubscription();
    }

    // Check daily reset
    await _checkDailyReset();
  }

  // Reset daily article count
  Future<void> _checkDailyReset() async {
    if (_currentSubscription == null) return;

    final now = DateTime.now();
    final lastReset = _currentSubscription!.lastResetDate;

    if (lastReset == null || !_isSameDay(now, lastReset)) {
      _currentSubscription = _currentSubscription!.copyWith(
        dailyArticleCount: 0,
        lastResetDate: now,
      );
      await _saveSubscription();
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  // Save subscription to local storage AND backend
  Future<void> _saveSubscription() async {
    if (_currentSubscription == null) return;

    // Save to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _subscriptionKey,
      jsonEncode(_currentSubscription!.toJson()),
    );

    // Sync to backend
    try {
      final response = await _api.put(
        'subscriptions/${_currentSubscription!.userId}',
        body: _currentSubscription!.toJson(),
      );

      if (_api.isSuccess(response)) {
        log('✅ Subscription synced to backend');
      } else {
        log('⚠️ Failed to sync subscription to backend: ${_api.getErrorMessage(response)}');
      }
    } catch (e) {
      log('⚠️ Error syncing subscription to backend: $e');
    }
  }

  // Get current subscription (async)
  Future<UserSubscription?> getCurrentSubscription() async {
    if (_currentSubscription == null) {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_subscriptionKey);
      if (stored != null) {
        _currentSubscription = UserSubscription.fromJson(jsonDecode(stored));
        await _checkAndUpdateSubscriptionStatus();
      }
    }
    return _currentSubscription;
  }

  // Premium status getter
  bool get isPremium =>
      _currentSubscription?.isPremium == true &&
      _currentSubscription?.isActive == true;

  bool get isTrialActive => _currentSubscription?.isTrialActive == true;

  bool get canAccessPremiumFeatures => isPremium || isTrialActive;

  int get remainingArticles => _currentSubscription?.remainingArticles ?? 10;

  bool get hasReachedLimit => _currentSubscription?.hasReachedDailyLimit ?? false;

  int? get trialDaysRemaining {
    if (_currentSubscription?.status != SubscriptionStatus.trial) return null;
    if (_currentSubscription?.trialEndDate == null) return null;

    final now = DateTime.now();
    final diff = _currentSubscription!.trialEndDate!.difference(now);
    return diff.inDays.clamp(0, 7);
  }

  // Check if user has ever had a trial
  bool get hasUsedTrial => _currentSubscription?.trialStartDate != null;

  // Get current plan
  SubscriptionPlan get currentPlan {
    final planId = _currentSubscription?.planId ?? 'free';
    return SubscriptionPlan.allPlans.firstWhere(
      (plan) => plan.id == planId,
      orElse: () => SubscriptionPlan.free,
    );
  }
}
