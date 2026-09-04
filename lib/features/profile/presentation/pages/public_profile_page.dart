import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/bookmark_manager.dart';
import '../../../../core/utils/follow_manager.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/image_url.dart';
import '../../../../core/utils/paginated.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading_shimmer.dart';
import '../../../../core/widgets/icon_widget.dart';
import '../../../../core/widgets/invite_freelancer_dialog.dart';
import '../../domain/entities/review.dart';
import '../../domain/repositories/review_repository.dart';
import '../../../freelancer_dashboard/domain/repositories/freelancer_repository.dart';
import '../../../meetings/presentation/widgets/schedule_meeting_sheet.dart';
import '../widgets/profile_view.dart';

export '../widgets/profile_view.dart' show PublicProfileType;

/// Canonical web-style deep-link: `https://goexperts.in/{type}/{id}`
String _shareLink(PublicProfileType type, String id) {
  const base = 'https://goexperts.in';
  switch (type) {
    case PublicProfileType.freelancer:
      return '$base/u/freelancer/$id';
    case PublicProfileType.company:
      return '$base/u/company/$id';
    case PublicProfileType.investor:
      return '$base/u/investor/$id';
    case PublicProfileType.founder:
      return '$base/u/founder/$id';
  }
}

/// Public profile page for any role.
/// Fetches data from the public API endpoints (no auth required).
class PublicProfilePage extends StatefulWidget {
  const PublicProfilePage({super.key, required this.type, required this.id});

  final PublicProfileType type;
  final String id;

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadAll();
  }

  String get _bookmarkCategory {
    switch (widget.type) {
      case PublicProfileType.freelancer:
        return BookmarkManager.categoryFreelancers;
      case PublicProfileType.company:
        return BookmarkManager.categoryCompanies;
      case PublicProfileType.investor:
        return BookmarkManager.categoryInvestors;
      case PublicProfileType.founder:
        return BookmarkManager.categoryFounders;
    }
  }

  String get _followCategory {
    switch (widget.type) {
      case PublicProfileType.freelancer:
        return FollowManager.categoryFreelancers;
      case PublicProfileType.company:
        return FollowManager.categoryCompanies;
      case PublicProfileType.investor:
        return FollowManager.categoryInvestors;
      case PublicProfileType.founder:
        return FollowManager.categoryFounders;
    }
  }

List<String> _extractList(dynamic val) {
  if (val == null) return [];
  if (val is Map) {
    final str = (val['skillName'] ??
            val['name'] ??
            val['industryName'] ??
            val['workModeName'] ??
            val['experienceLevelName'] ??
            val['label'] ??
            val['title'] ??
            val['value'])
        ?.toString()
        .trim();
    if (str != null && str.isNotEmpty && !RegExp(r'^[0-9a-fA-F-]{20,}$').hasMatch(str)) {
      return [str];
    }
    return [];
  }
  if (val is List) {
    return val
        .map((item) {
          if (item is Map) {
            return (item['skillName'] ??
                    item['name'] ??
                    item['industryName'] ??
                    item['workModeName'] ??
                    item['experienceLevelName'] ??
                    item['label'] ??
                    item['title'] ??
                    item['value'] ??
                    item['id'])
                ?.toString()
                .trim() ??
                '';
          }
          return item.toString().trim();
        })
        .where((s) => s.isNotEmpty && !RegExp(r'^[0-9a-fA-F-]{20,}$').hasMatch(s))
        .toList();
  }
  if (val is String && val.trim().isNotEmpty) {
    return val
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty && !RegExp(r'^[0-9a-fA-F-]{20,}$').hasMatch(s))
        .toList();
  }
  return [];
}

String _formatLabel(dynamic val) {
  if (val == null) return '';
  if (val is Map) {
    return (val['experienceLevelName'] ??
            val['workModeName'] ??
            val['industryName'] ??
            val['skillName'] ??
            val['name'] ??
            val['label'] ??
            val['title'] ??
            val['value'])
            ?.toString()
            .trim() ??
        '';
  }
  final s = val.toString().trim();
  if (s.isEmpty) return '';

  String cleaned = s;
  if (cleaned.startsWith('mo_experience_level_')) {
    cleaned = cleaned.replaceFirst('mo_experience_level_', '');
  } else if (cleaned.startsWith('mo_work_mode_')) {
    cleaned = cleaned.replaceFirst('mo_work_mode_', '');
  } else if (cleaned.startsWith('mo_industry_')) {
    cleaned = cleaned.replaceFirst('mo_industry_', '');
  }

  final isUuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(cleaned);
  if (isUuid) {
    return '';
  }

  cleaned = cleaned.replaceAll('_', ' ').replaceAll('-', ' ');
  return cleaned
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}

