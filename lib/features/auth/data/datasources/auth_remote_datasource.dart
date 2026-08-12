import '../../../../app/config/app_config.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/utils/device_info_helper.dart';
import '../../../../core/utils/enums.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/profile_completion_result.dart';

class AuthRemoteDatasource {
  AuthRemoteDatasource(this._api, this._secureStorage, this._deviceInfo);

  final ApiClientHelper _api;
  final SecureStorage _secureStorage;
  final DeviceInfoHelper _deviceInfo;

  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final device = await _deviceInfo.authPayload();
    final result = await _api.postPayload<Map<String, dynamic>>(
      ApiEndpoints.login,
      body: {
        'email': email,
        'password': password,
        'deviceId': device['deviceId'] ?? '',
        ...device,
      },
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );
    if (result.isFailure) throw Exception(result.failureOrNull!.message);
    final data = result.valueOrNull!;
    await _persistTokens(data);
    return _userFromAuthPayload(data);
  }

  Future<AppUser> signup({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
    String? countryCode,
    Map<String, dynamic> signupData = const {},
  }) async {
    final device = await _deviceInfo.authPayload();
    final trimmedPhone = phone?.trim() ?? '';
    final result = await _api.postPayload<Map<String, dynamic>>(
      ApiEndpoints.register,
      body: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'role': role.apiValue,
        if (trimmedPhone.isNotEmpty) ...{
          'phone': trimmedPhone,
          if (countryCode != null && countryCode.trim().isNotEmpty)
            'countryCode': countryCode.trim(),
        },
        ...signupData,
        ...device,
      },
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );
    if (result.isFailure) throw Exception(result.failureOrNull!.message);
    final data = result.valueOrNull!;
    await _persistTokens(data);
    return _userFromAuthPayload(data);
  }

  Future<AppUser> getMe() async {
    final result = await _api.getEnvelope<AppUser>(
      ApiEndpoints.me,
      parser: (envelope) {
        final raw = envelope.data;
        if (raw is Map<String, dynamic> && raw['user'] is Map) {
          return AppUser.fromApiJson(
            Map<String, dynamic>.from(raw['user'] as Map),
          );
        }
        if (raw is Map<String, dynamic>) {
          return AppUser.fromApiJson(raw);
        }
        throw Exception('Invalid user payload');
      },
    );
    return result.fold((f) => throw Exception(f.message), (user) => user);
  }

  Future<ProfileCompletionResult> updateProfile(
    Map<String, dynamic> data,
  ) async {
    final result = await _api.putEnvelope<ProfileCompletionResult>(
      ApiEndpoints.updateMe,
      body: data,
      parser: (envelope) {
        final raw = envelope.data;
        final message = envelope.message ?? 'Profile updated successfully';
        Map<String, dynamic> userJson;
        if (raw is Map && raw['user'] is Map) {
          userJson = Map<String, dynamic>.from(raw['user'] as Map);
        } else if (raw is Map<String, dynamic>) {
          userJson = raw;
        } else {
          throw Exception('User data missing from profile response');
        }
        return ProfileCompletionResult(
          user: AppUser.fromApiJson(userJson),
          message: message,
        );
      },
    );
    return result.fold((f) => throw Exception(f.message), (value) => value);
  }

  Future<void> saveOnboardingDraft(Map<String, dynamic> data) async {
    final result = await _api.putEnvelope<bool>(
      '${AppConfig.authBaseUrl}${ApiEndpoints.onboardingDraft}',
      body: data,
      parser: (_) => true,
    );
    result.fold((f) => throw Exception(f.message), (_) => null);
  }

  Future<AppUser> uploadAvatarBytes(List<int> bytes) async {
    final result = await _api.uploadBytesEnvelope<AppUser>(
      ApiEndpoints.updateMeAvatar,
      bytes: bytes,
      filename: 'avatar.jpg',
      fileField: 'file',
      parser: (envelope) {
        final raw = envelope.data;
        if (raw is Map && raw['user'] is Map) {
          return AppUser.fromApiJson(
            Map<String, dynamic>.from(raw['user'] as Map),
          );
        }
        if (raw is Map<String, dynamic>) {
          final avatarUrl =
              raw['avatarUrl']?.toString() ?? raw['url']?.toString();
          if (avatarUrl != null) {
            return AppUser(
              id: '',
              fullName: '',
              email: '',
              avatarUrl: avatarUrl,
            );
          }
        }
        throw Exception('Avatar upload response missing user data');
      },
    );
    return result.fold((f) => throw Exception(f.message), (user) => user);
  }

  Future<bool> sendOtp({
    required String phone,
    required String countryCode,
  }) async {
    final result = await _api.postAction(
      ApiEndpoints.sendOtp,
      body: {'phone': phone, 'countryCode': countryCode},
    );
    return result.fold((f) => throw Exception(f.message), (v) => v);
  }

  Future<bool> verifyOtp({
    required String code,
    String? phone,
    String? countryCode,
  }) async {
    final result = await _api.postAction(
      ApiEndpoints.verifyOtp,
      body: {
        'code': code,
        if (phone != null) 'phone': phone,
        if (countryCode != null) 'countryCode': countryCode,
      },
    );
    return result.fold((f) => throw Exception(f.message), (v) => v);
  }

  Future<bool> forgotPassword(String email) async {
    final result = await _api.postAction(
      ApiEndpoints.forgotPassword,
      body: {'email': email},
    );
    return result.fold((f) => throw Exception(f.message), (v) => v);
  }

  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final result = await _api.postAction(
      ApiEndpoints.resetPassword, // Assuming this is correct
      body: {'email': email, 'otp': otp, 'newPassword': newPassword},
    );
    return result.fold((f) => throw Exception(f.message), (v) => v);
  }

  Future<String> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final result = await _api.postAction(
      ApiEndpoints.changePassword,
      body: {'oldPassword': oldPassword, 'newPassword': newPassword},
    );
    return result.fold(
      (f) => throw Exception(f.message),
      (_) => 'Password changed successfully',
    );
  }

  Future<void> logout() async {
    final device = await _deviceInfo.authPayload();
    final refreshToken = await _secureStorage.refreshToken;
    final body = <String, dynamic>{
      'fcmToken': device['fcmToken'] ?? '',
      'deviceId': device['deviceId'] ?? '',
      if (refreshToken != null && refreshToken.isNotEmpty)
        'refreshToken': refreshToken,
    };
    await _api.postAction(ApiEndpoints.logout, body: body);
    await _secureStorage.deleteAll();
  }

  Future<AppUser> socialLogin({
    required String endpoint,
    required UserRole role,
    required String idToken,
    String? accessToken,
    String? email,
    String? fullName,
  }) async {
    final device = await _deviceInfo.authPayload();
    final body = <String, dynamic>{
      'role': role.apiValue,
      'idToken': idToken,
      if (accessToken != null) 'accessToken': accessToken,
      if (email != null) 'email': email,
      if (fullName != null) 'fullName': fullName,
      ...device,
    };
    final result = await _api.postPayload<Map<String, dynamic>>(
      endpoint,
      body: body,
      parser: (data) => Map<String, dynamic>.from(data as Map),
    );
    if (result.isFailure) throw Exception(result.failureOrNull!.message);
    final data = result.valueOrNull!;
    await _persistTokens(data);
    return _userFromAuthPayload(data);
  }

  Future<void> _persistTokens(Map<String, dynamic> data) async {
    final access =
        (data['token'] ?? data['accessToken']) as String?;
    final refresh = (data['refreshToken'] ?? '') as String;
    final userJson = data['user'] ?? data['data'];
    String? userId;
    String? role;
    if (userJson is Map<String, dynamic>) {
      userId = userJson['id']?.toString();
      role = userJson['role']?.toString();
    }
    if (access != null && access.isNotEmpty) {
      await _secureStorage.saveSession(
        accessToken: access,
        refreshToken: refresh,
        userId: userId,
        role: role,
      );
    }
  }

  AppUser _userFromAuthPayload(Map<String, dynamic> data) {
    final userRaw = data['user'] ?? data['data'];
    if (userRaw is! Map) {
      throw Exception('User data missing from auth response');
    }
    final userJson = Map<String, dynamic>.from(userRaw);
    // Merge top-level auth-response fields into the user map so AppUser
    // can read hasSubscription, isSubscribed, redirectTo, etc.
    for (final key in [
      'hasSubscription',
      'isSubscribed',
      'redirectTo',
      'subscriptionPlan',
    ]) {
      if (!userJson.containsKey(key) && data.containsKey(key)) {
        userJson[key] = data[key];
      }
    }
    return AppUser.fromApiJson(userJson);
  }
}
