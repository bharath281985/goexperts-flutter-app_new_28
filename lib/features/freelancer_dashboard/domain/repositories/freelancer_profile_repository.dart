import '../../../../core/utils/result.dart';
import '../entities/freelancer_profile.dart';

abstract class FreelancerProfileRepository {
  Future<Result<FreelancerProfile>> getProfile();
  Future<Result<bool>> updateProfile(Map<String, dynamic> data);
  Future<Result<String>> uploadAvatar(String filePath);
  Future<Result<String>> uploadResume(String filePath);
  Future<Result<String>> uploadCertificate(String filePath);
  Future<Result<String>> uploadKycDocument({
    required String filePath,
    required String documentType,
  });
}
