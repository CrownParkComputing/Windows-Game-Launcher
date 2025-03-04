class GameConfig {
  final String name;
  final String executablePath;
  final String logoPath;
  final String videoPath;
  final String storyText;
  final String bannerPath;

  GameConfig({
    required this.name,
    required this.executablePath,
    required this.logoPath,
    this.videoPath = '',
    this.storyText = '',
    this.bannerPath = '',
  });

  // Create a GameConfig from a JSON map
  factory GameConfig.fromJson(Map<String, dynamic> json) {
    return GameConfig(
      name: json['name'] as String,
      executablePath: json['executablePath'] as String,
      logoPath: json['logoPath'] as String,
      videoPath: json['videoPath'] as String? ?? '',
      storyText: json['storyText'] as String? ?? '',
      bannerPath: json['bannerPath'] as String? ?? '',
    );
  }

  // Convert a GameConfig to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'executablePath': executablePath,
      'logoPath': logoPath,
      'videoPath': videoPath,
      'storyText': storyText,
      'bannerPath': bannerPath,
    };
  }

  // Create a copy of this GameConfig with some fields replaced
  GameConfig copyWith({
    String? name,
    String? executablePath,
    String? logoPath,
    String? videoPath,
    String? storyText,
    String? bannerPath,
  }) {
    return GameConfig(
      name: name ?? this.name,
      executablePath: executablePath ?? this.executablePath,
      logoPath: logoPath ?? this.logoPath,
      videoPath: videoPath ?? this.videoPath,
      storyText: storyText ?? this.storyText,
      bannerPath: bannerPath ?? this.bannerPath,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameConfig &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          executablePath == other.executablePath &&
          logoPath == other.logoPath &&
          videoPath == other.videoPath &&
          storyText == other.storyText &&
          bannerPath == other.bannerPath;

  @override
  int get hashCode =>
      name.hashCode ^
      executablePath.hashCode ^
      logoPath.hashCode ^
      videoPath.hashCode ^
      storyText.hashCode ^
      bannerPath.hashCode;

  @override
  String toString() {
    return 'GameConfig{name: $name, executablePath: $executablePath, logoPath: $logoPath, videoPath: $videoPath, storyText: $storyText, bannerPath: $bannerPath}';
  }
}
