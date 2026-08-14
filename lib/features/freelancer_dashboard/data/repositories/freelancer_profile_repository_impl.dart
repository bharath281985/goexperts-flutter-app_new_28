import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/file_upload_helper.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/freelancer_profile.dart';
import '../../domain/repositories/freelancer_profile_repository.dart';

class FreelancerProfileRepositoryImpl implements FreelancerProfileRepository {
  FreelancerProfileRepositoryImpl(this._api, this._uploader);

  final ApiClientHelper _api;
  final FileUploadHelper _uploader;

  @override
  Future<Result<FreelancerProfile>> getProfile() {
    return _api.get<FreelancerProfile>(
      ApiEndpoints.freelancerProfile,
      parser: (data) =>
          FreelancerProfile.fromApiJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  @override
  Future<Result<bool>> updateProfile(Map<String, dynamic> data) {
    return _api.putEnvelope<bool>(
      ApiEndpoints.freelancerProfile,
      body: data,
      parser: (raw) => true,
    );
  }

  @override
  Future<Result<Map<String, dynamic>>> getProfessionalDetails() {
    return _api.getEnvelope<Map<String, dynamic>>(
      ApiEndpoints.freelancerProfessionalDetails,
      parser: (env) {
        final data = env.data;
        if (data is Map) return Map<String, dynamic>.from(data);
        return <String, dynamic>{};
      },
    );
  }

  @override
  Future<Result<bool>> updateProfessionalDetails(
    Map<String, dynamic> data, {
    String? id,
  }) {
    final path = id != null && id.isNotEmpty
        ? ApiEndpoints.freelancerProfessionalDetailsItem(id)
        : ApiEndpoints.freelancerProfessionalDetails;
    return _api.putEnvelope<bool>(
      path,
      body: data,
      parser: (env) => true,
    );
  }

  @override
  Future<Result<Map<String, dynamic>>> getVerificationDetails() {
    return _api.getEnvelope<Map<String, dynamic>>(
      ApiEndpoints.freelancerVerification,
      parser: (env) {
        final data = env.data;
        if (data is Map) return Map<String, dynamic>.from(data);
        return <String, dynamic>{};
      },
    );
  }

  @override
  Future<Result<bool>> updateVerificationDetail({
    required String key,
    String? value,
    String? status,
    String? documentUrl,
  }) {
    final body = <String, dynamic>{
      'key': key,
      if (value != null) 'value': value,
      'status': status ?? 'pending',
      if (documentUrl != null) 'documentUrl': documentUrl,
    };
    return _api.patchEnvelope<bool>(
      ApiEndpoints.freelancerVerification,
      body: body,
      parser: (env) => true,
    );
  }

  @override
  Future<Result<bool>> deleteVerificationDetail({
    required String key,
  }) {
    return _api.deleteEnvelope<bool>(
      ApiEndpoints.freelancerVerification,
      body: {
        'key': key,
      },
      parser: (env) => true,
    );
  }

  @override
  Future<Result<String>> uploadAvatar(
    String filePath, {
    void Function(int sent, int total)? onProgress,
  }) async {
    return _uploader.uploadUrl(
      path: filePath,
      endpoint: ApiEndpoints.freelancerProfileAvatar,
      onProgress: onProgress,
    );
  }

  @override
  Future<Result<String>> uploadResume(
    String filePath, {
    void Function(int sent, int total)? onProgress,
  }) async {
    return _uploader.uploadUrl(
      path: filePath,
      endpoint: ApiEndpoints.freelancerProfileResume,
      onProgress: onProgress,
    );
  }

  @override
  Future<Result<String>> uploadCertificate(
    String filePath, {
    void Function(int sent, int total)? onProgress,
  }) async {
    return _uploader.uploadUrl(
      path: filePath,
      endpoint: ApiEndpoints.filesUpload,
      fields: {'category': 'certificate'},
      onProgress: onProgress,
    );
  }

  @override
  Future<Result<String>> uploadKycDocument({
    required String filePath,
    required String documentType,
    void Function(int sent, int total)? onProgress,
  }) async {
    return _uploader.uploadUrl(
      path: filePath,
      endpoint: ApiEndpoints.freelancerProfileKyc,
      fields: {'documentType': documentType},
      onProgress: onProgress,
    );
  }
}
