import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/paginated.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/founder.dart';
import '../../domain/repositories/founder_repository.dart';

class FounderRepositoryImpl implements FounderRepository {
  FounderRepositoryImpl([this._api]);
  final ApiClientHelper? _api;

  @override
  Future<Result<Paginated<Founder>>> getFounders(QueryParams params) async {
    if (_api == null) return _apiNotConfigured();
    return _api.getEnvelope<Paginated<Founder>>(
      '/founders',
      query: params.toApiQuery(),
      parser: (env) => ApiResponse.parsePaginated(
        env.data,
        env.meta,
        _founderFromJson,
        fallbackPage: params.page,
      ),
    );
  }

  @override
  Future<Result<Founder>> getFounder(String id) async {
    if (_api == null) return _apiNotConfigured();
    return _api.get<Founder>(
      '/founders/$id',
      parser: (raw) => _founderFromJson(Map<String, dynamic>.from(raw as Map)),
    );
  }

  @override
  Future<Result<Paginated<InvestorRequest>>> getInvestorRequests(
    QueryParams params,
  ) async {
    if (_api == null) return _apiNotConfigured();
    return _api.getEnvelope<Paginated<InvestorRequest>>(
      ApiEndpoints.founderInvestorRequests,
      query: params.toApiQuery(),
      parser: (env) => ApiResponse.parsePaginated(
        env.data,
        env.meta,
        _requestFromJson,
        fallbackPage: params.page,
      ),
    );
  }

  @override
  Future<Result<bool>> respondToRequest(String id, String status) async {
    if (_api == null) return _apiNotConfigured();
    final normalized = status.toLowerCase();
    if (normalized == 'accepted' || normalized == 'accept') {
      return _api.patchAction(ApiEndpoints.founderInvestorRequestAccept(id));
    }
    if (normalized == 'rejected' || normalized == 'reject') {
      return _api.patchAction(ApiEndpoints.founderInvestorRequestReject(id));
    }
    if (normalized == 'meeting') {
      return _api.patchAction(ApiEndpoints.founderInvestorRequestMeeting(id));
    }
    return _api.patchAction(
      ApiEndpoints.founderInvestorRequestMessage(id),
      body: {'message': status},
    );
  }

  @override
  Future<Result<bool>> toggleFollow(String id) async {
    if (_api == null) return _apiNotConfigured();
    return _api.postAction(
      '${ApiEndpoints.favorites}/toggle',
      body: {'entityType': 'founder', 'entityId': id},
    );
  }

  @override
  Future<Result<Map<String, dynamic>>> getVerificationDetails() async {
    if (_api == null) return _apiNotConfigured();
    return _api.getEnvelope<Map<String, dynamic>>(
      ApiEndpoints.founderVerification,
      parser: (env) {
        final data = env.data;
        if (data is Map) return Map<String, dynamic>.from(data);
        return <String, dynamic>{};
      },
    );
  }

  @override
  Future<Result<String?>> updateVerificationDetail({
    required String key,
    String? value,
    String? status,
    String? documentUrl,
  }) async {
    if (_api == null) return _apiNotConfigured();
    final body = <String, dynamic>{
      'key': key,
      if (value != null) 'value': value,
      'status': status ?? 'pending',
      if (documentUrl != null) 'documentUrl': documentUrl,
    };
    return _api.patchEnvelope<String?>(
      ApiEndpoints.founderVerification,
      body: body,
      parser: (env) => env.message,
    );
  }

  @override
  Future<Result<String?>> deleteVerificationDetail({
    required String key,
  }) async {
    if (_api == null) return _apiNotConfigured();
    return _api.deleteEnvelope<String?>(
      ApiEndpoints.founderVerification,
      body: {'key': key},
      parser: (env) => env.message,
    );
  }

  Founder _founderFromJson(Map<String, dynamic> json) => Founder(
    id: json['id']?.toString() ?? '',
    name: json['name'] as String? ?? 'Founder',
    founderType: json['founderType'] as String? ?? 'Founder',
    location: json['location'] as String? ?? 'N/A',
    avatarUrl: json['avatarUrl'] as String?,
    coverUrl: json['coverUrl'] as String?,
    bio: json['bio'] as String? ?? '',
    experienceYears: (json['experienceYears'] as num?)?.toInt() ?? 0,
    skills:
        (json['skills'] as List?)?.map((e) => e.toString()).toList() ??
        const [],
    linkedIn: json['linkedIn'] as String?,
    startupName: json['startupName'] as String? ?? '',
    isVerified: json['isVerified'] as bool? ?? false,
    isFollowing: json['isFollowing'] as bool? ?? false,
    followers: (json['followers'] as num?)?.toInt() ?? 0,
  );

  InvestorRequest _requestFromJson(Map<String, dynamic> json) =>
      InvestorRequest(
        id: json['id']?.toString() ?? '',
        investorName: json['investorName'] as String? ?? 'Investor',
        investorAvatar: json['investorAvatar'] as String?,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        equity: (json['equity'] as num?)?.toDouble() ?? 0,
        status: EntityStatus.fromString(
          json['status']?.toString() ?? 'pending',
        ),
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
            DateTime.now(),
        message: json['message'] as String? ?? '',
      );

  Future<Result<T>> _apiNotConfigured<T>() async =>
      const Err(ServerFailure('Live API client is not configured.'));
}
