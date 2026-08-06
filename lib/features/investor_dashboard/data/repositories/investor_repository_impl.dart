import 'dart:convert';
import '../../../../app/config/app_config.dart';
import '../../../../core/auth/token_role_helper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/paginated.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/enums.dart';
import '../../domain/entities/investor.dart';
import '../../domain/repositories/investor_repository.dart';

class InvestorRepositoryImpl implements InvestorRepository {
  InvestorRepositoryImpl([this._api, this._tokenRoleHelper]);
  final ApiClientHelper? _api;
  final TokenRoleHelper? _tokenRoleHelper;

  Future<UserRole?> _role() async => await _tokenRoleHelper?.resolve();

  @override
  Future<Result<Paginated<Investor>>> getInvestors(QueryParams params) async {
    if (_api == null) return _apiNotConfigured();
    final role = await _role();
    final path = role == UserRole.founder
        ? ApiEndpoints.founderInvestors
        : '/investors';
    return _api.getEnvelope<Paginated<Investor>>(
      path,
      query: params.toApiQuery(),
      parser: (env) => ApiResponse.parsePaginated(
        env.data,
        env.meta,
        _investorFromJson,
        fallbackPage: params.page,
      ),
    );
  }

  @override
  Future<Result<Investor>> getInvestor(String id) async {
    if (_api == null) return _apiNotConfigured();
    final role = await _role();
    final path = role == UserRole.founder
        ? ApiEndpoints.founderInvestor(id)
        : '/investors/$id';
    return _api.get<Investor>(
      path,
      parser: (raw) => _investorFromJson(Map<String, dynamic>.from(raw as Map)),
    );
  }

  @override
  Future<Result<Paginated<Deal>>> getDeals(QueryParams params) async {
    if (_api == null) return _apiNotConfigured();
    return _api.getEnvelope<Paginated<Deal>>(
      ApiEndpoints.investorInvestments,
      query: params.toApiQuery(),
      parser: (env) {
        return ApiResponse.parsePaginated(env.data, env.meta, (rawRaw) {
          final raw = Map<String, dynamic>.from(rawRaw as Map);
          final ideaDetails =
              raw['startupDetails'] as Map? ?? raw['ideaDetails'] as Map?;
          final userDetails = ideaDetails?['user'] as Map?;
          final startupId =
              raw['startup']?.toString() ??
              ideaDetails?['id']?.toString() ??
              raw['startupId']?.toString() ??
              '';

          int parsedDocsCount = (raw['documentsCount'] as num?)?.toInt() ?? 0;
          Map<String, dynamic> actualDocs = {};
          if (raw['docs'] is String && (raw['docs'] as String).isNotEmpty) {
            try {
              final Map<String, dynamic> docsMap = jsonDecode(
                raw['docs'] as String,
              );
              actualDocs = docsMap;
              parsedDocsCount = docsMap.values
                  .where((v) => v != null && v.toString().trim().isNotEmpty)
                  .length;
            } catch (_) {}
          } else if (raw['docs'] is Map) {
            final docsMap = raw['docs'] as Map;
            actualDocs = Map<String, dynamic>.from(docsMap);
            parsedDocsCount = docsMap.values
                .where((v) => v != null && v.toString().trim().isNotEmpty)
                .length;
          }

          return Deal(
            id: raw['id']?.toString() ?? '',
            startupId: startupId,
            startupName:
                ideaDetails?['startup']?.toString() ??
                raw['startupName']?.toString() ??
                raw['name']?.toString() ??
                'Startup',
            founderName:
                userDetails?['fullName']?.toString() ??
                ideaDetails?['founder']?.toString() ??
                raw['founderName']?.toString() ??
                'Founder',
            stage:
                ideaDetails?['stage']?.toString() ??
                raw['stage']?.toString() ??
                'MVP',
            amount:
                (raw['offer'] as num?)?.toDouble() ??
                (raw['amount'] as num?)?.toDouble() ??
                0.0,
            equity: (raw['equity'] as num?)?.toDouble() ?? 0.0,
            status: EntityStatus.fromString(
              raw['status']?.toString() ?? 'pending',
            ),
            updatedAt:
                DateTime.tryParse(raw['updatedAt']?.toString() ?? '') ??
                DateTime.now(),
            startupLogo:
                ideaDetails?['logo']?.toString() ??
                raw['startupLogo']?.toString() ??
                raw['logoUrl']?.toString(),
            hasNda: raw['hasNda'] as bool? ?? false,
            documentsCount: parsedDocsCount,
            documents: actualDocs,
            founderId:
                userDetails?['id']?.toString() ??
                ideaDetails?['userId']?.toString() ??
                ideaDetails?['founderId']?.toString() ??
                raw['founderId']?.toString() ??
                raw['userId']?.toString() ??
                startupId,
          );
        }, fallbackPage: params.page);
      },
    );
  }

