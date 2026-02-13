class SocialPost {
  const SocialPost({
    required this.id,
    required this.userId,
    required this.username,
    required this.text,
    required this.createdAt,
    this.userAvatarUrl,
    this.heading,
    this.articleId,
    this.articleTitle,
    this.articleImageUrl,
    this.articleUrl,
    this.shareCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
  });

  final String id;
  final String userId;
  final String username;
  final String? userAvatarUrl;
  final String? heading;
  final String text;
  final String? articleId;
  final String? articleTitle;
  final String? articleImageUrl;
  final String? articleUrl;
  final int shareCount;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final DateTime createdAt;

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  SocialPost copyWith({
    String? heading,
    String? articleUrl,
    int? shareCount,
    int? likeCount,
    int? commentCount,
    bool? isLiked,
  }) {
    return SocialPost(
      id: id,
      userId: userId,
      username: username,
      userAvatarUrl: userAvatarUrl,
      heading: heading ?? this.heading,
      text: text,
      articleId: articleId,
      articleTitle: articleTitle,
      articleImageUrl: articleImageUrl,
      articleUrl: articleUrl ?? this.articleUrl,
      shareCount: shareCount ?? this.shareCount,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
      createdAt: createdAt,
    );
  }

  factory SocialPost.fromMap(Map<String, dynamic> map) {
    return SocialPost(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      username: map['username'] as String? ?? 'reader',
      userAvatarUrl: map['userAvatarUrl'] as String?,
      heading: map['heading'] as String?,
      text: map['text'] as String? ?? '',
      articleId: map['articleId'] as String?,
      articleTitle: map['articleTitle'] as String?,
      articleImageUrl: map['articleImageUrl'] as String?,
      articleUrl: map['articleUrl'] as String?,
      shareCount: _toInt(map['shareCount']),
      likeCount: _toInt(map['likeCount']),
      commentCount: _toInt(map['commentCount']),
      isLiked: map['isLiked'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
