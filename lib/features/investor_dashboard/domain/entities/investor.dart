import 'package:equatable/equatable.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/image_url.dart';

/// An investor profile discovered by founders.
class Investor extends Equatable {
  const Investor({
    required this.id,
    this.investorId = '',
    required this.name,
    required this.investorType,
    required this.company,
    required this.location,
    required this.minInvestment,
    required this.maxInvestment,
    required this.interestedIndustries,
    this.avatarUrl,
    this.coverUrl,
    this.bio = '',
    this.partnerRole = '',
    this.stagePreferences = const ['Seed', 'Series A'],
    this.dealsCount = 0,
    this.portfolioCount = 0,
    this.isVerified = true,
    this.isFollowing = false,
    this.isSaved = false,
  });

  final String id;
  final String investorId;
  final String name;
  final String investorType;
  final String company;
  final String location;
  final double minInvestment;
  final double maxInvestment;
  final List<String> interestedIndustries;
  final String? avatarUrl;
  final String? coverUrl;
  final String bio;
  final String partnerRole;
  final List<String> stagePreferences;
  final int dealsCount;
  final int portfolioCount;
  final bool isVerified;
  final bool isFollowing;
  final bool isSaved;

  Investor copyWith({bool? isFollowing, bool? isSaved}) => Investor(
    id: id,
    investorId: investorId,
    name: name,
    investorType: investorType,
    company: company,
    location: location,
    minInvestment: minInvestment,
    maxInvestment: maxInvestment,
    interestedIndustries: interestedIndustries,
    avatarUrl: avatarUrl,
    coverUrl: coverUrl,
    bio: bio,
    partnerRole: partnerRole,
    stagePreferences: stagePreferences,
    dealsCount: dealsCount,
    portfolioCount: portfolioCount,
    isVerified: isVerified,
    isFollowing: isFollowing ?? this.isFollowing,
    isSaved: isSaved ?? this.isSaved,
  );

