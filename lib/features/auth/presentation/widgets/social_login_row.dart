import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/enums.dart';
import '../bloc/auth_bloc.dart';

class SocialLoginRow extends StatelessWidget {
  const SocialLoginRow({super.key});

  void _startSocial(BuildContext context, String provider) {
    // Directly trigger social login without showing the role picker dialog
    context.read<AuthBloc>().add(
      AuthSocialLoginRequested(
        provider: provider,
        role: UserRole.freelancer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showApple = Platform.isIOS || Platform.isMacOS;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.theme.dividerColor.withValues(alpha: 0.0),
                      context.theme.dividerColor,
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCard
                    : AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                'or continue with',
                style: context.text.labelMedium?.copyWith(
                  color: isDark ? AppColors.subtleText : AppColors.mutedText,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.theme.dividerColor,
                      context.theme.dividerColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        AppSizes.vGapLg,
        Row(
          children: [
            Expanded(
              child: _SocialButton(
                icon: Icons.g_mobiledata_rounded,
                customIcon: _GoogleLogo(),
                label: 'Login with Google',
                onTap: () => _startSocial(context, 'google'),
              ),
            ),
            if (showApple) ...[
              AppSizes.hGapMd,
              Expanded(
                child: _SocialButton(
                  icon: Icons.apple,
                  label: 'Login with Apple',
                  onTap: () => _startSocial(context, 'apple'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.customIcon,
  });

  final IconData icon;
  final Widget? customIcon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorder
                  : const Color(0xFFE5E7EB),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              customIcon ??
                  Icon(
                    icon,
                    size: 22,
                    color: isDark ? AppColors.white : AppColors.darkText,
                  ),
              const SizedBox(width: 10),
              Text(
                label,
                style: context.text.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? AppColors.white : AppColors.darkText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFF2F4F8),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: Color(0xFF4285F4),
            fontWeight: FontWeight.w900,
            fontSize: 15,
            fontFamily: 'Roboto',
          ),
        ),
      ),
    );
  }
}

