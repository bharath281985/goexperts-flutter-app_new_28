import '../../../../core/auth/token_role_helper.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/paginated.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/investor.dart';
import '../../domain/repositories/investor_repository.dart';

class InvestorRepositoryImpl implements InvestorRepository {
  InvestorRepositoryImpl(this._api, [this._tokenRoleHelper]);

  final ApiClientHelper _api;
  final TokenRoleHelper? _tokenRoleHelper;

  @override
  Future<Result<Paginated<Investor>>> getInvestors(QueryParams params) async {
    return _api.getEnvelope<Paginated<Investor>>(
      ApiEndpoints.publicInvestors,
      query: params.toApiQuery(),
      parser: (envelope) {
        final raw = envelope.data;
        final list = raw is List
            ? raw
            : (raw is Map ? (raw['items'] ?? raw['data'] ?? raw['rows'] ?? const []) : const []);
        return ApiResponse.parsePaginated(
          list as List,
          envelope.meta,
          (item) => Investor.fromApiJson(item as Map<String, dynamic>),
          fallbackPage: params.page,
        );
      },
    );
  }

  @override
  Future<Result<Investor>> getInvestor(String id) async {
    return _api.getEnvelope<Investor>(
      ApiEndpoints.publicInvestor(id),
      parser: (envelope) =>
          Investor.fromApiJson(envelope.data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<Paginated<Deal>>> getDeals(QueryParams params) async {
    return _api.getEnvelope<Paginated<Deal>>(
      '/investor/deals',
      query: params.toApiQuery(),
      parser: (envelope) {
        final raw = envelope.data;
        final list = raw is List
            ? raw
            : (raw is Map ? (raw['items'] ?? raw['data'] ?? raw['deals'] ?? const []) : const []);
        return ApiResponse.parsePaginated(
          list as List,
          envelope.meta,
          (item) => Deal.fromApiJson(item as Map<String, dynamic>),
          fallbackPage: params.page,
        );
      },
    );
  }

  @override
  Future<Result<Deal>> getDeal(String id) async {
    return _api.getEnvelope<Deal>(
      '/investor/deals/$id',
      parser: (envelope) =>
          Deal.fromApiJson(envelope.data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<Paginated<PortfolioItem>>> getPortfolio(
    QueryParams params, {
    String? investorId,
  }) async {
    final endpoint = investorId != null && investorId.isNotEmpty
        ? ApiEndpoints.publicInvestorPortfolio(investorId)
        : '/investor/portfolio';
    return _api.getEnvelope<Paginated<PortfolioItem>>(
      endpoint,
      query: params.toApiQuery(),
      parser: (envelope) {
        final raw = envelope.data;
        final list = raw is List
            ? raw
            : (raw is Map ? (raw['items'] ?? raw['data'] ?? raw['portfolio'] ?? const []) : const []);
        return ApiResponse.parsePaginated(
          list as List,
          envelope.meta,
          (item) => PortfolioItem.fromApiJson(item as Map<String, dynamic>),
          fallbackPage: params.page,
        );
      },
    );
  }

  @override
  Future<Result<PortfolioItem>> addPortfolioItem(Map<String, dynamic> data) async {
    return _api.postEnvelope<PortfolioItem>(
      '/investor/portfolio',
      body: data,
      parser: (envelope) =>
          PortfolioItem.fromApiJson(envelope.data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<PortfolioItem>> updatePortfolioItem(
    String id,
    Map<String, dynamic> data,
  ) async {
    return _api.putEnvelope<PortfolioItem>(
      '/investor/portfolio/$id',
      body: data,
      parser: (envelope) =>
          PortfolioItem.fromApiJson(envelope.data as Map<String, dynamic>),
    );
  }

  @override
  Future<Result<String>> deletePortfolioItem(String id) async {
    return _api.deleteEnvelope<String>(
      '/investor/portfolio/$id',
      parser: (envelope) => envelope.message ?? 'Portfolio holding deleted',
    );
  }

  @override
  Future<Result<void>> expressInterest(Map<String, dynamic> data) async {
    return _api.postEnvelope<void>(
      ApiEndpoints.publicInvestmentsOffer,
      body: data,
      parser: (_) {},
    );
  }

  @override
  Future<Result<void>> updateInvestment(
    String id,
    Map<String, dynamic> data,
  ) async {
    return _api.putEnvelope<void>(
      '/investor/deals/$id',
      body: data,
      parser: (_) {},
    );
  }

  @override
  Future<Result<void>> updateInvestmentStatus(String id, String status) async {
    return _api.putEnvelope<void>(
      '/investor/deals/$id/status',
      body: {'status': status},
      parser: (_) {},
    );
  }

  @override
  Future<Result<void>> followInvestor(String id) async {
    return _api.postEnvelope<void>(
      '/public/investors/$id/follow',
      parser: (_) {},
    );
  }

  @override
  Future<Result<void>> unfollowInvestor(String id) async {
    return _api.deleteEnvelope<void>(
      '/public/investors/$id/follow',
      parser: (_) {},
    );
  }

  @override
  Future<Result<void>> saveInvestor(String id) async {
    return _api.postEnvelope<void>(
      ApiEndpoints.publicInvestorSave(id),
      parser: (_) {},
    );
  }

  @override
  Future<Result<void>> unsaveInvestor(String id) async {
    return _api.deleteEnvelope<void>(
      ApiEndpoints.publicInvestorSave(id),
      parser: (_) {},
    );
  }

  @override
  Future<Result<Map<String, dynamic>>> getVerificationDetails() async {
    return _api.getEnvelope<Map<String, dynamic>>(
      ApiEndpoints.publicVerification,
      parser: (envelope) {
        final raw = envelope.data;
        if (raw is Map) return Map<String, dynamic>.from(raw);
        return const <String, dynamic>{};
      },
    );
  }

  @override
  Future<Result<String>> updateVerificationDetail({
    required String key,
    required String value,
    required String status,
    String? documentUrl,
  }) async {
    return _api.postEnvelope<String>(
      ApiEndpoints.publicVerification,
      body: {
        'key': key,
        'value': value,
        'status': status,
        if (documentUrl != null && documentUrl.isNotEmpty)
          'documentUrl': documentUrl,
      },
      parser: (envelope) => envelope.message ?? 'Verification detail updated',
    );
  }

  @override
  Future<Result<String>> deleteVerificationDetail({required String key}) async {
    return _api.deleteEnvelope<String>(
      '${ApiEndpoints.publicVerification}/$key',
      parser: (envelope) => envelope.message ?? 'Verification detail deleted',
    );
  }
}
