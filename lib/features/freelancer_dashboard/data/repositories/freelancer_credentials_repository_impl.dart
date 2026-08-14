import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/freelancer_credentials.dart';
import '../../domain/repositories/freelancer_credentials_repository.dart';

class FreelancerCredentialsRepositoryImpl
    implements FreelancerCredentialsRepository {
  FreelancerCredentialsRepositoryImpl(this._api);

  final ApiClientHelper _api;

  @override
  Future<Result<List<FreelancerEducation>>> getEducation() {
    return _api.getEnvelope<List<FreelancerEducation>>(
      _authPath(ApiEndpoints.freelancerEducation),
      parser: (envelope) => ApiResponse.parseList(
        _listPayload(envelope),
        FreelancerEducation.fromJson,
      ),
    );
  }

  @override
  Future<Result<FreelancerEducation>> addEducation(Map<String, dynamic> data) {
    return _api.postEnvelope<FreelancerEducation>(
      _authPath(ApiEndpoints.freelancerEducation),
      body: data,
      parser: (envelope) => _educationFromEnvelope(envelope, data),
    );
  }

  @override
  Future<Result<FreelancerEducation>> updateEducation(
    String id,
    Map<String, dynamic> data,
  ) {
    return _api.putEnvelope<FreelancerEducation>(
      _authPath(ApiEndpoints.freelancerEducationItem(id)),
      body: data,
      parser: (envelope) =>
          _educationFromEnvelope(envelope, {'id': id, ...data}),
    );
  }

  @override
  Future<Result<String>> deleteEducation(String id) {
    return _api.deleteEnvelope<String>(
      _authPath(ApiEndpoints.freelancerEducationItem(id)),
      parser: (envelope) => envelope.message ?? 'Education deleted',
    );
  }

  @override
  Future<Result<List<FreelancerCertificate>>> getCertificates() {
    return _api.getEnvelope<List<FreelancerCertificate>>(
      _authPath(ApiEndpoints.freelancerCertificates),
      parser: (envelope) => ApiResponse.parseList(
        _listPayload(envelope),
        FreelancerCertificate.fromJson,
      ),
    );
  }

  @override
  Future<Result<FreelancerCertificate>> addCertificate(
    Map<String, dynamic> data,
  ) {
    return _api.postEnvelope<FreelancerCertificate>(
      _authPath(ApiEndpoints.freelancerCertificates),
      body: data,
      parser: (envelope) => _certificateFromEnvelope(envelope, data),
    );
  }

  @override
  Future<Result<FreelancerCertificate>> updateCertificate(
    String id,
    Map<String, dynamic> data,
  ) {
    return _api.putEnvelope<FreelancerCertificate>(
      _authPath(ApiEndpoints.freelancerCertificateItem(id)),
      body: data,
      parser: (envelope) =>
          _certificateFromEnvelope(envelope, {'id': id, ...data}),
    );
  }

  @override
  Future<Result<String>> deleteCertificate(String id) {
    return _api.deleteEnvelope<String>(
      _authPath(ApiEndpoints.freelancerCertificateItem(id)),
      parser: (envelope) => envelope.message ?? 'Certificate deleted',
    );
  }

  @override
  Future<Result<List<FreelancerExperience>>> getExperiences() {
    return _api.getEnvelope<List<FreelancerExperience>>(
      _authPath(ApiEndpoints.freelancerExperience),
      parser: (envelope) => ApiResponse.parseList(
        _listPayload(envelope),
        FreelancerExperience.fromJson,
      ),
    );
  }

  @override
  Future<Result<FreelancerExperience>> addExperience(
    Map<String, dynamic> data,
  ) {
    return _api.postEnvelope<FreelancerExperience>(
      _authPath(ApiEndpoints.freelancerExperience),
      body: data,
      parser: (envelope) => _experienceFromEnvelope(envelope, data),
    );
  }

  @override
  Future<Result<FreelancerExperience>> updateExperience(
    String id,
    Map<String, dynamic> data,
  ) {
    return _api.putEnvelope<FreelancerExperience>(
      _authPath(ApiEndpoints.freelancerExperienceItem(id)),
      body: data,
      parser: (envelope) =>
          _experienceFromEnvelope(envelope, {'id': id, ...data}),
    );
  }

  @override
  Future<Result<String>> deleteExperience(String id) {
    return _api.deleteEnvelope<String>(
      _authPath(ApiEndpoints.freelancerExperienceItem(id)),
      parser: (envelope) => envelope.message ?? 'Experience deleted',
    );
  }

  String _authPath(String path) => path;

  dynamic _listPayload(ApiResponse<dynamic> envelope) {
    final raw = envelope.data;
    if (raw is List) return raw;
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      return map['data'] ?? map['items'] ?? map['rows'] ?? const [];
    }
    return const [];
  }

  FreelancerEducation _educationFromEnvelope(
    ApiResponse<dynamic> envelope,
    Map<String, dynamic> fallback,
  ) {
    final json = _itemPayload(envelope, fallback);
    return FreelancerEducation.fromJson(
      json,
      responseMessage: envelope.message,
    );
  }

  FreelancerCertificate _certificateFromEnvelope(
    ApiResponse<dynamic> envelope,
    Map<String, dynamic> fallback,
  ) {
    final json = _itemPayload(envelope, fallback);
    return FreelancerCertificate.fromJson(
      json,
      responseMessage: envelope.message,
    );
  }

  FreelancerExperience _experienceFromEnvelope(
    ApiResponse<dynamic> envelope,
    Map<String, dynamic> fallback,
  ) {
    final json = _itemPayload(envelope, fallback);
    return FreelancerExperience.fromJson(
      json,
      responseMessage: envelope.message,
    );
  }

  Map<String, dynamic> _itemPayload(
    ApiResponse<dynamic> envelope,
    Map<String, dynamic> fallback,
  ) {
    final raw = envelope.data;
    final rawMap = raw is Map ? Map<String, dynamic>.from(raw) : null;
    final nested = rawMap?['data'] is Map
        ? Map<String, dynamic>.from(rawMap!['data'] as Map)
        : rawMap?['item'] is Map
        ? Map<String, dynamic>.from(rawMap!['item'] as Map)
        : rawMap;
    return {...fallback, if (nested != null) ...nested};
  }
}
