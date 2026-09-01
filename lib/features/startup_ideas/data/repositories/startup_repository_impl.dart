import '../../../../core/auth/token_role_helper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/paginated.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/startup.dart';
import '../../domain/repositories/startup_repository.dart';

class StartupRepositoryImpl implements StartupRepository {
  StartupRepositoryImpl([this._api, this._tokenRoleHelper]);

  final ApiClientHelper? _api;
  final TokenRoleHelper? _tokenRoleHelper;

  @override
  Future<Result<Paginated<Startup>>> getStartups(QueryParams params) async {
    if (_api == null) return _apiNotConfigured();
    return _api.getEnvelope<Paginated<Startup>>(
      ApiEndpoints.publicStartups,
      query: params.toApiQuery(),
      parser: (env) => ApiResponse.parsePaginated(
        env.data,
        env.meta,
        Startup.fromApiJson,
        fallbackPage: params.page,
      ),
    );
  }

  @override
  Future<Result<Paginated<Startup>>> getMyStartups(QueryParams params) async {
    if (_api == null) return _apiNotConfigured();
    var res = await _api.getEnvelope<Paginated<Startup>>(
      ApiEndpoints.founderIdeas,
      query: params.toApiQuery(),
      parser: (env) => ApiResponse.parsePaginated(
        env.data,
        env.meta,
        Startup.fromApiJson,
        fallbackPage: params.page,
      ),
    );
    if (res.isFailure) {
      final fallback = await _api.getEnvelope<Paginated<Startup>>(
        ApiEndpoints.publicMyStartups,
        query: params.toApiQuery(),
        parser: (env) => ApiResponse.parsePaginated(
          env.data,
          env.meta,
          Startup.fromApiJson,
          fallbackPage: params.page,
        ),
      );
      if (fallback.isSuccess) res = fallback;
    }
    return res;
  }

  @override
  Future<Result<Startup>> getStartup(String id) async {
    if (_api == null) return _apiNotConfigured();
    return _api.get<Startup>(
      '${ApiEndpoints.publicStartups}/$id',
      parser: (raw) =>
          Startup.fromApiJson(Map<String, dynamic>.from(raw as Map)),
    );
  }

  @override
  Future<Result<bool>> toggleSave(String id) async {
    if (_api == null) return _apiNotConfigured();
    var post = await _api.postAction(ApiEndpoints.investorStartupSave(id));
    if (post.isSuccess) return post;
    post = await _api.postAction('${ApiEndpoints.publicStartups}/$id/save');
    if (post.isSuccess) return post;
    final del = await _api.deleteAction(ApiEndpoints.investorStartupSave(id));
    if (del.isSuccess) return del;
    return _api.deleteAction('${ApiEndpoints.publicStartups}/$id/save');
  }

  @override
  Future<Result<bool>> toggleFollow(String id) async {
    if (_api == null) return _apiNotConfigured();
    return _api.postAction(
      '${ApiEndpoints.favorites}/toggle',
      body: {'entityType': 'startup', 'entityId': id},
    );
  }

  @override
  Future<Result<bool>> submitOffer(Map<String, dynamic> data) async {
    if (_api == null) return _apiNotConfigured();
    final primary = await _api.postEnvelope<bool>(
      ApiEndpoints.investorOffer,
      body: data,
      parser: (env) => true,
    );
    if (primary.isSuccess) return primary;
    return _api.postEnvelope<bool>(
      ApiEndpoints.publicInvestmentsOffer,
      body: data,
      parser: (env) => true,
    );
  }

  @override
  Future<Result<bool>> withdrawInterest(String id) async {
    if (_api == null) return _apiNotConfigured();
    return _api.patchAction('${ApiEndpoints.publicInvestments}/$id/cancel');
  }

  @override
  Future<Result<Startup>> createIdea(Map<String, dynamic> data) async {
    if (_api == null) return _apiNotConfigured();
    final primary = await _api.post<Startup>(
      ApiEndpoints.founderIdeas,
      body: data,
      parser: (raw) =>
          Startup.fromApiJson(Map<String, dynamic>.from(raw as Map)),
    );
    if (primary.isSuccess) return primary;
    return _api.post<Startup>(
      ApiEndpoints.publicStartups,
      body: data,
      parser: (raw) =>
          Startup.fromApiJson(Map<String, dynamic>.from(raw as Map)),
    );
  }

