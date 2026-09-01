import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/dashboard/dashboard_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_chart_card.dart';
import '../../../../core/widgets/app_loading_shimmer.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_segmented_tabs.dart';
import '../../../../core/widgets/dashboard_header.dart';
import '../../../../core/widgets/dashboard_metric_card.dart';
import '../../../../core/widgets/dashboard_action_button.dart';
import '../../../../core/widgets/free_plan_prompt_dialog.dart';
import '../../../meetings/presentation/widgets/meeting_card.dart';
import '../../../projects/presentation/widgets/project_card.dart';

class FreelancerHomePage extends StatefulWidget {
  const FreelancerHomePage({super.key});

  @override
  State<FreelancerHomePage> createState() => _FreelancerHomePageState();
}

class _FreelancerHomePageState extends State<FreelancerHomePage> {
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
            context.push(Routes.freelancerEditProfile);
          } else {
            context.push(Routes.freelancerVerification);
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
                            "Here's what's happening with your freelance work today.",
                        onMenu: () => Scaffold.of(ctx).openDrawer(),
                        unread: state.unreadNotificationsCount,
                      ),
                    ),
                    //  if (state.shouldShowVerificationPrompt) ...[
                    //         VerificationPromptCard(
                    //             missingCount: state.verificationMissingCount,
                    //             accountVerified: state.accountVerified,
                    //             route: Routes.freelancerVerification,
                    //           ),
                    //           const SizedBox(height: 16),
                    //       ],
                    _buildHeroBanner(context, state),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.screenPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                         
                          _buildQuickActions(context),
                          const SizedBox(height: 24),
                          _buildMetricsGrid(context, state),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildChartsSection(context, state),
                    const SizedBox(height: 24),
                    _buildBottomTabsSection(context, state),
                    const SizedBox(height: 100),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildHeroBanner(BuildContext context, DashboardState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenPadding,
        vertical: AppSizes.sm,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF090D16)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.05)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildBannerTag(
                      Icons.circle,
                      'Available for work',
                      const Color(0xFF22C55E),
                    ),
                    const SizedBox(width: 8),
                    _buildBannerTag(Icons.verified, 'Verified', AppColors.info),
                    const SizedBox(width: 8),
                    _buildBannerTag(
                      Icons.workspace_premium,
                      'Job Success 95%',
                      AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  text: 'You have ',
                  children: [
                    TextSpan(
                      text:
                          '${state.projects.isNotEmpty ? state.projects.length + 119 : 122} new project matches ',
                      style: const TextStyle(color: Color(0xFFEF4444)),
                    ),
                    const TextSpan(text: 'and '),
                    TextSpan(
                      text:
                          '₹${Formatters.compact(state.wallet?.available ?? 0)} ',
                      style: const TextStyle(color: Color(0xFFFBBF24)),
                    ),
                    const TextSpan(text: 'ready to withdraw.'),
                  ],
                ),
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your pipeline is clear — browse open projects and send a fresh proposal today. Profile completion is at ${state.profileCompletionPercent}%.',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              _buildBannerActions(context, state),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerActions(BuildContext context, DashboardState state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildBannerButton(
                'Apply to matches',
                Icons.bolt,
                AppColors.primary,
                onTap: () => context.push(Routes.freelancerProjects),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBannerButton(
                'Withdraw earnings',
                Icons.account_balance_wallet_outlined,
                AppColors.primaryBlack,
                onTap: () => context.push(Routes.wallet),
                isDark: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildBannerButton(
                'AI Proposal Writer',
                Icons.auto_awesome_outlined,
                AppColors.primaryBlack,
                onTap: () => context.push(Routes.freelancerProjects),
                isDark: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Builder(
                builder: (ctx) => PopupMenuButton<String>(
                  color: const Color(0xFF1E293B),
                  elevation: 16,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: AppColors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  position: PopupMenuPosition.over,
                  offset: const Offset(0, -210),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      enabled: false,
                      padding: EdgeInsets.zero,
                      child: _buildProfileCompletionPopup(ctx, state),
                    ),
                  ],
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlack.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          size: 14,
                          color: AppColors.white,
                        ),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Profile Completion',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
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
          ],
        ),
      ],
    );
  }

  Widget _buildProfileCompletionPopup(
    BuildContext context,
    DashboardState state,
  ) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'PROFILE COMPLETION',
            style: TextStyle(
              color: AppColors.subtleText,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            textBaseline: TextBaseline.alphabetic,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            children: [
              Text(
                '${state.profileCompletionPercent > 0 ? state.profileCompletionPercent : 70}%',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'to All-Star',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProgressRow('Personal Info', 1.0),
          const SizedBox(height: 10),
          _buildProgressRow('Professional Info', 0.6),
          const SizedBox(height: 10),
          _buildProgressRow('Portfolio', 0.0),
          const SizedBox(height: 10),
          _buildProgressRow('Resume', 1.0),
        ],
      ),
    );
  }

  Widget _buildBannerTag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerButton(
    String text,
    IconData icon,
    Color bgColor, {
    required VoidCallback onTap,
    bool isDark = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: isDark
              ? Border.all(color: AppColors.white.withValues(alpha: 0.2))
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: AppColors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(String title, double value) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 4,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(
              value >= 1.0 ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick actions',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlack,
          ),
        ),
        const Text(
          'Jump into the tools you use most',
          style: TextStyle(fontSize: 11, color: AppColors.subtleText),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final int columns = context.isDesktop
                ? 6
                : (context.isTablet ? 4 : 3);
            const double spacing = 5.0;
            final double width =
                (constraints.maxWidth - (columns - 1) * spacing) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                DashboardActionButton(
                  text: 'Apply Project',
                  icon: Icons.assignment_turned_in_outlined,
                  color: AppColors.primary,
                  onTap: () => context.push(Routes.freelancerProjects),
                  width: width,
                ),
                DashboardActionButton(
                  text: 'Update Profile',
                  icon: Icons.person_outline,
                  color: AppColors.warning,
                  onTap: () => context.push(Routes.freelancerEditProfile),
                  width: width,
                ),
                DashboardActionButton(
                  text: 'Upload Portfolio',
                  icon: Icons.upload_file_outlined,
                  color: AppColors.projectPurple,
                  onTap: () => context.push(Routes.wallet),
                  width: width,
                ),
                DashboardActionButton(
                  text: 'Book Meeting',
                  icon: Icons.calendar_today_outlined,
                  color: AppColors.info,
                  onTap: () => context.push(Routes.meetings),
                  width: width,
                ),
                DashboardActionButton(
                  text: 'Withdraw',
                  icon: Icons.wallet_outlined,
                  color: AppColors.success,
                  onTap: () => context.push(Routes.wallet),
                  width: width,
                ),
                DashboardActionButton(
                  text: 'AI Proposal',
                  icon: Icons.auto_awesome_outlined,
                  color: AppColors.projectPurpleText,
                  onTap: () => context.push(Routes.freelancerProjects),
                  width: width,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context, DashboardState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = context.isDesktop
            ? 4
            : (context.isTablet ? 3 : 2);
        const double spacing =
            16.0; // matching AppSizes.sm is usually 16 or 12, I'll use 16
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
                title: 'TOTAL EARNINGS',
                value: Formatters.currency(state.freelancerMonthlyEarnings),
                lineColor: AppColors.primary,
                tagLabel: 'Lifetime stats',
                tagColor: AppColors.info,
                showIcon: false,
                onTap: () => context.push(Routes.wallet),
              ),
            ),
            SizedBox(
              width: width,
              child: DashboardMetricCard(
                title: 'AVAILABLE BALANCE',
                value: Formatters.currency(state.freelancerWalletBalance),
                lineColor: AppColors.success,
                tagLabel: 'Ready to withdraw',
                tagColor: AppColors.success,
                showIcon: false,
                onTap: () => context.push(Routes.wallet),
              ),
            ),
            SizedBox(
              width: width,
              child: DashboardMetricCard(
                title: 'PROJECTS WON',
                value: state.freelancerTotalProjects,
                lineColor: AppColors.info,
                tagLabel: '1 active now',
                tagColor: AppColors.info,
                showIcon: false,
                onTap: () => context.push(Routes.freelancerProjects),
              ),
            ),
            SizedBox(
              width: width,
              child: DashboardMetricCard(
                title: 'CONTRACTS ACTIVE',
                value: state.freelancerActiveContracts,
                lineColor: AppColors.warning,
                tagLabel: 'In delivery',
                tagColor: AppColors.warning,
                showIcon: false,
                onTap: () => context.push(Routes.freelancerProjects),
              ),
            ),
            SizedBox(
              width: width,
              child: DashboardMetricCard(
                title: 'PENDING PROPOSALS',
                value: state.freelancerPendingProposals,
                lineColor: AppColors.info,
                tagLabel: state.pendingProposalsCount == 0
                    ? 'No proposals yet'
                    : 'Active proposals',
                tagColor: AppColors.subtleText,
                showIcon: false,
                onTap: () => context.push(Routes.freelancerProposals),
              ),
            ),
            SizedBox(
              width: width,
              child: DashboardMetricCard(
                title: 'TASKS DUE TODAY',
                value: state.freelancerTodaysTasks,
                lineColor: AppColors.primary,
                tagLabel: 'None urgent',
                tagColor: AppColors.success,
                showIcon: false,
                onTap: () => context.push(Routes.freelancerProjects),
              ),
            ),
            SizedBox(
              width: width,
              child: DashboardMetricCard(
                title: 'MEETINGS TODAY',
                value: '${state.meetings.length}',
                lineColor: AppColors.primary,
                tagLabel: state.meetings.isEmpty
                    ? 'No meetings scheduled'
                    : 'Meetings scheduled',
                tagColor: AppColors.subtleText,
                showIcon: false,
                onTap: () => context.push(Routes.meetings),
              ),
            ),
            SizedBox(
              width: width,
              child: DashboardMetricCard(
                title: 'AVERAGE RATING',
                value: state.freelancerAverageRating,
                lineColor: AppColors.success,
                tagLabel: '${state.freelancerReviewCount} reviews',
                tagColor: AppColors.success,
                showIcon: false,
                onTap: () => context.push(Routes.freelancerProfile),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartsSection(BuildContext context, DashboardState state) {
    return AppSegmentedTabs(
      tabs: {
        'Monthly Earnings': _buildMonthlyEarningsChart(state),
        'Skill Distribution': const _SkillDistributionChart(),
        'Pipeline snapshot': _buildPipelineSnapshot(state),
        'Account health': _buildAccountHealth(state),
        'AI suggestions': _buildAiSuggestions(state),
      },
    );
  }

  Widget _buildPipelineSnapshot(DashboardState state) {
    return _buildActivityCard(
      'Pipeline snapshot',
      'Live from your account',
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatText('122', 'OPEN MATCHES'),
                _buildStatText(
                  state.freelancerPendingProposals,
                  'PENDING PROPOSALS',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatText(
                  state.freelancerActiveContracts,
                  'ACTIVE CONTRACTS',
                ),
                _buildStatText(
                  state.freelancerCompletedProjects,
                  'COMPLETED PROJECTS',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatText(state.freelancerReviewCount, 'REVIEWS'),
                _buildStatText(
                  '${state.freelancerProfileCompletion}%',
                  'PROFILE COMPLETION',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatText(String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.primaryBlack,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.subtleText),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountHealth(DashboardState state) {
    final completion = state.profileCompletionPercent > 0
        ? state.profileCompletionPercent
        : 70;
    return _buildActivityCard(
      'Account health',
      'Completion and rating',
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Profile completion',
                  style: TextStyle(fontSize: 11),
                ),
                Text(
                  '$completion%',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFE50A36),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: completion / 100.0,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFFE50A36),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatText(state.freelancerAverageRating, 'RATING'),
                _buildStatText(
                  Formatters.compactCurrency(state.freelancerWalletBalance),
                  'BALANCE',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiSuggestions(DashboardState state) {
    return _buildActivityCard(
      'AI suggestions',
      'Personalised for your growth',
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAiSuggestionItem(
              '122 open projects available to bid on',
              'Browse matches',
            ),
            const SizedBox(height: 8),
            _buildAiSuggestionItem(
              'Your profile is 70% complete — finish the last sections',
              'Complete profile',
            ),
            const SizedBox(height: 8),
            _buildAiSuggestionItem(
              'Send a proposal today to keep your pipeline warm',
              'Find projects',
            ),
          ],
        ),
      ),
      actionLabel: 'POWERED BY GO AI',
      onAction:
          () {}, // Required to show the red styling and arrow if left intact in _buildActivityCard
    );
  }

  Widget _buildAiSuggestionItem(String text, String linkText) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, size: 16, color: Color(0xFFE50A36)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primaryBlack,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$linkText \u203A',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFE50A36),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyEarningsChart(DashboardState state) {
    return AppChartCard(
      title: 'Monthly earnings & proposals',
      subtitle: 'Last 12 months',
      color: AppColors.primary,
      height: 220,
      data: _get12MonthChartData(state.earningsChart),
    );
  }

  List<BarData> _get12MonthChartData(List<double> raw) {
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
    if (raw.isEmpty) {
      return const [
        BarData('Aug', 0),
        BarData('Sep', 0),
        BarData('Oct', 0),
        BarData('Nov', 0),
        BarData('Dec', 0),
        BarData('Jan', 0),
        BarData('Feb', 0),
        BarData('Mar', 0),
        BarData('Apr', 0),
        BarData('May', 0),
        BarData('Jun', 1500),
        BarData('Jul', 6000),
      ];
    }
    return List.generate(labels.length, (i) {
      return BarData(labels[i], i < raw.length ? raw[i] : 0);
    });
  }

  Widget _buildBottomTabsSection(BuildContext context, DashboardState state) {
    return AppSegmentedTabs(
      tabs: {
        'Latest Activity': _buildLatestActivityTab(context, state),
        'Conversations': _buildConversationsTab(context, state),
        'Trending Skills': _TrendingSkillsCard(skills: state.topSkills),
      },
    );
  }

  Widget _buildLatestActivityTab(BuildContext context, DashboardState state) {
    final recentProjects = _buildActivityCard(
      'Recent projects',
      'Live contracts and delivery status',
      state.projects.isEmpty
          ? _buildEmptyContent('No projects found.', Icons.work_outline)
          : Column(
              children: state.projects
                  .take(3)
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: AppProjectCard(
                        project: p,
                        onTap: () async {
                          await context.push('${Routes.projectDetails}/${p.id}');
                          if (context.mounted) {
                            context.read<DashboardCubit>().refresh();
                          }
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
      actionLabel: 'View all',
      onAction: () => context.push(Routes.freelancerProjects),
    );

    final recentProposals = _buildActivityCard(
      'Recent proposals',
      'Track your bids and interviews',
      _buildEmptyContent(
        'No proposals yet. Start bidding to fill this list.',
        Icons.assignment_outlined,
        height: 100,
      ),
      actionLabel: 'All proposals',
      onAction: () => context.push(Routes.freelancerProjects),
    );

    return Column(
      children: [recentProjects, const SizedBox(height: 16), recentProposals],
    );
  }

  Widget _buildActivityCard(
    String title,
    String? subtitle,
    Widget child, {
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryBlack.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlack,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.subtleText,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (actionLabel != null)
                    InkWell(
                      onTap: onAction,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            actionLabel,
                            style: const TextStyle(
                              color: Color(0xFFE50A36),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_outward,
                            size: 14,
                            color: Color(0xFFE50A36),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyContent(
    String message,
    IconData icon, {
    double height = 120,
  }) {
    return SizedBox(
      height: height,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              style: const TextStyle(color: AppColors.subtleText, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsTab(BuildContext context, DashboardState state) {
    final upcomingMeetings = _buildActivityCard(
      'Upcoming meetings',
      null, // No subtitle in screenshot
      state.meetings.isEmpty
          ? _buildEmptyContent(
              'No upcoming meetings.',
              Icons.calendar_today_outlined,
            )
          : Column(
              children: state.meetings
                  .take(2)
                  .map(
                    (m) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: AppMeetingCard(meeting: m),
                    ),
                  )
                  .toList(),
            ),
      onTap: () => context.push(Routes.meetings),
    );

    final messages = _buildActivityCard(
      'Messages',
      null, // No subtitle
      _buildEmptyContent('No messages yet.', Icons.chat_bubble_outline),
      onTap: () => context.push(Routes.messages),
    );

    return Column(
      children: [upcomingMeetings, const SizedBox(height: 16), messages],
    );
  }
}

class _TrendingSkillsCard extends StatelessWidget {
  const _TrendingSkillsCard({this.skills});

  final List<String>? skills;

  @override
  Widget build(BuildContext context) {
    const fallbackSkills = [
      'Flutter',
      'AI/ML',
      'Next.js',
      'Kubernetes',
      'LLMs',
      'Rust',
      'Figma',
    ];

    final effectiveSkills = (skills != null && skills!.isNotEmpty)
        ? skills!
              .where((s) => s.trim().isNotEmpty && !_skillLooksLikeUuid(s))
              .toList()
        : fallbackSkills;
    final displaySkills = effectiveSkills.isNotEmpty
        ? effectiveSkills
        : fallbackSkills;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSectionHeader(
            title: 'Trending Skills',
            subtitle: 'In demand this week',
          ),
          AppSizes.vGapMd,
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: [
              for (final s in displaySkills)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        s,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

final _skillUuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

bool _skillLooksLikeUuid(String value) =>
    _skillUuidPattern.hasMatch(value.trim());

class _SkillDistributionChart extends StatelessWidget {
  const _SkillDistributionChart();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Skill distribution',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const Text(
            'From your professional profile',
            style: TextStyle(color: AppColors.subtleText, fontSize: 11),
          ),
          const SizedBox(height: 36),
          Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: CustomPaint(
                painter: DonutChartPainter(
                  values: const [30, 25, 20, 15, 10],
                  colors: const [
                    Color(0xFFE30613), // Python (red)
                    Color(0xFF0EA5E9), // UI/UX Design (blue)
                    Color(0xFFF59E0B), // Go Lang (orange)
                    Color(0xFF16A34A), // GraphQL (green)
                    Color(0xFF7C3AED), // Website Developer (purple)
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: const [
              _LegendItem(color: Color(0xFFE30613), label: 'Python'),
              _LegendItem(color: Color(0xFF0EA5E9), label: 'UI/UX Design'),
              _LegendItem(color: Color(0xFFF59E0B), label: 'Go Lang'),
              _LegendItem(color: Color(0xFF16A34A), label: 'GraphQL'),
              _LegendItem(color: Color(0xFF7C3AED), label: 'Website Developer'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.projectBodyText,
          ),
        ),
      ],
    );
  }
}

class DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  DonutChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = values.fold(0.0, (sum, value) => sum + value);
    if (total == 0) return;

    const double strokeWidth = 20.0;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final Rect rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: (size.width - strokeWidth) / 2,
    );

    double startAngle = -3.1415926535 / 2; // Start from top
    for (int i = 0; i < values.length; i++) {
      final double sweepAngle = (values[i] / total) * 2 * 3.1415926535;
      paint.color = colors[i];
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) => true;
}