  factory Investor.fromApiJson(Map<String, dynamic> json) {
    final Map<String, dynamic> profile =
        (json['investorProfile'] ?? json['investor_profile']) != null
        ? Map<String, dynamic>.from(
            (json['investorProfile'] ?? json['investor_profile']) as Map,
          )
        : json;

    final id = (json['id']?.toString() ?? '');
    final profileId =
        (profile['id']?.toString() ?? json['investorId']?.toString() ?? '');
    final name =
        json['fullName']?.toString() ??
        json['name']?.toString() ??
        profile['fullName']?.toString() ??
        profile['name']?.toString() ??
        'Investor';
    final bio =
        json['bio']?.toString() ??
        json['thesis']?.toString() ??
        profile['bio']?.toString() ??
        profile['thesis']?.toString() ??
        '';
    final rawAvatar =
        json['avatarUrl']?.toString() ??
        json['avatar']?.toString() ??
        profile['avatarUrl']?.toString();
    final avatarUrl = rawAvatar == null || rawAvatar.isEmpty
        ? null
        : normalizeImageUrl(rawAvatar);

    final country = json['country'] as String? ?? profile['country'] as String?;
    final city = json['city'] as String? ?? profile['city'] as String?;
    String location =
        json['location']?.toString() ?? profile['location']?.toString() ?? '';
    if (location.isEmpty &&
        city != null &&
        city.isNotEmpty &&
        country != null &&
        country.isNotEmpty) {
      location = city.toLowerCase().contains(country.toLowerCase())
          ? city
          : '$city, $country';
    } else if (location.isEmpty && city != null && city.isNotEmpty) {
      location = city;
    } else if (location.isEmpty && country != null && country.isNotEmpty) {
      location = country;
    }
    if (location.isEmpty) location = 'N/A';

    final ticketMin =
        (profile['ticketMin'] as num?)?.toDouble() ??
        (json['minInvestment'] as num?)?.toDouble() ??
        0.0;
    final ticketMax =
        (profile['ticketMax'] as num?)?.toDouble() ??
        (json['maxInvestment'] as num?)?.toDouble() ??
        0.0;
    final company =
        profile['firmName']?.toString() ??
        profile['firm']?.toString() ??
        json['company']?.toString() ??
        '';

    final focusAreasStr = profile['focusAreas'] is String
        ? profile['focusAreas'].toString()
        : '';
    List<String> interestedIndustries = const [];
    final focusAreaList = profile['FocusAreas'] ?? json['FocusAreas'];
    if (focusAreaList is List) {
      interestedIndustries = focusAreaList
          .map((item) {
            if (item is Map) {
              return (item['focusAreaName'] ?? item['focusAreaId'])
                      ?.toString()
                      .trim() ??
                  '';
            }
            return item.toString().trim();
          })
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();
    } else if (focusAreasStr.isNotEmpty) {
      interestedIndustries = focusAreasStr
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (profile['categories'] is List &&
        (profile['categories'] as List).isNotEmpty) {
      interestedIndustries = (profile['categories'] as List)
          .map((e) => e.toString())
          .toList();
    } else if (profile['industries'] is List &&
        (profile['industries'] as List).isNotEmpty) {
      interestedIndustries = (profile['industries'] as List)
          .map((e) => e.toString())
          .toList();
    } else if (json['interestedIndustries'] is List) {
      interestedIndustries = (json['interestedIndustries'] as List)
          .map((e) => e.toString())
          .toList();
    }

    final role = json['role']?.toString() ?? '';
    final investorType =
        profile['investorTypeName']?.toString() ??
        json['investorTypeName']?.toString() ??
        profile['investorType']?.toString() ??
        (focusAreasStr.trim().isNotEmpty ? focusAreasStr : 'Angel Investor');

    final preferredStagesRaw =
        profile['PreferredStage'] ?? json['PreferredStage'];
    final stagePreferences = preferredStagesRaw is List
        ? preferredStagesRaw
              .map((item) {
                if (item is Map) {
                  return (item['preferredStageName'] ??
                              item['preferredStageId'])
                          ?.toString()
                          .trim() ??
                      '';
                }
                return item.toString().trim();
              })
              .where((value) => value.isNotEmpty)
              .toList()
        : const <String>[];

    final isVerified =
        json['isVerified'] as bool? ?? json['verified'] as bool? ?? false;
    final isFollowing = json['isFollowing'] as bool? ?? false;
    final isSaved = json['isSaved'] as bool? ?? false;

    return Investor(
      id: id,
      investorId: profileId,
      name: name,
      investorType: investorType,
      company: company,
      location: location,
      minInvestment: ticketMin,
      maxInvestment: ticketMax,
      interestedIndustries: interestedIndustries,
      avatarUrl: avatarUrl,
      bio: bio,
      partnerRole: role,
      stagePreferences: stagePreferences,
      dealsCount:
          (profile['deals'] as num?)?.toInt() ??
          (profile['investmentsCount'] as num?)?.toInt() ??
          0,
      portfolioCount: 0,
      isVerified: isVerified,
      isFollowing: isFollowing,
      isSaved: isSaved,
    );
  }

  @override
  List<Object?> get props => [id, investorId, isFollowing, isSaved];
}

/// A deal / investment opportunity in the pipeline.
class Deal extends Equatable {
  const Deal({
    required this.id,
    required this.startupId,
    required this.startupName,
    required this.founderName,
    required this.stage,
    required this.amount,
    required this.equity,
    required this.status,
    required this.updatedAt,
    this.startupLogo,
    this.hasNda = false,
    this.documentsCount = 0,
    this.documents = const {},
    this.founderId,
  });

  final String id;
  final String startupId;
  final String startupName;
  final String founderName;
  final String stage;
  final double amount;
  final double equity;
  final EntityStatus status;
  final DateTime updatedAt;
  final String? startupLogo;
  final bool hasNda;
  final int documentsCount;
  final Map<String, dynamic> documents;
  final String? founderId;

  @override
  List<Object?> get props => [id, status, founderId];
}

/// A holding in the investor's portfolio.
class PortfolioItem extends Equatable {
  const PortfolioItem({
    required this.id,
    required this.startupName,
    required this.investedAmount,
    required this.currentValue,
    required this.equity,
    required this.investedAt,
    this.logoUrl,
  });

  final String id;
  final String startupName;
  final double investedAmount;
  final double currentValue;
  final double equity;
  final DateTime investedAt;
  final String? logoUrl;

  double get roi => investedAmount == 0
      ? 0
      : ((currentValue - investedAmount) / investedAmount) * 100;

  @override
  List<Object?> get props => [id, currentValue];
}
