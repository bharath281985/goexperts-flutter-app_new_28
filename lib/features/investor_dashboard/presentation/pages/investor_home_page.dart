import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/dashboard/dashboard_cubit.dart';
import '../../../../core/widgets/app_segmented_tabs.dart';
import '../../../../core/widgets/dashboard_header.dart';
import '../../../../core/widgets/dashboard_metric_card.dart';
import '../../../../core/widgets/dashboard_action_button.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/widgets/app_chart_card.dart';
import '../../../../core/widgets/app_loading_shimmer.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/custom_cached_image.dart';
import '../../../../core/widgets/free_plan_prompt_dialog.dart';
import '../../../../core/widgets/verification_prompt_card.dart';
import '../../../../core/widgets/dashboard_recommendations_section.dart';
import '../../../startup_ideas/domain/entities/startup.dart';

class InvestorHomePage extends StatefulWidget {
  const InvestorHomePage({super.key});

  @override
  State<InvestorHomePage> createState() => _InvestorHomePageState();
}

class _InvestorHomePageState extends State<InvestorHomePage> {
  bool _popupShown = false;
  bool _recommendationsLoading = true;
  Map<String, List<Map<String, dynamic>>> _recommendedItems = const {};

  void _maybeShowFreePlanPopup(BuildContext context, DashboardState state) {
    if (_popupShown) return;
    if (!state.shouldShowFreePlanPrompt) return;
    _popupShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FreePlanPromptDialog.show(
        context,
        profileCompletion: state.dashboardProfileCompletion,
        verificationMissingCount: state.verificationMissingCount,
        onComplete: ({required bool navigateToProfile}) {
          if (navigateToProfile) {
            context.push(Routes.investorProfile);
          } else {
            context.push(Routes.investorVerification);
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DashboardCubit, DashboardState>(
      listenWhen: (prev, curr) =>
          curr.status == ViewStatus.success && prev.status != ViewStatus.success,
      listener: (context, state) => _maybeShowFreePlanPopup(context, state),
      builder: (context, state) {
        final loading =
            state.status == ViewStatus.loading ||
            state.status == ViewStatus.initial;

        return RefreshIndicator(
          onRefresh: () async {
            _popupShown = false;
            context.read<AuthBloc>().add(const AuthRefreshUser());
            await Future.wait([
              context.read<DashboardCubit>().refresh(),
              _loadRecommendations(),
            ]);
          },
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: AppLoadingShimmer(itemCount: 5, height: 120),
                )
              : ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    Builder(
                      builder: (ctx) => DashboardHeader(
                        subtitle:
                            'Discover top startups, manage deals, and track your portfolio.',
                        unread: state.unreadNotificationsCount,
                        onMenu: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    ),
                    //  if (state.shouldShowVerificationPrompt) ...[
                    //   Padding(
                    //     padding: const EdgeInsets.symmetric(
                    //       horizontal: AppSizes.screenPadding,
                    //     ),
                    //     child: VerificationPromptCard(
                    //       missingCount: state.verificationMissingCount,
                    //       accountVerified: state.accountVerified,
                    //       route: Routes.investorVerification,
                    //     ),
                    //   ),
                    //   const SizedBox(height: 16),
                    // ],
                    _buildTopHeader(context, state),
                   
                    _buildActionButtons(context),
                     _buildRecommendationTabs(context),
                    const SizedBox(height: 100),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildTopHeader(BuildContext context, DashboardState state) {
    final kycStatus = state.kycStatus;
    final missingCount = state.verificationMissingCount;
    final isVerified =
        kycStatus == 'APPROVED' || (state.accountVerified && missingCount == 0);
    final isPending = kycStatus == 'PENDING';

    final Color badgeBgColor = isVerified
        ? AppColors.success.withValues(alpha: 0.12)
        : (isPending
            ? AppColors.warning.withValues(alpha: 0.14)
            : AppColors.primary.withValues(alpha: 0.12));
    final Color badgeBorderColor = isVerified
        ? AppColors.success.withValues(alpha: 0.3)
        : (isPending
            ? AppColors.warning.withValues(alpha: 0.35)
            : AppColors.primary.withValues(alpha: 0.3));
    final Color badgeTextColor = isVerified
        ? AppColors.success
        : (isPending ? AppColors.warning : AppColors.primary);
    final IconData badgeIcon = isVerified
        ? Icons.verified_rounded
        : (isPending ? Icons.schedule_rounded : Icons.pending_actions_rounded);
    final String badgeLabel = isVerified
        ? 'Verified Investor'
        : (isPending
            ? 'KYC In Review'
            : (missingCount > 0
                ? '$missingCount Docs Missing'
                : 'Verify Identity'));

    final walletBalance = state.effectiveWalletBalance;
    final referralsCount = state.referralsCount;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenPadding,
        vertical: AppSizes.xs,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: context.isDark ? AppColors.darkCard : Colors.white,
          border: Border.all(
            color: context.isDark ? AppColors.darkBorder : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: context.isDark ? 0.2 : 0.04,
              ),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row: Dynamic Verification Status Badge & Profile Completion
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () => context.push(Routes.investorVerification),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4.5,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: badgeBorderColor, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, size: 14, color: badgeTextColor),
                          const SizedBox(width: 5),
                          Text(
                            badgeLabel,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: badgeTextColor,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 14,
                            color: badgeTextColor.withValues(alpha: 0.8),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => context.push(Routes.profile),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.tune_rounded,
                            size: 14,
                            color: AppColors.mutedText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${state.dashboardProfileCompletion}% Profile',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Main Row: Wallet & Referrals Metric Cards
              Row(
                children: [
                  // Wallet Card
                  Expanded(
                    child: InkWell(
                      onTap: () => context.push(Routes.wallet),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(
                            alpha: context.isDark ? 0.1 : 0.05,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: AppColors.mutedText,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              Formatters.currency(walletBalance),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: context.isDark
                                    ? Colors.white
                                    : AppColors.darkText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Wallet Balance',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Referrals Card
                  Expanded(
                    child: InkWell(
                      onTap: () => context.push(Routes.referrals),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(
                            alpha: context.isDark ? 0.1 : 0.05,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.card_giftcard_rounded,
                                    size: 16,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 14,
                                  color: AppColors.mutedText,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '$referralsCount',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: context.isDark
                                    ? Colors.white
                                    : AppColors.darkText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Total Referrals',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenPadding,
        vertical: AppSizes.sm,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final int columns = context.isDesktop
              ? 3
              : (context.isTablet ? 3 : 2);
          const double spacing = 12.0;
          final double width =
              (constraints.maxWidth - (columns - 1) * spacing) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              DashboardActionButton(
                text: 'Discover Startups',
                subtitle: 'Curated deals, sectors & pitch info',
                tag: 'Deals',
                icon: Icons.rocket_launch_rounded,
                color: const Color(0xFF3B82F6),
                onTap: () => context.push(Routes.investorStartups),
                width: width,
              ),
              DashboardActionButton(
                text: 'My Portfolio',
                subtitle: 'Holdings, valuations & startup ROI',
                tag: 'Holdings',
                icon: Icons.pie_chart_rounded,
                color: const Color(0xFF10B981),
                onTap: () => context.push(Routes.investorPortfolio),
                width: width,
              ),
              DashboardActionButton(
                text: 'Active Deals',
                subtitle: 'Term sheets, diligence & syndicates',
                tag: 'Pipeline',
                icon: Icons.handshake_rounded,
                color: const Color(0xFF8B5CF6),
                onTap: () => context.push(Routes.investorDeals),
                width: width,
              ),
              DashboardActionButton(
                text: 'Pitch Meetings',
                subtitle: '1-on-1 calls with verified founders',
                tag: '1-on-1',
                icon: Icons.video_call_rounded,
                color: const Color(0xFFF59E0B),
                onTap: () => context.push(Routes.meetings),
                width: width,
              ),
            
             
            ],
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
      final api = sl<ApiClientHelper>();
      final res = await api.getEnvelope<Map<String, dynamic>>(
        ApiEndpoints.discoveryRecommendations,
        parser: (e) => Map<String, dynamic>.from((e.data as Map?) ?? const {}),
      );
      if (!mounted) return;
      final items = (res.valueOrNull ?? const {})['recommendedItems'];
      if (items is Map) {
        _recommendedItems = items.map(
          (key, value) => MapEntry(
            key.toString(),
            (value as List? ?? const [])
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList(),
          ),
        );
      }
    } catch (_) {}
    if (mounted) setState(() => _recommendationsLoading = false);
  }

  Widget _buildRecommendationTabs(BuildContext context) {
    return DashboardRecommendationsSection(
      title: 'Top Matches For You',
      subtitle: 'Verified startups, client projects and specialized talent',
      isLoading: _recommendationsLoading,
      items: _recommendedItems,
      onRefresh: _loadRecommendations,
      tabs: const [
        RecommendationTabConfig(
          key: 'startups',
          label: 'Startups',
          icon: Icons.rocket_launch_rounded,
          accent: Color(0xFF3B82F6),
          viewAllRoute: Routes.investorStartups,
        ),
        RecommendationTabConfig(
          key: 'projects',
          label: 'Projects',
          icon: Icons.task_alt_rounded,
          accent: Color(0xFF10B981),
          viewAllRoute: Routes.investorProjects,
        ),
        RecommendationTabConfig(
          key: 'freelancers',
          label: 'Freelancers',
          icon: Icons.code_rounded,
          accent: Color(0xFF8B5CF6),
          viewAllRoute: Routes.clientFreelancers,
        ),
      ],
    );
  }
}
