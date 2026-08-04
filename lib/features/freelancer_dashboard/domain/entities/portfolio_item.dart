import 'package:equatable/equatable.dart';

class PortfolioSkill extends Equatable {
  const PortfolioSkill({required this.skillId, required this.skillName});

  final String skillId;
  final String skillName;

  Map<String, dynamic> toJson() => {'skillId': skillId, 'skillName': skillName};

  factory PortfolioSkill.fromJson(Map<String, dynamic> json) {
    return PortfolioSkill(
      skillId: json['skillId']?.toString() ?? json['id']?.toString() ?? '',
      skillName:
          json['skillName']?.toString() ??
          json['name']?.toString() ??
          json['label']?.toString() ??
          '',
    );
  }

  @override
  List<Object?> get props => [skillId, skillName];
}

class PortfolioItem extends Equatable {
  const PortfolioItem({
    required this.id,
    required this.title,
    required this.description,
    this.projectUrl,
    this.technologies = const [],
    this.industry = '',
    this.industryId = '',
    this.categoryId = '',
    this.skills = const [],
    this.status = '',
    this.client = '',
    this.duration = '',
    this.teamSize = '',
    this.teamSizeId = '',
    this.role = '',
    this.category = '',
    this.githubUrl = '',
    this.liveUrl = '',
    this.overview = '',
    this.coverMedia = '',
    this.videoDemo = '',
    this.pdfCaseStudy = '',
    this.extraScreenshot = '',
    this.completionDate,
    this.createdAt,
    this.updatedAt,
    this.responseMessage,
  });

  final String id;
  final String title;
  final String description;
  final String? projectUrl;
  final List<String> technologies;
  final String industry;
  final String industryId;
  final String categoryId;
  final List<PortfolioSkill> skills;
  final String status;
  final String client;
  final String duration;
  final String teamSize;
  final String teamSizeId;
  final String role;
  final String category;
  final String githubUrl;
  final String liveUrl;
  final String overview;
  final String coverMedia;
  final String videoDemo;
  final String pdfCaseStudy;
  final String extraScreenshot;
  final DateTime? completionDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? responseMessage;

  String get displayDescription => description.isNotEmpty
      ? description
      : overview.isNotEmpty
      ? overview
      : '';

  List<String> get displaySkillNames {
    if (skills.isNotEmpty) return skills.map((e) => e.skillName).toList();
    return technologies;
  }

  factory PortfolioItem.fromApiJson(
    Map<String, dynamic> json, {
    String? responseMessage,
  }) {
    final rawSkills = json['skills'] is List
        ? json['skills'] as List
        : const [];
    final skills = rawSkills
        .whereType<Map>()
        .map((item) => PortfolioSkill.fromJson(Map<String, dynamic>.from(item)))
        .where((item) => item.skillName.isNotEmpty || item.skillId.isNotEmpty)
        .toList();
    final technologies =
        (json['technologies'] as List?)?.map((e) => e.toString()).toList() ??
        skills
            .map((item) => item.skillName)
            .where((e) => e.isNotEmpty)
            .toList();
    return PortfolioItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Portfolio item',
      description: json['description'] as String? ?? '',
      projectUrl: json['projectUrl'] as String? ?? json['url'] as String?,
      technologies: technologies,
      industry: json['industry']?.toString() ?? '',
      industryId: json['industryId']?.toString() ?? '',
      categoryId: json['categoryId']?.toString() ?? '',
      skills: skills,
      status: json['status']?.toString() ?? '',
      client: json['client']?.toString() ?? '',
      duration: json['duration']?.toString() ?? '',
      teamSize: json['teamSize']?.toString() ?? '',
      teamSizeId: json['teamSizeId']?.toString() ?? '',
      role: json['role'] as String? ?? '',
      category: json['category'] as String? ?? '',
      githubUrl: json['githubUrl']?.toString() ?? '',
      liveUrl: json['liveUrl']?.toString() ?? '',
      overview: json['overview']?.toString() ?? '',
      coverMedia: json['coverMedia']?.toString() ?? '',
      videoDemo: json['videoDemo']?.toString() ?? '',
      pdfCaseStudy: json['pdfCaseStudy']?.toString() ?? '',
      extraScreenshot: json['extraScreenshot']?.toString() ?? '',
      completionDate: DateTime.tryParse(
        json['completionDate'] as String? ?? '',
      ),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      responseMessage: responseMessage,
    );
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    industryId,
    categoryId,
    skills,
    status,
  ];
}
