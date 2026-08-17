import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:goexperts_app/app/constants/app_assets.dart';
import 'package:goexperts_app/core/widgets/icon_widget.dart';
import '../../app/constants/app_colors.dart';
import '../../app/constants/app_sizes.dart';
import '../../app/router/route_names.dart';
import '../../core/utils/enums.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../extensions/context_extensions.dart';
import 'app_confirm_dialog.dart';
import 'app_avatar.dart';
import 'app_gradient_header.dart';

/// Gradient greeting header shared by all role home screens.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.subtitle,
    this.onMenu,
    this.unread = 0,
  });

  final String subtitle;
  final VoidCallback? onMenu;
  final int unread;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select((AuthBloc b) => b.state.user);
    final firstName = (user?.fullName ?? 'there').split(' ').first;
    return AppGradientHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onMenu != null)
                IconTapWidget(
                  onTap: onMenu,
                  iconImage: AppAssets.menuIcon,
                  padding: 8,
                ),
              if (onMenu != null) AppSizes.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${context.tr(_greeting)},',
                      style: TextStyle(
                        color: AppColors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      firstName,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              _iconButton(
                context,
                Icons.search_rounded,
                () => context.push(Routes.search),
              ),
              AppSizes.hGapSm,
              Badge(
                isLabelVisible: unread > 0,
                label: Text('$unread'),
                child: _iconButton(
                  context,
                  Icons.notifications_none_rounded,
                  () => context.push(Routes.notifications),
                ),
              ),
              AppSizes.hGapSm,
              GestureDetector(
                onTap: () => _showAccountPanel(context),
                child: AppAvatar(
                  name: user?.fullName ?? 'User',
                  imageUrl: user?.avatarUrl,
                  size: 40,
                ),
              ),
            ],
          ),
          AppSizes.vGapMd,
          Text(
            context.tr(subtitle),
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _editProfileRoute(UserRole role) {
    switch (role) {
      case UserRole.freelancer:
        return Routes.freelancerEditProfile;
      case UserRole.client:
        return Routes.clientProfile;
      case UserRole.investor:
        return Routes.investorProfile;
      case UserRole.founder:
        return Routes.founderProfile;
    }
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

  Future<void> _showAccountPanel(BuildContext context) async {
    final user = context.read<AuthBloc>().state.user;
    final role = user?.role ?? UserRole.freelancer;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close account menu',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, __) => Align(
        alignment: Alignment.topRight,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 50, right: AppSizes.xs),
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              elevation: 12,
              borderRadius: BorderRadius.circular(AppSizes.md),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: 180,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    child: Row(
                      children: [
                        AppAvatar(
                          name: user?.fullName ?? 'User',
                          imageUrl: user?.avatarUrl,
                          size: 34,
                        ),
                        AppSizes.hGapSm,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'User',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(fontSize: 11),
                              ),
                              Text(
                                role.shortLabel,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(fontSize: 9),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 28,
                            height: 28,
                          ),
                          icon: const Icon(Icons.close_rounded, size: 18),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  _accountTile(
                    dialogContext,
                    icon: Icons.manage_accounts_outlined,
                    label: 'Edit Profile',
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      context.push(_editProfileRoute(role));
                    },
                  ),
                  _accountTile(
                    dialogContext,
                    icon: Icons.verified_user_outlined,
                    label: 'Verification / KYC',
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      context.push(_verificationRoute(role));
                    },
                  ),
                  const Divider(height: 1),
                  _accountTile(
                    dialogContext,
                    icon: Icons.logout_rounded,
                    label: 'Log Out',
                    color: Theme.of(context).colorScheme.error,
                    onTap: () async {
                      Navigator.of(dialogContext).pop();
                      final confirmed = await AppConfirmDialog.show(
                        context,
                        title: 'Log out?',
                        message:
                            'You will need to sign in again to access your account.',
                        confirmLabel: 'Log Out',
                        isDestructive: true,
                        icon: Icons.logout_rounded,
                      );
                      if (confirmed && context.mounted) {
                        context.read<AuthBloc>().add(const AuthLoggedOut());
                      }
                    },
                  ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      ),
    );
  }

  Widget _accountTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      dense: true,
      visualDensity: const VisualDensity(vertical: -4),
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
      minLeadingWidth: 22,
      horizontalTitleGap: AppSizes.sm,
      leading: Icon(icon, color: color, size: 18),
      title: Text(
        label,
        maxLines: 1,
        style: TextStyle(color: color, fontSize: 11),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: color, size: 18),
      onTap: onTap,
    );
  }

  Widget _iconButton(BuildContext context, IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: AppColors.white, size: 20),
        ),
      ),
    );
  }
}
