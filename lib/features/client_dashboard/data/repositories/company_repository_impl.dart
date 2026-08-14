import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/file_upload_helper.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/paginated.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/company.dart';
import '../../domain/repositories/company_repository.dart';

class CompanyRepositoryImpl implements CompanyRepository {
  CompanyRepositoryImpl([this._api, this._uploader]);
  final ApiClientHelper? _api;
  final FileUploadHelper? _uploader;

  @override
  Future<Result<Paginated<Company>>> getCompanies(QueryParams params) async {
    if (_api == null) return _apiNotConfigured();
    return _api.getEnvelope<Paginated<Company>>(
      ApiEndpoints
          .publicClients, // Assuming clients map to companies based on endpoints
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
  Future<Result<Company>> getCompany(String id) async {
    if (_api == null) return _apiNotConfigured();
    return _api.get<Company>(
      ApiEndpoints.publicClient(id),
      parser: (data) => _fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  @override
  Future<Result<bool>> toggleFollow(String id) async {
    if (_api == null) return _apiNotConfigured();
    return _api.postAction(
      '${ApiEndpoints.favorites}/toggle',
      body: {'entityType': 'company', 'entityId': id},
    );
  }

  @override
  Future<Result<Company>> getClientProfile() async {
    if (_api == null) {
      return _apiNotConfigured();
    }
    return _api.get<Company>(
      ApiEndpoints.clientProfile,
      parser: (data) => _fromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  @override
  Future<Result<bool>> updateClientProfile(
    Map<String, dynamic> data, {
    String? logoPath,
  }) async {
    if (_api == null) {
      return _apiNotConfigured();
    }
    if (logoPath != null && _uploader != null) {
      final uploadRes = await _uploader.upload(
        path: logoPath,
        endpoint: ApiEndpoints.clientProfile,
        fileField: 'file',
        method: 'put',
        fields: data,
      );
      return uploadRes.fold(Err.new, (_) => const Success(true));
    }
    return _api.putEnvelope<bool>(
      ApiEndpoints.clientProfile,
      body: data,
      parser: (_) => true,
    );
  }

  @override
  Future<Result<String>> uploadClientLogo(String filePath) async {
    if (_api == null || _uploader == null) {
      return _apiNotConfigured();
    }
    return _uploader.uploadUrl(
      path: filePath,
      endpoint: ApiEndpoints.clientProfileLogo,
    );
  }

  @override
  Future<Result<String>> uploadClientDocument(String filePath) async {
    if (_api == null || _uploader == null) {
      return _apiNotConfigured();
    }
    final direct = await _uploader.uploadUrl(
      path: filePath,
      endpoint: ApiEndpoints.clientProfileDocuments,
    );
    if (direct.isSuccess) return direct;
    return _uploader.uploadUrl(
      path: filePath,
      endpoint: ApiEndpoints.filesUpload,
      fields: {'category': 'company_document'},
    );
  }

  @override
  Future<Result<Map<String, dynamic>>> getVerificationDetails() async {
    if (_api == null) return _apiNotConfigured();
    return _api.getEnvelope<Map<String, dynamic>>(
      ApiEndpoints.clientVerification,
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
      ApiEndpoints.clientVerification,
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
      ApiEndpoints.clientVerification,
      body: {'key': key},
      parser: (env) => env.message,
    );
  }

  static Company _fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final user = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : const <String, dynamic>{};
    return Company(
      id: data['id']?.toString() ?? 'company',
      name:
          data['companyName'] as String? ??
          data['name'] as String? ??
          'Company',
      industry: data['industry'] as String? ?? 'General',
      location:
          json['location'] as String? ?? json['address'] as String? ?? 'N/A',
      ownerName:
          data['fullName'] as String? ?? user['fullName'] as String? ?? '',
      logoUrl:
          json['logoUrl'] as String? ??
          json['logo'] as String? ??
          json['avatarUrl'] as String?,
      coverUrl: json['coverUrl'] as String?,
      description: json['description'] as String? ?? '',
      website: data['website'] as String?,
      teamSize:
          data['companySize']?.toString() ??
          data['teamSize']?.toString() ??
          '1-10',
      isVerified: json['isVerified'] as bool? ?? false,
      projectsPosted: (json['projectsPosted'] as num?)?.toInt() ?? 0,
      hiresCount: (json['hiresCount'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      isFollowing: json['isFollowing'] as bool? ?? false,
      isSaved: json['isSaved'] as bool? ?? false,
      gst: json['gst'] as String? ?? '',
      pan: json['pan'] as String? ?? '',
      panNumber: json['panNumber'] as String? ?? '',
      aadhaarNumber: json['aadhaarNumber'] as String? ?? '',
      email: data['email'] as String? ?? user['email'] as String? ?? '',
      phone: data['phone'] as String? ?? user['phone'] as String? ?? '',
      bio: data['bio'] as String? ?? user['bio'] as String? ?? '',
      city: data['city'] as String? ?? user['city'] as String? ?? '',
      country: data['countryId'] as String? ?? data['country'] as String? ?? '',
      linkedin: data['linkedin'] as String? ?? '',
      companySize: data['companySize']?.toString() ?? '',
      phoneCode:
          data['phoneCode']?.toString() ?? user['phoneCode']?.toString() ?? '',
      countryCode:
          data['countryCode']?.toString() ??
          user['countryCode']?.toString() ??
          '',
      countryId: data['countryId']?.toString() ?? '',
    );
  }

  Future<Result<T>> _apiNotConfigured<T>() async =>
      const Err(ServerFailure('Live API client is not configured.'));
}
