class NetworkHighlight {
  const NetworkHighlight({
    required this.dedupeKey,
    required this.articleTitle,
    required this.latestSharedAt,
    required this.shareCount,
    this.likeCount = 0,
    this.commentCount = 0,
    this.articleId,
    this.articleSourceName,
    this.articleImageUrl,
    this.articleUrl,
    this.articleDescription,
    this.sharers = const [],
  });

  final String dedupeKey;
  final String? articleId;
  final String articleTitle;
  final String? articleSourceName;
  final String? articleImageUrl;
  final String? articleUrl;
  final String? articleDescription;
  final DateTime latestSharedAt;
  final int shareCount;
  final int likeCount;
  final int commentCount;
  final List<String> sharers;

  factory NetworkHighlight.fromMap(Map<String, dynamic> map) {
    return NetworkHighlight(
      dedupeKey: map['dedupeKey'] as String,
      articleId: map['articleId'] as String?,
      articleTitle: map['articleTitle'] as String? ?? 'Shared article',
      articleSourceName: map['articleSourceName'] as String?,
      articleImageUrl: map['articleImageUrl'] as String?,
      articleUrl: map['articleUrl'] as String?,
      articleDescription: map['articleDescription'] as String?,
      latestSharedAt: DateTime.parse(map['latestSharedAt'] as String),
      shareCount: map['shareCount'] as int? ?? 1,
      likeCount: map['likeCount'] as int? ?? 0,
      commentCount: map['commentCount'] as int? ?? 0,
      sharers: List<String>.from(map['sharers'] ?? const []),
    );
  }
}
