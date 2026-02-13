class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String billingPeriod; // 'monthly', 'yearly'
  final List<String> features;
  final bool isFree;
  final int? trialDays;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.billingPeriod,
    required this.features,
    this.isFree = false,
    this.trialDays,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      billingPeriod: json['billingPeriod'] as String? ?? json['interval'] as String? ?? 'monthly',
      features: List<String>.from(json['features'] as List),
      isFree: json['isFree'] as bool? ?? false,
      trialDays: json['trialDays'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'billingPeriod': billingPeriod,
      'features': features,
      'isFree': isFree,
      'trialDays': trialDays,
    };
  }

  static const SubscriptionPlan free = SubscriptionPlan(
    id: 'free',
    name: 'Free',
    description: 'Try mindful news basics',
    price: 0,
    billingPeriod: 'forever',
    isFree: true,
    features: [
      '10 articles per day',
      'Read full articles',
      'Save articles for later',
      '3 categories',
      'Basic calm mode',
      'Ads included',
    ],
  );

  static const SubscriptionPlan premium = SubscriptionPlan(
    id: 'premium_monthly',
    name: 'Premium',
    description: 'Full mindful reading experience with 7-day free trial',
    price: 119,
    billingPeriod: 'monthly',
    trialDays: 7,
    features: [
      '7-day free trial',
      'Unlimited articles',
      'All categories',
      'Ad-free reading',
      'Advanced calm mode',
      'Content intensity filter',
      'Mood tracking and insights',
      'Break reminders',
      'Solution-focused badges',
      'Article enrichment',
      'Text-to-speech',
      'Video articles',
      'Priority support',
    ],
  );

  static const SubscriptionPlan premiumYearly = SubscriptionPlan(
    id: 'premium_yearly',
    name: 'Premium Yearly',
    description: 'Best value - Save 40% annually',
    price: 1199,
    billingPeriod: 'yearly',
    trialDays: 7,
    features: [
      '7-day free trial',
      'Unlimited articles',
      'All categories',
      'Ad-free reading',
      'Advanced calm mode',
      'Content intensity filter',
      'Mood tracking and insights',
      'Break reminders',
      'Solution-focused badges',
      'Article enrichment',
      'Text-to-speech',
      'Video articles',
      'Priority support',
    ],
  );

  static List<SubscriptionPlan> get allPlans => [free, premium, premiumYearly];
  static List<SubscriptionPlan> get paidPlans => [premium, premiumYearly];
}

class UserSubscription {
  final String userId;
  final String planId;
  final SubscriptionStatus status;
  final DateTime? trialStartDate;
  final DateTime? trialEndDate;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final String? transactionId;
  final int dailyArticleCount;
  final DateTime? lastResetDate;

  UserSubscription({
    required this.userId,
    required this.planId,
    required this.status,
    this.trialStartDate,
    this.trialEndDate,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.transactionId,
    this.dailyArticleCount = 0,
    this.lastResetDate,
  });

  bool get isFreePlan => planId == 'free';
  bool get isPremium => planId.startsWith('premium');
  bool get isTrialActive => status == SubscriptionStatus.trial;
  bool get isActive => status == SubscriptionStatus.active || status == SubscriptionStatus.trial;

  bool get hasReachedDailyLimit {
    if (isPremium && isActive) return false;
    return dailyArticleCount >= 10; // Free tier limit
  }

  int get remainingArticles {
    if (isPremium && isActive) return -1; // Unlimited
    return (10 - dailyArticleCount).clamp(0, 10);
  }

  UserSubscription copyWith({
    String? userId,
    String? planId,
    SubscriptionStatus? status,
    DateTime? trialStartDate,
    DateTime? trialEndDate,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    String? transactionId,
    int? dailyArticleCount,
    DateTime? lastResetDate,
  }) {
    return UserSubscription(
      userId: userId ?? this.userId,
      planId: planId ?? this.planId,
      status: status ?? this.status,
      trialStartDate: trialStartDate ?? this.trialStartDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      subscriptionStartDate: subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      transactionId: transactionId ?? this.transactionId,
      dailyArticleCount: dailyArticleCount ?? this.dailyArticleCount,
      lastResetDate: lastResetDate ?? this.lastResetDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'planId': planId,
      'status': status.name,
      'trialStartDate': trialStartDate?.toIso8601String(),
      'trialEndDate': trialEndDate?.toIso8601String(),
      'subscriptionStartDate': subscriptionStartDate?.toIso8601String(),
      'subscriptionEndDate': subscriptionEndDate?.toIso8601String(),
      'transactionId': transactionId,
      'dailyArticleCount': dailyArticleCount,
      'lastResetDate': lastResetDate?.toIso8601String(),
    };
  }

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      userId: json['userId'],
      planId: json['planId'],
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SubscriptionStatus.inactive,
      ),
      trialStartDate: json['trialStartDate'] != null
          ? DateTime.parse(json['trialStartDate'])
          : null,
      trialEndDate: json['trialEndDate'] != null
          ? DateTime.parse(json['trialEndDate'])
          : null,
      subscriptionStartDate: json['subscriptionStartDate'] != null
          ? DateTime.parse(json['subscriptionStartDate'])
          : null,
      subscriptionEndDate: json['subscriptionEndDate'] != null
          ? DateTime.parse(json['subscriptionEndDate'])
          : null,
      transactionId: json['transactionId'],
      dailyArticleCount: json['dailyArticleCount'] ?? 0,
      lastResetDate: json['lastResetDate'] != null
          ? DateTime.parse(json['lastResetDate'])
          : null,
    );
  }
}

enum SubscriptionStatus {
  trial,      // In 7-day trial
  active,     // Paid and active
  expired,    // Subscription expired
  inactive,   // Never subscribed (free tier)
  cancelled,  // Cancelled but still active until end date
}
