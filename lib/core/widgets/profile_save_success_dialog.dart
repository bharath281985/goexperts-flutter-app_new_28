import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import 'app_primary_button.dart';

class ProfileSaveSuccessDialog extends StatefulWidget {
  const ProfileSaveSuccessDialog({super.key});

  static Future<void> show(BuildContext context) {
    if (!kIsWeb && Platform.isIOS) {
      return Future.value();
    }
    return showGeneralDialog<void>(

      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close success dialog',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, _, __) => const ProfileSaveSuccessDialog(),
    );
  }

  @override
  State<ProfileSaveSuccessDialog> createState() =>
      _ProfileSaveSuccessDialogState();
}

class _ProfileSaveSuccessDialogState extends State<ProfileSaveSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _verificationRoute(UserRole role) {
    switch (role) {
      case UserRole.freelancer:
        return Routes.freelancerVerification;
      case UserRole.client:
        return Routes.clientVerification;
      case UserRole.investor:
        return Routes.investorVerification;
      case UserRole.founder:
        return Routes.founderVerification;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.user;
    final role = user?.role ?? UserRole.freelancer;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: ScaleTransition(
            scale: _scale,
            child: FadeTransition(
              opacity: _ctrl,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(AppSizes.xl),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(AppSizes.lg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 48,
                      ),
                    ),
                    AppSizes.vGapXl,
                    Text(
                      'Awesome! 🎉',
                      textAlign: TextAlign.center,
                      style: context.text.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.onSurface,
                      ),
                    ),
                    AppSizes.vGapMd,
                    Text(
                      'Your profile is 100% complete. You are just one step away from enjoying your free plan. Complete your KYC to unlock all features!',
                      textAlign: TextAlign.center,
                      style: context.text.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    AppSizes.vGapXl,
                    AppPrimaryButton(
                      label: 'Complete KYC',
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push(_verificationRoute(role));
                      },
                    ),
                    AppSizes.vGapMd,
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Maybe Later'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
