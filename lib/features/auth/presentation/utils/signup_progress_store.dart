import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/utils/enums.dart';

class SignupProgress {
  const SignupProgress({
    required this.role,
    required this.step,
    this.verifiedEmail,
    this.registeredEmail,
    this.fields = const {},
  });

  final UserRole role;
  final int step;
  final String? verifiedEmail;
  final String? registeredEmail;
  final Map<String, dynamic> fields;
}

class SignupProgressStore {
  SignupProgressStore._();

  static const _key = 'signup_flow_progress';

  static SignupProgress? read() {
    final json = sl<LocalStorage>().getJson(_key);
    if (json == null) return null;
    final roleName = json['role']?.toString();
    final role = roleName == null || roleName.isEmpty
        ? null
        : UserRole.fromString(roleName);
    final step = json['step'];
    if (role == null || step is! int) return null;
    return SignupProgress(
      role: role,
      step: step,
      verifiedEmail: json['verifiedEmail']?.toString(),
      registeredEmail: json['registeredEmail']?.toString(),
      fields: json['fields'] is Map
          ? Map<String, dynamic>.from(json['fields'] as Map)
          : const {},
    );
  }

  static bool hasProgress() => read() != null;

  static Future<void> save({
    required UserRole role,
    required int step,
    String? verifiedEmail,
    String? registeredEmail,
    Map<String, dynamic> fields = const {},
  }) {
    return sl<LocalStorage>().setJson(_key, {
      'role': role.name,
      'step': step,
      if (verifiedEmail != null && verifiedEmail.trim().isNotEmpty)
        'verifiedEmail': verifiedEmail.trim(),
      if (registeredEmail != null && registeredEmail.trim().isNotEmpty)
        'registeredEmail': registeredEmail.trim(),
      'fields': fields,
    });
  }

  static Future<void> clear() {
    return sl<LocalStorage>().remove(_key);
  }
}
