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
            await context.read<DashboardCubit>().refresh();
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
                    _buildRecommendationTabs(context),
                    _buildActionButtons(context),
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
              DashboardActionButton(
                text: 'Explore Investors',
                subtitle: 'Angel networks & syndicate leads',
                tag: 'Syndicate',
                icon: Icons.monetization_on_rounded,
                color: const Color(0xFFEC4899),
                onTap: () => context.push(Routes.investorInvestors),
                width: width,
              ),
              DashboardActionButton(
                text: 'Wallet & Capital',
                subtitle: 'Escrow deposits & transaction logs',
                tag: 'Capital',
                icon: Icons.account_balance_rounded,
                color: const Color(0xFF06B6D4),
                onTap: () => context.push(Routes.wallet),
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
    setState(() => _recommendationsLoading = false);
  }

  Widget _buildRecommendationTabs(BuildContext context) {
    return AppSegmentedTabs(
      tabs: {
        'Startups': _buildRecommendationList('startups', Icons.rocket_launch_outlined, const Color(0xFF2563EB)),
        'Founders': _buildRecommendationList('founders', Icons.person_outline, const Color(0xFF0F766E)),
        'Freelancers': _buildRecommendationList('freelancers', Icons.engineering_outlined, const Color(0xFF7C3AED)),
      },
    );
  }

  Widget _buildRecommendationList(String key, IconData icon, Color accent) {
    final items = _recommendedItems[key] ?? const [];
    if (_recommendationsLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (items.isEmpty) return _buildRecommendationEmpty('No recommendations yet.');
    return Container(
      width: double.infinity,
      child: Column(
        children: [
          for (final item in items.take(5)) ...[
            _buildRecommendationItemTile(item, icon, accent),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationItemTile(Map<String, dynamic> item, IconData icon, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title']?.toString() ?? 'Recommendation', style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(item['subtitle']?.toString() ?? '', style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w700)),
                if ((item['description']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(item['description']!.toString(), style: TextStyle(color: AppColors.projectSecondaryText, fontSize: 13)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationEmpty(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: Text(text, style: TextStyle(color: AppColors.projectSecondaryText)),
  );

  Widget _buildTag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioPopupContent(
    BuildContext context,
    DashboardState state,
  ) {
    final deployed = state.investorDeployedRaw;
    final investments = state.investorTotalInvestments;
    final capital = state.investorWalletBalance;
    final closed = state.investorDealsClosed;

    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.pie_chart,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Portfolio Overview',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: AppColors.white.withValues(alpha: 0.1), height: 1),
          const SizedBox(height: 12),
          _buildPopupStatRow(
            Icons.trending_up,
            'Total Deployed',
            '\$$deployed',
            AppColors.primary,
          ),
          const SizedBox(height: 10),
          _buildPopupStatRow(
            Icons.business_center,
            'Investments',
            investments,
            AppColors.info,
          ),
          const SizedBox(height: 10),
          _buildPopupStatRow(
            Icons.account_balance_wallet,
            'Wallet Balance',
            '\u20b9$capital',
            AppColors.success,
          ),
          const SizedBox(height: 10),
          _buildPopupStatRow(
            Icons.check_circle_outline,
            'Deals Closed',
            '$closed closed',
            AppColors.warning,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () => context.push(Routes.investorPortfolio),
              child: const Text(
                'View Full Portfolio \u2192',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupStatRow(
    IconData icon,
    String label,
    String value,
    Color accentColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 13, color: accentColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.white, fontSize: 12),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderButton(
    String text,
    IconData icon,
    Color bgColor,
    VoidCallback onTap, {
    bool isDark = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: isDark
              ? Border.all(color: AppColors.white.withValues(alpha: 0.24))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isDark ? AppColors.white : AppColors.white,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCards(BuildContext context, DashboardState state) {
    final portfolioValue = Formatters.compactCurrency(
      state.investorDeployedRaw,
    );
    final balance = state.investorWalletBalance;

    final totalInvestments = state.investorTotalInvestments;
    final pendingDeals = state.investorPendingDeals;
    final dealsClosed = state.investorDealsClosed;

    final startupsFollowing = state.investorStartupsFollowing;
    const offersSent = '0';
    const dueDiligence = '0';
    final roip = '$dealsClosed closed';
    final meetingsCount = state.upcomingMeetingsCount.toString();
    final unreadMsgs = state.unreadMessagesCount.toString();
    final notifs = state.unreadNotificationsCount.toString();

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = context.isMobile
            ? 2
            : (context.isTablet ? 3 : 4);
        const double spacing = 16.0;
        final double width =
            (constraints.maxWidth - (crossAxisCount - 1) * spacing) /
            crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: width,
              child: DashboardMetricCard(
                title: 'PORTFOLIO VALUE',
                value: portfolioValue,
                lineColor: Colors.red,
                onTap: () => context.push(Routes.investorPortfolio),
              ),
            ),
            SizedBox(
              width: width,
              child: DashboardMetricCard(
                title: 'TOTAL INVESTMENTS',
                value: totalInvestments,
                lineColor: AppColors.success,
                onTap: () => context.push(Routes.investorPortfolio),
              ),
            ),
            SizedBox(
              width: width,
              child: DashboardMetricCard(
                title: 'AVAILABLE CAPITAL',
                value: balance,
                lineColor: AppColors.projectPurpleText,
                onTap: () => context.push(Routes.wallet),
              ),
            ),
            SizedBox(
              width: width,
              child: DashboardMetricCard(
                title: 'STARTUPS FOLLOWING',
                value: startupsFollowing,
                lineColor: AppColors.warning,
                onTap: () => context.push(Routes.investorStartups),
              ),
            ),
            SizedBox(
              width: width,
              child: DashboardMetricCard(
                title: 'PENDING INTERESTS',
                value: pendingDeals,
                lineColor: AppColors.danger,
                onTap: () => context.push(Routes.investorDeals),
              ),
            ),
            SizedBox(
              width: width,
              child: DashboardMetricCard(
                title: 'MEETINGS THIS WEEK',
                value: meetingsCount,
                lineColor: AppColors.info,
                onTap: () => context.push(Routes.meetings),
              ),
            ),
            SizedBox(
              width: width,
              child: DashboardMetricCard(
                title: 'DUE DILIGENCE',
                value: dueDiligence,
                lineColor: AppColors.warning,
                onTap: () => context.push(Routes.investorDeals),
              ),
            ),
            SizedBox(
              width: width,
              child: DashboardMetricCard(
                title: 'OFFERS SENT',
                value: offersSent,
                lineColor: AppColors.success,
                onTap: () => context.push(Routes.investorOffers),
              ),
            ),
            SizedBox(
              width: width,
              child: DashboardMetricCard(
                title: 'ROI %',
                value: roip,
                lineColor: AppColors.success,
                onTap: () => context.push(Routes.investorPortfolio),
              ),
            ),
            SizedBox(
              width: width,
              child: DashboardMetricCard(
                title: 'UNREAD MESSAGES',
                value: unreadMsgs,
                lineColor: Colors.red,
                onTap: () => context.push(Routes.messages),
              ),
            ),
            SizedBox(
              width: width,
              child: DashboardMetricCard(
                title: 'NOTIFICATIONS',
                value: notifs,
                lineColor: AppColors.warning,
              ),
            ),
            SizedBox(
              width: width,
              child: DashboardMetricCard(
                title: 'WALLET BALANCE',
                value: balance,
                lineColor: AppColors.info,
                onTap: () => context.push(Routes.wallet),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUpcomingMeetings(BuildContext context, DashboardState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Upcoming Meetings',
          actionLabel: 'View all',
          onAction: () => context.push(Routes.meetings),
        ),
        AppSizes.vGapMd,
        if (state.meetings.isEmpty)
          const Center(
            child: Text(
              'No upcoming meetings.',
              style: TextStyle(color: AppColors.subtleText),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.meetings.length > 3 ? 3 : state.meetings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final meeting = state.meetings[index];
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.background,
                    backgroundImage: meeting.withAvatar != null
                        ? NetworkImage(meeting.withAvatar!)
                        : null,
                    child: meeting.withAvatar == null
                        ? const Icon(Icons.person, color: AppColors.subtleText)
                        : null,
                  ),
                  title: Text(
                    meeting.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: AppColors.subtleText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          Formatters.dateTime(meeting.startTime),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.subtleText,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          meeting.isVideo ? Icons.videocam : Icons.phone,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: AppColors.subtleText,
                  ),
                  onTap: () {
                    context.push(Routes.meetings);
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildRecentMessages(BuildContext context, DashboardState state) {
    final msgs = state.investorRecentMessages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: 'Recent Messages',
          actionLabel: 'View all',
          onAction: () => context.push(Routes.messages),
        ),
        AppSizes.vGapMd,
        if (msgs.isEmpty)
          const Text(
            'No recent messages.',
            style: TextStyle(color: AppColors.subtleText),
          )
        else
          ...msgs.take(3).map((m) {
            final msg = m;
            return InkWell(
              onTap: () => context.push(Routes.messages),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    ClipOval(
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: msg['avatar'] != null
                            ? CustomCachedImage(
                                imageUrl: msg['avatar'],
                                fit: BoxFit.cover,
                              )
                            : const ColoredBox(
                                color: AppColors.background,
                                child: Icon(Icons.person, size: 16),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            msg['name'] ?? 'Support',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            msg['msg'] ?? '',
                            style: const TextStyle(
                              color: AppColors.subtleText,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      msg['time'] ?? 'Today',
                      style: const TextStyle(
                        color: AppColors.subtleText,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCompactStartupTile(BuildContext context, Startup s) {
    return InkWell(
      onTap: () => context.push('${Routes.startupDetails}/${s.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.warning,
              radius: 20,
              child: Text(
                s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${s.industry} - ${s.stage}',
                    style: const TextStyle(
                      color: AppColors.subtleText,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  s.fundingRaised > 0
                      ? Formatters.compactCurrency(s.fundingRaised)
                      : '--',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const Text(
                  'Raising',
                  style: TextStyle(color: AppColors.subtleText, fontSize: 10),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.startupIconGreenSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 8, color: AppColors.success),
                  const SizedBox(width: 4),
                  Text(
                    s.stage,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppColors.subtleText,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _DealMixChart extends StatelessWidget {
  const _DealMixChart();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Deal Mix', style: TextStyle(fontWeight: FontWeight.bold)),
          const Text(
            'By status / sector',
            style: TextStyle(color: AppColors.subtleText, fontSize: 12),
          ),
          const SizedBox(height: 24),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 20,
                    color: AppColors.border,
                  ),
                ),
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: 0.6,
                    strokeWidth: 20,
                    color: AppColors.warning,
                  ),
                ),
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: 0.3,
                    strokeWidth: 20,
                    color: AppColors.success,
                  ),
                ),
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: 0.1,
                    strokeWidth: 20,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(color: Colors.red, text: 'Approved'),
              SizedBox(width: 8),
              _Legend(color: AppColors.warning, text: 'Due Diligence'),
              SizedBox(width: 8),
              _Legend(color: AppColors.success, text: 'Rejected'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(radius: 4, backgroundColor: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 10, color: AppColors.subtleText),
        ),
      ],
    );
  }
}

List<BarData> _pipelineData(List<double> raw) {
  if (raw.isEmpty) {
    return const [
      BarData('Aug', 0),
      BarData('Sep', 0),
      BarData('Oct', 0),
      BarData('Nov', 0),
    ];
  }
  final labels = [
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
  ];
  return [
    for (var i = 0; i < raw.length && i < labels.length; i++)
      BarData(labels[i], raw[i]),
  ];
}