Map<String, dynamic> _safeMap(dynamic val) {
  if (val == null) return const {};
  if (val is Map<String, dynamic>) return val;
  if (val is Map) return Map<String, dynamic>.from(val);
  if (val is String && val.trim().isNotEmpty) {
    final trimmed = val.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
  }
  return const {};
}

double _safeDouble(dynamic val, [double fallback = 0.0]) {
  if (val == null) return fallback;
  if (val is num) return val.toDouble();
  if (val is String) {
    return double.tryParse(val.replaceAll(RegExp(r'[^0-9.]'), '')) ?? fallback;
  }
  return fallback;
}

int _safeInt(dynamic val, [int fallback = 0]) {
  if (val == null) return fallback;
  if (val is num) return val.toInt();
  if (val is String) {
    return int.tryParse(val.replaceAll(RegExp(r'[^0-9]'), '')) ?? fallback;
  }
  return fallback;
}

String _cleanCityString(String rawCity) {
  if (rawCity.isEmpty) return '';
  return rawCity.replaceAll(RegExp(r'\{.*?\}'), '').replaceAll(RegExp(r',\s*,+'), ',').trim();
}

  /// Builds a ProfileViewData from the raw API data map.
  ProfileViewData? _parse(Map<String, dynamic> raw) {
    final reg = _safeMap(raw['registrationData']);
    final id = raw['id']?.toString() ??
        raw['freelancerId']?.toString() ??
        raw['userId']?.toString() ??
        raw['investorId']?.toString() ??
        widget.id;
    final fullName =
        raw['fullName']?.toString() ??
        reg['fullName']?.toString() ??
        raw['full_name']?.toString() ??
        'User';
    final rawAvatarUrl =
        raw['avatarUrl']?.toString() ??
        reg['avatarUrl']?.toString() ??
        raw['avatar_url']?.toString();
    final avatarUrl = rawAvatarUrl == null || rawAvatarUrl.isEmpty
        ? null
        : normalizeImageUrl(rawAvatarUrl);
    final rawCity = _cleanCityString(raw['city']?.toString() ?? reg['city']?.toString() ?? '');
    final locationParts = [
      rawCity,
      raw['state']?.toString() ?? reg['state']?.toString() ?? '',
      raw['country']?.toString() ?? reg['country']?.toString() ?? '',
    ]
        .where((e) => e.trim().isNotEmpty)
        .where((e) => !RegExp(r'^[0-9a-fA-F-]{20,}$').hasMatch(e.trim()))
        .toSet()
        .toList();
    final location = locationParts.join(', ');
    final bio = raw['bio']?.toString() ??
        reg['bio']?.toString() ??
        raw['about']?.toString() ??
        '';
    final isVerified =
        raw['isVerified'] as bool? ??
        reg['isVerified'] as bool? ??
        raw['is_verified'] as bool? ??
        raw['verified'] as bool? ??
        false;
    final email = raw['email']?.toString() ?? reg['email']?.toString() ?? '';
    final phone = raw['phone']?.toString() ?? reg['phone']?.toString() ?? '';

    bool toBool(dynamic val) {
      if (val == null) return false;
      if (val is bool) return val;
      if (val is num) return val != 0;
      if (val is String) {
        final s = val.trim().toLowerCase();
        return s == 'true' || s == '1' || s == 'yes';
      }
      return false;
    }

    final hasAuthoritativeSavedState =
        raw.containsKey('isSaved') || raw.containsKey('is_saved');
    final apiIsSaved = hasAuthoritativeSavedState
        ? toBool(raw['isSaved'] ?? raw['is_saved'])
        : toBool(raw['savedData']);
    BookmarkManager.instance.syncItem(_bookmarkCategory, id, apiIsSaved);

    final apiIsFollowing =
        toBool(raw['isFollowing']) || toBool(raw['is_following']);
    FollowManager.instance.syncItem(_followCategory, id, apiIsFollowing);

    switch (widget.type) {
      case PublicProfileType.freelancer:
        {
          final fp = _safeMap(
            raw['freelancerProfile'] ?? raw['profile'] ?? (reg.isNotEmpty ? reg : raw),
          );

          // 1. Skills / Skills
          var skills = _extractList(
            raw['Skills'] ??
                raw['skills'] ??
                fp['Skills'] ??
                fp['skills'] ??
                reg['Skills'] ??
                reg['skills'],
          );
          if (skills.isEmpty) {
            skills = _extractList(raw['skills'] ?? fp['skills'] ?? reg['skills']);
          }

          // 2. Industry / industry / industries / industryName
          var industries = _extractList(raw['industryName'] ?? raw['IndustryName']);
          if (industries.isEmpty) {
            industries = _extractList(
              raw['Industry'] ??
                  raw['industry'] ??
                  raw['Industries'] ??
                  raw['industries'] ??
                  fp['Industry'] ??
                  fp['industry'] ??
                  fp['Industries'] ??
                  fp['industries'] ??
                  reg['Industry'] ??
                  reg['industry'] ??
                  reg['category'] ??
                  raw['category'],
            );
          }

          // 3. WorkMode / workMode / workModes / workModeName
          var workModes = _extractList(raw['workModeName'] ?? raw['WorkModeName']);
          if (workModes.isEmpty) {
            workModes = _extractList(
              raw['workMode'] ??
                  raw['WorkMode'] ??
                  raw['workModes'] ??
                  raw['WorkModes'] ??
                  fp['workMode'] ??
                  fp['WorkMode'] ??
                  fp['workModes'] ??
                  fp['WorkModes'] ??
                  reg['workMode'] ??
                  reg['WorkMode'],
            );
          }

          final hourlyRate = _safeDouble(
            fp['hourlyRate'] ?? reg['hourlyRate'] ?? raw['hourlyRate'],
          );

          // 4. Experience Level
          final rawExp = raw['experienceLevelName'] ??
              raw['ExperienceLevelName'] ??
              raw['experienceLevel'] ??
              raw['ExperienceLevel'] ??
              raw['experience'] ??
              raw['Experience'] ??
              fp['experienceLevelName'] ??
              fp['ExperienceLevelName'] ??
              fp['experienceLevel'] ??
              fp['ExperienceLevel'] ??
              fp['experience'] ??
              reg['experienceLevel'] ??
              reg['experience'];
          final expLevel = _formatLabel(rawExp);

          final titleHeadline = raw['titleHeadline']?.toString() ??
              raw['professionalTitle']?.toString() ??
              raw['title']?.toString() ??
              fp['titleHeadline']?.toString() ??
              reg['titleHeadline']?.toString() ??
              raw['headline']?.toString() ??
              '';

          final portfolioUrl = fp['portfolioUrl']?.toString() ??
              reg['portfolioUrl']?.toString() ??
              raw['portfolioUrl']?.toString() ??
              '';
          final linkedInUrl = fp['linkedInUrl']?.toString() ??
              fp['linkedinUrl']?.toString() ??
              fp['linkedin']?.toString() ??
              reg['linkedInUrl']?.toString() ??
              raw['linkedInUrl']?.toString() ??
              '';
          final githubUrl = fp['githubUrl']?.toString() ??
              reg['githubUrl']?.toString() ??
              raw['githubUrl']?.toString() ??
              '';
          final websiteUrl = fp['websiteUrl']?.toString() ??
              fp['website']?.toString() ??
              reg['websiteUrl']?.toString() ??
              raw['websiteUrl']?.toString() ??
              '';

          final headline = titleHeadline.isNotEmpty
              ? titleHeadline
              : [
                  if (expLevel.isNotEmpty) expLevel,
                  if (hourlyRate > 0)
                    '${Formatters.compactCurrency(hourlyRate)}/hr',
                ].join(' · ');

          final ratingRaw = raw['rating'] ?? fp['rating'] ?? reg['rating'];
          final double? rating = ratingRaw is num
              ? ratingRaw.toDouble()
              : double.tryParse(ratingRaw?.toString() ?? '');
          final reviewsCountRaw = raw['reviewsCount'] ?? fp['reviewsCount'] ?? reg['reviewsCount'];
          final int reviewsCount = reviewsCountRaw is num
              ? reviewsCountRaw.toInt()
              : int.tryParse(reviewsCountRaw?.toString() ?? '') ?? 0;

          final ratingStr = rating != null && rating > 0
              ? (rating % 1 == 0 ? '${rating.toInt()}.0' : rating.toStringAsFixed(1))
              : '5.0';

          final stats = <String, String>{
            'Experience': expLevel.isNotEmpty ? expLevel : '—',
            'Rating': ratingStr,
            'Skills Count': '${skills.length}',
          };

          return ProfileViewData(
            id: id,
            name: fullName,
            headline: headline,
            location: location,
            avatarUrl: avatarUrl,
            isVerified: isVerified,
            about: bio,
            skills: skills,
            industries: industries,
            workModes: workModes,
            experienceLevel: expLevel,
            portfolioUrl: portfolioUrl,
            linkedInUrl: linkedInUrl,
            githubUrl: githubUrl,
            websiteUrl: websiteUrl,
            hourlyRate: hourlyRate > 0 ? hourlyRate : null,
            rating: rating,
            reviewsCount: reviewsCount,
            isFollowing: apiIsFollowing,
            isSaved: apiIsSaved,
            type: PublicProfileType.freelancer,
            primaryActionLabel: 'Hire Now',
            primaryActionIcon: Icons.handshake_outlined,
            stats: stats,
            phone: phone,
            email: email,
          );
        }
      case PublicProfileType.company:
        {
          final cp = _safeMap(raw['clientProfile'] ?? raw);
          final company = cp['company']?.toString() ?? fullName;
          final industry = cp['industry']?.toString() ?? '';
          return ProfileViewData(
            id: id,
            name: company,
            headline: industry.isNotEmpty ? industry : 'Client',
            location: location,
            avatarUrl: avatarUrl,
            isVerified: isVerified,
            about: bio,
            isFollowing: apiIsFollowing,
            isSaved: apiIsSaved,
            type: PublicProfileType.company,
            primaryActionLabel: 'Post a Job',
            primaryActionIcon: Icons.work_outline_rounded,
            stats: {
              'Industry': industry.isEmpty ? '—' : industry,
              'Manager': fullName.split(' ').first,
            },
            phone: phone,
            email: email,
          );
        }
      case PublicProfileType.investor:
        {
          final ip = _safeMap(raw['investorProfile'] ?? raw);
          final firm =
              ip['firm']?.toString() ?? ip['company']?.toString() ?? '';
          final ticketMin = _safeDouble(ip['ticketMin']);
          final ticketMax = _safeDouble(ip['ticketMax']);
          final focusRaw = ip['focusAreas'] is String
              ? ip['focusAreas'].toString()
              : '';
          final focusList = ip['FocusAreas'];
          final focus = focusList is List
              ? focusList
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
                    .toList()
              : focusRaw.isNotEmpty
              ? focusRaw
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList()
              : <String>[];
          final preferredStageList =
              ip['PreferredStage'] ?? ip['preferredStages'];
          final preferredStages = preferredStageList is List
              ? preferredStageList
                    .map((item) {
                      if (item is Map) {
                        return (item['preferredStageName'] ??
                                    item['stageName'] ??
                                    item['name'] ??
                                    item['preferredStageId'])
                                ?.toString()
                                .trim() ??
                            '';
                      }
                      return item.toString().trim();
                    })
                    .where((value) => value.isNotEmpty)
                    .toSet()
                    .toList()
              : <String>[];
          final deals = _safeInt(ip['deals'] ?? ip['investmentsCount']);
          return ProfileViewData(
            id: id,
            name: fullName,
            headline: [
              ip['investorTypeName']?.toString() ??
                  ip['investorType']?.toString() ??
                  'Investor',
              if (firm.isNotEmpty) firm,
            ].join(' · '),
            location: raw['location']?.toString().isNotEmpty == true
                ? raw['location'].toString()
                : location,
            avatarUrl: avatarUrl,
            isVerified: isVerified,
            about: bio,
            skills: focus,
            preferredStages: preferredStages,
            isFollowing: FollowManager.instance.isFollowing(
              _followCategory,
              id,
            ),
            isSaved: apiIsSaved,
            type: PublicProfileType.investor,
            primaryActionLabel: 'Connect',
            primaryActionIcon: Icons.handshake_outlined,
            stats: {
              'Deals': deals > 0 ? '$deals' : '—',
              'Min Ticket': ticketMin > 0
                  ? Formatters.compactCurrency(ticketMin)
                  : '—',
              'Max Ticket': ticketMax > 0
                  ? Formatters.compactCurrency(ticketMax)
                  : '—',
            },
            phone: phone,
            email: email,
          );
        }
      case PublicProfileType.founder:
        {
          final fp = _safeMap(raw['founderProfile'] ?? raw);
          final founderName = fp['founder']?.toString() ?? fullName;

          final startupMap = _safeMap(fp['startup']);
          final startupName =
              fp['startupName']?.toString() ??
              startupMap['startup']?.toString() ??
              startupMap['name']?.toString() ??
              (fp['startup'] is String ? fp['startup'].toString() : null) ??
              fullName;

          final industryValue = fp['Industry'] ?? fp['industry'];
          final industry = industryValue is Map
              ? (industryValue['industryName'] ?? industryValue['name'])
                        ?.toString() ??
                    ''
              : industryValue?.toString() ??
                    startupMap['industry']?.toString() ??
                    '';
          final rawStage = fp['stage']?.toString() ?? '';
          final startupStage = startupMap['stage']?.toString() ?? '';
          final stage = rawStage.contains('-') && startupStage.isNotEmpty
              ? startupStage
              : (rawStage.isNotEmpty ? rawStage : startupStage);

          final teamSizeValue = fp['teamSize'];
          final startupMetrics = _safeMap(startupMap['metrics']);
          final startupTeamSize =
              startupMap['teamSize'] ?? startupMetrics['teamSize'];
          final teamSizeLabel = teamSizeValue is Map
              ? (teamSizeValue['name'] ?? teamSizeValue['label'])?.toString() ??
                    ''
              : teamSizeValue is num
              ? teamSizeValue.toInt().toString()
              : startupTeamSize is num
              ? startupTeamSize.toInt().toString()
              : startupTeamSize?.toString() ?? '';
          final raised = _safeDouble(
            fp['raised'] ?? startupMap['fundingRaised'] ?? startupMap['funding'],
          );

          final primaryGoals = fp['PrimaryGoal'];
          final skillsRaw = raw['skills']?.toString() ?? '';
          final skills = primaryGoals is List
              ? primaryGoals
                    .map(
                      (goal) => goal is Map
                          ? (goal['primaryGoalName'] ?? goal['name'])
                                    ?.toString() ??
                                ''
                          : goal.toString(),
                    )
                    .where((goal) => goal.trim().isNotEmpty)
                    .toList()
              : skillsRaw.isNotEmpty
              ? skillsRaw
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList()
              : <String>[];
          final experience = raw['experience']?.toString() ?? '';
          final education = raw['education']?.toString() ?? '';
          final linkedin = raw['linkedin']?.toString() ?? '';
          final website = raw['website']?.toString() ?? '';
          final founderType =
              raw['founderType']?.toString() ??
              raw['founderRole']?.toString() ??
              '';

          return ProfileViewData(
            id: id,
            name: founderName.isNotEmpty && founderName != 'User'
                ? founderName
                : startupName,
            headline: [
              founderType.isNotEmpty ? founderType : 'Founder',
              if (startupName.isNotEmpty && startupName != 'User') startupName,
              if (industry.isNotEmpty) industry,
              if (stage.isNotEmpty) stage,
            ].join(' · '),
            location: location,
            avatarUrl: avatarUrl,
            isVerified: isVerified,
            about: bio,
            skills: skills,
            experience: experience,
            education: education,
            linkedin: linkedin,
            website: website,
            isFollowing: FollowManager.instance.isFollowing(
              _followCategory,
              id,
            ),
            isSaved: apiIsSaved,
            type: PublicProfileType.founder,
            primaryActionLabel: 'Connect',
            primaryActionIcon: Icons.handshake_outlined,
            stats: {
              'Startup': startupName,
              'Stage': stage.isEmpty ? '—' : stage,
              'Team': teamSizeLabel.isNotEmpty ? teamSizeLabel : '—',
              'Raised': raised > 0 ? Formatters.compactCurrency(raised) : '—',
            },
            phone: phone,
            email: email,
          );
        }
    }
  }

  Future<Map<String, dynamic>> _loadAll() async {
    final api = sl<ApiClientHelper>();
    final String endpoint;
    switch (widget.type) {
      case PublicProfileType.freelancer:
        endpoint = ApiEndpoints.publicFreelancer(widget.id);
        break;
      case PublicProfileType.company:
        endpoint = ApiEndpoints.publicClient(widget.id);
        break;
      case PublicProfileType.investor:
        endpoint = ApiEndpoints.publicInvestor(widget.id);
        break;
      case PublicProfileType.founder:
        endpoint = ApiEndpoints.publicFounder(widget.id);
        break;
    }

    var rawResult = await api.get<Map<String, dynamic>>(
      endpoint,
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );

    if (rawResult.isFailure && widget.type == PublicProfileType.freelancer) {
      final fallbackEndpoint = '${ApiEndpoints.clientFreelancers}/${widget.id}';
      final fallbackResult = await api.get<Map<String, dynamic>>(
        fallbackEndpoint,
        parser: (data) => Map<String, dynamic>.from(data as Map),
      );
      if (fallbackResult.isSuccess) {
        rawResult = fallbackResult;
      }
    }

    final raw = rawResult.valueOrNull ?? {};
    final profile = raw.isNotEmpty ? _parse(raw) : null;

    List<Review> reviews = [];
    if (profile != null) {
      final reviewsRes = await sl<ReviewRepository>().getReviews(
        QueryParams(
          filters: {'targetId': widget.id, 'targetType': widget.type.name},
        ),
      );
      reviews = reviewsRes.fold((_) => [], (page) => page.items);
    }

    return {'profile': profile, 'reviews': reviews};
  }

  void _share(ProfileViewData data) {
    final link = _shareLink(widget.type, widget.id);
    final text = '${data.name} — ${data.headline}\n\nView profile: $link';
    Share.share(text, subject: '${data.name} on GoExperts');
  }

  void _copyLink() {
    final link = _shareLink(widget.type, widget.id);
    Clipboard.setData(ClipboardData(text: link));
    context.showSnack('Profile link copied!');
  }

  void _showShareSheet(BuildContext context, ProfileViewData data) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusXl),
        ),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                0,
                AppSizes.screenPadding,
                8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share ${data.name}\'s Profile',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _shareLink(widget.type, widget.id),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.mutedText),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.share_rounded),
              title: const Text('Share via apps (WhatsApp, Gmail…)'),
              onTap: () {
                Navigator.of(context).pop();
                _share(data);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy link'),
              onTap: () {
                Navigator.of(context).pop();
                _copyLink();
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_rounded),
              title: const Text('Show QR code'),
              onTap: () {
                Navigator.of(context).pop();
                _showQr(context, data);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showQr(BuildContext context, ProfileViewData data) => showDialog(
    context: context,
    builder: (_) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppAvatar(name: data.name, imageUrl: data.avatarUrl, size: 52),
            const SizedBox(height: 12),
            Text(data.name, style: Theme.of(context).textTheme.titleMedium),
            Text(
              data.headline,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            AppSizes.vGapLg,
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: const Icon(Icons.qr_code_2_rounded, size: 150),
            ),
            AppSizes.vGapMd,
            Text(
              'Scan to view public profile',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            AppSizes.vGapMd,
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _copyLink();
              },
              child: const Text('Copy Link'),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        BookmarkManager.instance,
        FollowManager.instance,
      ]),
      builder: (context, _) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            final profile = snapshot.data?['profile'] as ProfileViewData?;
            final reviews =
                snapshot.data?['reviews'] as List<Review>? ?? const [];

            return Scaffold(
              appBar: AppBar(
                leading: IconTapWidget(
                  onTap: () => Navigator.of(context).maybePop(true),
                ),
                title: Text(
                  widget.type == PublicProfileType.freelancer
                      ? 'Freelancer details'
                      : widget.type == PublicProfileType.investor
                          ? 'Investor details'
                          : widget.type == PublicProfileType.company
                              ? 'Company details'
                              : widget.type == PublicProfileType.founder
                                  ? 'Founder details'
                                  : (profile?.name ?? 'Profile'),
                  overflow: TextOverflow.ellipsis,
                ),
                actions: [
                  if (profile != null)
                    IconButton(
                      icon: const Icon(Icons.share_outlined),
                      tooltip: 'Share profile',
                      onPressed: () => _showShareSheet(context, profile),
                    ),
                ],
              ),
              body: () {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AppLoadingShimmer(itemCount: 4, height: 120);
                }
                if (profile == null) return const AppErrorState();
                return ProfileView(
                  data: profile,
                  reviews: reviews,
                  onShare: () => _showShareSheet(context, profile),
                  onPrimaryAction: () async {
                    if (widget.type == PublicProfileType.freelancer) {
                      final invited = await InviteFreelancerDialog.show(
                        context,
                        freelancerId: widget.id,
                        freelancerName: profile.name,
                        freelancerAvatar: profile.avatarUrl,
                      );
                      if (invited == true && mounted) {
                        setState(() {
                          _future = _loadAll();
                        });
                      }
                    } else if (profile.primaryActionLabel == 'Connect') {
                      ScheduleMeetingSheet.show(
                        context,
                        targetId: widget.id,
                        targetName: profile.name,
                        targetAvatar: profile.avatarUrl,
                      );
                    } else {
                      context.showSnack(
                        '${profile.primaryActionLabel} · ${profile.name}',
                      );
                    }
                  },
                  onMessage: () {
                    final nameEncoded = Uri.encodeComponent(profile.name);
                    final avatarEncoded = Uri.encodeComponent(
                      profile.avatarUrl ?? '',
                    );
                    context.push(
                      '${Routes.chat}/${widget.id}?name=$nameEncoded&avatarUrl=$avatarEncoded',
                    );
                  },

                  onBookmark: () async {
                    if (widget.type == PublicProfileType.investor) {
                      final api = sl<ApiClientHelper>();
                      final isSaved = BookmarkManager.instance.isBookmarked(
                        _bookmarkCategory,
                        widget.id,
                      );
                      final res = isSaved
                          ? await api.deleteAction(
                              ApiEndpoints.publicInvestorSave(widget.id),
                            )
                          : await api.postAction(
                              ApiEndpoints.publicInvestorSave(widget.id),
                            );
                      if (!context.mounted) return;
                      res.fold(
                        (f) {
                          context.showSnack(f.message, isError: true);
                        },
                        (success) {
                          BookmarkManager.instance.syncItem(
                            _bookmarkCategory,
                            widget.id,
                            !isSaved,
                          );
                          context.showSnack(
                            isSaved
                                ? 'Investor removed from saved'
                                : 'Investor saved',
                          );
                          setState(() {
                            _future = _loadAll();
                          });
                        },
                      );
                    } else if (widget.type == PublicProfileType.founder) {
                      final api = sl<ApiClientHelper>();
                      final isSaved = BookmarkManager.instance.isBookmarked(
                        _bookmarkCategory,
                        widget.id,
                      );

                      final res = isSaved
                          ? await api.deleteAction(
                              ApiEndpoints.investorFounderSave(widget.id),
                            )
                          : await api.postAction(
                              ApiEndpoints.investorFounderSave(widget.id),
                            );

                      res.fold(
                        (f) {
                          context.showSnack(f.message, isError: true);
                        },
                        (success) {
                          BookmarkManager.instance.toggle(
                            _bookmarkCategory,
                            widget.id,
                          );
                          setState(() {
                            _future = _loadAll();
                          });
                        },
                      );
                    } else if (widget.type == PublicProfileType.freelancer) {
                      final isSaved = BookmarkManager.instance.isBookmarked(
                        _bookmarkCategory,
                        widget.id,
                      );
                      final res = await sl<FreelancerRepository>().toggleSave(widget.id);
                      if (!context.mounted) return;
                      res.fold(
                        (f) => context.showSnack(
                          f.message.isNotEmpty ? f.message : 'Failed to update saved status',
                          isError: true,
                        ),
                        (_) {
                          BookmarkManager.instance.syncItem(
                            _bookmarkCategory,
                            widget.id,
                            !isSaved,
                          );
                          context.showSnack(
                            isSaved
                                ? 'Freelancer removed from saved'
                                : 'Freelancer saved',
                          );
                          setState(() => _future = _loadAll());
                        },
                      );
                    } else {
                      final api = sl<ApiClientHelper>();
                      final isSaved = BookmarkManager.instance.isBookmarked(
                        _bookmarkCategory,
                        widget.id,
                      );

                      final res = isSaved
                          ? await api.deleteAction(
                              '${ApiEndpoints.favorites}/${widget.id}',
                            )
                          : await api.postAction(
                              '${ApiEndpoints.favorites}/${widget.id}',
                            );

                      if (!context.mounted) return;
                      res.fold(
                        (f) => context.showSnack(
                          f.message.isNotEmpty ? f.message : 'Failed to update saved status',
                          isError: true,
                        ),
                        (_) {
                          BookmarkManager.instance.toggle(
                            _bookmarkCategory,
                            widget.id,
                          );
                          setState(() => _future = _loadAll());
                        },
                      );
                    }
                  },

                );
              }(),
            );
          },
        );
      },
    );
  }
}
