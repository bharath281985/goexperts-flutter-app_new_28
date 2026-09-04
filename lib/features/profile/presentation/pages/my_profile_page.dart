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
import '../../../../core/widgets/app_list_tile.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/dashboard/dashboard_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/repositories/review_repository.dart';

class MyProfilePage extends StatefulWidget {
  const MyProfilePage({super.key});

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  double _rating = 0.0;
  int _reviewsCount = 0;
  bool _loadingAverage = true;

  // Dynamic Profile Completeness & Document Verification
  int _profileCompletion = 0;
  bool _isVerified = false;
  String _verificationStatus = 'unverified'; // 'verified', 'under_review', 'action_required', 'unverified'
  int _verifiedDocsCount = 0;
  int _missingDocsCount = 0;

  @override
  void initState() {
    super.initState();
    _refreshAllData();
  }

  void _refreshAllData() {
    context.read<AuthBloc>().add(const AuthRefreshUser());
    _syncRoleProfile();
    _fetchVerificationStatus();
    _fetchAverage();
  }

  Future<void> _navigateAndRefresh(Future<void> Function() navAction) async {
    await navAction();
    if (mounted) {
      _refreshAllData();
    }
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

      // Dynamic Profile Completion calculation
      final rawComp = data['profileCompletion'] ??
          data['profile_completion'] ??
          data['completionPercentage'] ??
          (data['user'] is Map ? (data['user'] as Map)['profileCompletion'] : null);

      int computedPercent = (user.profileCompletion ?? 0);
      if (rawComp != null) {
        computedPercent = (rawComp as num).toInt();
      } else {
        int filled = 0;
        const int totalFields = 7;
        if ((nameStr ?? user.fullName ?? '').isNotEmpty) filled++;
        if ((avatarStr ?? user.avatarUrl ?? '').isNotEmpty) filled++;
        if ((user.email).isNotEmpty) filled++;
        if ((user.headline ?? '').isNotEmpty) filled++;
        if (data['bio'] != null || data['description'] != null || data['about'] != null) filled++;
        if (data['skills'] != null || data['category'] != null || data['industry'] != null) filled++;
        if (data['hourlyRate'] != null || data['location'] != null || data['experience'] != null) filled++;
        computedPercent = ((filled / totalFields) * 100).round().clamp(0, 100);
      }

      setState(() {
        _profileCompletion = computedPercent;
      });

      if (nameStr != null || avatarStr != null) {
        final currentUser = context.read<AuthBloc>().state.user;
        if (currentUser != null) {
          context.read<AuthBloc>().add(
            AuthUserUpdated(
              currentUser.copyWith(
                fullName: nameStr ?? currentUser.fullName,
                avatarUrl: avatarStr ?? currentUser.avatarUrl,
                profileCompletion: computedPercent,
              ),
            ),
          );
        }
      }
    });
  }

  Future<void> _fetchVerificationStatus() async {
    final user = context.read<AuthBloc>().state.user;
    if (user == null || user.role == null) return;

    final api = sl<ApiClientHelper>();
    final endpoint = switch (user.role!) {
      UserRole.freelancer => ApiEndpoints.freelancerVerification,
      UserRole.client => ApiEndpoints.clientVerification,
      UserRole.investor => ApiEndpoints.investorVerification,
      UserRole.founder => ApiEndpoints.founderVerification,
    };

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
      final payload = (data['data'] is Map)
          ? Map<String, dynamic>.from(data['data'] as Map)
          : data;

      final rawKycStatus = (payload['kycStatus'] ??
              payload['kyc_status'] ??
              payload['status'] ??
              payload['verificationStatus'] ??
              '')
          .toString()
          .trim()
          .toUpperCase();

      final missingCount = (payload['missingCount'] ??
              payload['missing_count'] as num?)
          ?.toInt() ??
          0;
      final pendingCount = (payload['pendingCount'] ??
              payload['pending_count'] as num?)
          ?.toInt() ??
          0;
      final verifiedCount = (payload['verifiedCount'] ??
              payload['verified_count'] as num?)
          ?.toInt() ??
          0;

      final isAccVerified = (rawKycStatus == 'APPROVED' ||
              rawKycStatus == 'VERIFIED' ||
              payload['accountVerified'] == true) &&
          missingCount == 0;

      String statusKey = 'unverified';
      if (isAccVerified || (missingCount == 0 && pendingCount == 0 && verifiedCount > 0)) {
        statusKey = 'verified';
      } else if (rawKycStatus == 'PENDING' ||
          rawKycStatus == 'UNDER_REVIEW' ||
          rawKycStatus == 'IN_REVIEW' ||
          pendingCount > 0) {
        statusKey = 'pending';
      } else if (rawKycStatus == 'REJECTED' ||
          rawKycStatus == 'ACTION_REQUIRED') {
        statusKey = 'action_required';
      } else if (missingCount > 0 ||
          rawKycStatus == 'NOT_SUBMITTED' ||
          rawKycStatus == 'MISSING') {
        statusKey = 'missing';
      } else {
        statusKey = 'unverified';
      }

      setState(() {
        _isVerified = isAccVerified;
        _verificationStatus = statusKey;
        _verifiedDocsCount = verifiedCount;
        _missingDocsCount = missingCount;
      });
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

    DashboardState? dashState;
    try {
      dashState = context.watch<DashboardCubit>().state;
    } catch (_) {
      dashState = null;
    }

    final activeCompletion = _profileCompletion > 0
        ? _profileCompletion
        : (user?.profileCompletion ?? dashState?.dashboardProfileCompletion ?? 0);

    // Role-specific metrics
    String metric1Val = '0';
    String metric1Label = 'Projects';
    IconData metric1Icon = Icons.folder_outlined;
    String metric2Val = '₹0';
    String metric2Label = 'Earned';
    IconData metric2Icon = Icons.account_balance_wallet_outlined;

    if (role == UserRole.investor) {
      metric1Label = 'Investments';
      metric1Val = dashState?.activeProjectsCount.toString() ?? '0';
      metric1Icon = Icons.trending_up_rounded;
      metric2Label = 'Portfolio';
      metric2Val = dashState != null
          ? '₹${dashState.monthlyEarnings.toStringAsFixed(0)}'
          : '₹0';
      metric2Icon = Icons.account_balance_rounded;
    } else if (role == UserRole.founder) {
      metric1Label = 'Meetings';
      metric1Val = dashState?.topSkills.isNotEmpty == true
          ? dashState!.topSkills.first
          : '0';
      metric1Icon = Icons.event_available_rounded;
      metric2Label = 'Raised';
      metric2Val = dashState != null
          ? '₹${dashState.monthlyEarnings.toStringAsFixed(0)}'
          : '₹0';
      metric2Icon = Icons.monetization_on_outlined;
    } else if (role == UserRole.client) {
      metric1Label = 'Projects';
      metric1Val = dashState?.activeProjectsCount.toString() ?? '0';
      metric1Icon = Icons.assignment_outlined;
      metric2Label = 'Total Spend';
      metric2Val = dashState != null
          ? '₹${dashState.monthlyEarnings.toStringAsFixed(0)}'
          : '₹0';
      metric2Icon = Icons.payments_outlined;
    } else if (role == UserRole.freelancer) {
      metric1Label = 'Projects';
      metric1Val = dashState?.activeProjectsCount.toString() ?? '0';
      metric1Icon = Icons.work_outline_rounded;
      metric2Label = 'Total Earned';
      metric2Val = dashState != null
          ? '₹${dashState.monthlyEarnings.toStringAsFixed(0)}'
          : '₹0';
      metric2Icon = Icons.savings_outlined;
    }

    final topInset = MediaQuery.viewPaddingOf(context).top;

    return Scaffold(
      backgroundColor: context.isDark ? AppColors.darkBackground : AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: Colors.white,
        onRefresh: () async {
          context.read<AuthBloc>().add(const AuthRefreshUser());
          DashboardCubit? dashboardCubit;
          try {
            dashboardCubit = context.read<DashboardCubit>();
          } catch (_) {}
          await Future.wait([
            _syncRoleProfile(),
            _fetchVerificationStatus(),
            _fetchAverage(),
          ]);
          if (!mounted) return;
          dashboardCubit?.refresh();
        },
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // ─── PROFESSIONAL HEADER & IDENTITY ───────────────────────────────
            Container(
              color: context.isDark ? AppColors.darkCard : Colors.white,
              padding: EdgeInsets.fromLTRB(
                AppSizes.screenPadding,
                topInset + 16,
                AppSizes.screenPadding,
                20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Title Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('My Profile'),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: context.isDark ? Colors.white : AppColors.darkText,
                          letterSpacing: -0.4,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _navigateAndRefresh(
                          () => context.push(Routes.changePassword),
                        ),
                        icon: Icon(
                          Icons.settings_outlined,
                          color: context.isDark ? Colors.white70 : AppColors.mutedText,
                          size: 22,
                        ),
                        tooltip: 'Account Settings',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // User Info Row
                  Row(
                    children: [
                      Stack(
                        children: [
                          AppAvatar(
                            name: user?.fullName ?? 'User',
                            imageUrl: user?.avatarUrl,
                            size: 68,
                          ),
                          if (user?.isVerified ?? _isVerified)
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.verified_rounded,
                                  color: AppColors.success,
                                  size: 18,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'User Profile',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: context.isDark ? Colors.white : AppColors.darkText,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            if ((user?.email ?? '').isNotEmpty)
                              Text(
                                user!.email,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.mutedText,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: context.isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: context.isDark
                                      ? AppColors.darkBorder
                                      : AppColors.border,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                role.label.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: context.isDark
                                      ? Colors.white70
                                      : AppColors.darkText,
                                  letterSpacing: 0.5,
                                ),
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
            const Divider(height: 1, thickness: 1, color: AppColors.border),

            Padding(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── CLEAN METRICS STRIP ─────────────────────────────────────
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: _cleanMetric(
                            icon: Icons.star_rounded,
                            iconColor: const Color(0xFFF59E0B),
                            value: _loadingAverage ? '…' : _rating.toStringAsFixed(1),
                            label: 'Rating',
                            caption: _loadingAverage ? '—' : '$_reviewsCount reviews',
                          ),
                        ),
                        _cleanDivider(),
                        Expanded(
                          child: _cleanMetric(
                            icon: metric1Icon,
                            iconColor: AppColors.primary,
                            value: metric1Val,
                            label: metric1Label,
                            caption: 'Active',
                          ),
                        ),
                        _cleanDivider(),
                        Expanded(
                          child: _cleanMetric(
                            icon: metric2Icon,
                            iconColor: AppColors.success,
                            value: metric2Val,
                            label: metric2Label,
                            caption: 'Total',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ─── PROFILE COMPLETION STATUS CARD ──────────────────────────
                  if (activeCompletion < 100) ...[
                    InkWell(
                      onTap: () => _navigateAndRefresh(() async {
                        switch (role) {
                          case UserRole.investor:
                            await context.push(Routes.investorProfile);
                            break;
                          case UserRole.founder:
                            await context.push(Routes.founderProfile);
                            break;
                          case UserRole.client:
                            await context.push(Routes.clientProfile);
                            break;
                          case UserRole.freelancer:
                            await context.push(Routes.freelancerEditProfile);
                            break;
                        }
                      }),
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                          border: Border.all(
                            color: context.isDark ? AppColors.darkBorder : AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.tune_rounded,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      context.tr('Profile Completion'),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: context.isDark ? Colors.white : AppColors.darkText,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '$activeCompletion%',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (activeCompletion / 100.0).clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: context.isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : AppColors.background,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Complete your bio, skills and documents to maximize project match rates.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedText,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ─── SECTION 1: WORK & PROFILE ───────────────────────────────
                  _sectionTitle(context, 'WORK & PROFILE'),
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        // Edit Profile with live percentage
                        _profileTile(
                          context,
                          icon: Icons.person_outline_rounded,
                          title: 'Edit Profile',
                          subtitle: 'Personal info, bio, skills and rates',
                          trailing: _buildPercentageBadge(activeCompletion),
                          onTap: () {
                            _navigateAndRefresh(() async {
                              switch (role) {
                                case UserRole.investor:
                                  await context.push(Routes.investorProfile);
                                  break;
                                case UserRole.founder:
                                  await context.push(Routes.founderProfile);
                                  break;
                                case UserRole.client:
                                  await context.push(Routes.clientProfile);
                                  break;
                                case UserRole.freelancer:
                                  await context.push(Routes.freelancerEditProfile);
                                  break;
                              }
                            });
                          },
                        ),
                        _tileDivider(context),

                        // Verification & Documents
                        _profileTile(
                          context,
                          icon: Icons.verified_user_outlined,
                          title: 'Verification & Documents',
                          subtitle: _getVerificationSubtitle(),
                          trailing: _buildVerificationBadge(),
                          onTap: () => _navigateAndRefresh(
                            () => context.push(Routes.verification),
                          ),
                        ),

                        // Portfolio
                        if (role == UserRole.freelancer || role == UserRole.investor) ...[
                          _tileDivider(context),
                          _profileTile(
                            context,
                            icon: Icons.collections_bookmark_outlined,
                            title: 'My Portfolio',
                            subtitle: 'Showcase projects and case studies',
                            onTap: () {
                              _navigateAndRefresh(() async {
                                if (role == UserRole.investor) {
                                  await context.push(Routes.investorPortfolio);
                                } else {
                                  await context.push(Routes.freelancerPortfolioPage);
                                }
                              });
                            },
                          ),
                        ],
                        _tileDivider(context),

                        // Bookmarks
                        _profileTile(
                          context,
                          icon: Icons.bookmark_outline_rounded,
                          title: 'My Bookmarks',
                          subtitle: 'Saved items, bookmarks & shortlist',
                          onTap: () => _navigateAndRefresh(
                            () => context.push(Routes.bookmarks),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── SECTION 2: ACCOUNT & BILLING ───────────────────────────
                  _sectionTitle(context, 'ACCOUNT & BILLING'),
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        _profileTile(
                          context,
                          icon: Icons.workspace_premium_outlined,
                          title: 'My Subscription',
                          subtitle: 'Plan details, limits and invoices',
                          trailing: _buildSubscriptionBadge(user),
                          onTap: () => _navigateAndRefresh(
                            () => context.push(Routes.subscriptionsManage),
                          ),
                        ),
                        _tileDivider(context),
                        _profileTile(
                          context,
                          icon: Icons.card_giftcard_outlined,
                          title: 'My Referrals',
                          subtitle: 'Invite colleagues and earn rewards',
                          onTap: () => _navigateAndRefresh(
                            () => context.push(Routes.referrals),
                          ),
                        ),
                        _tileDivider(context),
                        _profileTile(
                          context,
                          icon: Icons.lock_outline_rounded,
                          title: 'Security Center',
                          subtitle: 'Password, PIN and account safety',
                          onTap: () => _navigateAndRefresh(
                            () => context.push(Routes.changePassword),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── SECTION 3: PREFERENCES & SUPPORT ───────────────────────
                  _sectionTitle(context, 'SUPPORT & SETTINGS'),
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: [
                        _profileTile(
                          context,
                          icon: Icons.help_outline_rounded,
                          title: 'Help & Support',
                          subtitle: 'Frequently asked questions and support desk',
                          onTap: () => _navigateAndRefresh(
                            () => context.push(Routes.support),
                          ),
                        ),
                        _tileDivider(context),
                        _profileTile(
                          context,
                          icon: Icons.delete_outline_rounded,
                          title: 'Delete Account',
                          subtitle: 'Permanently close your GoExperts account',
                          onTap: () => _navigateAndRefresh(
                            () => context.push(Routes.deleteAccount),
                          ),
                          isDestructive: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── LOGOUT BUTTON ───────────────────────────────────────────
                  AppCard(
                    onTap: () => _handleLogout(context),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.logout_rounded,
                          color: AppColors.danger,
                          size: 19,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.tr('Log Out'),
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CLEAN UI HELPERS ─────────────────────────────────────────────────────

  Widget _cleanMetric({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required String caption,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          caption,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.mutedText,
          ),
        ),
      ],
    );
  }

  Widget _cleanDivider() {
    return Container(
      width: 1,
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.border,
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        context.tr(title),
        style: const TextStyle(
          color: AppColors.mutedText,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _buildPercentageBadge(int percent) {
    final clamped = percent.clamp(0, 100);
    final isFull = clamped >= 100;
    final color = isFull ? AppColors.success : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$clamped%',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: AppColors.mutedText,
          ),
        ],
      ),
    );
  }

  String _getVerificationSubtitle() {
    switch (_verificationStatus) {
      case 'verified':
        return 'KYC & documents verified';
      case 'pending':
      case 'under_review':
        return _missingDocsCount > 0
            ? '$_missingDocsCount missing • Review in progress'
            : 'KYC documents under review';
      case 'action_required':
        return 'Updates required on submitted documents';
      case 'missing':
        return '$_missingDocsCount documents pending submission';
      case 'unverified':
      default:
        return _missingDocsCount > 0
            ? '$_missingDocsCount documents pending submission'
            : 'Submit government ID & verification proofs';
    }
  }

  Widget _buildVerificationBadge() {
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (_verificationStatus) {
      case 'verified':
        badgeColor = AppColors.success;
        badgeText = 'Verified';
        badgeIcon = Icons.verified_rounded;
        break;
      case 'pending':
      case 'under_review':
        badgeColor = AppColors.warning;
        badgeText = 'In Review';
        badgeIcon = Icons.schedule_rounded;
        break;
      case 'action_required':
        badgeColor = AppColors.danger;
        badgeText = 'Action Req.';
        badgeIcon = Icons.error_outline_rounded;
        break;
      case 'missing':
        badgeColor = AppColors.warning;
        badgeText = _missingDocsCount > 0 ? '$_missingDocsCount Missing' : 'Missing Docs';
        badgeIcon = Icons.pending_actions_rounded;
        break;
      case 'unverified':
      default:
        badgeColor = AppColors.mutedText;
        badgeText = 'Not Verified';
        badgeIcon = Icons.upload_file_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            context.tr(badgeText),
            style: TextStyle(
              color: badgeColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: AppColors.mutedText,
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionBadge(dynamic user) {
    final rawPlan = (user?.subscriptionPlan ?? '').toString().trim();
    final isSubscribed = user?.serverHasSubscription == true ||
        (user?.subscriptionStatus?.toString().toLowerCase() == 'active');

    if (!isSubscribed ||
        rawPlan.isEmpty ||
        rawPlan.toLowerCase() == 'null' ||
        rawPlan.toLowerCase() == 'none') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.danger.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 12,
              color: AppColors.danger,
            ),
            const SizedBox(width: 4),
            Text(
              context.tr('Not Verified'),
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppColors.mutedText,
            ),
          ],
        ),
      );
    }

    final clean = rawPlan.toLowerCase();
    Color badgeColor = const Color(0xFF8B5CF6);
    if (clean.contains('gold') ||
        clean.contains('vip') ||
        clean.contains('enterprise') ||
        clean.contains('diamond')) {
      badgeColor = const Color(0xFFD97706);
    } else if (clean.contains('pro') ||
        clean.contains('premium') ||
        clean.contains('plus') ||
        clean.contains('growth')) {
      badgeColor = const Color(0xFF8B5CF6);
    } else if (clean.contains('starter') || clean.contains('basic')) {
      badgeColor = const Color(0xFF3B82F6);
    } else if (clean.contains('free')) {
      badgeColor = const Color(0xFFEAB308);
    }

    final label =
        rawPlan.replaceAll(RegExp(r'\s+plan', caseSensitive: false), '').trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            label.isEmpty ? 'Pro' : label,
            style: TextStyle(
              color: badgeColor,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: AppColors.mutedText,
          ),
        ],
      ),
    );
  }

  Widget _profileTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return AppListTile(
      title: title,
      subtitle: subtitle,
      leadingIcon: icon,
      trailing: trailing,
      iconColor: isDestructive ? AppColors.danger : AppColors.primary,
      onTap: onTap,
    );
  }

  Widget _tileDivider(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 56,
      endIndent: 16,
      color: AppColors.border,
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Log out?',
      message: 'You will need to sign in again to access your account.',
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
                horizontal: 24,
                vertical: 20,
              ),
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
                        AppColors.primary,
                      ),
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
  }
}
