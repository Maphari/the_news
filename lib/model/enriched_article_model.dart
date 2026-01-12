/// Model for structured content blocks
class ContentBlock {
  final ContentBlockType type;
  final String content;
  final int? level; // For headings (1-6)
  final String? alt; // For images
  final String? caption; // For images

  ContentBlock({
    required this.type,
    required this.content,
    this.level,
    this.alt,
    this.caption,
  });

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    return ContentBlock(
      type: ContentBlockType.fromString(json['type'] as String),
      content: json['content'] as String,
      level: json['level'] as int?,
      alt: json['alt'] as String?,
      caption: json['caption'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'content': content,
      'level': level,
      'alt': alt,
      'caption': caption,
    };
  }
}

/// Types of content blocks in structured content
enum ContentBlockType {
  heading,
  subheading,
  paragraph,
  image;

  String get name {
    switch (this) {
      case ContentBlockType.heading:
        return 'heading';
      case ContentBlockType.subheading:
        return 'subheading';
      case ContentBlockType.paragraph:
        return 'paragraph';
      case ContentBlockType.image:
        return 'image';
    }
  }

  static ContentBlockType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'heading':
        return ContentBlockType.heading;
      case 'subheading':
        return ContentBlockType.subheading;
      case 'paragraph':
        return ContentBlockType.paragraph;
      case 'image':
        return ContentBlockType.image;
      default:
        return ContentBlockType.paragraph;
    }
  }
}

/// Model for AI-generated summary
class AISummary {
  final String summary;
  final List<String> keyPoints;
  final DateTime? generatedAt;

  AISummary({
    required this.summary,
    required this.keyPoints,
    this.generatedAt,
  });

  factory AISummary.fromJson(Map<String, dynamic> json) {
    return AISummary(
      summary: json['summary'] as String? ?? '',
      keyPoints: json['keyPoints'] != null
          ? List<String>.from(json['keyPoints'] as List)
          : [],
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'keyPoints': keyPoints,
      'generatedAt': generatedAt?.toIso8601String(),
    };
  }
}

/// Model for enriched article content scraped from source URL
class EnrichedArticle {
  final String articleId;
  final String sourceUrl;
  final String? title;
  final String? content; // Full HTML content
  final String? textContent; // Plain text content
  final List<ContentBlock> structuredContent; // Structured content with formatting
  final String? excerpt;
  final String? author;
  final DateTime? publishedDate;
  final List<String> images;
  final List<VideoEmbed> videos;
  final int? readingTimeMinutes;
  final AISummary? aiSummary; // AI-generated summary (premium feature)
  final bool success;
  final String? error;

  EnrichedArticle({
    required this.articleId,
    required this.sourceUrl,
    this.title,
    this.content,
    this.textContent,
    this.structuredContent = const [],
    this.excerpt,
    this.author,
    this.publishedDate,
    this.images = const [],
    this.videos = const [],
    this.readingTimeMinutes,
    this.aiSummary,
    this.success = true,
    this.error,
  });

  factory EnrichedArticle.fromJson(Map<String, dynamic> json) {
    return EnrichedArticle(
      articleId: json['articleId'] as String,
      sourceUrl: json['sourceUrl'] as String,
      title: json['title'] as String?,
      content: json['content'] as String?,
      textContent: json['textContent'] as String? ?? json['fullText'] as String?,
      structuredContent: json['structuredContent'] != null
          ? (json['structuredContent'] as List)
              .map((block) => ContentBlock.fromJson(block as Map<String, dynamic>))
              .toList()
          : [],
      excerpt: json['excerpt'] as String?,
      author: json['author'] as String?,
      publishedDate: json['publishedDate'] != null
          ? DateTime.parse(json['publishedDate'] as String)
          : null,
      images: json['images'] != null
          ? List<String>.from(json['images'] as List)
          : [],
      videos: json['videos'] != null
          ? (json['videos'] as List)
              .map((v) => VideoEmbed.fromJson(v as Map<String, dynamic>))
              .toList()
          : [],
      readingTimeMinutes: json['readingTimeMinutes'] as int?,
      aiSummary: json['aiSummary'] != null
          ? AISummary.fromJson(json['aiSummary'] as Map<String, dynamic>)
          : null,
      success: json['success'] as bool? ?? true,
      error: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'articleId': articleId,
      'sourceUrl': sourceUrl,
      'title': title,
      'content': content,
      'textContent': textContent,
      'structuredContent': structuredContent.map((block) => block.toJson()).toList(),
      'excerpt': excerpt,
      'author': author,
      'publishedDate': publishedDate?.toIso8601String(),
      'images': images,
      'videos': videos.map((v) => v.toJson()).toList(),
      'readingTimeMinutes': readingTimeMinutes,
      'aiSummary': aiSummary?.toJson(),
      'success': success,
      'error': error,
    };
  }

  /// Check if enrichment was successful and has content
  bool get hasContent => success && (content?.isNotEmpty ?? false);

  /// Check if article has additional images beyond the main one
  bool get hasAdditionalImages => images.length > 1;

  /// Check if article has video embeds
  bool get hasVideos => videos.isNotEmpty;
}

/// Model for video embeds found in articles
class VideoEmbed {
  final String url;
  final VideoType type;
  final String? thumbnailUrl;
  final String? videoId;
  final String? title;

  VideoEmbed({
    required this.url,
    required this.type,
    this.thumbnailUrl,
    this.videoId,
    this.title,
  });

  factory VideoEmbed.fromJson(Map<String, dynamic> json) {
    return VideoEmbed(
      url: json['url'] as String,
      type: VideoType.fromString(json['type'] as String? ?? 'unknown'),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      videoId: json['videoId'] as String?,
      title: json['title'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'type': type.name,
      'thumbnailUrl': thumbnailUrl,
      'videoId': videoId,
      'title': title,
    };
  }
}

/// Types of video embeds supported
enum VideoType {
  youtube,
  vimeo,
  dailymotion,
  twitter,
  facebook,
  instagram,
  direct, // Direct MP4/other video file
  unknown;

  String get name {
    switch (this) {
      case VideoType.youtube:
        return 'youtube';
      case VideoType.vimeo:
        return 'vimeo';
      case VideoType.dailymotion:
        return 'dailymotion';
      case VideoType.twitter:
        return 'twitter';
      case VideoType.facebook:
        return 'facebook';
      case VideoType.instagram:
        return 'instagram';
      case VideoType.direct:
        return 'direct';
      case VideoType.unknown:
        return 'unknown';
    }
  }

  static VideoType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'youtube':
        return VideoType.youtube;
      case 'vimeo':
        return VideoType.vimeo;
      case 'dailymotion':
        return VideoType.dailymotion;
      case 'twitter':
        return VideoType.twitter;
      case 'facebook':
        return VideoType.facebook;
      case 'instagram':
        return VideoType.instagram;
      case 'direct':
        return VideoType.direct;
      default:
        return VideoType.unknown;
    }
  }
}
