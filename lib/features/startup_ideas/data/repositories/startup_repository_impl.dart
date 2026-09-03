import '../../../../core/auth/token_role_helper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/paginated.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/startup.dart';
import '../../domain/repositories/startup_repository.dart';

class StartupRepositoryImpl implements StartupRepository {
  StartupRepositoryImpl([this._api, this._tokenRoleHelper]);

  final ApiClientHelper? _api;
  final TokenRoleHelper? _tokenRoleHelper;

  Future<String> _rolePath() async {
    final role = await _tokenRoleHelper?.resolve();
    return ApiEndpoints.rolePath(role);
  }

  Future<List<String>> _myStartupPaths() async {
    final rolePath = await _rolePath();
    return switch (rolePath) {
      'freelancer' => [
        ApiEndpoints.freelancerMyStartups,
        ApiEndpoints.freelancerIdeas,
        ApiEndpoints.publicMyStartups,
      ],
      'client' => [
        ApiEndpoints.clientMyStartups,
        ApiEndpoints.clientIdeas,
        ApiEndpoints.publicMyStartups,
      ],
      'investor' => [
        ApiEndpoints.investorMyStartups,
        ApiEndpoints.investorIdeas,
        ApiEndpoints.publicMyStartups,
      ],
      _ => [
        ApiEndpoints.founderIdeas,
        ApiEndpoints.publicMyStartups,
      ],
    };
  }

  Future<List<String>> _createIdeaPaths() async {
    final rolePath = await _rolePath();
    return switch (rolePath) {
      'freelancer' => [ApiEndpoints.freelancerStartups, ApiEndpoints.freelancerIdeas],
      'client' => [ApiEndpoints.clientStartups, ApiEndpoints.clientIdeas],
      'investor' => [ApiEndpoints.investorStartups, ApiEndpoints.investorIdeas],
      _ => [ApiEndpoints.founderIdeas, ApiEndpoints.publicStartups],
    };
  }

