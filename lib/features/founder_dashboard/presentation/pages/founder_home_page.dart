import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../core/dashboard/dashboard_cubit.dart';
import '../../../../core/widgets/app_segmented_tabs.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_loading_shimmer.dart';
import '../../../../core/widgets/app_chart_card.dart';
import '../../../../core/widgets/dashboard_action_button.dart';
import '../../../../core/widgets/dashboard_header.dart';
import '../../../../core/widgets/dashboard_metric_card.dart';

class FounderHomePage extends StatelessWidget {
  const FounderHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        final loading =
            state.status == ViewStatus.loading ||
            state.status == ViewStatus.initial;

        return RefreshIndicator(
          onRefresh: () async {
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
                            'Grow your startup, raise funds and engage investors.',
                        unread: state.unreadNotificationsCount,
                        onMenu: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    ),
                    _buildHeroBanner(context, state),
                    _buildActionButtons(context),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.screenPadding,
                      ),
                      child: _buildMetricsGrid(context, state),
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
    final raised = state.monthlyEarnings;
    final goal = state.fundingGoal > 0 ? state.fundingGoal : 0.0;
    final pitchViews = state.pendingProposalsCount;
    final meetings = state.meetings.length;

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
            colors: [Color(0xFF1B0706), Color(0xFF330907), Color(0xFF140303)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.05)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildBannerTag(
                    Icons.auto_awesome,
                    'Live Fundraising Campaign',
                    AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  _buildBannerTag(
                    Icons.health_and_safety,
                    'Health Score ${state.profileCompletionPercent}%',
                    AppColors.subtleText,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  text: 'You raised ',
                  children: [
                    TextSpan(
                      text: Formatters.compactCurrency(raised),
                      style: const TextStyle(color: AppColors.primary),
                    ),
                    const TextSpan(text: ' of your '),
                    TextSpan(
                      text: Formatters.compactCurrency(goal),
                      style: const TextStyle(color: AppColors.primary),
                    ),
                    const TextSpan(text: ' target round.'),
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
                'Pitch Views: $pitchViews. You have $meetings meetings listed. Keep pitching!',
                style: TextStyle(
                  color: AppColors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildBannerButton(
                      'Complete Startup Profile',
                      Icons.edit,
                      AppColors.primary,
                      onTap: () => context.push(Routes.founderStartup),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBannerButton(
                      'Pitch Deck Manager',
                      Icons.slideshow,
                      AppColors.primaryBlack,
                      isDark: true,
                      onTap: () => context.push(Routes.founderPitchDeck),
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

  Widget _buildBannerButton(
    String text,
    IconData icon,
    Color bgColor, {
    bool isDark = false,
    VoidCallback? onTap,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: AppColors.white),
            const SizedBox(width: 8),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  text,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
        horizontal: AppSizes.screenPadding + 10,
        vertical: AppSizes.sm,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final int columns = context.isDesktop
              ? 6
              : (context.isTablet ? 4 : 3);
          const double spacing = 12.0;
          final double width =
              (constraints.maxWidth - (columns - 1) * spacing) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              DashboardActionButton(
                text: 'Edit Startup',
                icon: Icons.edit_note,
                color: AppColors.warning,
                onTap: () => context.push(Routes.founderStartup),
                width: width,
              ),
              DashboardActionButton(
                text: 'Upload Pitch Deck',
                icon: Icons.upload_file,
                color: AppColors.projectPurple,
                onTap: () => context.push(Routes.founderPitchDeck),
                width: width,
              ),
              DashboardActionButton(
                text: 'Invite Team',
                icon: Icons.person_add,
                color: AppColors.info,
                onTap: () => context.push(Routes.founderTeam),
                width: width,
              ),
              DashboardActionButton(
                text: 'Schedule Meeting',
                icon: Icons.calendar_month,
                color: AppColors.success,
                onTap: () => context.push(Routes.meetings),
                width: width,
              ),
              DashboardActionButton(
                text: 'Request Funding',
                icon: Icons.attach_money,
                color: AppColors.primary,
                onTap: () => context.push(Routes.founderFunding),
                width: width,
              ),
              DashboardActionButton(
                text: 'Export Reports',
                icon: Icons.download,
                color: AppColors.projectPurpleText,
                onTap: () => context.push(Routes.founderAnalytics),
                width: width,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context, DashboardState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = context.isDesktop
            ? 4
            : (context.isTablet ? 3 : 2);
        const double spacing = 16.0; // matching AppSizes.sm
        final double width =
            (constraints.maxWidth - (crossAxisCount - 1) * spacing) /
            crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: width,
              child: _buildMetricCard(
                'STARTUP PROFILE STATUS',
                'Active',
                AppColors.primary,
              ),
            ),
            SizedBox(
              width: width,
              child: _buildMetricCard(
                'INVESTOR VIEWS',
                '${state.profileCompletionPercent}',
                AppColors.success,
              ),
            ),
            SizedBox(
              width: width,
              child: _buildMetricCard(
                'INVESTOR INTERESTS',
                '${state.activeProjectsCount}',
                AppColors.warning,
              ),
            ),
            SizedBox(
              width: width,
              child: _buildMetricCard('CONTACT REQUESTS', '0', AppColors.info),
            ),
            SizedBox(
              width: width,
              child: _buildMetricCard(
                'PITCH DECK DOWNLOADS',
                '${state.pendingProposalsCount}',
                AppColors.primary,
              ),
            ),
            SizedBox(
              width: width,
              child: _buildMetricCard(
                'UNREAD MESSAGES',
                '${state.unreadMessagesCount}',
                AppColors.warning,
              ),
            ),
            SizedBox(
              width: width,
              child: _buildMetricCard(
                'SCHEDULED MEETINGS',
                '${state.meetings.length}',
                AppColors.info,
              ),
            ),
            SizedBox(
              width: width,
              child: _buildMetricCard(
                'SUBSCRIPTION STATUS',
                'Free Founder Plan',
                AppColors.primary,
              ),
            ),
            SizedBox(
              width: width,
              child: _buildMetricCard(
                'PROFILE STRENGTH SCORE',
                '${state.profileCompletionPercent}%',
                AppColors.success,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, Color bottomColor) {
    return DashboardMetricCard(
      title: title,
      value: value,
      lineColor: bottomColor,
    );
  }

  Widget _buildEmptyStateCard(
    String title,
    String subtitle,
    String emptyMessage, {
    IconData icon = Icons.calendar_today,
  }) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.subtleText, fontSize: 11),
          ),
          const Spacer(),
          Center(
            child: Column(
              children: [
                if (title.contains('Meeting')) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppColors.subtleText, size: 24),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  emptyMessage,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primaryBlack,
                  ),
                ),
                if (title.contains('Meeting'))
                  const Text(
                    'Use your scheduler to invite interestedinvestors.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.subtleText),
                  ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildChartsSection(BuildContext context, DashboardState state) {
    return AppSegmentedTabs(
      tabs: {
        'Interest Trend': AppChartCard(
          title: 'Investor Interest Trend',
          subtitle: 'Outreaches per month',
          color: AppColors.primary,
          height: 220,
          data: _getChartData(state.earningsChart),
        ),
        'Funding Distribution': Container(
          height: 220,
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
                'Funding Distribution',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const Text(
                'Current Target Breakdown',
                style: TextStyle(color: AppColors.subtleText, fontSize: 11),
              ),
              const Spacer(),
              Center(
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 16,
                        color: AppColors.success,
                      ),
                      CircularProgressIndicator(
                        value: 0.65,
                        strokeWidth: 16,
                        color: AppColors.warning,
                      ),
                      CircularProgressIndicator(
                        value: 0.35,
                        strokeWidth: 16,
                        color: AppColors.danger,
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.circle, size: 8, color: AppColors.danger),
                  SizedBox(width: 4),
                  Text('Seed', style: TextStyle(fontSize: 10)),
                  SizedBox(width: 12),
                  Icon(Icons.circle, size: 8, color: AppColors.warning),
                  SizedBox(width: 4),
                  Text('Extend', style: TextStyle(fontSize: 10)),
                  SizedBox(width: 12),
                  Icon(Icons.circle, size: 8, color: AppColors.success),
                  SizedBox(width: 4),
                  Text('Remaining', style: TextStyle(fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
        'Activity Volume': AppChartCard(
          title: 'Activity Volume',
          subtitle: 'Deals by month',
          color: AppColors.info,
          height: 220,
          data: _getChartData(state.earningsChart),
        ),
      },
    );
  }

  Widget _buildBottomTabsSection(BuildContext context, DashboardState state) {
    return AppSegmentedTabs(
      tabs: {
        'Milestones': _buildEmptyStateCard(
          'Milestone Progress',
          'Key roadmap checkpoints',
          'No milestones yet.',
          icon: Icons.flag,
        ),
        'Recent Activity': _buildEmptyStateCard(
          'Recent Investor Activity',
          'From investor requests',
          'No recent activity.',
          icon: Icons.history,
        ),
        'Upcoming Meetings': _buildEmptyStateCard(
          'Upcoming Meetings',
          '',
          'No meetings scheduled',
          icon: Icons.calendar_today,
        ),
      },
    );
  }

  List<BarData> _getChartData(List<double> raw) {
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
        BarData('Jun', 0),
        BarData('Jul', 0),
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
    return List.generate(labels.length, (i) {
      return BarData(labels[i], i < raw.length ? raw[i] : 0);
    });
  }
}
