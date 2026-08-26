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
import '../../../../core/widgets/verification_prompt_card.dart';

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
               if (state.shouldShowVerificationPrompt) ...[
                        VerificationPromptCard(
                          missingCount: state.verificationMissingCount,
                          accountVerified: state.accountVerified,
                          route: Routes.clientVerification,
                        ),
                        const SizedBox(height: 16),
                      ],
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
          int.parse(state.clientPendingProposals) > 0 ||
                  int.parse(state.clientShortlistedFreelancers) > 0
              ? '${state.clientPendingProposals} applications, ${state.clientShortlistedFreelancers} hires.'
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
            onTap: () => context.push(Routes.clientProjects),
          ),
          _buildEmptyStateCard(
            'Pending Payments',
            'Release before due date to keep vendors happy',
            'No pending payments.',
            onTap: () => context.push(Routes.clientPayments),
          ),
        ]),
        'Workspace': _buildMultiColumn(context, [
          _buildEmptyStateCard(
            'Today\'s Meetings',
            '${state.meetings.length} scheduled',
            state.meetings.isNotEmpty
                ? 'You have ${state.meetings.length} meetings.'
                : 'No meetings scheduled today.',
            onTap: () => context.push(Routes.meetings),
          ),
          _buildEmptyStateCard(
            'Today\'s Tasks',
            '0 due',
            'No tasks due today.',
            onTap: () => context.push(Routes.clientProjects),
          ),
          _buildEmptyStateCard(
            'Pending Approvals',
            'Awaiting your sign-off',
            'Nothing pending your approval.',
            onTap: () => context.push(Routes.clientProjects),
          ),
        ]),
        'Inbox': _buildMultiColumn(context, [
          _buildEmptyStateCard(
            'Latest Messages',
            '${state.unreadMessagesCount} unread',
            state.unreadMessagesCount > 0
                ? 'You have ${state.unreadMessagesCount} unread messages.'
                : 'No messages yet.',
            onTap: () => context.push(Routes.messages),
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
                    text: '${state.clientPendingProposals} approvals',
                    style: const TextStyle(color: Color(0xFFEF4444)),
                  ),
                  const TextSpan(text: ', '),
                  TextSpan(
                    text: '${state.clientPendingPayments} pending payments',
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
                  '${state.clientActiveProjects} active projects',
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
        const SizedBox(height: 8),
        const Text(
          'Jump into the tools you use most',
          style: TextStyle(fontSize: 11, color: AppColors.subtleText),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final int columns = context.isMobile ? 3 : 6;
            const double spacing = 12.0;
            final double width =
                (constraints.maxWidth - (columns - 1) * spacing) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                DashboardActionButton(
                  text: 'Post Project',
                  icon: Icons.add,
                  color: const Color(
                    0xFFE50A36,
                  ), // Vibrant red, matching screenshot
                  onTap: () => context.push(Routes.clientCreateProject),
                  width: width,
                ),
                DashboardActionButton(
                  text: 'Invite Freelancer',
                  icon: Icons.person_add_alt_1,
                  color: const Color(0xFF2563EB), // Blue
                  onTap: () => context.push(Routes.clientFreelancers),
                  width: width,
                ),
                DashboardActionButton(
                  text: 'Book Consultation',
                  icon: Icons.edit_calendar,
                  color: const Color(0xFF9333EA), // Purple
                  onTap: () => context.push(Routes.meetings),
                  width: width,
                ),
                DashboardActionButton(
                  text: 'Schedule Meeting',
                  icon: Icons.video_call,
                  color: const Color(0xFF0D9488), // Teal
                  onTap: () => context.push(Routes.meetings),
                  width: width,
                ),
                DashboardActionButton(
                  text: 'Generate Invoice',
                  icon: Icons.receipt_long,
                  color: const Color(0xFFEA580C), // Orange
                  onTap: () => context.push(Routes.clientPayments),
                  width: width,
                ),
                DashboardActionButton(
                  text: 'Fund Wallet',
                  icon: Icons.account_balance_wallet,
                  color: const Color(0xFF2563EB), // Blue
                  onTap: () => context.push(Routes.wallet),
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
    if (context.isMobile) {
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
                  context,
                  'TOTAL PROJECTS',
                  '${int.tryParse(state.clientActiveProjects)! + int.tryParse(state.clientDraftProjects)! + int.tryParse(state.clientCompletedProjects)!}',
                ),
              ),
              SizedBox(
                width: width,
                child: _projCard(
                  context,
                  'DRAFT PROJECTS',
                  state.clientDraftProjects,
                ),
              ),
              SizedBox(
                width: width,
                child: _projCard(
                  context,
                  'ACTIVE PROJECTS',
                  state.clientActiveProjects,
                ),
              ),
              SizedBox(
                width: width,
                child: _projCard(
                  context,
                  'COMPLETED',
                  state.clientCompletedProjects,
                ),
              ),
              SizedBox(
                width: width,
                child: _spendCard(
                  context,
                  'TOTAL SPEND',
                  Formatters.compactCurrency(state.clientTotalSpend),
                ),
              ),
              SizedBox(
                width: width,
                child: _spendCard(
                  context,
                  'WALLET BALANCE',
                  Formatters.compactCurrency(state.clientWalletBalance),
                ),
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
            context,
            'TOTAL PROJECTS',
            '${int.tryParse(state.clientActiveProjects)! + int.tryParse(state.clientDraftProjects)! + int.tryParse(state.clientCompletedProjects)!}',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _projCard(
            context,
            'DRAFT PROJECTS',
            state.clientDraftProjects,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _projCard(
            context,
            'ACTIVE PROJECTS',
            state.clientActiveProjects,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _projCard(context, 'COMPLETED', state.clientCompletedProjects),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _spendCard(
            context,
            'TOTAL SPEND',
            Formatters.compactCurrency(state.clientTotalSpend),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _spendCard(
            context,
            'WALLET BALANCE',
            Formatters.compactCurrency(state.clientWalletBalance),
          ),
        ),
      ],
    );
  }

  Widget _projCard(BuildContext context, String title, String value) {
    return DashboardMetricCard(
      title: title,
      value: value,
      lineColor: const Color(0xFFE50A36),
      tagLabel: '',
      tagColor: AppColors.success,
      onTap: () => context.push(Routes.clientProjects),
    );
  }

  Widget _spendCard(BuildContext context, String title, String value) {
    return DashboardMetricCard(
      title: title,
      value: value,
      lineColor: const Color(0xFFE50A36),
      tagLabel: '',
      tagColor: AppColors.success,
      onTap: () => title.contains('SPEND')
          ? context.push(Routes.clientPayments)
          : context.push(Routes.wallet),
    );
  }
}
