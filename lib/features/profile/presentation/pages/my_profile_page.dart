import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_gradient_header.dart';
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/dashboard/dashboard_cubit.dart';
// DashboardCubit is optional — MyProfilePage works with AuthBloc alone.
// We access it with a null-safe try to avoid crashes on standalone pages.
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/repositories/review_repository.dart';
import 'my_reviews_page.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  double _rating = 0.0;
  int _reviewsCount = 0;
  bool _loadingAverage = true;

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthRefreshUser());
    _syncRoleProfile();
    _fetchAverage();
  }

  Future<void> _syncRoleProfile() async {
    final user = context.read<AuthBloc>().state.user;
    if (user == null || user.role == null) return;

    final api = sl<ApiClientHelper>();
    String endpoint = '';

    switch (user.role!) {
      case UserRole.freelancer:
        endpoint = ApiEndpoints.freelancerProfile;
        break;
      case UserRole.client:
        endpoint = ApiEndpoints.clientProfile;
        break;
      case UserRole.investor:
        endpoint = ApiEndpoints.investorProfile;
        break;
      case UserRole.founder:
        endpoint = ApiEndpoints.founderProfile;
        break;
    }

    if (endpoint.isEmpty) return;

    final res = await api.getEnvelope<Map<String, dynamic>>(
      endpoint,
      parser: (raw) {
        if (raw.data is Map) {
          return Map<String, dynamic>.from(raw.data as Map);
        }
        return {};
      },
    );

    if (!mounted) return;

    res.fold((_) {}, (data) {
      final possibleNames = [
        data['fullName'],
        data['name'],
        data['companyCategory'],
        data['companyName'],
        if (data['user'] is Map) (data['user'] as Map)['fullName'],
      ];
      final nameStr = possibleNames
          .firstWhere(
            (e) => e != null && e.toString().trim().isNotEmpty,
            orElse: () => null,
          )
          ?.toString()
          .trim();

      final possibleAvatars = [
        data['avatarUrl'],
        data['logoUrl'],
        data['logo'],
        data['avatar_url'],
        if (data['user'] is Map) (data['user'] as Map)['avatarUrl'],
      ];
      final avatarStr = possibleAvatars
          .firstWhere(
            (e) => e != null && e.toString().trim().isNotEmpty,
            orElse: () => null,
          )
          ?.toString()
          .trim();

      if (nameStr != null || avatarStr != null) {
        final currentUser = context.read<AuthBloc>().state.user;
        if (currentUser != null) {
          context.read<AuthBloc>().add(
            AuthUserUpdated(
              currentUser.copyWith(
                fullName: nameStr ?? currentUser.fullName,
                avatarUrl: avatarStr ?? currentUser.avatarUrl,
              ),
            ),
          );
        }
      }
    });
  }

  Future<void> _fetchAverage() async {
    final repo = sl<ReviewRepository>();
    final result = await repo.getReviewsAverage();
    if (!mounted) return;
    result.fold(
      (f) {
        setState(() {
          _loadingAverage = false;
        });
      },
      (data) {
        final avgRating =
            data['averageRating'] ??
            data['average_rating'] ??
            data['average'] ??
            data['rating'] ??
            0.0;
        final totalReviews =
            data['totalReviews'] ??
            data['total_reviews'] ??
            data['total'] ??
            data['count'] ??
            0;
        setState(() {
          _rating = double.tryParse(avgRating.toString()) ?? 0.0;
          _reviewsCount = int.tryParse(totalReviews.toString()) ?? 0;
          _loadingAverage = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final user = state.user;
    final role = user?.role ?? UserRole.freelancer;

    // Try to read DashboardCubit — it may not be present when the page is
    // reached via a standalone route (e.g. from the drawer).
    DashboardState? dashState;
    try {
      dashState = context.watch<DashboardCubit>().state;
    } catch (_) {
      dashState = null;
    }

    // Map dynamic fields based on role
    String metric1Val = '1.2K';
    String metric1Label = 'Followers';
    String metric2Val = '94';
    String metric2Label = 'Projects';

    if (role == UserRole.investor) {
      metric1Label = 'Investments';
      metric1Val = dashState?.activeProjectsCount.toString() ?? '—';
      metric2Label = 'Portfolio';
      metric2Val = dashState != null
          ? '₹${dashState.monthlyEarnings.toStringAsFixed(0)}'
          : '—';
    } else if (role == UserRole.founder) {
      metric1Label = 'Meetings';
      metric1Val = dashState?.topSkills.isNotEmpty == true
          ? dashState!.topSkills.first
          : '0';
      metric2Label = 'Raised';
      metric2Val = dashState != null
          ? '₹${dashState.monthlyEarnings.toStringAsFixed(0)}'
          : '—';
    } else if (role == UserRole.client) {
      metric1Label = 'Projects';
      metric1Val = dashState?.activeProjectsCount.toString() ?? '—';
      metric2Label = 'Spend';
      metric2Val = dashState != null
          ? '₹${dashState.monthlyEarnings.toStringAsFixed(0)}'
          : '—';
    } else if (role == UserRole.freelancer) {
      metric1Label = 'Projects';
      metric1Val = dashState?.activeProjectsCount.toString() ?? '—';
      metric2Label = 'Earned';
      metric2Val = dashState != null
          ? '₹${dashState.monthlyEarnings.toStringAsFixed(0)}'
          : '—';
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<AuthBloc>().add(const AuthRefreshUser());
        DashboardCubit? dashboardCubit;
        try {
          dashboardCubit = context.read<DashboardCubit>();
        } catch (_) {}
        await Future.wait([_syncRoleProfile(), _fetchAverage()]);
        if (!mounted) return;
        dashboardCubit?.refresh();
      },
      child: ListView(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          AppGradientHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      context.tr('My Profile'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => context.push(Routes.settings),
                      icon: const Icon(
                        Icons.settings_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                AppSizes.vGapMd,
                Row(
                  children: [
                    AppAvatar(
                      name: user?.fullName ?? 'User',
                      imageUrl: user?.avatarUrl,
                      size: 64,
                    ),
                    AppSizes.hGapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user?.fullName ?? 'Guest',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (user?.isVerified ?? false) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                          Text(
                            user?.headline ?? role.label,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: _stat(
                          context,
                          _loadingAverage ? '…' : _rating.toStringAsFixed(1),
                          'Rating',
                        ),
                      ),
                      _divider(context),
                      Expanded(
                        child: _stat(
                          context,
                          _loadingAverage ? '…' : _reviewsCount.toString(),
                          'Reviews',
                        ),
                      ),
                      _divider(context),
                      Expanded(child: _stat(context, metric1Val, metric1Label)),
                      _divider(context),
                      Expanded(child: _stat(context, metric2Val, metric2Label)),
                    ],
                  ),
                ),
                AppSizes.vGapLg,
                _group(context, 'Profile', [
                  _tile(context, Icons.edit_outlined, 'Edit Profile', () {
                    switch (role) {
                      case UserRole.investor:
                        context.push(Routes.investorProfile);
                        break;
                      case UserRole.founder:
                        context.push(Routes.founderProfile);
                        break;
                      case UserRole.client:
                        context.push(Routes.clientProfile);
                        break;
                      case UserRole.freelancer:
                        // Navigate to the dedicated edit profile page
                        context.push(Routes.freelancerEditProfile);
                        break;
                    }
                  }),
               
                  if (role == UserRole.freelancer || role == UserRole.investor)
                    _tile(context, Icons.collections_outlined, 'Portfolio', () {
                      if (role == UserRole.investor) {
                        context.push(Routes.investorPortfolio);
                      } else {
                        context.push(Routes.freelancerPortfolioPage);
                      }
                    }),
                  _tile(
                    context,
                    Icons.star_outline_rounded,
                    'Reviews',
                    () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyReviewsPage()),
                    ),
                  ),
                  _tile(context, Icons.insights_outlined, 'Analytics', () {
                    switch (role) {
                      case UserRole.investor:
                        context.push(Routes.investorAnalytics);
                        break;
                      case UserRole.founder:
                        context.push(Routes.founderAnalytics);
                        break;
                      case UserRole.client:
                        context.push(Routes.clientAnalytics);
                        break;
                      case UserRole.freelancer:
                        context.push(Routes.freelancerAnalytics);
                        break;
                    }
                  }),
                ]),
                AppSizes.vGapLg,
                _group(context, 'Account', [
                  _tile(
                    context,
                    Icons.workspace_premium_outlined,
                    'Subscription',
                    () => context.push(Routes.subscriptionsManage),
                  ),
                  _tile(
                    context,
                    Icons.account_balance_wallet_outlined,
                    'Wallet',
                    () => context.push(Routes.wallet),
                  ),
                  _tile(
                    context,
                    Icons.shield_outlined,
                    'Security Center',
                    () => context.push(Routes.securityCenter),
                  ),
                  _tile(
                    context,
                    Icons.bookmark_outline_rounded,
                    'Bookmarks',
                    () => context.push(Routes.bookmarks),
                  ),
                  _tile(
                    context,
                    Icons.settings_outlined,
                    'Settings',
                    () => context.push(Routes.settings),
                  ),
                  _tile(
                    context,
                    Icons.help_outline_rounded,
                    'Support',
                    () => context.push(Routes.support),
                  ),
                  _tile(
                    context,
                    Icons.delete_outline_rounded,
                    'Delete Account',
                    () => context.push(Routes.deleteAccount),
                  ),
                ]),
                AppSizes.vGapLg,
                AppCard(
                  onTap: () async {
                    final confirm = await AppConfirmDialog.show(
                      context,
                      title: 'Log out?',
                      message: 'You will need to sign in again.',
                      confirmLabel: 'Log Out',
                      isDestructive: true,
                      icon: Icons.logout_rounded,
                    );
                    if (confirm && context.mounted) {
                      showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => PopScope(
                          canPop: false,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.primary),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    'Logging out...',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.darkText,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                      context.read<AuthBloc>().add(const AuthLoggedOut());
                    }
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.logout_rounded, color: AppColors.danger),
                      const SizedBox(width: AppSizes.md),
                      Text(
                        context.tr('Log Out'),
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) => Column(
    children: [
      Text(value, style: context.text.titleMedium),
      Text(context.tr(label), style: context.text.labelSmall),
    ],
  );

  Widget _divider(BuildContext context) =>
      Container(width: 1, height: 28, color: context.theme.dividerColor);

  Widget _group(BuildContext context, String title, List<Widget> children) =>
      AppCard(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.md,
                AppSizes.sm,
                AppSizes.md,
                AppSizes.xs,
              ),
              child: Text(
                context.tr(title).toUpperCase(),
                style: context.text.labelSmall?.copyWith(letterSpacing: 1),
              ),
            ),
            ...children,
          ],
        ),
      );

  Widget _tile(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) => AppListTile(title: label, leadingIcon: icon, onTap: onTap);
}
