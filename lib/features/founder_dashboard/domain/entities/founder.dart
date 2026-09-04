import 'package:equatable/equatable.dart';
import '../../../../core/utils/enums.dart';

/// A startup founder profile.
class Founder extends Equatable {
  const Founder({
    required this.id,
    required this.name,
    required this.founderType,
    required this.location,
    this.avatarUrl,
    this.coverUrl,
    this.bio = '',
    this.experienceYears = 5,
    this.skills = const [],
    this.linkedIn,
    this.startupName = '',
    this.isVerified = true,
    this.isFollowing = false,
    this.isSaved = false,
    this.followers = 0,
  });

  final String id;
  final String name;
  final String founderType;
  final String location;
  final String? avatarUrl;
  final String? coverUrl;
  final String bio;
  final int experienceYears;
  final List<String> skills;
  final String? linkedIn;
  final String startupName;
  final bool isVerified;
  final bool isFollowing;
  final bool isSaved;
  final int followers;

  Founder copyWith({bool? isFollowing, bool? isSaved}) => Founder(
    id: id,
    name: name,
    founderType: founderType,
    location: location,
    avatarUrl: avatarUrl,
    coverUrl: coverUrl,
    bio: bio,
    experienceYears: experienceYears,
    skills: skills,
    linkedIn: linkedIn,
    startupName: startupName,
    isVerified: isVerified,
    isFollowing: isFollowing ?? this.isFollowing,
    isSaved: isSaved ?? this.isSaved,
    followers: followers,
  );

  factory Founder.fromApiJson(Map<String, dynamic> json) {
    String parseVal(dynamic field, [String fallback = '']) {
      if (field is Map) {
        final n = field['name'] ?? field['label'] ?? field['value'] ?? field['title'];
        if (n != null && n.toString().trim().isNotEmpty) return n.toString().trim();
      }
      if (field is String && field.trim().isNotEmpty) {
        return field.trim();
      }
      return fallback;
    }

    final fType = parseVal(json['founderType'], 'Founder');
    final sName = parseVal(json['startupName'] ?? json['startup'] ?? json['company'], '');
    final loc = parseVal(json['location'], 'N/A');

    return Founder(
      id: json['id']?.toString() ?? json['founderId']?.toString() ?? '',
      name: json['name']?.toString() ?? json['fullName']?.toString() ?? 'Founder',
      founderType: fType.isNotEmpty ? fType : 'Founder',
      location: loc.isNotEmpty ? loc : 'N/A',
      avatarUrl: json['avatarUrl']?.toString(),
      coverUrl: json['coverUrl']?.toString(),
      bio: json['bio']?.toString() ?? '',
      experienceYears: (json['experienceYears'] as num?)?.toInt() ?? 0,
      skills: (json['skills'] as List?)
              ?.map((e) => parseVal(e))
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      linkedIn: json['linkedIn']?.toString(),
      startupName: sName,
      isVerified: json['isVerified'] == true,
      isFollowing: json['isFollowing'] == true,
      isSaved: json['isSaved'] == true,
      followers: (json['followers'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, isFollowing, isSaved];
}

/// A funding request from an investor to a founder (or vice versa).
class InvestorRequest extends Equatable {
  const InvestorRequest({
    required this.id,
    required this.investorName,
    required this.amount,
    required this.equity,
    required this.status,
    required this.createdAt,
    this.investorAvatar,
    this.message = '',
  });

  final String id;
  final String investorName;
  final String? investorAvatar;
  final double amount;
  final double equity;
  final EntityStatus status;
  final DateTime createdAt;
  final String message;

  InvestorRequest copyWith({EntityStatus? status}) => InvestorRequest(
    id: id,
    investorName: investorName,
    investorAvatar: investorAvatar,
    amount: amount,
    equity: equity,
    status: status ?? this.status,
    createdAt: createdAt,
    message: message,
  );

  @override
  List<Object?> get props => [id, status];
}
