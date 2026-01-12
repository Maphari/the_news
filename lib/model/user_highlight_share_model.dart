class HighlightShare {
  final String id;
  final String userId;
  final String userName;
  final String articleId;
  final String highlightText;
  final String note;
  final DateTime sharedAt;
  final int likes;

  const HighlightShare({
    required this.id,
    required this.userId,
    required this.userName,
    required this.articleId,
    required this.highlightText,
    required this.note,
    required this.sharedAt,
    this.likes = 0,
  });
}