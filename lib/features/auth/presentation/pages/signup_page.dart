import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/utils/enums.dart';
import '../bloc/auth_bloc.dart';
import '../widgets/choose_role_view.dart';
import '../utils/signup_progress_store.dart';
import 'freelancer_signup_flow.dart';
import 'client_signup_flow.dart';
import 'investor_signup_flow.dart';
import 'founder_signup_flow.dart';

/// Main Mobile Signup Page Delegator (Asks role 1st then continues signup steps)
class SignupPage extends StatefulWidget {
  final String? initialRole;

  const SignupPage({super.key, this.initialRole});

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
    } else {
      _selectedRole = SignupProgressStore.read()?.role;
    }
  }

  void _onRoleSelected(UserRole role) {
    setState(() {
      _selectedRole = role;
    });
    context.go('${Routes.signup}?role=${role.name}');
  }

  void _onBackToRoleSelection() async {
    await SignupProgressStore.clear();
    if (!mounted) return;
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
    final progress = SignupProgressStore.read();
    final activeRole =
        _selectedRole ??
        (routeRole == null || routeRole.isEmpty
            ? null
            : UserRole.fromString(routeRole)) ??
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

    switch (activeRole) {
      case UserRole.client:
        return ClientSignupFlow(
          onBackToRoleSelection: _onBackToRoleSelection,
          initialStep: progress?.role == UserRole.client ? progress!.step : 1,
          verifiedEmail: progress?.role == UserRole.client
              ? progress!.verifiedEmail
              : null,
        );
      case UserRole.investor:
        return InvestorSignupFlow(
          onBackToRoleSelection: _onBackToRoleSelection,
          initialStep: progress?.role == UserRole.investor ? progress!.step : 1,
          verifiedEmail: progress?.role == UserRole.investor
              ? progress!.verifiedEmail
              : null,
        );
      case UserRole.founder:
        return FounderSignupFlow(
          onBackToRoleSelection: _onBackToRoleSelection,
          initialStep: progress?.role == UserRole.founder ? progress!.step : 1,
          verifiedEmail: progress?.role == UserRole.founder
              ? progress!.verifiedEmail
              : null,
        );
      case UserRole.freelancer:
        return FreelancerSignupFlow(
          onBackToRoleSelection: _onBackToRoleSelection,
          initialStep: progress?.role == UserRole.freelancer
              ? progress!.step
              : 1,
          verifiedEmail: progress?.role == UserRole.freelancer
              ? progress!.verifiedEmail
              : null,
        );
    }
  }
}
