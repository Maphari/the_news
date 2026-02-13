/// Podcast model representing a podcast show
class Podcast {
  final String id;
  final String title;
  final String description;
  final String publisher;
  final String? imageUrl;
  final List<String> categories;
  final int totalEpisodes;
  final String? website;
  final String? rssUrl;
  final double? rating;
  final int? ratingCount;
  final String? language;
  final DateTime? latestEpisodeDate;

  Podcast({
    required this.id,
    required this.title,
    required this.description,
    required this.publisher,
    this.imageUrl,
    this.categories = const [],
    this.totalEpisodes = 0,
    this.website,
    this.rssUrl,
    this.rating,
    this.ratingCount,
    this.language,
    this.latestEpisodeDate,
  });

  factory Podcast.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value, [int fallback = 0]) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    int? toNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    double? toDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return Podcast(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      publisher: json['publisher'] ?? json['author'] ?? 'Unknown',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? json['thumbnail'],
      categories: json['categories'] != null
          ? List<String>.from(json['categories'])
          : json['genre_ids'] != null
              ? List<String>.from(
                  (json['genre_ids'] as List).map((e) => e.toString()))
              : [],
      totalEpisodes: toInt(json['total_episodes'] ?? json['totalEpisodes']),
      website: json['website'] ?? json['listennotes_url'],
      rssUrl: json['rss_url'] ?? json['rss'],
      rating: toDouble(json['rating']),
      ratingCount: toNullableInt(json['rating_count'] ?? json['ratingCount']),
      language: json['language'],
      latestEpisodeDate: json['latest_episode_date'] != null
          ? DateTime.tryParse(json['latest_episode_date'])
          : json['latestEpisodeDate'] != null
              ? DateTime.tryParse(json['latestEpisodeDate'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'publisher': publisher,
      'imageUrl': imageUrl,
      'categories': categories,
      'totalEpisodes': totalEpisodes,
      'website': website,
      'rssUrl': rssUrl,
      'rating': rating,
      'ratingCount': ratingCount,
      'language': language,
      'latestEpisodeDate': latestEpisodeDate?.toIso8601String(),
    };
  }

  Podcast copyWith({
    String? id,
    String? title,
    String? description,
    String? publisher,
    String? imageUrl,
    List<String>? categories,
    int? totalEpisodes,
    String? website,
    String? rssUrl,
    double? rating,
    int? ratingCount,
    String? language,
    DateTime? latestEpisodeDate,
  }) {
    return Podcast(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      publisher: publisher ?? this.publisher,
      imageUrl: imageUrl ?? this.imageUrl,
      categories: categories ?? this.categories,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      website: website ?? this.website,
      rssUrl: rssUrl ?? this.rssUrl,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      language: language ?? this.language,
      latestEpisodeDate: latestEpisodeDate ?? this.latestEpisodeDate,
    );
  }
}

/// Episode model representing a podcast episode
class Episode {
  final String id;
  final String podcastId;
  final String podcastTitle;
  final String title;
  final String description;
  final String audioUrl;
  final int durationSeconds;
  final DateTime publishedDate;
  final String? imageUrl;
  final int? fileSize;
  final String? podcastImageUrl;
  final String? transcript;
  final bool isExplicit;

