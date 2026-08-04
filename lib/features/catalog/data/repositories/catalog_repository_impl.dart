import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/paginated.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/catalog_entities.dart';
import '../../domain/repositories/catalog_repository.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl([this._api]);

  final ApiClientHelper? _api;

  @override
  Future<Result<Paginated<ServiceItem>>> getServices(QueryParams params) async {
    if (_api == null) return _apiNotConfigured();
    // Assuming a public endpoint for services (if missing from ApiEndpoints, just fallback to error or general search)
    return const Err(ServerFailure('Endpoint for services not mapped yet.'));
  }

  @override
  Future<Result<ServiceItem>> getService(String id) async {
    if (_api == null) return _apiNotConfigured();
    return const Err(
      ServerFailure('Endpoint for service by id not mapped yet.'),
    );
  }

  @override
  Future<Result<Paginated<Technology>>> getTechnologies(
    QueryParams params,
  ) async {
    if (_api == null) return _apiNotConfigured();
    // Replace with correct ApiEndpoint if available
    return const Err(
      ServerFailure('Endpoint for technologies not mapped yet.'),
    );
  }

  @override
  Future<Result<Technology>> getTechnology(String id) async {
    if (_api == null) return _apiNotConfigured();
    return const Err(
      ServerFailure('Endpoint for technology by id not mapped yet.'),
    );
  }

  @override
  Future<Result<Paginated<CategoryItem>>> getCategories(
    QueryParams params,
  ) async {
    if (_api == null) return _apiNotConfigured();
    // Assuming parsing map logic for category
    return const Err(
      ServerFailure('Endpoint for categories not fully implemented yet.'),
    );
  }

  @override
  Future<Result<CategoryItem>> getCategory(String id) async {
    if (_api == null) return _apiNotConfigured();
    return const Err(
      ServerFailure('Endpoint for category by id not mapped yet.'),
    );
  }

  @override
  Future<Result<Paginated<Certificate>>> getCertificates(
    QueryParams params,
  ) async {
    if (_api == null) return _apiNotConfigured();

    return _api.getEnvelope<Paginated<Certificate>>(
      ApiEndpoints.files,
      query: {...params.toApiQuery(), 'category': 'certificate'},
      parser: (envelope) => ApiResponse.parsePaginated(
        envelope.data,
        envelope.meta,
        _certificateFromJson,
        fallbackPage: params.page,
      ),
    );
  }

  @override
  Future<Result<Certificate>> getCertificate(String id) async {
    if (_api == null) return _apiNotConfigured();
    return const Err(
      ServerFailure('Endpoint for certificate by id not mapped yet.'),
    );
  }

  @override
  Future<Result<Paginated<InvestmentOpportunity>>> getOpportunities(
    QueryParams params,
  ) async {
    if (_api == null) return _apiNotConfigured();
    return const Err(
      ServerFailure('Endpoint for opportunities not mapped yet.'),
    );
  }

  @override
  Future<Result<InvestmentOpportunity>> getOpportunity(String id) async {
    if (_api == null) return _apiNotConfigured();
    return const Err(
      ServerFailure('Endpoint for opportunity by id not mapped yet.'),
    );
  }

  @override
  Future<Result<BusinessPlan>> getBusinessPlan(String startupId) async {
    if (_api == null) return _apiNotConfigured();
    return const Err(
      ServerFailure('Endpoint for business plan not mapped yet.'),
    );
  }

  @override
  Future<Result<PitchDeck>> getPitchDeck(String startupId) async {
    if (_api == null) return _apiNotConfigured();
    return const Err(ServerFailure('Endpoint for pitch deck not mapped yet.'));
  }

  static Certificate _certificateFromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['id']?.toString() ?? '',
      title:
          json['title'] as String? ?? json['name'] as String? ?? 'Certificate',
      issuer:
          json['issuer'] as String? ??
          json['uploadedBy'] as String? ??
          'Issuer',
      issuedAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      credentialId: json['credentialId'] as String? ?? '',
      url: json['url'] as String? ?? json['previewUrl'] as String?,
      skills:
          (json['skills'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }

  Future<Result<T>> _apiNotConfigured<T>() async =>
      const Err(ServerFailure('Live API client is not configured.'));
}
