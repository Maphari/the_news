class CustomPromptTemplate {
  final int? id;
  final String name;
  final String description;
  final String promptTemplate;
  final DateTime createdAt;
  final bool isFavorite;
  final int usageCount;

  CustomPromptTemplate({
    this.id,
    required this.name,
    required this.description,
    required this.promptTemplate,
    required this.createdAt,
    this.isFavorite = false,
    this.usageCount = 0,
  });

  String generatePrompt(Map<String, String> variables) {
    String result = promptTemplate;
    variables.forEach((key, value) {
      result = result.replaceAll('{$key}', value);
    });
    return result;
  }

  // Extract variable names from template
  List<String> get requiredVariables {
    final regex = RegExp(r'\{(\w+)\}');
    final matches = regex.allMatches(promptTemplate);
    return matches.map((m) => m.group(1)!).toSet().toList();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'promptTemplate': promptTemplate,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite ? 1 : 0,
      'usageCount': usageCount,
    };
  }

  factory CustomPromptTemplate.fromMap(Map<String, dynamic> map) {
    return CustomPromptTemplate(
      id: map['id'] as int?,
      name: map['name'] as String,
      description: map['description'] as String,
      promptTemplate: map['promptTemplate'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isFavorite: (map['isFavorite'] as int?) == 1,
      usageCount: map['usageCount'] as int? ?? 0,
    );
  }

  CustomPromptTemplate copyWith({
    int? id,
    String? name,
    String? description,
    String? promptTemplate,
    DateTime? createdAt,
    bool? isFavorite,
    int? usageCount,
  }) {
    return CustomPromptTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      promptTemplate: promptTemplate ?? this.promptTemplate,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      usageCount: usageCount ?? this.usageCount,
    );
  }
}

class CustomPromptResult {
  final String promptName;
  final String articleId;
  final String result;
  final DateTime executedAt;

  CustomPromptResult({
    required this.promptName,
    required this.articleId,
    required this.result,
    required this.executedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'promptName': promptName,
      'articleId': articleId,
      'result': result,
      'executedAt': executedAt.toIso8601String(),
    };
  }

  factory CustomPromptResult.fromMap(Map<String, dynamic> map) {
    return CustomPromptResult(
      promptName: map['promptName'] as String,
      articleId: map['articleId'] as String,
      result: map['result'] as String,
      executedAt: DateTime.parse(map['executedAt'] as String),
    );
  }
}