  Episode({
    required this.id,
    required this.podcastId,
    required this.podcastTitle,
    required this.title,
    required this.description,
    required this.audioUrl,
    required this.durationSeconds,
    required this.publishedDate,
    this.imageUrl,
    this.fileSize,
    this.podcastImageUrl,
    this.transcript,
    this.isExplicit = false,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value, [int fallback = 0]) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    int? toNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    return Episode(
      id: json['id']?.toString() ?? '',
      podcastId: json['podcast_id']?.toString() ?? json['podcastId']?.toString() ?? '',
      podcastTitle: json['podcast_title'] ?? json['podcastTitle'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      audioUrl: json['audio_url'] ?? json['audioUrl'] ?? json['audio'] ?? '',
      durationSeconds: toInt(
        json['duration_seconds'] ?? json['durationSeconds'] ?? json['audio_length_sec'],
      ),
      publishedDate: json['published_date'] != null
          ? DateTime.tryParse(json['published_date']) ?? DateTime.now()
          : json['publishedDate'] != null
              ? DateTime.tryParse(json['publishedDate']) ?? DateTime.now()
              : json['pub_date_ms'] != null
                  ? DateTime.fromMillisecondsSinceEpoch(json['pub_date_ms'])
                  : DateTime.now(),
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? json['thumbnail'],
      fileSize: toNullableInt(json['file_size'] ?? json['fileSize']),
      podcastImageUrl: json['podcast_image_url'] ?? json['podcastImageUrl'],
      transcript: json['transcript'],
      isExplicit: json['is_explicit'] ?? json['explicit_content'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'podcastId': podcastId,
      'podcastTitle': podcastTitle,
      'title': title,
      'description': description,
      'audioUrl': audioUrl,
      'durationSeconds': durationSeconds,
      'publishedDate': publishedDate.toIso8601String(),
      'imageUrl': imageUrl,
      'fileSize': fileSize,
      'podcastImageUrl': podcastImageUrl,
      'transcript': transcript,
      'isExplicit': isExplicit,
    };
  }

  /// Format duration as HH:MM:SS or MM:SS
  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Episode copyWith({
    String? id,
    String? podcastId,
    String? podcastTitle,
    String? title,
    String? description,
    String? audioUrl,
    int? durationSeconds,
    DateTime? publishedDate,
    String? imageUrl,
    int? fileSize,
    String? podcastImageUrl,
    String? transcript,
    bool? isExplicit,
  }) {
    return Episode(
      id: id ?? this.id,
      podcastId: podcastId ?? this.podcastId,
      podcastTitle: podcastTitle ?? this.podcastTitle,
      title: title ?? this.title,
      description: description ?? this.description,
      audioUrl: audioUrl ?? this.audioUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      publishedDate: publishedDate ?? this.publishedDate,
      imageUrl: imageUrl ?? this.imageUrl,
      fileSize: fileSize ?? this.fileSize,
      podcastImageUrl: podcastImageUrl ?? this.podcastImageUrl,
      transcript: transcript ?? this.transcript,
      isExplicit: isExplicit ?? this.isExplicit,
    );
  }
}

/// Listening progress for an episode
class ListeningProgress {
  final String episodeId;
  final String podcastId;
  final int progressSeconds;
  final int totalSeconds;
  final DateTime lastListenedAt;
  final bool completed;

  ListeningProgress({
    required this.episodeId,
    required this.podcastId,
    required this.progressSeconds,
    required this.totalSeconds,
    required this.lastListenedAt,
    this.completed = false,
  });

  double get progressPercent => totalSeconds > 0 ? progressSeconds / totalSeconds : 0;

  factory ListeningProgress.fromJson(Map<String, dynamic> json) {
    return ListeningProgress(
      episodeId: json['episodeId'] ?? json['episode_id'] ?? '',
      podcastId: json['podcastId'] ?? json['podcast_id'] ?? '',
      progressSeconds: json['progressSeconds'] ?? json['progress_seconds'] ?? 0,
      totalSeconds: json['totalSeconds'] ?? json['total_seconds'] ?? 0,
      lastListenedAt: json['lastListenedAt'] != null
          ? DateTime.parse(json['lastListenedAt'])
          : json['last_listened_at'] != null
              ? DateTime.parse(json['last_listened_at'])
              : DateTime.now(),
      completed: json['completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'episodeId': episodeId,
      'podcastId': podcastId,
      'progressSeconds': progressSeconds,
      'totalSeconds': totalSeconds,
      'lastListenedAt': lastListenedAt.toIso8601String(),
      'completed': completed,
    };
  }
}

/// Saved podcast with additional metadata
class SavedPodcast {
  final Podcast podcast;
  final DateTime savedAt;
  final bool notificationsEnabled;

  SavedPodcast({
    required this.podcast,
    required this.savedAt,
    this.notificationsEnabled = false,
  });

  factory SavedPodcast.fromJson(Map<String, dynamic> json) {
    return SavedPodcast(
      podcast: Podcast.fromJson(json['podcast'] ?? json),
      savedAt: json['savedAt'] != null
          ? DateTime.parse(json['savedAt'])
          : json['saved_at'] != null
              ? DateTime.parse(json['saved_at'])
              : DateTime.now(),
      notificationsEnabled: json['notificationsEnabled'] ?? json['notifications_enabled'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'podcast': podcast.toJson(),
      'savedAt': savedAt.toIso8601String(),
      'notificationsEnabled': notificationsEnabled,
    };
  }
}