  Future<List<String>> _ideaItemPaths(String id) async {
    final rolePath = await _rolePath();
    return switch (rolePath) {
      'freelancer' => [
        '${ApiEndpoints.freelancerIdeas}/$id',
        '${ApiEndpoints.freelancerStartups}/$id',
      ],
      'client' => [
        '${ApiEndpoints.clientIdeas}/$id',
        '${ApiEndpoints.clientStartups}/$id',
      ],
      'investor' => [
        '${ApiEndpoints.investorIdeas}/$id',
        '${ApiEndpoints.investorStartups}/$id',
      ],
      _ => [
        ApiEndpoints.founderIdea(id),
        '${ApiEndpoints.publicStartups}/$id',
      ],
    };
  }

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
    Result<Paginated<Startup>> res = const Err(ServerFailure('No data'));
    for (final path in await _myStartupPaths()) {
      res = await _api.getEnvelope<Paginated<Startup>>(
        path,
        query: params.toApiQuery(),
        parser: (env) => ApiResponse.parsePaginated(
          env.data,
          env.meta,
          Startup.fromApiJson,
          fallbackPage: params.page,
        ),
      );
      if (res.isSuccess) break;
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
    return _api.postAction(ApiEndpoints.publicStartupSave(id));
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
  Future<Result<bool>> expressInterest(Map<String, dynamic> data) async {
    if (_api == null) return _apiNotConfigured();
    final primary = await _api.postEnvelope<bool>(
      ApiEndpoints.investorInvestmentsExpressInterest,
      body: data,
      parser: (env) => true,
    );
    if (primary.isSuccess) return primary;
    return submitOffer(data);
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
    final primary = await _api.patchAction(
      ApiEndpoints.investorCancelInvestment(id),
    );
    if (primary.isSuccess) return primary;
    return _api.patchAction('${ApiEndpoints.publicInvestments}/$id/cancel');
  }

  @override
  Future<Result<Startup>> createIdea(Map<String, dynamic> data) async {
    if (_api == null) return _apiNotConfigured();
    Result<Startup> res = const Err(ServerFailure('No data'));
    for (final path in await _createIdeaPaths()) {
      res = await _api.post<Startup>(
        path,
        body: data,
        parser: (raw) =>
            Startup.fromApiJson(Map<String, dynamic>.from(raw as Map)),
      );
      if (res.isSuccess) break;
    }
    return res;
  }

  @override
  Future<Result<bool>> updateIdea(String id, Map<String, dynamic> data) async {
    if (_api == null) return _apiNotConfigured();
    Result<bool> res = const Err(ServerFailure('No data'));
    for (final path in await _ideaItemPaths(id)) {
      res = await _api.putEnvelope<bool>(
        path,
        body: data,
        parser: (env) => true,
      );
      if (res.isSuccess) break;
    }
    return res;
  }

  @override
  Future<Result<bool>> deleteIdea(String id) async {
    if (_api == null) return _apiNotConfigured();
    Result<bool> res = const Err(ServerFailure('No data'));
    for (final path in await _ideaItemPaths(id)) {
      res = await _api.deleteAction(path);
      if (res.isSuccess) break;
    }
    return res;
  }

  @override
  Future<Result<Paginated<dynamic>>> getMyInvestments(QueryParams params) async {
    if (_api == null) return _apiNotConfigured();
    var res = await _api.getEnvelope<Paginated<dynamic>>(
      ApiEndpoints.investorInvestments,
      query: params.toApiQuery(),
      parser: (env) => ApiResponse.parsePaginated(
        env.data,
        env.meta,
        (raw) => raw,
        fallbackPage: params.page,
      ),
    );
    if (res.isFailure) {
      final fallback = await _api.getEnvelope<Paginated<dynamic>>(
        ApiEndpoints.publicInvestments,
        query: params.toApiQuery(),
        parser: (env) => ApiResponse.parsePaginated(
          env.data,
          env.meta,
          (raw) => raw,
          fallbackPage: params.page,
        ),
      );
      if (fallback.isSuccess) res = fallback;
    }
    return res;
  }

  @override
  Future<Result<Paginated<dynamic>>> getIncomingOffers({
    String? startupId,
    QueryParams? params,
  }) async {
    if (_api == null) return _apiNotConfigured();
    final path = (startupId != null && startupId.isNotEmpty)
        ? '${ApiEndpoints.publicStartups}/$startupId/proposals'
        : ApiEndpoints.founderInvestorRequests;
    var res = await _api.getEnvelope<Paginated<dynamic>>(
      path,
      query: params?.toApiQuery(),
      parser: (env) => ApiResponse.parsePaginated(
        env.data,
        env.meta,
        (raw) => raw,
        fallbackPage: params?.page ?? 1,
      ),
    );
    if (res.isFailure) {
      final fallbackPath = (startupId != null && startupId.isNotEmpty)
          ? '${ApiEndpoints.publicStartups}/$startupId/investor-requests'
          : ApiEndpoints.publicInvestorRequests;
      final fallback = await _api.getEnvelope<Paginated<dynamic>>(
        fallbackPath,
        query: params?.toApiQuery(),
        parser: (env) => ApiResponse.parsePaginated(
          env.data,
          env.meta,
          (raw) => raw,
          fallbackPage: params?.page ?? 1,
        ),
      );
      if (fallback.isSuccess) res = fallback;
    }
    return res;
  }

  @override
  Future<Result<bool>> acceptOffer(String id) async {
    if (_api == null) return _apiNotConfigured();
    final primary = await _api.patchAction(
      ApiEndpoints.founderInvestorRequestAccept(id),
    );
    if (primary.isSuccess) return primary;
    return _api.patchAction(ApiEndpoints.publicInvestorRequestAccept(id));
  }

  @override
  Future<Result<bool>> rejectOffer(String id) async {
    if (_api == null) return _apiNotConfigured();
    final primary = await _api.patchAction(
      ApiEndpoints.founderInvestorRequestReject(id),
    );
    if (primary.isSuccess) return primary;
    return _api.patchAction(ApiEndpoints.publicInvestorRequestReject(id));
  }

  @override
  Future<Result<bool>> scheduleOfferMeeting(
    String id, {
    String? date,
    String? time,
    Map<String, dynamic>? data,
  }) async {
    if (_api == null) return _apiNotConfigured();
    final body = data ?? <String, dynamic>{
      if (date != null) 'date': date,
      if (time != null) 'time': time,
    };
    final primary = await _api.patchAction(
      ApiEndpoints.founderInvestorRequestMeeting(id),
      body: body.isNotEmpty ? body : null,
    );
    if (primary.isSuccess) return primary;
    return _api.patchAction(
      ApiEndpoints.publicInvestorRequestMeeting(id),
      body: body.isNotEmpty ? body : null,
    );
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
