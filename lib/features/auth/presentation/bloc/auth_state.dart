part of 'auth_bloc.dart';

/// Holds signup form data until role is selected and register API is called.
class SignupDraft extends Equatable {
  const SignupDraft({
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

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.isSubmitting = false,
    this.errorMessage,
    this.pendingSignup,
    this.subscriptionStatus = SubscriptionGateStatus.unknown,
    this.subscriptionPlanId,
    this.successMessage,
  });

  final AuthStatus status;
  final AppUser? user;
  final bool isSubmitting;
  final String? errorMessage;
  final SignupDraft? pendingSignup;
  final SubscriptionGateStatus subscriptionStatus;
  final String? subscriptionPlanId;
  final String? successMessage;

  bool get hasRole => user?.role != null;
  bool get isProfileComplete => user?.isProfileComplete ?? false;
  bool get hasSubscription =>
      subscriptionStatus == SubscriptionGateStatus.active ||
      // Server explicitly says the user has a subscription
      (user?.serverHasSubscription == true) ||
      // Server provides a direct dashboard redirect — honour it
      _serverRedirectsToDashboard;
  bool get needsSubscription => !hasSubscription;

  /// True when the server explicitly redirects to a known dashboard path.
  bool get _serverRedirectsToDashboard {
    final r = user?.redirectTo;
    if (r == null || r.isEmpty) return false;
    return r.contains('dashboard') ||
        r.contains('/founder/') ||
        r.contains('/investor/') ||
        r.contains('/client/') ||
        r.contains('/freelancer/');
  }

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    bool? isSubmitting,
    String? errorMessage,
    SignupDraft? pendingSignup,
    bool clearPendingSignup = false,
    SubscriptionGateStatus? subscriptionStatus,
    String? subscriptionPlanId,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pendingSignup: clearPendingSignup
          ? null
          : (pendingSignup ?? this.pendingSignup),
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionPlanId: subscriptionPlanId ?? this.subscriptionPlanId,
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    isSubmitting,
    errorMessage,
    pendingSignup,
    subscriptionStatus,
    subscriptionPlanId,
    successMessage,
  ];
}
