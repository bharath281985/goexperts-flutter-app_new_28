import 'package:equatable/equatable.dart';
import '../../../../core/utils/bookmark_manager.dart';
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

    final role = parseVal(json['role']);
    final rawType = parseVal(
      profile['investorTypeName'] ??
          json['investorTypeName'] ??
          profile['investorType'] ??
          json['investorType'],
    );
    final investorType = rawType.isNotEmpty
        ? rawType
        : (focusAreasStr.trim().isNotEmpty ? focusAreasStr : 'Angel Investor');

    final preferredStagesRaw =
        profile['PreferredStage'] ?? json['PreferredStage'] ?? profile['preferredStages'] ?? json['preferredStages'];
    final stagePreferences = preferredStagesRaw is List
        ? preferredStagesRaw
              .map((item) => parseVal(item))
              .where((value) => value.isNotEmpty)
              .toList()
        : const <String>[];

    final isVerified =
        json['isVerified'] as bool? ?? json['verified'] as bool? ?? false;
    final isFollowing = json['isFollowing'] as bool? ?? false;
    final rawSaved = json['isSaved'] ??
        json['is_saved'] ??
        profile['isSaved'] ??
        profile['is_saved'] ??
        json['savedData'] ??
        profile['savedData'];
    bool parsedSaved = false;
    if (rawSaved is bool) {
      parsedSaved = rawSaved;
    } else if (rawSaved is num) {
      parsedSaved = rawSaved != 0;
    } else if (rawSaved is String) {
      final s = rawSaved.trim().toLowerCase();
      parsedSaved = s == 'true' || s == '1' || s == 'yes';
    }
    final isSaved = parsedSaved ||
        BookmarkManager.instance
            .isBookmarked(BookmarkManager.categoryInvestors, id);
    if (parsedSaved && id.isNotEmpty) {
      BookmarkManager.instance
          .syncItem(BookmarkManager.categoryInvestors, id, true);
    }

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

  factory Deal.fromApiJson(Map<String, dynamic> json) {
    final startup = json['startup'] is Map
        ? json['startup'] as Map
        : (json['startupDetails'] is Map
            ? json['startupDetails'] as Map
            : (json['startup_details'] is Map
                ? json['startup_details'] as Map
                : (json['startupIdea'] is Map
                    ? json['startupIdea'] as Map
                    : const {})));
    final founder = json['founder'] is Map
        ? json['founder'] as Map
        : (json['founderDetails'] is Map
            ? json['founderDetails'] as Map
            : (json['founder_details'] is Map
                ? json['founder_details'] as Map
                : (startup['user'] is Map
                    ? startup['user'] as Map
                    : (json['user'] is Map ? json['user'] as Map : const {}))));

    String? parseName(dynamic val) {
      if (val == null) return null;
      if (val is Map) {
        final n = val['name'] ?? val['startup'] ?? val['label'] ?? val['title'] ?? val['fullName'];
        if (n != null && n.toString().trim().isNotEmpty) return n.toString().trim();
      }
      final s = val.toString().trim();
      if (s.isEmpty || s == 'null' || s == 'undefined') return null;
      return s;
    }

    final rawNameCandidates = [
      parseName(json['startupName']),
      parseName(json['startup_name']),
      parseName(startup['startup']),
      parseName(startup['name']),
      parseName(startup['title']),
      parseName(startup['companyName']),
      parseName(startup['company']),
      parseName(json['company']),
      if (json['startup'] is String &&
          !(json['startup'] as String).contains('-') &&
          (json['startup'] as String).length < 50)
        (json['startup'] as String).trim(),
    ];
    final validStartupName = rawNameCandidates.firstWhere(
      (n) => n != null && n.isNotEmpty && n != 'Startup',
      orElse: () => rawNameCandidates.firstWhere(
        (n) => n != null && n.isNotEmpty,
        orElse: () => 'Startup',
      ),
    )!;

    final rawFounderCandidates = [
      parseName(json['founderName']),
      parseName(json['founder_name']),
      parseName(founder['fullName']),
      parseName(founder['name']),
      parseName(founder['userName']),
      if (startup['user'] is Map) parseName((startup['user'] as Map)['fullName']),
    ];
    final validFounderName = rawFounderCandidates.firstWhere(
      (n) => n != null && n.isNotEmpty && n != 'Founder',
      orElse: () => rawFounderCandidates.firstWhere(
        (n) => n != null && n.isNotEmpty,
        orElse: () => 'Founder',
      ),
    )!;

    double parseNum(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) {
        final d = double.tryParse(val.replaceAll(RegExp(r'[^0-9.]'), ''));
        if (d != null) return d;
      }
      return 0.0;
    }

    final amount = parseNum(
      json['offer'] ??
          json['amount'] ??
          json['investmentAmount'] ??
          startup['funding'] ??
          (startup['metrics'] is Map ? (startup['metrics'] as Map)['fundingGoal'] : null),
    );
    final equity = parseNum(
      json['equity'] ??
          json['equityOffered'] ??
          startup['equity'] ??
          (startup['metrics'] is Map ? (startup['metrics'] as Map)['equityOffered'] : null),
    );

    String resolveStage() {
      final candidates = [
        json['stageName'],
        json['stage_name'],
        startup['stageName'],
        startup['stage_name'],
        json['stage'],
        startup['stage'],
      ];
      for (final c in candidates) {
        if (c is Map) {
          final name = c['name'] ?? c['label'] ?? c['title'] ?? c['value'];
          if (name != null && name.toString().trim().isNotEmpty) {
            return name.toString().trim();
          }
        } else if (c is String && c.trim().isNotEmpty) {
          final s = c.trim();
          if (s.startsWith('{') && s.endsWith('}')) {
            final match = RegExp(r'(?:name|label):\s*([^,}]+)').firstMatch(s);
            if (match != null) return match.group(1)!.trim();
          }
          if (s != 'null' && s != 'undefined') return s;
        }
      }
      return 'MVP';
    }

    final stage = resolveStage();
    final statusStr = json['status']?.toString() ?? 'pending';
    final dateStr = json['updatedAt'] ?? json['createdAt'];
    DateTime updatedAt = DateTime.now();
    if (dateStr != null) {
      try {
        updatedAt = DateTime.parse(dateStr.toString());
      } catch (_) {}
    }

    final logoCandidates = [
      parseName(json['startupLogo']),
      parseName(json['startup_logo']),
      parseName(startup['logo']),
      parseName(startup['logoUrl']),
      parseName(startup['avatarUrl']),
      parseName(startup['coverUrl']),
      parseName(founder['avatarUrl']),
    ];
    final startupLogo = logoCandidates.firstWhere(
      (l) => l != null && l.isNotEmpty && l.startsWith('http'),
      orElse: () => logoCandidates.firstWhere(
        (l) => l != null && l.isNotEmpty,
        orElse: () => null,
      ),
    );

    return Deal(
      id: json['id']?.toString() ?? '',
      startupId:
          json['startupId']?.toString() ??
          json['startup_id']?.toString() ??
          startup['id']?.toString() ??
          (json['startup'] is String ? json['startup'] as String : ''),
      startupName: validStartupName,
      founderName: validFounderName,
      stage: stage,
      amount: amount,
      equity: equity,
      status: EntityStatus.fromString(statusStr),
      updatedAt: updatedAt,
      startupLogo: startupLogo,
      hasNda: json['hasNda'] == true || json['nda'] == true,
      documentsCount: (json['documentsCount'] as num?)?.toInt() ??
          (json['documents_count'] as num?)?.toInt() ??
          0,
      documents: json['documents'] is Map
          ? Map<String, dynamic>.from(json['documents'] as Map)
          : const {},
      founderId: json['founderId']?.toString() ??
          json['founder_id']?.toString() ??
          founder['id']?.toString() ??
          (startup['user'] is Map ? (startup['user'] as Map)['id']?.toString() : null),
    );
  }
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
    this.status = 'Ongoing',
    this.industry = 'General',
    this.stage = 'Seed',
    this.projectUrl,
    this.logoUrl,
  });

  final String id;
  final String startupName;
  final double investedAmount;
  final double currentValue;
  final double equity;
  final DateTime investedAt;
  final String status;
  final String industry;
  final String stage;
  final String? projectUrl;
  final String? logoUrl;

  double get roi => investedAmount == 0
      ? 0
      : ((currentValue - investedAmount) / investedAmount) * 100;

  @override
  List<Object?> get props => [id, currentValue, status, industry, stage, projectUrl];

  factory PortfolioItem.fromApiJson(Map<String, dynamic> json) {
    final startup = json['startup'] is Map ? json['startup'] as Map : {};
    final startupName = json['startupName']?.toString() ??
        json['company']?.toString() ??
        json['companyName']?.toString() ??
        startup['name']?.toString() ??
        startup['startup']?.toString() ??
        'Company';
    final investedAmount = (json['investedAmount'] ??
                json['investmentAmount'] ??
                json['amount']) is num
        ? ((json['investedAmount'] ??
                json['investmentAmount'] ??
                json['amount']) as num)
            .toDouble()
        : 0.0;
    final currentValue = (json['currentValue'] ??
                json['valuation'] ??
                json['currentValuation'] ??
                investedAmount) is num
        ? ((json['currentValue'] ??
                json['valuation'] ??
                json['currentValuation'] ??
                investedAmount) as num)
            .toDouble()
        : investedAmount;
    final equity = (json['equity'] ?? json['equityPercentage']) is num
        ? ((json['equity'] ?? json['equityPercentage']) as num).toDouble()
        : 0.0;
    final dateStr = json['investedAt'] ??
        json['investmentDate'] ??
        json['createdAt'];
    DateTime investedAt = DateTime.now();
    if (dateStr != null) {
      try {
        investedAt = DateTime.parse(dateStr.toString());
      } catch (_) {}
    }
    final rawStatus = json['status']?.toString() ??
        json['investmentStatus']?.toString() ??
        'Ongoing';
    // Normalize status strings
    final status = switch (rawStatus.toLowerCase()) {
      'completed' || 'closed' => 'Completed',
      'exited' => 'Exited',
      'pending' || 'under review' => 'Pending',
      'written off' || 'written_off' || 'failed' => 'Written Off',
      _ => 'Ongoing',
    };
    final industry = json['industry']?.toString() ??
        startup['industry']?.toString() ??
        'General';
    final stage = json['stage']?.toString() ??
        startup['stage']?.toString() ??
        'Seed';
    final projectUrl = json['projectUrl']?.toString() ??
        json['websiteUrl']?.toString() ??
        json['website']?.toString() ??
        json['url']?.toString() ??
        startup['website']?.toString() ??
        startup['url']?.toString();

    return PortfolioItem(
      id: json['id']?.toString() ?? '',
      startupName: startupName,
      investedAmount: investedAmount,
      currentValue: currentValue,
      equity: equity,
      investedAt: investedAt,
      status: status,
      industry: industry,
      stage: stage,
      projectUrl: projectUrl,
      logoUrl: json['logoUrl']?.toString() ??
          json['logo']?.toString() ??
          startup['logo']?.toString(),
    );
  }
}
