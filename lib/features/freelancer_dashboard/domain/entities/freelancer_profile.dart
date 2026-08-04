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

    return FreelancerProfile(
      // The API returns 'skillIds' as an array of strings, or 'skills' as a comma-separated string
      skills: toStrings(json['skills']),
      experience: json['experience']?.toString() ?? '',
      education: json['education']?.toString() ?? '',
      languages: toStrings(json['languages']),
      hourlyRate:
          (json['hourlyRate'] as num?)?.toDouble() ??
          (json['hourly_rate'] as num?)?.toDouble() ??
          0,
      bio: json['bio'] as String? ?? json['overview'] as String? ?? '',
      availability:
          json['status'] as String? ?? json['availability'] as String? ?? '',
      avatarUrl:
          (json['user'] as Map?)?['avatarUrl'] as String? ??
          json['avatarUrl'] as String? ??
          json['avatar'] as String?,
      resumeUrl: json['resume'] as String? ?? json['resumeUrl'] as String?,
      fullName: json['fullName'] as String? ?? json['name'] as String? ?? '',
      phone:
          json['phone'] as String? ??
          json['mobile'] as String? ??
          json['phoneNumber'] as String? ??
          '',
      title:
          json['title'] as String? ??
          json['professionalTitle'] as String? ??
          '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      country: json['country'] as String? ?? '',
      githubUrl: json['githubUrl'] as String? ?? '',
      portfolioUrl: json['portfolioUrl'] as String? ?? '',
      linkedin: json['linkedin'] as String? ?? '',
      website: json['website'] as String? ?? '',
      panNumber: json['panNumber'] as String? ?? '',
      aadhaarNumber: json['aadhaarNumber'] as String? ?? '',
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
  ];
}
