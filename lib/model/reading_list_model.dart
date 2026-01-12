enum ListVisibility {
  private_,
  public,
  friendsOnly,
}

class ReadingList {
  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final String ownerName;
  final ListVisibility visibility;
  final List<String> articleIds;
  final List<String> collaboratorIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? coverImageUrl;
  final List<String> tags;
  final int viewCount;
  final int saveCount;

  ReadingList({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    required this.ownerName,
    this.visibility = ListVisibility.public,
    this.articleIds = const [],
    this.collaboratorIds = const [],
    required this.createdAt,
    required this.updatedAt,
    this.coverImageUrl,
    this.tags = const [],
    this.viewCount = 0,
    this.saveCount = 0,
  });

  int get articleCount => articleIds.length;
  int get collaboratorCount => collaboratorIds.length;
  bool get isCollaborative => collaboratorIds.isNotEmpty;
  bool get isPrivate => visibility == ListVisibility.private_;
  bool get isPublic => visibility == ListVisibility.public;

  bool isOwner(String userId) => ownerId == userId;
  bool isCollaborator(String userId) => collaboratorIds.contains(userId);
  bool canEdit(String userId) => isOwner(userId) || isCollaborator(userId);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'visibility': visibility.name,
      'articleIds': articleIds,
      'collaboratorIds': collaboratorIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'coverImageUrl': coverImageUrl,
      'tags': tags,
      'viewCount': viewCount,
      'saveCount': saveCount,
    };
  }

  factory ReadingList.fromMap(Map<String, dynamic> map) {
    return ReadingList(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      ownerId: map['ownerId'] as String,
      ownerName: map['ownerName'] as String,
      visibility: ListVisibility.values.firstWhere(
        (e) => e.name == map['visibility'],
        orElse: () => ListVisibility.public,
      ),
      articleIds: List<String>.from(map['articleIds'] ?? []),
      collaboratorIds: List<String>.from(map['collaboratorIds'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      coverImageUrl: map['coverImageUrl'] as String?,
      tags: List<String>.from(map['tags'] ?? []),
      viewCount: map['viewCount'] as int? ?? 0,
      saveCount: map['saveCount'] as int? ?? 0,
    );
  }

  ReadingList copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    String? ownerName,
    ListVisibility? visibility,
    List<String>? articleIds,
    List<String>? collaboratorIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? coverImageUrl,
    List<String>? tags,
    int? viewCount,
    int? saveCount,
  }) {
    return ReadingList(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      visibility: visibility ?? this.visibility,
      articleIds: articleIds ?? this.articleIds,
      collaboratorIds: collaboratorIds ?? this.collaboratorIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      tags: tags ?? this.tags,
      viewCount: viewCount ?? this.viewCount,
      saveCount: saveCount ?? this.saveCount,
    );
  }
}

class ListArticle {
  final String listId;
  final String articleId;
  final String addedBy;
  final DateTime addedAt;
  final String? note;

  ListArticle({
    required this.listId,
    required this.articleId,
    required this.addedBy,
    required this.addedAt,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'listId': listId,
      'articleId': articleId,
      'addedBy': addedBy,
      'addedAt': addedAt.toIso8601String(),
      'note': note,
    };
  }

  factory ListArticle.fromMap(Map<String, dynamic> map) {
    return ListArticle(
      listId: map['listId'] as String,
      articleId: map['articleId'] as String,
      addedBy: map['addedBy'] as String,
      addedAt: DateTime.parse(map['addedAt'] as String),
      note: map['note'] as String?,
    );
  }
}
