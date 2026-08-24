import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/utils/enums.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/choose_role_view.dart';
import 'freelancer_signup_flow.dart';
import 'client_signup_flow.dart';
import 'investor_signup_flow.dart';
import 'founder_signup_flow.dart';

/// Main Mobile Signup Page Delegator (Asks role 1st then continues signup steps)
class SignupPage extends StatefulWidget {
  final String? initialRole;
  final int? initialStep;

  const SignupPage({super.key, this.initialRole, this.initialStep});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  UserRole? _selectedRole;

  @override
  void initState() {
    super.initState();
    if (widget.initialRole != null && widget.initialRole!.isNotEmpty) {
      _selectedRole = UserRole.fromString(widget.initialRole!);
    }
  }

  void _onRoleSelected(UserRole role) {
    setState(() {
      _selectedRole = role;
    });
    context.go('${Routes.signup}?role=${role.name}');
  }

  void _onBackToRoleSelection() async {
    setState(() {
      _selectedRole = null;
    });
    context.go(Routes.signup);
  }

  @override
  Widget build(BuildContext context) {
    final draftRole = context
        .watch<AuthBloc>()
        .state
        .pendingSignup
        ?.signupData['role']
        ?.toString();
    final routeRole = widget.initialRole;
    final authState = context.watch<AuthBloc>().state;
    final activeRole =
        _selectedRole ??
        (routeRole == null || routeRole.isEmpty
            ? null
            : UserRole.fromString(routeRole)) ??
        authState.user?.role ??
        (draftRole == null || draftRole.isEmpty
            ? null
            : UserRole.fromString(draftRole));

    if (activeRole == null) {
      return ChooseRoleView(
        onRoleSelected: _onRoleSelected,
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(Routes.login);
          }
        },
      );
    }

    final verifiedEmailFromAuth = authState.pendingSignup?.email.trim() ??
        authState.user?.email.trim();
    final effectiveVerifiedEmail =
        (verifiedEmailFromAuth != null && verifiedEmailFromAuth.isNotEmpty)
            ? verifiedEmailFromAuth
            : null;

    final isSocialUser = authState.user?.isSocialLogin ?? false;
    final resolvedStep = widget.initialStep ?? (isSocialUser ? 2 : 1);

    switch (activeRole) {
      case UserRole.client:
        return ClientSignupFlow(
          onBackToRoleSelection: _onBackToRoleSelection,
          initialStep: resolvedStep,
          verifiedEmail: effectiveVerifiedEmail,
        );
      case UserRole.investor:
        return InvestorSignupFlow(
          onBackToRoleSelection: _onBackToRoleSelection,
          initialStep: resolvedStep,
          verifiedEmail: effectiveVerifiedEmail,
        );
      case UserRole.founder:
        return FounderSignupFlow(
          onBackToRoleSelection: _onBackToRoleSelection,
          initialStep: resolvedStep,
          verifiedEmail: effectiveVerifiedEmail,
        );
      case UserRole.freelancer:
        return FreelancerSignupFlow(
          onBackToRoleSelection: _onBackToRoleSelection,
          initialStep: resolvedStep,
          verifiedEmail: effectiveVerifiedEmail,
        );
    }
  }
}
