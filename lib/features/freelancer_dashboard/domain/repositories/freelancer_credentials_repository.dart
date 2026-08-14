import '../../../../core/utils/result.dart';
import '../entities/freelancer_credentials.dart';

abstract class FreelancerCredentialsRepository {
  Future<Result<List<FreelancerEducation>>> getEducation();
  Future<Result<FreelancerEducation>> addEducation(Map<String, dynamic> data);
  Future<Result<FreelancerEducation>> updateEducation(
    String id,
    Map<String, dynamic> data,
  );
  Future<Result<String>> deleteEducation(String id);

  Future<Result<List<FreelancerCertificate>>> getCertificates();
  Future<Result<FreelancerCertificate>> addCertificate(
    Map<String, dynamic> data,
  );
  Future<Result<FreelancerCertificate>> updateCertificate(
    String id,
    Map<String, dynamic> data,
  );
  Future<Result<String>> deleteCertificate(String id);

  Future<Result<List<FreelancerExperience>>> getExperiences();
  Future<Result<FreelancerExperience>> addExperience(Map<String, dynamic> data);
  Future<Result<FreelancerExperience>> updateExperience(
    String id,
    Map<String, dynamic> data,
  );
  Future<Result<String>> deleteExperience(String id);
}
