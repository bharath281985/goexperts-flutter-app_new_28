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

  static SignupProgress? read() {
    return null;
  }

  static bool hasProgress() => false;

  static Future<void> save({
    required UserRole role,
    required int step,
    String? verifiedEmail,
    String? registeredEmail,
    Map<String, dynamic> fields = const {},
  }) {
    return Future.value();
  }

  static Future<void> clear() {
    return Future.value();
  }
}
