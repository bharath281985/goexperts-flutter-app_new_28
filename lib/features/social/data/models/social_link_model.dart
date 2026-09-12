class SocialLink {
  final String id;
  final String platform;
  final String url;

  SocialLink({
    required this.id,
    required this.platform,
    required this.url,
  });

  factory SocialLink.fromJson(Map<String, dynamic> json) {
    return SocialLink(
      id: json['id']?.toString() ?? '',
      platform: json['platform']?.toString() ?? '',
      url: json['url']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'platform': platform,
      'url': url,
    };
  }

  SocialLink copyWith({
    String? id,
    String? platform,
    String? url,
  }) {
    return SocialLink(
      id: id ?? this.id,
      platform: platform ?? this.platform,
      url: url ?? this.url,
    );
  }
}
