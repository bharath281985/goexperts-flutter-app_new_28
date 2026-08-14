import '../entities/app_user.dart';

class ProfileCompletionResult {
  const ProfileCompletionResult({this.user, required this.message});

  final AppUser? user;
  final String message;
}
