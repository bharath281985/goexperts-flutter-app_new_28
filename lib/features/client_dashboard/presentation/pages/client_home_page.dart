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
import '../../../../core/widgets/app_loading_shimmer.dart';
import '../../../../core/widgets/dashboard_header.dart';
import '../../../../core/widgets/dashboard_metric_card.dart';
import '../../../../core/widgets/dashboard_action_button.dart';
import '../../../../core/widgets/app_segmented_tabs.dart';

class ClientHomePage extends StatelessWidget {
  const ClientHomePage({super.key});

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
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Builder(
                builder: (ctx) => DashboardHeader(
                  subtitle:
                      'Manage your projects, hire talent, and oversee operations.',
                  unread: state.unreadNotificationsCount,
                  onMenu: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
              // Hero Banner
              _buildHeroBanner(context, state),

              if (loading)
                const Padding(
                  padding: EdgeInsets.all(AppSizes.screenPadding),
                  child: AppLoadingShimmer(itemCount: 4, height: 110),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.screenPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlack,
                        ),
                      ),

                      _buildQuickActions(context),
                      const SizedBox(height: 24),
                      _buildMetricsGrid(context, state),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildAnalyticsTabs(context, state),
                const SizedBox(height: 24),
                _buildOperationalTabs(context, state),
                const SizedBox(height: 100),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTabs(BuildContext context, DashboardState state) {
    return AppSegmentedTabs(
      tabs: {
        'Monthly Hiring': _buildEmptyStateCard(
          'Monthly Hiring',
          'Applications vs. hires across the year',
          state.pendingProposalsCount > 0 || state.profileCompletionPercent > 0
              ? '${state.pendingProposalsCount} applications, ${state.profileCompletionPercent} hires.'
              : 'No hiring data yet.',
        ),
        'Hiring Pipeline': _buildEmptyStateCard(
          'Hiring Pipeline',
          'Live view across every stage of your hiring funnel',
          state.freelancers.isNotEmpty
              ? 'You have ${state.freelancers.length} active candidates in your pipeline.'
              : 'Pipeline will appear once you post projects.',
          topRightAction: 'Open pipeline \u2192',
          onActionTap: () => context.push(Routes.clientFreelancers),
        ),
        'Revenue vs Expenses': _buildEmptyStateCard(
          'Revenue vs Expenses',
          'In ₹ lakhs',
          state.monthlyEarnings > 0
              ? 'Current Spend: ${Formatters.compactCurrency(state.monthlyEarnings)}'
              : 'No finance data yet.',
        ),
      },
    );
  }

  Widget _buildOperationalTabs(BuildContext context, DashboardState state) {
    return AppSegmentedTabs(
      tabs: {
        'Latest Activity': _buildMultiColumn(context, [
          _buildEmptyStateCard(
            'Latest Applications',
            'AI-matched candidates from your open roles',
            state.freelancers.isNotEmpty
                ? '${state.freelancers.length} recent applications.'
                : 'No applications yet.',
          ),
          _buildEmptyStateCard(
            'Pending Payments',
            'Release before due date to keep vendors happy',
            'No pending payments.',
          ),
        ]),
        'Workspace': _buildMultiColumn(context, [
          _buildEmptyStateCard(
            'Today\'s Meetings',
            '${state.meetings.length} scheduled',
            state.meetings.isNotEmpty
                ? 'You have ${state.meetings.length} meetings.'
                : 'No meetings scheduled today.',
          ),
          _buildEmptyStateCard(
            'Today\'s Tasks',
            '0 due',
            'No tasks due today.',
          ),
          _buildEmptyStateCard(
            'Pending Approvals',
            'Awaiting your sign-off',
            'Nothing pending your approval.',
          ),
        ]),
        'Inbox': _buildMultiColumn(context, [
          _buildEmptyStateCard(
            'Latest Messages',
            '${state.unreadMessagesCount} unread',
            state.unreadMessagesCount > 0
                ? 'You have ${state.unreadMessagesCount} unread messages.'
                : 'No messages yet.',
          ),
          _buildEmptyStateCard(
            'Latest Notifications',
            '${state.unreadNotificationsCount} unread',
            state.unreadNotificationsCount > 0
                ? 'You have ${state.unreadNotificationsCount} unread notifications.'
                : 'You\'re all caught up.',
          ),
          _buildEmptyStateCard('Latest Reviews', null, 'No reviews yet.'),
        ]),
      },
    );
  }

  Widget _buildMultiColumn(BuildContext context, List<Widget> children) {
    if (context.isMobile) {
      return Column(
        children: children
            .map(
              (c) =>
                  Padding(padding: const EdgeInsets.only(bottom: 16), child: c),
            )
            .toList(),
      );
    }
    return Row(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i != children.length - 1) const SizedBox(width: 16),
        ],
      ],
    );
  }

  Widget _buildEmptyStateCard(
    String title,
    String? subtitle,
    String message, {
    String? topRightAction,
    VoidCallback? onActionTap,
  }) {
    return Container(
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
                if (topRightAction != null)
                  InkWell(
                    onTap: onActionTap,
                    child: Text(
                      topRightAction,
                      style: const TextStyle(
                        color: Color(0xFFE50A36),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              bottom: 40,
              top: 40,
              left: 16,
              right: 16,
            ),
            child: Center(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.subtleText,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, DashboardState state) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSizes.screenPadding,
        right: AppSizes.screenPadding,
        top: AppSizes.screenPadding,
        bottom: 8,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF090D16)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _pillTag(Icons.star_rounded, 'FREE', AppColors.warning),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Welcome back, ${context.read<AuthBloc>().state.user?.fullName ?? "Client"}.',
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text.rich(
              TextSpan(
                text: 'You have ',
                children: [
                  TextSpan(
                    text: '${state.pendingProposalsCount} approvals',
                    style: const TextStyle(color: Color(0xFFEF4444)),
                  ),
                  const TextSpan(text: ', '),
                  TextSpan(
                    text: '${state.activeProjectsCount} pending payments',
                    style: const TextStyle(color: Color(0xFFEF4444)),
                  ),
                  const TextSpan(text: ' and 0 new applications waiting.'),
                ],
              ),
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.82),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _pillTag(
                  Icons.verified_outlined,
                  'Verified Enterprise',
                  const Color(0xFF22C55E),
                ),
                _pillTag(
                  Icons.business_rounded,
                  'In-house Team',
                  AppColors.info,
                ),
                _pillTag(
                  Icons.work_outline_rounded,
                  '${state.activeProjectsCount} active projects',
                  AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillTag(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
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
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
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
        GridView.count(
          crossAxisCount: context.isMobile ? 3 : 6,
          shrinkWrap: true,
          padding: const EdgeInsets.only(top: 12),
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: context.isMobile ? 1.4 : 2.4,
          children: [
            DashboardActionButton(
              text: 'Post Project',
              icon: Icons.add,
              color: const Color(0xFFE50A36), // Vibrant red, matching screenshot
              onTap: () => context.push(Routes.clientCreateProject),
            ),
            DashboardActionButton(
              text: 'Invite Freelancer',
              icon: Icons.person_add_alt_1,
              color: const Color(0xFF2563EB), // Blue
              onTap: () => context.push(Routes.clientFreelancers),
            ),
            DashboardActionButton(
              text: 'Book Consultation',
              icon: Icons.edit_calendar,
              color: const Color(0xFF9333EA), // Purple
              onTap: () => context.push(Routes.meetings),
            ),
            DashboardActionButton(
              text: 'Schedule Meeting',
              icon: Icons.video_call,
              color: const Color(0xFF0D9488), // Teal
              onTap: () => context.push(Routes.meetings),
            ),
            DashboardActionButton(
              text: 'Generate Invoice',
              icon: Icons.receipt_long,
              color: const Color(0xFFEA580C), // Orange
              onTap: () => context.push(Routes.clientPayments),
            ),
            DashboardActionButton(
              text: 'Fund Wallet',
              icon: Icons.account_balance_wallet,
              color: const Color(0xFF2563EB), // Blue
              onTap: () => context.push(Routes.wallet),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricsGrid(BuildContext context, DashboardState state) {
    if (context.isMobile) {
      // 2 columns per row via Wrap
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - 16) / 2;
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: width,
                child: _projCard(
                  'TOTAL PROJECTS',
                  '${state.activeProjectsCount + state.pendingProposalsCount}',
                ),
              ),
              SizedBox(width: width, child: _projCard('OPEN PROJECTS', '0')),
              SizedBox(
                width: width,
                child: _projCard(
                  'ACTIVE PROJECTS',
                  '${state.activeProjectsCount}',
                ),
              ),
              SizedBox(
                width: width,
                child: _projCard('COMPLETED PROJECTS', '0'),
              ),
              SizedBox(
                width: width,
                child: _spendCard(
                  'TOTAL SPEND',
                  Formatters.compactCurrency(state.monthlyEarnings),
                ),
              ),
              SizedBox(
                width: width,
                child: _spendCard('WALLET BALANCE', '₹15,583'),
              ),
            ],
          );
        },
      );
    }

    // 6 columns flat, natural height
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _projCard(
            'TOTAL PROJECTS',
            '${state.activeProjectsCount + state.pendingProposalsCount}',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: _projCard('OPEN PROJECTS', '0')),
        const SizedBox(width: 16),
        Expanded(
          child: _projCard('ACTIVE PROJECTS', '${state.activeProjectsCount}'),
        ),
        const SizedBox(width: 16),
        Expanded(child: _projCard('COMPLETED PROJECTS', '0')),
        const SizedBox(width: 16),
        Expanded(
          child: _spendCard(
            'TOTAL SPEND',
            Formatters.compactCurrency(state.monthlyEarnings),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: _spendCard('WALLET BALANCE', '₹15,583')),
      ],
    );
  }

  Widget _projCard(String title, String value) {
    return DashboardMetricCard(
      title: title,
      value: value,
      lineColor: const Color(0xFFE50A36),
      tagLabel: '',
      tagColor: AppColors.success,
    );
  }

  Widget _spendCard(String title, String value) {
    return DashboardMetricCard(
      title: title,
      value: value,
      lineColor: const Color(0xFFE50A36),
      tagLabel: '',
      tagColor: AppColors.success,
    );
  }
}
