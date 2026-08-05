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
