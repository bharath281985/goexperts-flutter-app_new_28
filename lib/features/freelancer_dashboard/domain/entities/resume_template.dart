class ResumeTemplate {
  ResumeTemplate({
    required this.id,
    required this.key,
    required this.name,
    required this.category,
    required this.description,
    this.thumbnail,
    required this.atsFriendly,
    required this.version,
    required this.rendererKey,
    required this.supportedSections,
  });

  final String id;
  final String key;
  final String name;
  final String category;
  final String description;
  final String? thumbnail;
  final bool atsFriendly;
  final int version;
  final String rendererKey;
  final List<String> supportedSections;

  factory ResumeTemplate.fromJson(Map<String, dynamic> json) {
    final thumb = json['thumbnail']?.toString();
    return ResumeTemplate(
      id: json['id']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      thumbnail: (thumb != null && thumb.trim().isNotEmpty && thumb != 'null')
          ? thumb.trim()
          : null,
      atsFriendly: json['atsFriendly'] == true,
      version: (json['version'] as num?)?.toInt() ?? 1,
      rendererKey: json['rendererKey']?.toString() ?? '',
      supportedSections: (json['supportedSections'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
