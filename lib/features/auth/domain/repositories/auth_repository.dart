import '../../../../core/utils/enums.dart';
import '../../../../core/utils/result.dart';
import '../entities/app_user.dart';
import '../entities/profile_completion_result.dart';

abstract class AuthRepository {
  Future<Result<AppUser>> login({
    required String email,
    required String password,
  });
  Future<Result<AppUser>> signup({
    required String fullName,
    required String email,
    String? phone,
    String? countryCode,
    required String password,
    required UserRole role,
    Map<String, dynamic> signupData = const {},
  });
  Future<Result<AppUser>> socialLogin(
    String provider, {
    required UserRole role,
    required String idToken,
    String? accessToken,
    String? email,
    String? fullName,
  });
  Future<Result<bool>> sendOtp({
    required String phone,
    required String countryCode,
  });
  Future<Result<bool>> verifyOtp({
    required String code,
    String? phone,
    String? countryCode,
  });
  Future<Result<bool>> forgotPassword(String email);
  Future<Result<bool>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  });
  Future<Result<AppUser>> selectRole(UserRole role);
  Future<Result<ProfileCompletionResult>> completeProfile(
    Map<String, dynamic> data, {
    List<int>? avatarBytes,
  });
  Future<Result<bool>> saveOnboardingDraft(Map<String, dynamic> data);

  /// Persists a local "subscription active" flag so Skip / free activation
  /// survives router refreshes and re-login when the API has not caught up.
  Future<Result<AppUser>> markSubscriptionActive({String? planId});

  Future<Result<String>> changePassword({
    required String oldPassword,
    required String newPassword,
  });

  Future<Result<AppUser>> currentUser();
  Future<void> updateCachedUser(AppUser user);
  Future<void> logout();
}
