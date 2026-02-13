enum ActivityType {
  readArticle,
  createList,
  updateList,
  addToList,
  followUser,
  shareList,
  shareArticle,
  commentArticle,
  likeArticle,
}

class ActivityFeedItem {
  final String id;
  final String userId;
  final String username;
  final String? userAvatarUrl;
  final ActivityType activityType;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  ActivityFeedItem({
    required this.id,
    required this.userId,
    required this.username,
    this.userAvatarUrl,
    required this.activityType,
    required this.timestamp,
    this.metadata = const {},
  });

  String get activityDescription {
    switch (activityType) {
      case ActivityType.readArticle:
        return 'read an article';
      case ActivityType.createList:
        return 'created a reading list';
      case ActivityType.updateList:
        return 'updated a reading list';
      case ActivityType.addToList:
        return 'added an article to a list';
      case ActivityType.followUser:
        return 'followed a user';
      case ActivityType.shareList:
        return 'shared a reading list';
      case ActivityType.shareArticle:
        return 'shared an article';
      case ActivityType.commentArticle:
        return 'commented on an article';
      case ActivityType.likeArticle:
        return 'liked an article';
    }
  }

  String? get articleTitle => metadata['articleTitle'] as String?;
  String? get articleSourceName => metadata['articleSourceName'] as String?;
  String? get articleImageUrl => metadata['articleImageUrl'] as String?;
  String? get articleUrl => metadata['articleUrl'] as String?;
  String? get articleDescription => metadata['articleDescription'] as String?;
  String? get articleId => metadata['articleId'] as String?;
  String? get listName => metadata['listName'] as String?;
  String? get listId => metadata['listId'] as String?;
  String? get followedUsername => metadata['followedUsername'] as String?;
  String? get followedUserId => metadata['followedUserId'] as String?;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'username': username,
      'userAvatarUrl': userAvatarUrl,
      'activityType': activityType.name,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory ActivityFeedItem.fromMap(Map<String, dynamic> map) {
    final metadata = Map<String, dynamic>.from(map['metadata'] ?? {});

    // Backward compatibility: some APIs send fields at top-level
    void mergeIfPresent(String key) {
      final value = map[key];
      if (value != null) {
        metadata[key] = value;
      }
    }

    mergeIfPresent('articleId');
    mergeIfPresent('articleTitle');
    mergeIfPresent('articleSourceName');
    mergeIfPresent('articleImageUrl');
    mergeIfPresent('articleUrl');
    mergeIfPresent('articleDescription');
    mergeIfPresent('listId');
    mergeIfPresent('listName');
    mergeIfPresent('followedUserId');
    mergeIfPresent('followedUsername');
    mergeIfPresent('commentId');
    mergeIfPresent('commentText');

    return ActivityFeedItem(
      id: map['id'] as String,
      userId: map['userId'] as String,
      username: map['username'] as String,
      userAvatarUrl: map['userAvatarUrl'] as String?,
      activityType: ActivityType.values.firstWhere(
        (e) => e.name == map['activityType'],
        orElse: () => ActivityType.readArticle,
      ),
      timestamp: DateTime.parse(map['timestamp'] as String),
      metadata: metadata,
    );
  }

  // Factory methods for different activity types
  factory ActivityFeedItem.readArticle({
    required String userId,
    required String username,
    String? userAvatarUrl,
    required String articleId,
    required String articleTitle,
  }) {
    return ActivityFeedItem(
      id: '${userId}_read_$articleId',
      userId: userId,
      username: username,
      userAvatarUrl: userAvatarUrl,
      activityType: ActivityType.readArticle,
      timestamp: DateTime.now(),
      metadata: {
        'articleId': articleId,
        'articleTitle': articleTitle,
      },
    );
  }

  factory ActivityFeedItem.createList({
    required String userId,
    required String username,
    String? userAvatarUrl,
    required String listId,
    required String listName,
  }) {
    return ActivityFeedItem(
      id: '${userId}_createlist_$listId',
      userId: userId,
      username: username,
      userAvatarUrl: userAvatarUrl,
      activityType: ActivityType.createList,
      timestamp: DateTime.now(),
      metadata: {
        'listId': listId,
        'listName': listName,
      },
    );
  }

  factory ActivityFeedItem.followUser({
    required String userId,
    required String username,
    String? userAvatarUrl,
    required String followedUserId,
    required String followedUsername,
  }) {
    return ActivityFeedItem(
      id: '${userId}_follow_$followedUserId',
      userId: userId,
      username: username,
      userAvatarUrl: userAvatarUrl,
      activityType: ActivityType.followUser,
      timestamp: DateTime.now(),
      metadata: {
        'followedUserId': followedUserId,
        'followedUsername': followedUsername,
      },
    );
  }
}
