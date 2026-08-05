import 'package:equatable/equatable.dart';

class FreelancerProfile extends Equatable {
  const FreelancerProfile({
    required this.skills,
    required this.experience,
    required this.education,
    required this.languages,
    required this.hourlyRate,
    required this.bio,
    this.availability = '',
    this.avatarUrl,
    this.resumeUrl,
    this.fullName = '',
    this.phone = '',
    this.title = '',
    this.city = '',
    this.state = '',
    this.country = '',
    this.githubUrl = '',
    this.portfolioUrl = '',
    this.linkedin = '',
    this.website = '',
    this.panNumber = '',
    this.aadhaarNumber = '',
    this.phoneCode = '',
    this.countryCode = '',
    this.experienceYears = 0,
  });

  final List<String> skills;
  final String experience;
  final String education;
  final List<String> languages;
  final double hourlyRate;
  final String bio;
  final String availability;
  final String? avatarUrl;
  final String? resumeUrl;
  final String fullName;
  final String phone;
  final String title;
  final String city;
  final String state;
  final String country;
  final String githubUrl;
  final String portfolioUrl;
  final String linkedin;
  final String website;
  final String panNumber;
  final String aadhaarNumber;
  final String phoneCode;
  final String countryCode;
  final int experienceYears;

  factory FreelancerProfile.fromApiJson(Map<String, dynamic> json) {
    List<String> toStrings(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
      if (raw is String && raw.isNotEmpty) {
        return raw
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return const [];
    }

    final user = (json['user'] is Map)
        ? Map<String, dynamic>.from(json['user'])
        : null;

    return FreelancerProfile(
      // The API returns 'skillIds' as an array of strings, or 'skills' as a comma-separated string
      skills: toStrings(json['skills']),
      experience:
          json['experienceYears']?.toString() ??
          json['experience']?.toString() ??
          '',
      education: json['education']?.toString() ?? '',
      languages: toStrings(json['languages']),
      hourlyRate:
          (json['hourlyRate'] as num?)?.toDouble() ??
          (json['hourly_rate'] as num?)?.toDouble() ??
          0,
      bio:
          json['bio'] as String? ??
          json['overview'] as String? ??
          user?['bio'] as String? ??
          '',
      availability:
          json['status'] as String? ?? json['availability'] as String? ?? '',
      avatarUrl:
          user?['avatarUrl'] as String? ??
          json['avatarUrl'] as String? ??
          json['avatar'] as String?,
      resumeUrl: json['resume'] as String? ?? json['resumeUrl'] as String?,
      fullName:
          json['fullName'] as String? ??
          json['name'] as String? ??
          user?['fullName'] as String? ??
          user?['name'] as String? ??
          '',
      phone:
          json['phone'] as String? ??
          json['mobile'] as String? ??
          json['phoneNumber'] as String? ??
          user?['phone'] as String? ??
          user?['mobile'] as String? ??
          '',
      title:
          json['headline'] as String? ??
          json['title'] as String? ??
          json['professionalTitle'] as String? ??
          user?['title'] as String? ??
          '',
      city: json['city'] as String? ?? user?['city'] as String? ?? '',
      state: json['state'] as String? ?? user?['state'] as String? ?? '',
      country:
          json['countryId'] as String? ??
          json['country'] as String? ??
          user?['countryId'] as String? ??
          user?['country'] as String? ??
          '',
      githubUrl:
          json['github'] as String? ?? json['githubUrl'] as String? ?? '',
      portfolioUrl:
          json['portfolio'] as String? ?? json['portfolioUrl'] as String? ?? '',
      linkedin: json['linkedin'] as String? ?? '',
      website: json['website'] as String? ?? '',
      panNumber: json['panNumber'] as String? ?? '',
      aadhaarNumber: json['aadhaarNumber'] as String? ?? '',
      phoneCode:
          json['phoneCode'] as String? ?? user?['phoneCode'] as String? ?? '',
      countryCode:
          json['countryCode'] as String? ??
          user?['countryCode'] as String? ??
          '',
      experienceYears: (json['experienceYears'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    skills,
    experience,
    education,
    languages,
    hourlyRate,
    bio,
    availability,
    avatarUrl,
    resumeUrl,
    fullName,
    phone,
    title,
    city,
    state,
    country,
    githubUrl,
    portfolioUrl,
    linkedin,
    website,
    panNumber,
    aadhaarNumber,
    phoneCode,
    countryCode,
    experienceYears,
  ];
}
