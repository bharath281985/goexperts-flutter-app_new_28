import 'package:equatable/equatable.dart';
import '../../../../core/utils/enums.dart';

/// Authenticated user across all roles.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.countryCode,
    this.role,
    this.avatarUrl,
    this.isVerified = false,
    this.isProfileComplete = false,
    this.isSocialLogin = false,
    this.subscriptionPlan,
    this.subscriptionStatus,
    this.headline,
    this.location,
    this.profileCompletion = 0,
    
    this.serverHasSubscription,
    this.categoryId,
    this.industryId,
    this.skillIds = const [],
  });

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? countryCode;
  final UserRole? role;
  final String? avatarUrl;
  final bool isVerified;
  final bool isProfileComplete;
  final bool isSocialLogin;
  final String? subscriptionPlan;

  /// Backend gate: `active` | `expired` | `none`.
  final String? subscriptionStatus;
  final String? headline;
  final String? location;
  final int profileCompletion;

  /// Explicit redirect path from server (e.g. "/founder/dashboard").


  /// `hasSubscription` / `isSubscribed` flag as returned directly by the API.
  final bool? serverHasSubscription;

  final String? categoryId;
  final String? industryId;
  final List<String> skillIds;

  AppUser copyWith({
    String? fullName,
    UserRole? role,
    String? avatarUrl,
    bool? isVerified,
    bool? isProfileComplete,
    bool? isSocialLogin,
    String? subscriptionPlan,
    String? subscriptionStatus,
    String? headline,
    String? location,
    int? profileCompletion,
    String? phone,
    String? countryCode,
  
    bool? serverHasSubscription,
    String? categoryId,
    String? industryId,
    List<String>? skillIds,
  }) {
    return AppUser(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      countryCode: countryCode ?? this.countryCode,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isVerified: isVerified ?? this.isVerified,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      isSocialLogin: isSocialLogin ?? this.isSocialLogin,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      headline: headline ?? this.headline,
      location: location ?? this.location,
      profileCompletion: profileCompletion ?? this.profileCompletion,

      serverHasSubscription:
          serverHasSubscription ?? this.serverHasSubscription,
      categoryId: categoryId ?? this.categoryId,
      industryId: industryId ?? this.industryId,
      skillIds: skillIds ?? this.skillIds,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      AppUser.fromApiJson(json);

  /// Parses API user payloads (camelCase or snake_case).
  static final _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static String? _readablePlan(String? value) {
    final v = value?.trim();
    if (v == null || v.isEmpty || _uuidPattern.hasMatch(v)) return null;
    return v;
  }

  factory AppUser.fromApiJson(Map<String, dynamic> json) {
    // Safe string reader: returns null for falsy non-string values (bool false, 0, etc.)
    String? str(String camel, String snake) {
      final v = json[camel] ?? json[snake];
      if (v == null || v == false || v == 0) return null;
      if (v is String) return v.isEmpty ? null : v;
      return v.toString();
    }

    // Safe bool reader: handles bool, int, and string representations
    bool flag(String camel, String snake) {
      final v = json[camel] ?? json[snake];
      if (v is bool) return v;
      if (v is int) return v != 0;
      if (v is String) return v == 'true' || v == '1';
      return false;
    }

    final profileCompletion =
        json['profileCompletion'] as int? ??
        json['profile_completion'] as int? ??
        0;
    final roleRaw = str('role', 'role');

    final city = str('city', 'city');
    final country = str('country', 'country');
    final locationParts = [
      city,
      country,
    ].whereType<String>().where((s) => s.isNotEmpty);
    final joinedLocation = locationParts.isEmpty
        ? null
        : locationParts.join(', ');

    // hasSubscription / isSubscribed from the API response.
    final serverHasSubscription =
        json['hasSubscription'] as bool? ??
        json['isSubscribed'] as bool? ??
        json['has_subscription'] as bool?;

    final rawSkills = json['skills'] ?? json['skillIds'];
    final parsedSkills = <String>[];
    if (rawSkills is List) {
      parsedSkills.addAll(
        rawSkills
            .map((e) {
              if (e is Map) {
                return (e['id'] ?? e['name'] ?? e['value'])?.toString() ?? '';
              }
              return e.toString();
            })
            .where((e) => e.isNotEmpty),
      );
    } else if (rawSkills is String && rawSkills.isNotEmpty) {
      parsedSkills.addAll(
        rawSkills.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty),
      );
    }

    final avatar = str('avatarUrl', 'avatar_url') ??
        str('avatar', 'avatar') ??
        str('logoUrl', 'logo_url') ??
        str('logo', 'logo') ??
        (json['profile'] is Map
            ? (json['profile']['avatarUrl'] ??
                    json['profile']['avatar'] ??
                    json['profile']['logoUrl'] ??
                    json['profile']['logo'])
                ?.toString()
            : null);

    return AppUser(
      id: str('id', 'id') ?? '',
      fullName: str('fullName', 'full_name') ??
          str('name', 'name') ??
          (json['profile'] is Map
              ? (json['profile']['fullName'] ??
                      json['profile']['name'] ??
                      json['profile']['companyName'])
                  ?.toString()
              : null) ??
          '',
      email: str('email', 'email') ?? '',
      phone: str('phone', 'phone'),
      countryCode: str('countryCode', 'country_code'),
      role: roleRaw != null ? UserRole.fromString(roleRaw) : null,
      avatarUrl: avatar,
      isVerified: flag('isVerified', 'is_verified'),
      isProfileComplete:
          flag('isProfileComplete', 'is_profile_complete') ||
          profileCompletion >= 80,
      isSocialLogin: flag('isSocialLogin', 'is_social_login'),
      profileCompletion: profileCompletion,
      // Prefer human-readable plan name; never store raw plan UUIDs.
      subscriptionPlan:
          _readablePlan(str('subscriptionPlan', 'subscription_plan')) ??
          _readablePlan(
            str('subscriptionPlanName', 'subscription_plan_name'),
          ) ??
          _readablePlan(str('subscriptionPlanId', 'subscription_plan_id')),
      subscriptionStatus: str('subscriptionStatus', 'subscription_status'),
      headline: str('headline', 'headline') ?? str('bio', 'bio'),
      location: str('location', 'location') ?? joinedLocation,
    
      serverHasSubscription: serverHasSubscription,
      categoryId: str('categoryId', 'category_id'),
      industryId: str('industryId', 'industry_id'),
      skillIds: parsedSkills,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'country_code': countryCode,
    'role': role?.apiValue,
    'avatar_url': avatarUrl,
    'is_verified': isVerified,
    'is_profile_complete': isProfileComplete,
    'is_social_login': isSocialLogin,
    'subscription_plan': subscriptionPlan,
    'subscription_status': subscriptionStatus,
    'headline': headline,
    'location': location,
    'profile_completion': profileCompletion,
 
    if (serverHasSubscription != null)
      'has_subscription': serverHasSubscription,
    'category_id': categoryId,
    'industry_id': industryId,
    'skill_ids': skillIds,
  };

  @override
  List<Object?> get props => [
    id,
    email,
    phone,
    countryCode,
    role,
    isVerified,
    isProfileComplete,
    isSocialLogin,
    subscriptionPlan,
    subscriptionStatus,
    categoryId,
    industryId,
    skillIds,
  ];
}
