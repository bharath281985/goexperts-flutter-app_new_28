import 'package:equatable/equatable.dart';

import '../../../../core/utils/enums.dart';
import '../../domain/entities/app_user.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});
  final String email;
  final String password;
  @override
  List<Object?> get props => [email, password];
}

/// Saves signup form locally and navigates to role selection (no API call yet).
class AuthSignupDraftSaved extends AuthEvent {
  const AuthSignupDraftSaved({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.countryCode,
    required this.password,
    this.signupData = const {},
  });
  final String fullName;
  final String email;
  final String phone;
  final String countryCode;
  final String password;
  final Map<String, dynamic> signupData;
  @override
  List<Object?> get props => [
    fullName,
    email,
    phone,
    countryCode,
    password,
    signupData,
  ];
}

class AuthSocialLoginRequested extends AuthEvent {
  const AuthSocialLoginRequested({
    required this.provider,
    this.role,
    required this.idToken,
    this.accessToken,
    this.email,
    this.fullName,
  });

  final String provider;
  final UserRole? role;
  final String idToken;
  final String? accessToken;
  final String? email;
  final String? fullName;

  @override
  List<Object?> get props => [
    provider,
    role,
    idToken,
    accessToken,
    email,
    fullName,
  ];
}

class AuthRoleSelected extends AuthEvent {
  const AuthRoleSelected(this.role);
  final UserRole role;
  @override
  List<Object?> get props => [role];
}

class AuthProfileCompleted extends AuthEvent {
  const AuthProfileCompleted(this.data, {this.avatarBytes});
  final Map<String, dynamic> data;
  final List<int>? avatarBytes;
  @override
  List<Object?> get props => [data, avatarBytes];
}

/// Re-validates subscription from backend after plan selection or renewal.
class AuthSubscriptionRefreshed extends AuthEvent {
  const AuthSubscriptionRefreshed();
}

/// Optimistically marks subscription as active (e.g. after free plan success),
/// then refreshes from the API.
class AuthSubscriptionActivated extends AuthEvent {
  const AuthSubscriptionActivated();
}

class AuthUserUpdated extends AuthEvent {
  const AuthUserUpdated(this.user);
  final AppUser user;
  @override
  List<Object?> get props => [user];
}

class AuthRefreshUser extends AuthEvent {
  const AuthRefreshUser();
}

class AuthLoggedOut extends AuthEvent {
  const AuthLoggedOut({this.remote = true});

  final bool remote;

  @override
  List<Object?> get props => [remote];
}
