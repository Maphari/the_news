class ArticleModel {
  final String articleId;
  final String link;
  final String title;
  final String description;
  final String content;
  final List<String> keywords;
  final List<String> creator;
  final String language;
  final List<String> country;
  final List<String> category;
  final String datatype;
  final DateTime pubDate;
  final String pubDateTZ;
  final String? imageUrl;
  final String? videoUrl;
  final String sourceId;
  final String sourceName;
  final int sourcePriority;
  final String sourceUrl;
  final String sourceIcon;
  final String sentiment;
  final SentimentStats sentimentStats;
  final List<String> aiTag;
  final List<String> aiRegion;
  final String? aiOrg;
  final String aiSummary;
  final bool duplicate;

  ArticleModel({
    required this.articleId,
    required this.link,
    required this.title,
    required this.description,
    required this.content,
    required this.keywords,
    required this.creator,
    required this.language,
    required this.country,
    required this.category,
    required this.datatype,
    required this.pubDate,
    required this.pubDateTZ,
    this.imageUrl,
    this.videoUrl,
    required this.sourceId,
    required this.sourceName,
    required this.sourcePriority,
    required this.sourceUrl,
    required this.sourceIcon,
    required this.sentiment,
    required this.sentimentStats,
    required this.aiTag,
    required this.aiRegion,
    this.aiOrg,
    required this.aiSummary,
    required this.duplicate,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      articleId: json['article_id'] ?? '',
      link: json['link'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      content: json['content'] ?? '',
      keywords: List<String>.from(json['keywords'] ?? []),
      creator: List<String>.from(json['creator'] ?? []),
      language: json['language'] ?? 'en',
      country: List<String>.from(json['country'] ?? []),
      category: List<String>.from(json['category'] ?? []),
      datatype: json['datatype'] ?? 'news',
      pubDate: json['pubDate'] != null
          ? DateTime.parse(json['pubDate'])
          : DateTime.now(),
      pubDateTZ: json['pubDateTZ'] ?? 'UTC',
      imageUrl: json['image_url'],
      videoUrl: json['video_url'],
      sourceId: json['source_id'] ?? '',
      sourceName: json['source_name'] ?? 'Unknown',
      sourcePriority: json['source_priority'] ?? 0,
      sourceUrl: json['source_url'] ?? '',
      sourceIcon: json['source_icon'] ?? '',
      sentiment: json['sentiment'] ?? 'neutral',
      sentimentStats: json['sentiment_stats'] != null
          ? SentimentStats.fromJson(json['sentiment_stats'])
          : SentimentStats(negative: 0, neutral: 1, positive: 0),
      aiTag: List<String>.from(json['ai_tag'] ?? []),
      aiRegion: List<String>.from(json['ai_region'] ?? []),
      aiOrg: json['ai_org'],
      aiSummary: json['ai_summary'] ?? '',
      duplicate: json['duplicate'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'article_id': articleId,
      'link': link,
      'title': title,
      'description': description,
      'content': content,
      'keywords': keywords,
      'creator': creator,
      'language': language,
      'country': country,
      'category': category,
      'datatype': datatype,
      'pubDate': pubDate.toIso8601String(),
      'pubDateTZ': pubDateTZ,
      'image_url': imageUrl,
      'video_url': videoUrl,
      'source_id': sourceId,
      'source_name': sourceName,
      'source_priority': sourcePriority,
      'source_url': sourceUrl,
      'source_icon': sourceIcon,
      'sentiment': sentiment,
      'sentiment_stats': sentimentStats.toJson(),
      'ai_tag': aiTag,
      'ai_region': aiRegion,
      'ai_org': aiOrg,
      'ai_summary': aiSummary,
      'duplicate': duplicate,
    };
  }
}

class SentimentStats {
  final double negative;
  final double neutral;
  final double positive;

  SentimentStats({
    required this.negative,
    required this.neutral,
    required this.positive,
  });

  factory SentimentStats.fromJson(Map<String, dynamic> json) {
    return SentimentStats(
      negative: (json['negative'] as num).toDouble(),
      neutral: (json['neutral'] as num).toDouble(),
      positive: (json['positive'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'negative': negative,
      'neutral': neutral,
      'positive': positive,
    };
  }
}
