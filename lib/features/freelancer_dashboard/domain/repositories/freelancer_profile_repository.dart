import '../../../../core/utils/result.dart';
import '../entities/freelancer_profile.dart';

abstract class FreelancerProfileRepository {
  Future<Result<FreelancerProfile>> getProfile();
  Future<Result<bool>> updateProfile(Map<String, dynamic> data);
  Future<Result<Map<String, dynamic>>> getProfessionalDetails();
  Future<Result<bool>> updateProfessionalDetails(
    Map<String, dynamic> data, {
    String? id,
  });
  Future<Result<Map<String, dynamic>>> getVerificationDetails();
  Future<Result<bool>> updateVerificationDetail({
    required String key,
    String? value,
    String? status,
    String? documentUrl,
  });
  Future<Result<bool>> deleteVerificationDetail({
    required String key,
  });
  Future<Result<String>> uploadAvatar(String filePath);
  Future<Result<String>> uploadResume(String filePath);
  Future<Result<String>> uploadCertificate(String filePath);
  Future<Result<String>> uploadKycDocument({
    required String filePath,
    required String documentType,
  });
}
