import 'package:equatable/equatable.dart';
import '../../../../core/utils/enums.dart';

/// A project posted by a client that freelancers can apply to.
class Project extends Equatable {
  const Project({
    required this.id,
    required this.title,
    required this.description,
    required this.clientName,
    required this.category,
    required this.skills,
    required this.budgetMin,
    required this.budgetMax,
    required this.isHourly,
    required this.timeline,
    required this.status,
    required this.postedAt,
    this.clientId,
    this.clientAvatar,
    this.industryId,
    this.industryName = '',
    this.categoryId,
    this.skillIds = const [],
    this.proposalsCount = 0,
    this.workMode = 'Remote',
    this.workModeId,
    this.experienceLevel = 'intermediate',
    this.experienceLevelId,
    this.budgetRangeId,
    this.budgetRangeName = '',
    this.startDate,
    this.endDate,
    this.isSaved = false,
    this.isApplied = false,
    this.isOwner = false,
    this.location = 'Remote',
    this.techStack = const [],
    this.attachments = const [],
    this.clientVerified = true,
  });

  final String id;
  final String title;
  final String description;
  final String? clientId;
  final String clientName;
  final String? clientAvatar;
  final String? industryId;
  final String industryName;
  final String category;
  final String? categoryId;
  final List<String> skills;
  final List<String> skillIds;
  final List<String> techStack;
  final double budgetMin;
  final double budgetMax;
  final bool isHourly;
  final String timeline;
  final EntityStatus status;
  final DateTime postedAt;
  final int proposalsCount;
  final String workMode;
  final String? workModeId;
  final String experienceLevel;
  final String? experienceLevelId;
  final String? budgetRangeId;
  final String budgetRangeName;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isSaved;
  final bool isApplied;
  final bool isOwner;
  final String location;
  final List<String> attachments;
  final bool clientVerified;

  Project copyWith({
    bool? isSaved,
    bool? isApplied,
    bool? isOwner,
    EntityStatus? status,
    int? proposalsCount,
    String? workModeId,
    String? experienceLevelId,
    String? budgetRangeId,
    String? budgetRangeName,
    DateTime? startDate,
    DateTime? endDate,
  }) => Project(
    id: id,
    title: title,
    description: description,
    clientId: clientId,
    clientName: clientName,
    clientAvatar: clientAvatar,
    industryId: industryId,
    industryName: industryName,
    category: category,
    categoryId: categoryId,
    skills: skills,
    skillIds: skillIds,
    techStack: techStack,
    budgetMin: budgetMin,
    budgetMax: budgetMax,
    isHourly: isHourly,
    timeline: timeline,
    status: status ?? this.status,
    postedAt: postedAt,
    proposalsCount: proposalsCount ?? this.proposalsCount,
    workMode: workMode,
    workModeId: workModeId ?? this.workModeId,
    experienceLevel: experienceLevel,
    experienceLevelId: experienceLevelId ?? this.experienceLevelId,
    budgetRangeId: budgetRangeId ?? this.budgetRangeId,
    budgetRangeName: budgetRangeName ?? this.budgetRangeName,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    isSaved: isSaved ?? this.isSaved,
    isApplied: isApplied ?? this.isApplied,
    isOwner: isOwner ?? this.isOwner,
    location: location,
    attachments: attachments,
    clientVerified: clientVerified,
  );

  static final _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static String _displayName(String? value, {String fallback = 'Client'}) {
    final v = value?.trim();
    if (v == null || v.isEmpty || _uuid.hasMatch(v)) return fallback;
    return v;
  }

