import 'package:equatable/equatable.dart';

/// A client / business company profile.
class Company extends Equatable {
  const Company({
    required this.id,
    required this.name,
    required this.industry,
    required this.location,
    this.ownerName = '',
    this.logoUrl,
    this.coverUrl,
    this.description = '',
    this.website,
    this.teamSize = '11-50',
    this.isVerified = true,
    this.projectsPosted = 0,
    this.hiresCount = 0,
    this.rating = 4.7,
    this.isFollowing = false,
    this.isSaved = false,
    this.gst = '',
    this.pan = '',
    this.panNumber = '',
    this.aadhaarNumber = '',
    this.email = '',
    this.phone = '',
    this.bio = '',
    this.city = '',
    this.country = '',
    this.linkedin = '',
    this.companySize = '',
    this.phoneCode = '',
    this.countryCode = '',
    this.countryId = '',
  });

  final String id;
  final String name;
  final String industry;
  final String location;
  final String ownerName;
  final String? logoUrl;
  final String? coverUrl;
  final String description;
  final String? website;
  final String teamSize;
  final bool isVerified;
  final int projectsPosted;
  final int hiresCount;
  final double rating;
  final bool isFollowing;
  final bool isSaved;
  final String gst;
  final String pan;
  final String panNumber;
  final String aadhaarNumber;
  final String email;
  final String phone;
  final String bio;
  final String city;
  final String country;
  final String linkedin;
  final String companySize;
  final String phoneCode;
  final String countryCode;
  final String countryId;

  Company copyWith({bool? isFollowing, bool? isSaved}) => Company(
    id: id,
    name: name,
    industry: industry,
    location: location,
    ownerName: ownerName,
    logoUrl: logoUrl,
    coverUrl: coverUrl,
    description: description,
    website: website,
    teamSize: teamSize,
    isVerified: isVerified,
    projectsPosted: projectsPosted,
    hiresCount: hiresCount,
    rating: rating,
    isFollowing: isFollowing ?? this.isFollowing,
    isSaved: isSaved ?? this.isSaved,
    gst: gst,
    pan: pan,
    panNumber: panNumber,
    aadhaarNumber: aadhaarNumber,
    email: email,
    phone: phone,
    bio: bio,
    city: city,
    country: country,
    linkedin: linkedin,
    companySize: companySize,
    phoneCode: phoneCode,
    countryCode: countryCode,
    countryId: countryId,
  );

  @override
  List<Object?> get props => [id, isFollowing, isSaved];
}