  @override
  Future<Result<Paginated<PortfolioItem>>> getPortfolio(
    QueryParams params,
  ) async {
    if (_api == null) return _apiNotConfigured();
    return _api.getEnvelope<Paginated<PortfolioItem>>(
      ApiEndpoints.investorPortfolio,
      query: params.toApiQuery(),
      parser: (env) {
        final rawData = env.data;
        dynamic listRaw = rawData;
        if (rawData is Map) {
          listRaw =
              rawData['investments'] ??
              rawData['items'] ??
              rawData['data'] ??
              rawData;
        }
        return ApiResponse.parsePaginated(
          listRaw,
          env.meta,
          _portfolioFromJson,
          fallbackPage: params.page,
        );
      },
    );
  }

  @override
  Future<Result<bool>> toggleFollow(String id) async {
    if (_api == null) return _apiNotConfigured();
    return _api.postAction(
      '${ApiEndpoints.favorites}/toggle',
      body: {'entityType': 'investor', 'entityId': id},
    );
  }

  @override
  Future<Result<bool>> toggleSave(String id) async {
    if (_api == null) return _apiNotConfigured();
    final post = await _api.postAction(
      ApiEndpoints.investorWatchlist,
      body: {'startupId': id},
    );
    if (post.isSuccess) return post;
    return _api.deleteAction(ApiEndpoints.investorWatchlistItem(id));
  }

  Investor _investorFromJson(Map<String, dynamic> json) =>
      Investor.fromApiJson(json);

  PortfolioItem _portfolioFromJson(Map<String, dynamic> json) {
    final startup = json['startup'] as Map?;
    final startupProfile = json['startupProfile'] as Map?;
    final startupName =
        json['startupName'] as String? ??
        startup?['name'] as String? ??
        startupProfile?['startupName'] as String? ??
        json['name'] as String? ??
        'Startup';

    final investedAmount =
        (json['investedAmount'] as num?)?.toDouble() ??
        (json['amount'] as num?)?.toDouble() ??
        0.0;

    final currentValue =
        (json['currentValue'] as num?)?.toDouble() ??
        (json['value'] as num?)?.toDouble() ??
        (json['currentAmount'] as num?)?.toDouble() ??
        investedAmount;

    return PortfolioItem(
      id: json['id']?.toString() ?? '',
      startupName: startupName,
      investedAmount: investedAmount,
      currentValue: currentValue,
      equity: (json['equity'] as num?)?.toDouble() ?? 0,
      investedAt:
          DateTime.tryParse(
            json['investedAt']?.toString() ??
                json['createdAt']?.toString() ??
                '',
          ) ??
          DateTime.now(),
      logoUrl:
          json['logoUrl'] as String? ??
          json['logo'] as String? ??
          startup?['logoUrl'] as String?,
    );
  }

  Future<Result<T>> _apiNotConfigured<T>() async =>
      const Err(ServerFailure('Live API client is not configured.'));
}