  static List<String> _nameList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) {
            if (e is Map) {
              return (e['skillName'] ??
                      e['name'] ??
                      e['label'] ??
                      e['title'] ??
                      '')
                  .toString()
                  .trim();
            }
            return e.toString().trim();
          })
          .where((e) => e.isNotEmpty && !_uuid.hasMatch(e))
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty && !_uuid.hasMatch(e))
          .toList();
    }
    return const [];
  }

  static List<String> _idList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) {
            if (e is Map) {
              return (e['skillId'] ?? e['id'] ?? '').toString().trim();
            }
            return e.toString().trim();
          })
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static List<String> _attachments(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) {
            if (e is Map) {
              return e['url']?.toString() ?? e['name']?.toString() ?? '';
            }
            return e.toString();
          })
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        // handled as plain string URL list
      } catch (_) {}
      return raw
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  factory Project.fromApiJson(Map<String, dynamic> json) {
    final clientObj = json['client'];
    final clientNameRaw = clientObj is Map
        ? clientObj['fullName']?.toString() ?? clientObj['name']?.toString()
        : json['clientName'] as String? ??
              (clientObj is String && !_uuid.hasMatch(clientObj)
                  ? clientObj
                  : null);

    final industryObj = json['industry'];
    final industryId = json['industryId']?.toString() ??
        (industryObj is Map ? industryObj['id']?.toString() : null) ??
        (industryObj is String && _uuid.hasMatch(industryObj)
            ? industryObj
            : null);
    final industryName = json['industryName']?.toString() ??
        (industryObj is Map ? industryObj['name']?.toString() : null) ??
        (industryObj is String && !_uuid.hasMatch(industryObj)
            ? industryObj
            : null) ??
        '';

    final categoryObj = json['category'];
    final categoryRaw = (categoryObj is Map
            ? categoryObj['name']?.toString()
            : categoryObj?.toString()) ??
        json['categoryName']?.toString() ??
        (industryName.isNotEmpty ? industryName : 'General');
    final categoryId = json['categoryId']?.toString() ??
        (categoryObj is Map ? categoryObj['id']?.toString() : null) ??
        (_uuid.hasMatch(categoryRaw) ? categoryRaw : null);

    final skillNames = _nameList(json['skills']).isNotEmpty
        ? _nameList(json['skills'])
        : _nameList(json['techStack']).isNotEmpty
        ? _nameList(json['techStack'])
        : _nameList(json['technology']);

    final workModeObj = json['workMode'];
    final rawWorkModeId = (json['workModeId'] ??
            (workModeObj is Map ? workModeObj['id'] : null))
        ?.toString()
        .trim();
    final rawWorkModeName = (workModeObj is Map
            ? workModeObj['name']?.toString()
            : workModeObj?.toString()) ??
        json['workMode']?.toString() ??
        '';

    final String? workModeId;
    final String workMode;
    if (rawWorkModeId != null && rawWorkModeId.isNotEmpty) {
      workModeId = rawWorkModeId;
      workMode = rawWorkModeName.isNotEmpty ? rawWorkModeName : 'Remote';
    } else if (rawWorkModeName.isNotEmpty && _uuid.hasMatch(rawWorkModeName.trim())) {
      workModeId = rawWorkModeName.trim();
      workMode = 'Remote';
    } else {
      workModeId = null;
      workMode = rawWorkModeName.isNotEmpty ? rawWorkModeName : 'Remote';
    }

    final expObj = json['experienceLevel'];
    final rawExpId = (json['experienceLevelId'] ??
            (expObj is Map ? expObj['id'] : null))
        ?.toString()
        .trim();
    final rawExpName = (expObj is Map
            ? expObj['name']?.toString() ?? expObj['id']?.toString()
            : expObj?.toString()) ??
        json['experienceLevel']?.toString() ??
        '';

    final String? experienceLevelId;
    final String experienceLevel;
    if (rawExpId != null && rawExpId.isNotEmpty) {
      experienceLevelId = rawExpId;
      experienceLevel = rawExpName.isNotEmpty ? rawExpName : 'intermediate';
    } else if (rawExpName.isNotEmpty &&
        (rawExpName.startsWith('mo_') || _uuid.hasMatch(rawExpName.trim()))) {
      experienceLevelId = rawExpName.trim();
      experienceLevel = rawExpName
          .replaceAll('mo_experience_level_', '')
          .replaceAll('_', ' ')
          .trim();
    } else {
      experienceLevelId = null;
      experienceLevel = rawExpName.isNotEmpty ? rawExpName : 'intermediate';
    }

    final budgetRangeObj = json['budgetRange'];
    final rawBudgetId = (json['projectHireBudgetId'] ??
            json['budgetRangeId'] ??
            (budgetRangeObj is Map ? budgetRangeObj['id'] : null))
        ?.toString()
        .trim();
    final rawBudgetName = (budgetRangeObj is Map
            ? budgetRangeObj['label']?.toString() ??
                budgetRangeObj['name']?.toString() ??
                budgetRangeObj['value']?.toString()
            : budgetRangeObj?.toString()) ??
        '';

    final String? budgetRangeId;
    final String budgetRangeName;
    if (rawBudgetId != null && rawBudgetId.isNotEmpty) {
      budgetRangeId = rawBudgetId;
      budgetRangeName = rawBudgetName;
    } else if (rawBudgetName.isNotEmpty && _uuid.hasMatch(rawBudgetName.trim())) {
      budgetRangeId = rawBudgetName.trim();
      budgetRangeName = rawBudgetName.trim();
    } else {
      budgetRangeId = null;
      budgetRangeName = rawBudgetName;
    }

    final startDate = json['startDate'] != null
        ? DateTime.tryParse(json['startDate'].toString())?.toLocal()
        : (json['timeline'] != null
            ? DateTime.tryParse(json['timeline'].toString())?.toLocal()
            : null);
    final endDate = json['endDate'] != null
        ? DateTime.tryParse(json['endDate'].toString())?.toLocal()
        : null;

    return Project(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      clientId:
          json['clientId']?.toString() ??
          (clientObj is String && _uuid.hasMatch(clientObj)
              ? clientObj
              : null) ??
          (clientObj is Map ? clientObj['id']?.toString() : null),
      clientName: _displayName(clientNameRaw),
      clientAvatar:
          (json['clientAvatar'] as String?) ??
          (json['avatarUrl'] as String?) ??
          (clientObj is Map ? clientObj['avatarUrl']?.toString() : null),
      industryId: industryId,
      industryName: industryName,
      category: _uuid.hasMatch(categoryRaw) ? 'General' : categoryRaw,
      categoryId: categoryId,
      skills: skillNames,
      skillIds: _idList(json['skillIds']).isNotEmpty
          ? _idList(json['skillIds'])
          : _idList(json['skills']).isNotEmpty
          ? _idList(json['skills'])
          : _idList(json['technology']).where(_uuid.hasMatch).toList(),
      techStack: _nameList(json['techStack']).isNotEmpty
          ? _nameList(json['techStack'])
          : skillNames,
      budgetMin:
          (json['budgetMin'] as num?)?.toDouble() ??
          (json['budget'] as num?)?.toDouble() ??
          0,
      budgetMax:
          (json['budgetMax'] as num?)?.toDouble() ??
          (json['budget'] as num?)?.toDouble() ??
          0,
      isHourly:
          json['isHourly'] as bool? ?? (json['is_hourly'] as bool?) ?? false,
      timeline: json['timeline'] as String? ?? '',
      status: EntityStatus.fromString(json['status'] as String? ?? 'open'),
      postedAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      proposalsCount: (json['proposalsCount'] as num?)?.toInt() ?? 0,
      workMode: workMode,
      workModeId: workModeId,
      experienceLevel: experienceLevel,
      experienceLevelId: experienceLevelId,
      budgetRangeId: budgetRangeId,
      budgetRangeName: budgetRangeName,
      startDate: startDate,
      endDate: endDate,
      location:
          json['location'] as String? ?? json['city'] as String? ?? 'Remote',
      attachments: _attachments(json['attachments']),
      clientVerified: json['clientVerified'] as bool? ?? true,
      isOwner: json['isOwner'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [id, isSaved, isApplied, isOwner, status];
}

/// A milestone within a contract.
class Milestone extends Equatable {
  const Milestone({
    required this.title,
    required this.amount,
    required this.status,
    required this.dueDate,
  });

  final String title;
  final double amount;
  final EntityStatus status;
  final DateTime dueDate;

  @override
  List<Object?> get props => [title, status];
}

/// An active or completed contract between a client and freelancer.
class Contract extends Equatable {
  const Contract({
    required this.id,
    required this.projectTitle,
    required this.counterpartyName,
    required this.amount,
    required this.status,
    required this.startDate,
    required this.milestones,
    this.counterpartyAvatar,
    this.progress = 0,
  });

  final String id;
  final String projectTitle;
  final String counterpartyName;
  final String? counterpartyAvatar;
  final double amount;
  final EntityStatus status;
  final DateTime startDate;
  final List<Milestone> milestones;
  final double progress;

  @override
  List<Object?> get props => [id, status, progress];
}
