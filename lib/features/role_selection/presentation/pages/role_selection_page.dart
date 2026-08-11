import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/widgets/choose_role_view.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key, this.fromSignup = false});

  final bool fromSignup;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          prev.errorMessage != curr.errorMessage && curr.errorMessage != null,
      listener: (context, state) {
        if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
          context.showSnack(state.errorMessage!);
        }
      },
      child: ChooseRoleView(
        onRoleSelected: (role) {
          context.read<AuthBloc>().add(AuthRoleSelected(role));
        },
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(Routes.signup);
          }
        },
      ),
    );
  }
}
