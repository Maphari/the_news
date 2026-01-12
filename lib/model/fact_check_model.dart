enum FactCheckVerdict {
  verified, // Claim is supported by evidence
  disputed, // Claim has conflicting evidence
  misleading, // Claim is technically true but missing context
  falseInfo, // Claim is demonstrably false
  unverifiable, // Cannot be verified with available information
}

class FactCheckClaim {
  final String claim;
  final FactCheckVerdict verdict;
  final String explanation;
  final List<String> sources;
  final double confidenceScore; // 0.0 to 1.0

  FactCheckClaim({
    required this.claim,
    required this.verdict,
    required this.explanation,
    this.sources = const [],
    this.confidenceScore = 0.0,
  });

  String get verdictLabel {
    switch (verdict) {
      case FactCheckVerdict.verified:
        return 'Verified';
      case FactCheckVerdict.disputed:
        return 'Disputed';
      case FactCheckVerdict.misleading:
        return 'Misleading';
      case FactCheckVerdict.falseInfo:
        return 'False';
      case FactCheckVerdict.unverifiable:
        return 'Unverifiable';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'claim': claim,
      'verdict': verdict.name,
      'explanation': explanation,
      'sources': sources,
      'confidenceScore': confidenceScore,
    };
  }

  factory FactCheckClaim.fromMap(Map<String, dynamic> map) {
    return FactCheckClaim(
      claim: map['claim'] as String,
      verdict: FactCheckVerdict.values.firstWhere(
        (e) => e.name == map['verdict'],
        orElse: () => FactCheckVerdict.unverifiable,
      ),
      explanation: map['explanation'] as String,
      sources: List<String>.from(map['sources'] ?? []),
      confidenceScore: map['confidenceScore'] as double? ?? 0.0,
    );
  }
}

class FactCheckResult {
  final String articleId;
  final List<FactCheckClaim> claims;
  final DateTime checkedAt;
  final String overallAssessment;

  FactCheckResult({
    required this.articleId,
    required this.claims,
    required this.checkedAt,
    required this.overallAssessment,
  });

  int get verifiedCount => claims.where((c) => c.verdict == FactCheckVerdict.verified).length;
  int get disputedCount => claims.where((c) => c.verdict == FactCheckVerdict.disputed).length;
  int get falseCount => claims.where((c) => c.verdict == FactCheckVerdict.falseInfo).length;
  int get misleadingCount => claims.where((c) => c.verdict == FactCheckVerdict.misleading).length;

  double get credibilityScore {
    if (claims.isEmpty) return 0.5;
    return verifiedCount / claims.length;
  }

  Map<String, dynamic> toMap() {
    return {
      'articleId': articleId,
      'claims': claims.map((c) => c.toMap()).toList(),
      'checkedAt': checkedAt.toIso8601String(),
      'overallAssessment': overallAssessment,
    };
  }

  factory FactCheckResult.fromMap(Map<String, dynamic> map) {
    return FactCheckResult(
      articleId: map['articleId'] as String,
      claims: (map['claims'] as List).map((c) => FactCheckClaim.fromMap(c)).toList(),
      checkedAt: DateTime.parse(map['checkedAt'] as String),
      overallAssessment: map['overallAssessment'] as String,
    );
  }
}
