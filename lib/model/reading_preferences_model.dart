/// Reading preferences for customizing article reading experience
class ReadingPreferences {
  final FontSize fontSize;
  final FontFamily fontFamily;
  final LineSpacing lineSpacing;
  final ReadingTheme readingTheme;

  const ReadingPreferences({
    this.fontSize = FontSize.medium,
    this.fontFamily = FontFamily.system,
    this.lineSpacing = LineSpacing.normal,
    this.readingTheme = ReadingTheme.system,
  });

  ReadingPreferences copyWith({
    FontSize? fontSize,
    FontFamily? fontFamily,
    LineSpacing? lineSpacing,
    ReadingTheme? readingTheme,
  }) {
    return ReadingPreferences(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      readingTheme: readingTheme ?? this.readingTheme,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize.name,
      'fontFamily': fontFamily.name,
      'lineSpacing': lineSpacing.name,
      'readingTheme': readingTheme.name,
    };
  }

  factory ReadingPreferences.fromJson(Map<String, dynamic> json) {
    return ReadingPreferences(
      fontSize: FontSize.values.firstWhere(
        (e) => e.name == json['fontSize'],
        orElse: () => FontSize.medium,
      ),
      fontFamily: FontFamily.values.firstWhere(
        (e) => e.name == json['fontFamily'],
        orElse: () => FontFamily.system,
      ),
      lineSpacing: LineSpacing.values.firstWhere(
        (e) => e.name == json['lineSpacing'],
        orElse: () => LineSpacing.normal,
      ),
      readingTheme: ReadingTheme.values.firstWhere(
        (e) => e.name == json['readingTheme'],
        orElse: () => ReadingTheme.system,
      ),
    );
  }
}

/// Font size options
enum FontSize {
  small(14.0, 'Small', 'A'),
  medium(16.0, 'Medium', 'A'),
  large(18.0, 'Large', 'A'),
  extraLarge(20.0, 'Extra Large', 'A'),
  huge(24.0, 'Huge', 'A');

  final double size;
  final String label;
  final String icon;

  const FontSize(this.size, this.label, this.icon);

  /// Get scaled size for different text styles
  double getScaledSize(double baseScale) {
    return size * baseScale;
  }
}

/// Font family options
enum FontFamily {
  system('System', 'Default system font', null),
  nexaTrial('NexaTrial', 'Clean and modern', 'NexaTrial'),
  outfit('Outfit', 'Friendly and readable', 'Outfit'),
  serif('Serif', 'Classic reading experience', 'Georgia'),
  openDyslexic('OpenDyslexic', 'Designed for dyslexia', null); // Would need to add font

  final String label;
  final String description;
  final String? fontFamily;

  const FontFamily(this.label, this.description, this.fontFamily);

  /// Get the actual font family string for TextStyle
  String? get value => fontFamily;
}

/// Line spacing options
enum LineSpacing {
  compact(1.2, 'Compact', 'Tight spacing for more content'),
  normal(1.5, 'Normal', 'Comfortable reading'),
  relaxed(1.8, 'Relaxed', 'Extra space between lines'),
  spacious(2.1, 'Spacious', 'Maximum readability');

  final double height;
  final String label;
  final String description;

  const LineSpacing(this.height, this.label, this.description);
}

/// Reading theme options
enum ReadingTheme {
  system('System', 'Follow device theme', null, null),
  light('Light', 'Light background', 0xFFFFFFFF, 0xFF000000),
  dark('Dark', 'Dark background', 0xFF121212, 0xFFFFFFFF),
  sepia('Sepia', 'Warm paper tone', 0xFFF4ECD8, 0xFF5F4B32),
  highContrast('High Contrast', 'Maximum contrast', 0xFF000000, 0xFFFFFFFF);

  final String label;
  final String description;
  final int? backgroundColor;
  final int? textColor;

  const ReadingTheme(
    this.label,
    this.description,
    this.backgroundColor,
    this.textColor,
  );

  /// Check if this is a custom theme (not system)
  bool get isCustomTheme => backgroundColor != null;
}
