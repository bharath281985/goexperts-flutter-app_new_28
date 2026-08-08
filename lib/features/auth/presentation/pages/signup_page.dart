import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/auth_bloc.dart';
import 'freelancer_signup_flow.dart';
import 'client_signup_flow.dart';
import 'investor_signup_flow.dart';
import 'founder_signup_flow.dart';

/// Main Mobile Signup Page Delegator (Image 1 Mobile Reference)
class SignupPage extends StatelessWidget {
  final String? initialRole;

  const SignupPage({super.key, this.initialRole});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final role = (initialRole ?? state.selectedRole?.name ?? 'freelancer').toLowerCase();

        switch (role) {
          case 'client':
          case 'business':
            return const ClientSignupFlow();
          case 'investor':
            return const InvestorSignupFlow();
          case 'founder':
          case 'startup':
            return const FounderSignupFlow();
          case 'freelancer':
          default:
            return const FreelancerSignupFlow();
        }
      },
    );
  }
}
