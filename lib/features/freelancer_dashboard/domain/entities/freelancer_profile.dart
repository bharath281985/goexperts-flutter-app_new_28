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
    final raw = (json['data'] is Map)
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;

    List<String> toStrings(dynamic rawValue) {
      if (rawValue is List) {
        return rawValue
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      if (rawValue is String && rawValue.isNotEmpty) {
        return rawValue
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return const [];
    }

    final user = (raw['user'] is Map)
        ? Map<String, dynamic>.from(raw['user'])
        : null;

    return FreelancerProfile(
      // The API returns 'skillIds' as an array of strings, or 'skills' as a comma-separated string
      skills: toStrings(raw['skills']),
      experience:
          raw['experienceYears']?.toString() ??
          raw['experience']?.toString() ??
          '',
      education: raw['education']?.toString() ?? '',
      languages: toStrings(raw['languages']),
      hourlyRate:
          (raw['hourlyRate'] as num?)?.toDouble() ??
          (raw['hourly_rate'] as num?)?.toDouble() ??
          0,
      bio:
          raw['bio'] as String? ??
          raw['overview'] as String? ??
          user?['bio'] as String? ??
          '',
      availability:
          raw['status'] as String? ?? raw['availability'] as String? ?? '',
      avatarUrl:
          user?['avatarUrl'] as String? ??
          user?['avatar'] as String? ??
          raw['avatarUrl'] as String? ??
          raw['avatar'] as String?,
      resumeUrl:
          raw['resume'] as String? ??
          raw['resumeUrl'] as String? ??
          user?['resume'] as String? ??
          user?['resumeUrl'] as String?,
      fullName:
          raw['fullName'] as String? ??
          raw['name'] as String? ??
          user?['fullName'] as String? ??
          user?['name'] as String? ??
          '',
      phone:
          raw['phone'] as String? ??
          raw['mobile'] as String? ??
          raw['phoneNumber'] as String? ??
          user?['phone'] as String? ??
          user?['mobile'] as String? ??
          '',
      title:
          raw['headline'] as String? ??
          raw['title'] as String? ??
          raw['professionalTitle'] as String? ??
          user?['title'] as String? ??
          '',
      city: raw['city'] as String? ?? user?['city'] as String? ?? '',
      state: raw['state'] as String? ?? user?['state'] as String? ?? '',
      country:
          raw['countryId'] as String? ??
          raw['country'] as String? ??
          user?['countryId'] as String? ??
          user?['country'] as String? ??
          '',
      githubUrl: raw['github'] as String? ?? raw['githubUrl'] as String? ?? '',
      portfolioUrl:
          raw['portfolio'] as String? ?? raw['portfolioUrl'] as String? ?? '',
      linkedin: raw['linkedin'] as String? ?? '',
      website: raw['website'] as String? ?? '',
      panNumber: raw['panNumber'] as String? ?? '',
      aadhaarNumber: raw['aadhaarNumber'] as String? ?? '',
      phoneCode:
          raw['phoneCode'] as String? ?? user?['phoneCode'] as String? ?? '',
      countryCode:
          raw['countryCode'] as String? ??
          user?['countryCode'] as String? ??
          '',
      experienceYears: (raw['experienceYears'] as num?)?.toInt() ?? 0,
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
