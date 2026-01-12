enum BiasType {
  leftLeaning,
  rightLeaning,
  center,
  sensationalist,
  corporate,
  governmental,
}

enum BiasLevel {
  minimal, // 0-20%
  slight, // 21-40%
  moderate, // 41-60%
  significant, // 61-80%
  extreme, // 81-100%
}

class BiasIndicator {
  final String type;
  final String example;
  final String explanation;

  BiasIndicator({
    required this.type,
    required this.example,
    required this.explanation,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'example': example,
      'explanation': explanation,
    };
  }

  factory BiasIndicator.fromMap(Map<String, dynamic> map) {
    return BiasIndicator(
      type: map['type'] as String,
      example: map['example'] as String,
      explanation: map['explanation'] as String,
    );
  }
}

class BiasAnalysis {
  final String articleId;
  final BiasType primaryBias;
  final BiasLevel biasLevel;
  final double biasScore; // 0.0 (left) to 1.0 (right), 0.5 is center
  final List<BiasIndicator> indicators;
  final String summary;
  final DateTime analyzedAt;

  BiasAnalysis({
    required this.articleId,
    required this.primaryBias,
    required this.biasLevel,
    required this.biasScore,
    required this.indicators,
    required this.summary,
    required this.analyzedAt,
  });

  String get biasLevelLabel {
    switch (biasLevel) {
      case BiasLevel.minimal:
        return 'Minimal Bias';
      case BiasLevel.slight:
        return 'Slight Bias';
      case BiasLevel.moderate:
        return 'Moderate Bias';
      case BiasLevel.significant:
        return 'Significant Bias';
      case BiasLevel.extreme:
        return 'Extreme Bias';
    }
  }

  String get biasTypeLabel {
    switch (primaryBias) {
      case BiasType.leftLeaning:
        return 'Left-Leaning';
      case BiasType.rightLeaning:
        return 'Right-Leaning';
      case BiasType.center:
        return 'Centrist';
      case BiasType.sensationalist:
        return 'Sensationalist';
      case BiasType.corporate:
        return 'Corporate-Leaning';
      case BiasType.governmental:
        return 'Government-Aligned';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'articleId': articleId,
      'primaryBias': primaryBias.name,
      'biasLevel': biasLevel.name,
      'biasScore': biasScore,
      'indicators': indicators.map((i) => i.toMap()).toList(),
      'summary': summary,
      'analyzedAt': analyzedAt.toIso8601String(),
    };
  }

  factory BiasAnalysis.fromMap(Map<String, dynamic> map) {
    return BiasAnalysis(
      articleId: map['articleId'] as String,
      primaryBias: BiasType.values.firstWhere(
        (e) => e.name == map['primaryBias'],
        orElse: () => BiasType.center,
      ),
      biasLevel: BiasLevel.values.firstWhere(
        (e) => e.name == map['biasLevel'],
        orElse: () => BiasLevel.minimal,
      ),
      biasScore: map['biasScore'] as double,
      indicators: (map['indicators'] as List).map((i) => BiasIndicator.fromMap(i)).toList(),
      summary: map['summary'] as String,
      analyzedAt: DateTime.parse(map['analyzedAt'] as String),
    );
  }
}