  @override
  Future<Result<bool>> updateIdea(String id, Map<String, dynamic> data) async {
    if (_api == null) return _apiNotConfigured();
    return _api.putEnvelope<bool>(
      '${ApiEndpoints.publicStartups}/$id',
      body: data,
      parser: (env) => true,
    );
  }

  @override
  Future<Result<bool>> deleteIdea(String id) async {
    if (_api == null) return _apiNotConfigured();
    return _api.deleteAction('${ApiEndpoints.publicStartups}/$id');
  }

  @override
  Future<Result<Paginated<dynamic>>> getMyInvestments(QueryParams params) async {
    if (_api == null) return _apiNotConfigured();
    return _api.getEnvelope<Paginated<dynamic>>(
      ApiEndpoints.publicInvestments,
      query: params.toApiQuery(),
      parser: (env) => ApiResponse.parsePaginated(
        env.data,
        env.meta,
        (raw) => raw,
        fallbackPage: params.page,
      ),
    );
  }

  @override
  Future<Result<Paginated<dynamic>>> getIncomingOffers({
    String? startupId,
    QueryParams? params,
  }) async {
    if (_api == null) return _apiNotConfigured();
    final path = (startupId != null && startupId.isNotEmpty)
        ? '${ApiEndpoints.publicStartups}/$startupId/investor-requests'
        : ApiEndpoints.publicInvestorRequests;
    return _api.getEnvelope<Paginated<dynamic>>(
      path,
      query: params?.toApiQuery(),
      parser: (env) => ApiResponse.parsePaginated(
        env.data,
        env.meta,
        (raw) => raw,
        fallbackPage: params?.page ?? 1,
      ),
    );
  }

  @override
  Future<Result<bool>> acceptOffer(String id) async {
    if (_api == null) return _apiNotConfigured();
    return _api.patchAction(ApiEndpoints.publicInvestorRequestAccept(id));
  }

  @override
  Future<Result<bool>> rejectOffer(String id) async {
    if (_api == null) return _apiNotConfigured();
    return _api.patchAction(ApiEndpoints.publicInvestorRequestReject(id));
  }

  @override
  Future<Result<bool>> scheduleOfferMeeting(String id) async {
    if (_api == null) return _apiNotConfigured();
    return _api.patchAction(ApiEndpoints.publicInvestorRequestMeeting(id));
  }

  @override
  Future<Result<Map<String, dynamic>>> getFundingOverview() async {
    if (_api == null) return _apiNotConfigured();
    return _api.getEnvelope<Map<String, dynamic>>(
      ApiEndpoints.publicFunding,
      parser: (env) =>
          env.data is Map ? Map<String, dynamic>.from(env.data as Map) : {},
    );
  }

  @override
  Future<Result<bool>> createFundingRound(Map<String, dynamic> data) async {
    if (_api == null) return _apiNotConfigured();
    return _api.postAction(ApiEndpoints.publicFunding, body: data);
  }

  @override
  Future<Result<Map<String, dynamic>>> getPitchDeck() async {
    if (_api == null) return _apiNotConfigured();
    return _api.getEnvelope<Map<String, dynamic>>(
      ApiEndpoints.publicPitchDeck,
      parser: (env) =>
          env.data is Map ? Map<String, dynamic>.from(env.data as Map) : {},
    );
  }

  @override
  Future<Result<bool>> saveBusinessPlan(Map<String, dynamic> data) async {
    if (_api == null) return _apiNotConfigured();
    return _api.postAction(ApiEndpoints.publicBusinessPlan, body: data);
  }

  @override
  Future<Result<Map<String, dynamic>>> getBusinessPlan() async {
    if (_api == null) return _apiNotConfigured();
    return _api.getEnvelope<Map<String, dynamic>>(
      ApiEndpoints.publicBusinessPlan,
      parser: (env) =>
          env.data is Map ? Map<String, dynamic>.from(env.data as Map) : {},
    );
  }

  Future<Result<T>> _apiNotConfigured<T>() async =>
      const Err(ServerFailure('Live API client is not configured.'));
}
