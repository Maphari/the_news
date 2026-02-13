import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Payment service for handling Paystack subscriptions and premium features
/// Uses direct HTTP API calls to Paystack (no plugin dependency conflicts)
class PaymentService extends ChangeNotifier {
  static final PaymentService instance = PaymentService._init();
  PaymentService._init();

  static const String _paystackBaseUrl = 'https://api.paystack.co';
  String? _paystackPublicKey;
  String? _paystackSecretKey;
  String? _backendBaseUrl;

  // Subscription tiers
  static const String monthlyPlan = 'monthly';
  static const String yearlyPlan = 'yearly';

  // Prices in ZAR (South African Rand) - in kobo (1/100 of currency)
  static const int monthlyPriceKobo = 11900; // R119.00
  static const int yearlyPriceKobo = 119900; // R1,199.00 (save R229)

  bool _isPremium = false;
  String? _subscriptionType;
  DateTime? _subscriptionEndDate;
  String? _currentUserId; // ignore: unused_field - Used for state tracking

  // Getters
  bool get isPremium => _isPremium;
  String? get subscriptionType => _subscriptionType;
  DateTime? get subscriptionEndDate => _subscriptionEndDate;
  String? get backendBaseUrl => _backendBaseUrl;
  bool get isSubscriptionActive =>
      _isPremium &&
      _subscriptionEndDate != null &&
      _subscriptionEndDate!.isAfter(DateTime.now());

  /// Initialize with API keys
  void initialize({
    required String paystackPublicKey,
    String? paystackSecretKey,
    required String backendBaseUrl,
  }) {
    _paystackPublicKey = paystackPublicKey;
    _paystackSecretKey = paystackSecretKey;
    _backendBaseUrl = backendBaseUrl;
    log('✅ Payment service initialized');
  }

  /// Load subscription status from backend
  Future<void> loadSubscriptionStatus(String userId) async {
    _currentUserId = userId;

    try {
      final response = await http.get(
        Uri.parse('$_backendBaseUrl/subscriptions/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _isPremium = data['isPremium'] ?? false;
          _subscriptionType = data['subscriptionType'];

          if (data['subscriptionEndDate'] != null) {
            _subscriptionEndDate = DateTime.parse(data['subscriptionEndDate']);
          }

          // Save to local cache
          await _saveToCache();
          notifyListeners();

          log('✅ Subscription status loaded: Premium=$_isPremium');
        }
      }
    } catch (e) {
      log('❌ Error loading subscription status: $e');
      // Load from cache if network fails
      await _loadFromCache();
    }
  }

  /// Start monthly subscription
  Future<Map<String, dynamic>> subscribeMonthly({
    required String userId,
    required String email,
  }) async {
    return await _initializePayment(
      userId: userId,
      email: email,
      plan: monthlyPlan,
      amount: monthlyPriceKobo,
    );
  }

  /// Start yearly subscription
  Future<Map<String, dynamic>> subscribeYearly({
    required String userId,
    required String email,
  }) async {
    return await _initializePayment(
      userId: userId,
      email: email,
      plan: yearlyPlan,
      amount: yearlyPriceKobo,
    );
  }

  /// Initialize payment with Paystack via backend (more secure)
  Future<Map<String, dynamic>> _initializePayment({
    required String userId,
    required String email,
    required String plan,
    required int amount,
  }) async {
    try {
      final reference = 'SUB_${const Uuid().v4()}';

      // Initialize transaction via backend (backend will use secret key)
      final response = await http.post(
        Uri.parse('$_backendBaseUrl/subscriptions/initialize'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'userId': userId,
          'email': email,
          'amount': amount,
          'currency': 'ZAR',
          'reference': reference,
          'plan': plan,
        }),
      );

      log('Payment initialization response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return {
            'success': true,
            'authorizationUrl': data['authorizationUrl'],
            'accessCode': data['accessCode'],
            'reference': reference,
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to initialize payment'
          };
        }
      }

      return {
        'success': false,
        'message': 'Server error: ${response.statusCode}'
      };
    } catch (e) {
      log('❌ Payment initialization error: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  /// Save pending subscription to backend
  Future<void> _savePendingSubscription(
      String userId, String reference, String plan) async {
    try {
      await http.post(
        Uri.parse('$_backendBaseUrl/subscriptions/pending'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'reference': reference,
          'plan': plan,
          'status': 'pending',
        }),
      );
    } catch (e) {
      log('❌ Error saving pending subscription: $e');
    }
  }

  /// Verify payment after redirect
  Future<bool> verifyPayment(String reference) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendBaseUrl/subscriptions/verify'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'reference': reference}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _isPremium = true;
          _subscriptionType = data['plan'];
          _subscriptionEndDate = DateTime.parse(data['subscriptionEndDate']);

          await _saveToCache();
          notifyListeners();

          log('✅ Payment verified successfully');
          return true;
        }
      }
      return false;
    } catch (e) {
      log('❌ Payment verification error: $e');
      return false;
    }
  }

  /// Cancel subscription
  Future<bool> cancelSubscription(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$_backendBaseUrl/subscriptions/cancel'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _isPremium = false;
          _subscriptionType = null;
          _subscriptionEndDate = null;

          await _saveToCache();
          notifyListeners();

          log('✅ Subscription cancelled');
          return true;
        }
      }
      return false;
    } catch (e) {
      log('❌ Error cancelling subscription: $e');
      return false;
    }
  }

  /// Get subscription price displays
  String getMonthlyPriceDisplay() {
    return 'R${(monthlyPriceKobo / 100).toStringAsFixed(2)}/month';
  }

  String getYearlyPriceDisplay() {
    return 'R${(yearlyPriceKobo / 100).toStringAsFixed(2)}/year';
  }

  String getYearlySavingsDisplay() {
    final monthlyCost = (monthlyPriceKobo / 100) * 12;
    final yearlyCost = yearlyPriceKobo / 100;
    final savings = monthlyCost - yearlyCost;
    return 'Save R${savings.toStringAsFixed(2)}';
  }

  /// Save subscription status to cache
  Future<void> _saveToCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPremium', _isPremium);
    await prefs.setString('subscriptionType', _subscriptionType ?? '');
    await prefs.setString(
      'subscriptionEndDate',
      _subscriptionEndDate?.toIso8601String() ?? '',
    );
  }

  /// Load subscription status from cache
  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool('isPremium') ?? false;
    _subscriptionType = prefs.getString('subscriptionType');

    final endDateStr = prefs.getString('subscriptionEndDate');
    if (endDateStr != null && endDateStr.isNotEmpty) {
      _subscriptionEndDate = DateTime.tryParse(endDateStr);
    }

    notifyListeners();
  }

  /// Clear all subscription data
  Future<void> clearSubscriptionData() async {
    _isPremium = false;
    _subscriptionType = null;
    _subscriptionEndDate = null;
    _currentUserId = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isPremium');
    await prefs.remove('subscriptionType');
    await prefs.remove('subscriptionEndDate');

    notifyListeners();
  }

  /// Check if subscription is about to expire (within 7 days)
  bool get isExpiringSoon {
    if (_subscriptionEndDate == null) return false;
    final daysUntilExpiry =
        _subscriptionEndDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry > 0 && daysUntilExpiry <= 7;
  }

  /// Get days until subscription expires
  int get daysUntilExpiry {
    if (_subscriptionEndDate == null) return 0;
    final days = _subscriptionEndDate!.difference(DateTime.now()).inDays;
    return days > 0 ? days : 0;
  }
}
