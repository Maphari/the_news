class UserProfile {
  final String userId;
  final String username;
  final String displayName;
  final String? bio;
  final String? avatarUrl;
  final String? coverImageUrl;
  final DateTime joinedDate;
  final int followersCount;
  final int followingCount;
  final int articlesReadCount;
  final int collectionsCount;
  final bool isPublic;
  final List<String> interests;
  final Map<String, dynamic> stats;

  UserProfile({
    required this.userId,
    required this.username,
    required this.displayName,
    this.bio,
    this.avatarUrl,
    this.coverImageUrl,
    required this.joinedDate,
    this.followersCount = 0,
    this.followingCount = 0,
    this.articlesReadCount = 0,
    this.collectionsCount = 0,
    this.isPublic = true,
    this.interests = const [],
    this.stats = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'displayName': displayName,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'coverImageUrl': coverImageUrl,
      'joinedDate': joinedDate.toIso8601String(),
      'followersCount': followersCount,
      'followingCount': followingCount,
      'articlesReadCount': articlesReadCount,
      'collectionsCount': collectionsCount,
      'isPublic': isPublic,
      'interests': interests,
      'stats': stats,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['userId'] as String,
      username: map['username'] as String,
      displayName: map['displayName'] as String,
      bio: map['bio'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
      coverImageUrl: map['coverImageUrl'] as String?,
      joinedDate: DateTime.parse(map['joinedDate'] as String),
      followersCount: map['followersCount'] as int? ?? 0,
      followingCount: map['followingCount'] as int? ?? 0,
      articlesReadCount: map['articlesReadCount'] as int? ?? 0,
      collectionsCount: map['collectionsCount'] as int? ?? 0,
      isPublic: map['isPublic'] as bool? ?? true,
      interests: List<String>.from(map['interests'] ?? []),
      stats: Map<String, dynamic>.from(map['stats'] ?? {}),
    );
  }

  UserProfile copyWith({
    String? userId,
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? coverImageUrl,
    DateTime? joinedDate,
    int? followersCount,
    int? followingCount,
    int? articlesReadCount,
    int? collectionsCount,
    bool? isPublic,
    List<String>? interests,
    Map<String, dynamic>? stats,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      joinedDate: joinedDate ?? this.joinedDate,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      articlesReadCount: articlesReadCount ?? this.articlesReadCount,
      collectionsCount: collectionsCount ?? this.collectionsCount,
      isPublic: isPublic ?? this.isPublic,
      interests: interests ?? this.interests,
      stats: stats ?? this.stats,
    );
  }
}

class UserFollow {
  final String id;
  final String followerId; // User who follows
  final String followingId; // User being followed
  final DateTime followedAt;

  UserFollow({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.followedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'followerId': followerId,
      'followingId': followingId,
      'followedAt': followedAt.toIso8601String(),
    };
  }

  factory UserFollow.fromMap(Map<String, dynamic> map) {
    return UserFollow(
      id: map['id'] as String,
      followerId: map['followerId'] as String,
      followingId: map['followingId'] as String,
      followedAt: DateTime.parse(map['followedAt'] as String),
    );
  }
}
