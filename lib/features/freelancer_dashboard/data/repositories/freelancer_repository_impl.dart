import '../../../../core/auth/token_role_helper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/paginated.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/freelancer.dart';
import '../../domain/repositories/freelancer_repository.dart';

class FreelancerRepositoryImpl implements FreelancerRepository {
  FreelancerRepositoryImpl([this._api, this._tokenRoleHelper]);

  final ApiClientHelper? _api;
  final TokenRoleHelper? _tokenRoleHelper;

  @override
  Future<Result<Paginated<Freelancer>>> getFreelancers(
    QueryParams params,
  ) async {
    if (_api == null) return _apiNotConfigured();
    final role = await _tokenRoleHelper?.resolve();
    final path = role == UserRole.client
        ? ApiEndpoints.clientFreelancers
        : ApiEndpoints.publicFreelancers;
    return _api.getEnvelope<Paginated<Freelancer>>(
      path,
      query: params.toApiQuery(),
      parser: (env) => ApiResponse.parsePaginated(
        env.data,
        env.meta,
        _fromJson,
        fallbackPage: params.page,
      ),
    );
  }

  @override
  Future<Result<Freelancer>> getFreelancer(String id) async {
    if (_api == null) return _apiNotConfigured();
    final path = ApiEndpoints.publicFreelancer(id);
    var res = await _api.get<Freelancer>(
      path,
      parser: (data) => _fromJson(Map<String, dynamic>.from(data as Map)),
    );
    if (res.isFailure) {
      final fallbackRes = await _api.get<Freelancer>(
        '${ApiEndpoints.clientFreelancers}/$id',
        parser: (data) => _fromJson(Map<String, dynamic>.from(data as Map)),
      );
      if (fallbackRes.isSuccess) return fallbackRes;
    }
    return res;
  }

  @override
  Future<Result<bool>> toggleSave(String id) async {
    if (_api == null) return _apiNotConfigured();
    return _api.postAction(ApiEndpoints.publicFreelancerSave(id));
  }

  @override
  Future<Result<bool>> toggleFollow(String id) async {
    if (_api == null) return _apiNotConfigured();
    return _api.postAction(
      '${ApiEndpoints.favorites}/toggle',
      body: {'entityType': 'freelancer', 'entityId': id},
    );
  }

  @override
  Future<Result<bool>> invite(
    String id, {
    String? projectId,
    String? message,
  }) async {
    if (_api == null) return _apiNotConfigured();

    if (projectId != null && projectId.isNotEmpty) {
      return _api.postAction(
        ApiEndpoints.clientProjectInvite(projectId),
        body: {'freelancerId': id, 'message': message ?? ''},
      );
    }

    return _api.postAction(
      ApiEndpoints.mobileTeamInvite,
      body: {
        'freelancerId': id,
        'role': 'member',
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
      },
    );
  }

  static Freelancer _fromJson(Map<String, dynamic> json) {
    final profile = json['freelancerProfile'] as Map<String, dynamic>?;
    final rawSkills = json['Skills'] ?? json['skills'] ?? profile?['skills'];
    print('DEBUG: Freelancer json skills for ${json['id']}: rawSkills=$rawSkills, profile=$profile, jsonSkills=${json['skills']}');
    final skills = rawSkills is List
        ? rawSkills
              .map(
                (e) => e is Map
                    ? (e['skillName'] ?? e['name'] ?? e['skill'] ?? '')
                              ?.toString() ??
                          ''
                    : e.toString(),
              )
              .where((s) => s.trim().isNotEmpty)
              .toList()
        : (rawSkills is String
              ? rawSkills
                    .split(',')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList()
              : const <String>[]);

    final industryMap = json['Industry'] is Map
        ? json['Industry'] as Map
        : (json['industry'] is Map ? json['industry'] as Map : null);
    final category =
        industryMap?['name']?.toString() ??
        industryMap?['industryName']?.toString() ??
        json['industryName'] as String? ??
        json['category'] as String? ??
        'General';

    return Freelancer(
      id: json['id']?.toString() ?? '',
      name:
          json['name'] as String? ??
          json['fullName'] as String? ??
          'Freelancer',
      headline:
          json['titleHeadline'] as String? ??
          json['headline'] as String? ??
          json['professionalTitle'] as String? ??
          json['title'] as String? ??
          profile?['titleHeadline'] as String? ??
          profile?['headline'] as String? ??
          profile?['title'] as String? ??
          profile?['professionalTitle'] as String? ??
          '',
      category: category,
      skills: skills,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 
                  (profile?['hourlyRate'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewsCount: (json['reviewsCount'] as num?)?.toInt() ?? 0,
      location: json['location'] as String? ?? 'Remote',
      avatarUrl: json['avatarUrl'] as String?,
      bio: json['bio'] as String? ?? '',
      isSaved: json['isSaved'] as bool? ?? false,
      isFollowing: json['isFollowing'] as bool? ?? false,
      languages:
          (json['languages'] as List?)?.map((e) => e.toString()).toList() ??
          const ['English'],
      followers: (json['followers'] as num?)?.toInt() ?? 0,
      successRate: (json['successRate'] as num?)?.toInt() ?? 0,
      experienceYears: _parseExperience(json['experienceYears'] ?? profile?['experience']),
    );
  }

  static int _parseExperience(dynamic exp) {
    if (exp == null) return 3;
    if (exp is num) return exp.toInt();
    if (exp is String) {
      final match = RegExp(r'\d+').firstMatch(exp);
      if (match != null) {
        return int.tryParse(match.group(0) ?? '') ?? 3;
      }
    }
    return 3;
  }

  Future<Result<T>> _apiNotConfigured<T>() async =>
      const Err(ServerFailure('Live API client is not configured.'));
}
