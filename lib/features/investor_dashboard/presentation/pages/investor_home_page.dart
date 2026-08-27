import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/dashboard/dashboard_cubit.dart';
import '../../../../core/widgets/app_segmented_tabs.dart';
import '../../../../core/widgets/dashboard_header.dart';
import '../../../../core/widgets/dashboard_metric_card.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/formatters.dart';
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
                   
                    _buildActionButtons(context),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.screenPadding,
                        vertical: AppSizes.md,
                      ),
                      child: _buildGridCards(context, state),
                    ),
                    AppSegmentedTabs(
                      tabs: {
                        'Portfolio': AppChartCard(
                          title: 'Portfolio Growth',
                          subtitle: 'Cumulative deployment',
                          color: AppColors.warning,
                          data: _pipelineData(state.earningsChart),
                        ),
                        'Deal Mix': const _DealMixChart(),
                        'Monthly': AppChartCard(
                          title: 'Monthly Capital Deployment',
                          subtitle: 'USD invested per month',
                          color: AppColors.warning,
                          height: 200,
                          data: const [
                            BarData('Aug', 0),
                            BarData('Sep', 0),
                            BarData('Oct', 0),
                            BarData('Nov', 0),
                            BarData('Dec', 0),
                            BarData('Jan', 0),
                            BarData('Feb', 50000),
                            BarData('Mar', 0),
                            BarData('Apr', 0),
                            BarData('May', 50000),
                            BarData('Jun', 0),
                            BarData('Jul', 0),
                          ],
                        ),
                      },
                    ),
                    AppSizes.vGapLg,
                    AppSegmentedTabs(
                      tabs: {
                        'Startups': Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppSectionHeader(
                              title: 'Recommended Startups',
                              actionLabel: 'View all',
                              onAction: () =>
                                  context.push(Routes.investorStartups),
                            ),
                            AppSizes.vGapMd,
                            if (state.startups.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: AppSizes.xl,
                                  ),
                                  child: Text(
                                    'No records found',
                                    style: TextStyle(
                                      color: AppColors.subtleText,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              )
                            else
                              for (final s in state.startups.take(3))
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSizes.md,
                                  ),
                                  child: _buildCompactStartupTile(context, s),
                                ),
                          ],
                        ),
                        'New Meetings': _buildUpcomingMeetings(context, state),
                        'New Messages': _buildRecentMessages(context, state),
                      },
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildTopHeader(BuildContext context, DashboardState state) {
    final pending = state.investorPendingDeals;
    final meetingsCount = state.upcomingMeetingsCount.toString();
    final dealsClosed = state.investorDealsClosed;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenPadding,
        vertical: AppSizes.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Dark header banner (info only) ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF141414), Color(0xFF2e140d)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildTag(
                      Icons.verified,
                      'Verified Investor',
                      AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    _buildTag(
                      Icons.star_border,
                      'Premium Deal Flow',
                      AppColors.subtleText,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    text: 'You have ',
                    children: [
                      TextSpan(
                        text: pending,
                        style: const TextStyle(color: AppColors.warning),
                      ),
                      const TextSpan(text: ' pending interests and '),
                      TextSpan(
                        text: meetingsCount,
                        style: const TextStyle(color: AppColors.success),
                      ),
                      const TextSpan(text: ' meetings listed.'),
                    ],
                  ),
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Portfolio activity shows $dealsClosed closed. Review your due diligence items.',
                  style: const TextStyle(color: AppColors.white, fontSize: 11),
                ),
                const SizedBox(height: 14),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildHeaderButton(
                        'Discover Startups',
                        Icons.rocket_launch,
                        AppColors.primaryBlack,
                        () => context.push(Routes.investorStartups),
                      ),
                      const SizedBox(width: 10),
                      _buildHeaderButton(
                        'My Portfolio',
                        Icons.pie_chart_outline,
                        AppColors.primaryBlack,
                        () => context.push(Routes.investorPortfolio),
                        isDark: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // ── Portfolio Overview button (bottom-right) ──
                Row(
                  children: [
                    _buildHeaderButton(
                      'Opportunities',
                      Icons.bolt,
                      AppColors.primaryBlack,
                      () => context.push(Routes.investorDeals),
                      isDark: true,
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Builder(
                          builder: (ctx) => PopupMenuButton<String>(
                            color: AppColors.primaryBlack,
                            elevation: 16,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: AppColors.primary.withValues(alpha: 0.4),
                              ),
                            ),
                            position: PopupMenuPosition.over,
                            offset: const Offset(0, -210),
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                enabled: false,
                                padding: const EdgeInsets.all(16),
                                child: _buildPortfolioPopupContent(ctx, state),
                              ),
                            ],
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.projectBodyText,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.pie_chart,
                                    size: 14,
                                    color: AppColors.white,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Portfolio Overview',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.keyboard_arrow_up,
                                    size: 14,
                                    color: AppColors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildActionButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenPadding,
        vertical: AppSizes.sm,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildBigActionButton(
                'Browse Startups',
                Icons.rocket,
                AppColors.warning,
                () => context.push(Routes.investorStartups),
                isMobile,
                constraints.maxWidth,
              ),
              _buildBigActionButton(
                'View Watchlist',
                Icons.bookmark,
                AppColors.projectPurple,
                () => context.push(Routes.investorDeals),
                isMobile,
                constraints.maxWidth,
              ),
              _buildBigActionButton(
                'Schedule Meeting',
                Icons.calendar_month,
                AppColors.info,
                () => context.push(Routes.meetings),
                isMobile,
                constraints.maxWidth,
              ),
              _buildBigActionButton(
                'Express Interest',
                Icons.bolt,
                AppColors.success,
                () => context.push(Routes.investorOffers),
                isMobile,
                constraints.maxWidth,
              ),
              _buildBigActionButton(
                'Download Reports',
                Icons.insert_drive_file,
                AppColors.danger,
                () => context.push(Routes.investorReports),
                isMobile,
                constraints.maxWidth,
              ),
              _buildBigActionButton(
                'View Portfolio',
                Icons.pie_chart,
                AppColors.projectPurpleText,
                () => context.push(Routes.investorPortfolio),
                isMobile,
                constraints.maxWidth,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBigActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isMobile,
    double maxWidth,
  ) {
    double width = isMobile ? (maxWidth - 12) / 2 : (maxWidth - 5 * 12) / 6;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: width,
        height: 60,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.white, size: 18),
            const SizedBox(height: 4),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 11,
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
