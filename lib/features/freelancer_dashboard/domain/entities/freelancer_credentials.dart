class FreelancerEducation {
  const FreelancerEducation({
    required this.id,
    required this.institution,
    required this.qualification,
    required this.specialization,
    required this.year,
    required this.document,
    this.responseMessage,
  });

  final String id;
  final String institution;
  final String qualification;
  final String specialization;
  final String year;
  final String document;
  final String? responseMessage;

  factory FreelancerEducation.fromJson(
    Map<String, dynamic> json, {
    String? responseMessage,
  }) {
    return FreelancerEducation(
      id: json['id']?.toString() ?? '',
      institution: json['institution']?.toString() ?? '',
      qualification: json['qualification']?.toString() ?? '',
      specialization: json['specialization']?.toString() ?? '',
      year: json['year']?.toString() ?? '',
      document:
          json['document']?.toString() ??
          json['educationFile']?.toString() ??
          json['fileUrl']?.toString() ??
          '',
      responseMessage: responseMessage,
    );
  }

  Map<String, dynamic> toPayload() => {
    'institution': institution,
    'qualification': qualification,
    'specialization': specialization,
    'year': year,
    'document': document,
  };
}

class FreelancerCertificate {
  const FreelancerCertificate({
    required this.id,
    required this.name,
    required this.issuer,
    required this.issued,
    required this.certificateUrl,
    required this.certificateFile,
    required this.verified,
    this.responseMessage,
  });

  final String id;
  final String name;
  final String issuer;
  final String issued;
  final String certificateUrl;
  final String certificateFile;
  final bool verified;
  final String? responseMessage;

  factory FreelancerCertificate.fromJson(
    Map<String, dynamic> json, {
    String? responseMessage,
  }) {
    return FreelancerCertificate(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      issuer: json['issuer']?.toString() ?? '',
      issued: json['issued']?.toString() ?? '',
      certificateUrl:
          json['certificateUrl']?.toString() ?? json['url']?.toString() ?? '',
      certificateFile:
          json['certificateFile']?.toString() ??
          json['fileUrl']?.toString() ??
          '',
      verified: json['verified'] == true,
      responseMessage: responseMessage,
    );
  }

  Map<String, dynamic> toPayload() => {
    'name': name,
    'issuer': issuer,
    'issued': issued,
    'certificateUrl': certificateUrl,
    'certificateFile': certificateFile,
  };
}

class FreelancerExperience {
  const FreelancerExperience({
    required this.id,
    required this.title,
    required this.company,
    this.location = '',
    required this.startDate,
    this.endDate,
    this.isCurrent = false,
    this.description = '',
    this.industryId,
    this.industryName,
    this.skillIds = const [],
    this.skillNames = const [],
    this.responseMessage,
  });

  final String id;
  final String title;
  final String company;
  final String location;
  final String startDate;
  final String? endDate;
  final bool isCurrent;
  final String description;
  final String? industryId;
  final String? industryName;
  final List<String> skillIds;
  final List<String> skillNames;
  final String? responseMessage;

  factory FreelancerExperience.fromJson(
    Map<String, dynamic> json, {
    String? responseMessage,
  }) {
    final rawSkillIds =
        json['skillIds'] ?? json['skills'] ?? json['skillsUsed'];
    List<String> parsedSkillIds = [];
    if (rawSkillIds is List) {
      parsedSkillIds = rawSkillIds
          .map((e) => e is Map ? (e['id']?.toString() ?? '') : e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final rawSkillNames = json['skillNames'] ?? json['skillsList'];
    List<String> parsedSkillNames = [];
    if (rawSkillNames is List) {
      parsedSkillNames = rawSkillNames
          .map((e) => e is Map ? (e['name']?.toString() ?? '') : e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return FreelancerExperience(
      id: json['id']?.toString() ?? '',
      title:
          json['title']?.toString() ??
          json['designation']?.toString() ??
          json['role']?.toString() ??
          '',
      company: json['company']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      startDate:
          json['startDate']?.toString() ?? json['start']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? json['end']?.toString(),
      isCurrent: json['isCurrent'] == true || json['currentRole'] == true,
      description:
          json['description']?.toString() ??
          json['achievements']?.toString() ??
          '',
      industryId:
          json['industryId']?.toString() ?? json['industry']?['id']?.toString(),
      industryName:
          json['industryName']?.toString() ??
          json['industry']?['name']?.toString() ??
          json['industry']?.toString(),
      skillIds: parsedSkillIds,
      skillNames: parsedSkillNames,
      responseMessage: responseMessage,
    );
  }

  Map<String, dynamic> toPayload() => {
    'title': title,
    'company': company,
    'location': location,
    'startDate': startDate,
    if (endDate != null && endDate!.isNotEmpty) 'endDate': endDate,
    'isCurrent': isCurrent,
    'description': description,
    if (industryId != null && industryId!.isNotEmpty) 'industryId': industryId,
    if (skillIds.isNotEmpty) 'skillIds': skillIds,
  };
}
