import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_sizes.dart';
import '../../app/router/route_names.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../extensions/context_extensions.dart';
import '../utils/enums.dart';
import 'app_avatar.dart';
import 'app_confirm_dialog.dart';

/// A drawer menu entry.
class DrawerEntry {
  const DrawerEntry(
    this.label,
    this.icon, {
    this.route,
    this.onTap,
    this.badge,
    this.badgeText,
    this.badgeColor,
  });
  final String label;
  final IconData icon;
  final String? route;
  final VoidCallback? onTap;
  final int? badge;
  final String? badgeText;
  final Color? badgeColor;
}

/// A grouped section of drawer entries.
class DrawerSection {
  const DrawerSection(this.title, this.entries);
  final String title;
  final List<DrawerEntry> entries;
}

/// Role-aware navigation drawer used by all dashboards.
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    super.key,
    required this.role,
    this.unreadNotifications = 0,
    this.unreadMessages = 0,
  });

  final UserRole role;
  final int unreadNotifications;
  final int unreadMessages;

  static final _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static String _planLabel(String? plan) {
    final value = plan?.trim();
    if (value == null || value.isEmpty || _uuidPattern.hasMatch(value)) {
      return 'Starter plan';
    }
    final lower = value.toLowerCase();
    return lower.endsWith(' plan') ? value : '$value plan';
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final user = context.select((AuthBloc b) => b.state.user);
    final colors = context.colors;

    if (role == UserRole.founder ||
        role == UserRole.investor ||
        role == UserRole.freelancer) {
      return _FounderDrawer(
        user: user,
        sections: _sections(role),
        currentPath: currentPath,
        workspaceLabel: role == UserRole.investor
            ? 'INVESTOR OS'
            : role == UserRole.freelancer
            ? 'FREELANCER HQ'
            : 'FOUNDER OS',
        role: role,
      );
    }

    return Drawer(
      backgroundColor: colors.surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppAvatar(
                        name: user?.fullName ?? 'User',
                        imageUrl: user?.avatarUrl,
                        size: 52,
                      ),
                      AppSizes.hGapMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? context.tr('Guest'),
                              style: TextStyle(
                                color: colors.onPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              context.tr(role.label),
                              style: TextStyle(
                                color: colors.onPrimary.withValues(alpha: 0.85),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  AppSizes.vGapMd,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.onPrimary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium_outlined,
                          size: 15,
                          color: colors.onPrimary,
                        ),
                        AppSizes.hGapSm,
                        Flexible(
                          child: Text(
                            context.tr(_planLabel(user?.subscriptionPlan)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.onPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  context.read<AuthBloc>().add(const AuthRefreshUser());
                  await Future.delayed(const Duration(milliseconds: 600));
                },
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                  children: [
                    for (final section in _sections(role)) ...[
                      Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: section.entries.any(
                            (e) =>
                                e.route != null &&
                                currentPath.startsWith(e.route!),
                          ),
                          tilePadding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.lg,
                          ),
                          title: Text(
                            context.tr(section.title).toUpperCase(),
                            style: context.text.labelSmall?.copyWith(
                              letterSpacing: 1,
                              color: context.colors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          iconColor: context.colors.onSurfaceVariant,
                          collapsedIconColor: context.colors.onSurfaceVariant,
                          childrenPadding: EdgeInsets.zero,
                          children: [
                            for (final e in section.entries)
                              _DrawerMenuTile(
                                entry: e,
                                currentPath: currentPath,
                                dense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSizes.xl,
                                ),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  if (e.onTap != null) {
                                    e.onTap!();
                                  } else if (e.route != null) {
                                    context.push(e.route!);
                                  }
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                    Divider(color: colors.outlineVariant),
                    ListTile(
                      leading: Icon(
                        Icons.logout_rounded,
                        size: 20,
                        color: colors.error,
                      ),
                      title: Text(
                        context.tr('Log Out'),
                        style: context.text.bodyMedium?.copyWith(
                          color: colors.error,
                        ),
                      ),
                      onTap: () async {
                        final confirm = await AppConfirmDialog.show(
                          context,
                          title: 'Log out?',
                          message:
                              'You will need to sign in again to access your account.',
                          confirmLabel: 'Log Out',
                          isDestructive: true,
                          icon: Icons.logout_rounded,
                        );
                        if (confirm && context.mounted) {
                          context.read<AuthBloc>().add(const AuthLoggedOut());
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DrawerSection> _sections(UserRole role) {
    switch (role) {
      case UserRole.freelancer:
        return [
          DrawerSection('Overview', [
            const DrawerEntry(
              'Dashboard',
              Icons.dashboard_outlined,
              route: Routes.freelancerDashboard,
            ),
            const DrawerEntry(
              'Analytics',
              Icons.insights_outlined,
              route: Routes.freelancerDashboard,
            ),
            DrawerEntry(
              'Notifications',
              Icons.notifications_none_rounded,
              route: Routes.notifications,
              badge: unreadNotifications > 0 ? unreadNotifications : 4,
            ),
          ]),
          const DrawerSection('Profile', [
            DrawerEntry(
              'My Profile',
              Icons.person_outline_rounded,
              route: Routes.freelancerEditProfile,
            ),
            DrawerEntry('Professional Details', Icons.work_outline_rounded),
            DrawerEntry('Verification', Icons.verified_user_outlined),
            DrawerEntry('Portfolio', Icons.perm_media_outlined),
            DrawerEntry('Resume', Icons.description_outlined),
            DrawerEntry('Skills', Icons.psychology_outlined),
            DrawerEntry('Experience', Icons.timeline_outlined),
            DrawerEntry('Education', Icons.school_outlined),
            DrawerEntry('Certificates', Icons.workspace_premium_outlined),
          ]),
          const DrawerSection('Work', [
            DrawerEntry(
              'Projects',
              Icons.work_outline_rounded,
              route: Routes.freelancerProjects,
              badge: 1,
            ),
            DrawerEntry(
              'Proposals',
              Icons.send_outlined,
              route: Routes.freelancerProposals,
            ),
            DrawerEntry('Contracts', Icons.assignment_turned_in_outlined),
            DrawerEntry('Tasks', Icons.task_alt_outlined),
            DrawerEntry(
              'Calendar',
              Icons.calendar_month_outlined,
              route: Routes.calendar,
            ),
            DrawerEntry(
              'Meetings',
              Icons.event_outlined,
              route: Routes.meetings,
            ),
            DrawerEntry(
              'Messages',
              Icons.chat_bubble_outline_rounded,
              route: Routes.messages,
            ),
            DrawerEntry('My Clients', Icons.people_outline_rounded),
            DrawerEntry('Reviews', Icons.star_border_rounded),
          ]),
          const DrawerSection('Finance', [
            DrawerEntry('Earnings', Icons.bar_chart_rounded),
            DrawerEntry(
              'Wallet',
              Icons.account_balance_wallet_outlined,
              route: Routes.wallet,
            ),
            DrawerEntry('Transactions', Icons.sync_alt_rounded),
            DrawerEntry('Withdrawals', Icons.payments_outlined),
            DrawerEntry('Invoices', Icons.receipt_long_outlined),
            DrawerEntry(
              'Subscriptions',
              Icons.workspace_premium_outlined,
              route: Routes.subscriptionsManage,
            ),
          ]),
          const DrawerSection('Growth', [
            DrawerEntry(
              'AI Assistant',
              Icons.auto_awesome_outlined,
              badgeText: 'New',
              badgeColor: Color(0xFFFBC02D),
            ),
            DrawerEntry('AI Workspace', Icons.smart_toy_outlined),
            DrawerEntry('Learning Center', Icons.menu_book_outlined),
            DrawerEntry('Referral Program', Icons.card_giftcard_outlined),
          ]),
          const DrawerSection('System', [
            DrawerEntry('Search Center', Icons.search_rounded),
            DrawerEntry('Connected Apps', Icons.power_outlined),
            DrawerEntry('Downloads', Icons.download_outlined),
            DrawerEntry('Activity Logs', Icons.show_chart_rounded),
            DrawerEntry('Audit Logs', Icons.list_alt_rounded),
            DrawerEntry('System Status', Icons.monitor_heart_outlined),
            DrawerEntry(
              'Help Center',
              Icons.help_outline_rounded,
              route: Routes.support,
            ),
            DrawerEntry(
              'Support',
              Icons.support_agent_outlined,
              route: Routes.support,
            ),
            DrawerEntry(
              'Settings',
              Icons.settings_outlined,
              route: Routes.settings,
            ),
            DrawerEntry(
              'Security',
              Icons.security_outlined,
              route: Routes.securityCenter,
            ),
          ]),
        ];
      case UserRole.client:
        return [
          DrawerSection('Overview', [
            DrawerEntry(
              'Dashboard',
              Icons.dashboard_outlined,
              route: Routes.clientDashboard,
            ),
            DrawerEntry(
              'Analytics & Reports',
              Icons.bar_chart_rounded,
              route: Routes.clientDashboard,
            ), // Placeholder
            DrawerEntry(
              'Notifications',
              Icons.notifications_active_outlined,
              badge: unreadNotifications > 0 ? unreadNotifications : null,
            ),
          ]),
          const DrawerSection('Company', [
            DrawerEntry(
              'Company Profile',
              Icons.business_outlined,
              route: Routes.clientProfile,
            ),
            DrawerEntry('Verification', Icons.verified_user_outlined, badge: 2),
            DrawerEntry('Departments', Icons.account_balance_outlined),
            DrawerEntry('Teams', Icons.groups_outlined),
          ]),
          const DrawerSection('Projects', [
            DrawerEntry(
              'Projects',
              Icons.work_outline_rounded,
              route: Routes.clientProjects,
              badge: 12,
            ),
            DrawerEntry('Pipeline', Icons.view_kanban_outlined),
            DrawerEntry('Tasks', Icons.task_alt_outlined),
            DrawerEntry('Contracts', Icons.assignment_outlined),
          ]),
          const DrawerSection('Talent', [
            DrawerEntry(
              'Hire Freelancers',
              Icons.person_add_outlined,
              route: Routes.clientFreelancers,
            ),
            DrawerEntry(
              'Applications',
              Icons.inbox_outlined,
              route: Routes.clientApplications,
              badge: 10,
            ),
            DrawerEntry('Invitations', Icons.send_outlined),
            DrawerEntry('Shortlisted', Icons.favorite_border_rounded),
          ]),
          DrawerSection('Communication', [
            DrawerEntry(
              'Messages',
              Icons.chat_bubble_outline_rounded,
              route: Routes.messages,
              badge: unreadMessages > 0 ? unreadMessages : 8,
            ),
            DrawerEntry(
              'Meetings',
              Icons.event_outlined,
              route: Routes.meetings,
            ),
          ]),
          const DrawerSection('Finance', [
            DrawerEntry('Invoices', Icons.receipt_long_outlined),
            DrawerEntry(
              'Payments',
              Icons.payment_outlined,
              route: Routes.clientPayments,
            ),
            DrawerEntry(
              'Wallet',
              Icons.account_balance_wallet_outlined,
              route: Routes.wallet,
            ),
            DrawerEntry('Transactions', Icons.sync_alt_rounded),
            DrawerEntry(
              'Subscriptions',
              Icons.workspace_premium_outlined,
              route: Routes.subscriptionsManage,
            ),
          ]),
          const DrawerSection('Insights', [
            DrawerEntry('Freelancer Performance', Icons.insights_outlined),
            DrawerEntry('Reviews & Ratings', Icons.star_border_rounded),
            DrawerEntry(
              'Business Intelligence',
              Icons.lightbulb_outline_rounded,
              badgeText: 'Beta',
              badgeColor: Color(0xFFE53935),
            ),
          ]),
          const DrawerSection('Growth', [
            DrawerEntry(
              'AI Hiring Assistant',
              Icons.smart_toy_outlined,
              badgeText: 'New',
              badgeColor: Color(0xFFFBC02D),
            ),
            DrawerEntry('Referral Program', Icons.card_giftcard_outlined),
            DrawerEntry('Documents', Icons.description_outlined),
            DrawerEntry('Downloads', Icons.download_outlined),
          ]),
          const DrawerSection('System', [
            DrawerEntry('Notifications', Icons.notifications_outlined),
            DrawerEntry('Global Search', Icons.search_rounded),
            DrawerEntry(
              'AI Assistant',
              Icons.auto_awesome_outlined,
              badgeText: '⌘',
              badgeColor: Color(0xFFE53935),
            ),
            DrawerEntry(
              'Help Center',
              Icons.help_outline_rounded,
              route: Routes.support,
            ),
            DrawerEntry('Support', Icons.support_agent_outlined),
            DrawerEntry('Activity Log', Icons.show_chart_rounded),
            DrawerEntry('Audit Log', Icons.list_alt_rounded),
            DrawerEntry(
              'Security',
              Icons.security_outlined,
              route: Routes.securityCenter,
            ),
            DrawerEntry('Roles & Permissions', Icons.manage_accounts_outlined),
            DrawerEntry('Team Access', Icons.people_outline_rounded),
            DrawerEntry('Connected Apps', Icons.power_outlined),
            DrawerEntry('API Keys', Icons.api_rounded),
            DrawerEntry('Component Library', Icons.widgets_outlined),
            DrawerEntry(
              'Settings',
              Icons.settings_outlined,
              route: Routes.settings,
            ),
          ]),
        ];
      case UserRole.investor:
        return [
          DrawerSection('Overview', [
            DrawerEntry(
              'Dashboard',
              Icons.dashboard_outlined,
              route: Routes.investorDashboard,
            ),
            DrawerEntry(
              'Analytics',
              Icons.insights_outlined,
              route: Routes.investorAnalytics,
            ),
            DrawerEntry(
              'Notifications',
              Icons.notifications_none_rounded,
              route: Routes.notifications,
              badge: unreadNotifications > 0 ? unreadNotifications : null,
            ),
          ]),
          const DrawerSection('Deal Flow', [
            DrawerEntry(
              'Startup Discovery',
              Icons.travel_explore_rounded,
              route: Routes.investorStartups,
            ),
            DrawerEntry(
              'Opportunities',
              Icons.handshake_outlined,
              route: Routes.investorDeals,
            ),
            DrawerEntry(
              'Due Diligence',
              Icons.fact_check_outlined,
              route: Routes.investorDueDiligence,
            ),
            DrawerEntry(
              'Offers',
              Icons.local_offer_outlined,
              route: Routes.investorOffers,
            ),
            DrawerEntry(
              'Watchlist',
              Icons.bookmark_border_rounded,
              route: Routes.bookmarks,
            ),
          ]),
          const DrawerSection('Portfolio', [
            DrawerEntry(
              'Investments',
              Icons.pie_chart_outline_rounded,
              route: Routes.investorPortfolio,
            ),
            DrawerEntry(
              'Transactions',
              Icons.swap_horiz_rounded,
              route: Routes.investorTransactions,
            ),
            DrawerEntry(
              'Reports',
              Icons.assessment_outlined,
              route: Routes.investorReports,
            ),
          ]),
          DrawerSection('Communication', [
            DrawerEntry(
              'Messages',
              Icons.chat_bubble_outline_rounded,
              route: Routes.messages,
              badge: unreadMessages > 0 ? unreadMessages : null,
            ),
            const DrawerEntry(
              'Meetings',
              Icons.video_camera_front_outlined,
              route: Routes.meetings,
            ),
            const DrawerEntry(
              'Calendar',
              Icons.calendar_month_outlined,
              route: Routes.calendar,
            ),
          ]),
          const DrawerSection('Documents', [
            DrawerEntry(
              'Documents',
              Icons.description_outlined,
              route: Routes.investorDocuments,
            ),
          ]),
          const DrawerSection('Finance', [
            DrawerEntry(
              'Wallet',
              Icons.account_balance_wallet_outlined,
              route: Routes.wallet,
            ),
            DrawerEntry(
              'Subscription',
              Icons.workspace_premium_outlined,
              route: Routes.subscriptionsManage,
            ),
          ]),
          const DrawerSection('Account', [
            DrawerEntry(
              'Profile',
              Icons.person_outline_rounded,
              route: Routes.investorProfile,
            ),
            DrawerEntry(
              'Settings',
              Icons.settings_outlined,
              route: Routes.settings,
            ),
            DrawerEntry(
              'Security',
              Icons.shield_outlined,
              route: Routes.securityCenter,
            ),
            DrawerEntry(
              'Support',
              Icons.help_outline_rounded,
              route: Routes.support,
            ),
          ]),
        ];
      case UserRole.founder:
        return [
          DrawerSection('Overview', [
            DrawerEntry(
              'Dashboard',
              Icons.dashboard_outlined,
              route: Routes.founderDashboard,
            ),
            DrawerEntry(
              'Analytics & Reports',
              Icons.bar_chart_rounded,
              route: Routes.founderAnalytics,
            ),
            DrawerEntry(
              'Notifications',
              Icons.notifications_active_outlined,
              route: Routes.notifications,
              badge: unreadNotifications > 0 ? unreadNotifications : null,
            ),
          ]),
          const DrawerSection('Startup', [
            DrawerEntry(
              'My Startup',
              Icons.rocket_launch_outlined,
              route: Routes.founderListStartup,
            ),
            DrawerEntry(
              'Pitch Deck',
              Icons.slideshow_outlined,
              route: Routes.founderPitchDeck,
            ),
            DrawerEntry(
              'Business Plan',
              Icons.description_outlined,
              route: Routes.founderBusinessPlan,
            ),
            DrawerEntry(
              'Team Members',
              Icons.groups_outlined,
              route: Routes.founderTeam,
            ),
            DrawerEntry(
              'Hiring',
              Icons.person_add_alt_1_outlined,
              route: Routes.founderHiring,
            ),
          ]),
          const DrawerSection('Fundraising', [
            DrawerEntry(
              'Investors',
              Icons.trending_up_rounded,
              route: Routes.founderInvestors,
            ),
            DrawerEntry(
              'Funding',
              Icons.savings_outlined,
              route: Routes.founderFunding,
            ),
          ]),
          const DrawerSection('Assets & Documents', [
            DrawerEntry(
              'Media & Documents',
              Icons.perm_media_outlined,
              route: Routes.founderMedia,
            ),
          ]),
          DrawerSection('Communication', [
            DrawerEntry(
              'Messages',
              Icons.chat_bubble_outline_rounded,
              route: Routes.messages,
              badge: unreadMessages > 0 ? unreadMessages : null,
            ),
            DrawerEntry(
              'Meetings',
              Icons.event_outlined,
              route: Routes.meetings,
            ),
          ]),
          const DrawerSection('Finance', [
            DrawerEntry(
              'Wallet',
              Icons.account_balance_wallet_outlined,
              route: Routes.wallet,
            ),
            DrawerEntry(
              'Subscriptions',
              Icons.workspace_premium_outlined,
              route: Routes.subscriptionsManage,
            ),
          ]),
          const DrawerSection('Account', [
            DrawerEntry(
              'Founder Profile',
              Icons.person_outline_rounded,
              route: Routes.founderProfile,
            ),
            DrawerEntry(
              'Settings',
              Icons.settings_outlined,
              route: Routes.settings,
            ),
            DrawerEntry(
              'Security Center',
              Icons.shield_outlined,
              route: Routes.securityCenter,
            ),
            DrawerEntry(
              'Support',
              Icons.help_outline_rounded,
              route: Routes.support,
            ),
          ]),
        ];
    }
  }
}

class _FounderDrawer extends StatelessWidget {
  const _FounderDrawer({
    required this.user,
    required this.sections,
    required this.currentPath,
    required this.workspaceLabel,
    required this.role,
  });

  final AppUser? user;
  final List<DrawerSection> sections;
  final String currentPath;
  final String workspaceLabel;
  final UserRole role;

  Future<void> _refresh(BuildContext context) async {
    context.read<AuthBloc>().add(const AuthRefreshUser());
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await AppConfirmDialog.show(
      context,
      title: 'Log out?',
      message: 'You will need to sign in again to access your account.',
      confirmLabel: 'Log Out',
      isDestructive: true,
      icon: Icons.logout_rounded,
    );
    if (confirm && context.mounted) {
      context.read<AuthBloc>().add(const AuthLoggedOut());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Drawer(
      width: 288,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(),
      child: SafeArea(
        child: Column(
          children: [
            _FounderBrandHeader(
              workspaceLabel: workspaceLabel,
              onRefresh: () => _refresh(context),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _refresh(context),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.md,
                    AppSizes.sm,
                    AppSizes.md,
                    AppSizes.md,
                  ),
                  children: [
                    _FounderIdentityCard(user: user, role: role),
                    AppSizes.vGapMd,
                    for (final section in sections)
                      _FounderDrawerSection(
                        section: section,
                        currentPath: currentPath,
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSizes.sm),
                      child: Divider(color: colors.outlineVariant),
                    ),
                    _FounderFooterAction(
                      label: context.tr('Log Out'),
                      icon: Icons.logout_rounded,
                      color: colors.error,
                      onTap: () => _logout(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FounderBrandHeader extends StatelessWidget {
  const _FounderBrandHeader({
    required this.workspaceLabel,
    required this.onRefresh,
  });

  final String workspaceLabel;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.fromLTRB(
        AppSizes.md,
        AppSizes.sm,
        AppSizes.sm,
        AppSizes.sm,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outlineVariant)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: Text(
              'G',
              style: context.text.labelLarge?.copyWith(
                color: colors.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          AppSizes.hGapSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Go Experts',
                  style: context.text.labelLarge?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  workspaceLabel,
                  style: context.text.labelSmall?.copyWith(
                    color: colors.primary,
                    fontSize: 9,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: context.tr('Refresh profile'),
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
            color: colors.onSurfaceVariant,
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}

class _FounderIdentityCard extends StatelessWidget {
  const _FounderIdentityCard({required this.user, required this.role});

  final AppUser? user;
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final name = user?.fullName.trim();
    final displayName = name == null || name.isEmpty
        ? context.tr(
            role == UserRole.investor
                ? 'Investor'
                : role == UserRole.freelancer
                ? 'Freelancer'
                : 'Your startup',
          )
        : name;
    final completion = (user?.profileCompletion ?? 0).clamp(0, 100);
    final plan = AppDrawer._planLabel(user?.subscriptionPlan);
    final status = user?.subscriptionStatus?.trim();

    final healthLabel = completion >= 80
        ? context.tr(
            role == UserRole.investor
                ? 'Investor profile ready'
                : role == UserRole.freelancer
                ? 'Profile complete'
                : 'Startup ready',
          )
        : completion >= 50
        ? context.tr(
            role == UserRole.investor
                ? 'Profile taking shape'
                : role == UserRole.freelancer
                ? 'Building momentum'
                : 'Building momentum',
          )
        : context.tr('Complete your profile');

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(name: displayName, imageUrl: user?.avatarUrl, size: 44),
              AppSizes.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodyMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.headline?.trim().isNotEmpty == true
                          ? user!.headline!.trim()
                          : context.tr(
                              role == UserRole.investor
                                  ? 'Investor workspace'
                                  : role == UserRole.freelancer
                                  ? 'Freelancer workspace'
                                  : 'Founder workspace',
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSizes.vGapMd,
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.xs,
            children: [
              _FounderMetaLabel(
                icon: Icons.workspace_premium_outlined,
                label: role == UserRole.freelancer
                    ? 'Job Success: 95%'
                    : context.tr(plan),
                emphasize: role == UserRole.freelancer,
              ),
              if (role != UserRole.freelancer &&
                  status != null &&
                  status.isNotEmpty)
                _FounderMetaLabel(
                  icon: Icons.circle,
                  label: context.tr(status),
                  emphasize: status.toLowerCase() == 'active',
                ),
            ],
          ),
          AppSizes.vGapMd,
          Row(
            children: [
              Expanded(
                child: Text(
                  healthLabel,
                  style: context.text.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$completion%',
                style: context.text.labelSmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          AppSizes.vGapSm,
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            child: LinearProgressIndicator(
              value: completion / 100,
              minHeight: 5,
              color: colors.primary,
              backgroundColor: colors.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}

class _FounderMetaLabel extends StatelessWidget {
  const _FounderMetaLabel({
    required this.icon,
    required this.label,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = emphasize ? AppColors.success : colors.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        AppSizes.hGapXs,
        Text(
          label,
          style: context.text.labelSmall?.copyWith(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _FounderDrawerSection extends StatelessWidget {
  const _FounderDrawerSection({
    required this.section,
    required this.currentPath,
  });

  final DrawerSection section;
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.sm),
        child: ExpansionTile(
          initiallyExpanded:
              section.entries.any(
                (e) => e.route != null && currentPath.startsWith(e.route!),
              ) ||
              section.title == 'Overview', // Keep overview open by default
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
          title: Text(
            context.tr(section.title).toUpperCase(),
            style: context.text.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontSize: 9,
              letterSpacing: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          iconColor: colors.onSurfaceVariant,
          collapsedIconColor: colors.onSurfaceVariant,
          childrenPadding: EdgeInsets.zero,
          children: [
            for (final entry in section.entries)
              _DrawerMenuTile(
                entry: entry,
                currentPath: currentPath,
                founderStyle: true,
                onTap: () {
                  Navigator.of(context).pop();
                  if (entry.onTap != null) {
                    entry.onTap!();
                  } else if (entry.route != null) {
                    context.push(entry.route!);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _FounderFooterAction extends StatelessWidget {
  const _FounderFooterAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 44,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
      leading: Icon(icon, color: color, size: 19),
      title: Text(
        label,
        style: context.text.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _DrawerMenuTile extends StatelessWidget {
  const _DrawerMenuTile({
    required this.entry,
    required this.currentPath,
    this.dense = false,
    this.founderStyle = false,
    this.contentPadding,
    this.onTap,
  });

  final DrawerEntry entry;
  final String currentPath;
  final bool dense;
  final bool founderStyle;
  final EdgeInsetsGeometry? contentPadding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isSelected =
        entry.route != null && currentPath.startsWith(entry.route!);

    final bgColor = isSelected
        ? colors.primary.withValues(alpha: 0.1)
        : Colors.transparent;
    final fgColor = isSelected ? colors.primary : colors.onSurfaceVariant;
    final fontWeight = isSelected ? FontWeight.w700 : FontWeight.w500;

    return Container(
      constraints: BoxConstraints(minHeight: founderStyle ? 44 : 0),
      margin: EdgeInsets.symmetric(
        horizontal: founderStyle ? 0 : AppSizes.md,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(
          founderStyle ? AppSizes.radiusSm : AppSizes.radiusMd,
        ),
        border: founderStyle && isSelected
            ? Border(left: BorderSide(color: colors.primary, width: 3))
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          dense: dense || founderStyle,
          minTileHeight: founderStyle ? 44 : null,
          minLeadingWidth: founderStyle ? 24 : null,
          horizontalTitleGap: founderStyle ? AppSizes.sm : null,
          contentPadding:
              contentPadding ??
              EdgeInsets.symmetric(
                horizontal: founderStyle ? AppSizes.md : AppSizes.md,
              ),
          leading: Icon(
            entry.icon,
            color: fgColor,
            size: founderStyle ? 19 : 20,
          ),
          title: Text(
            context.tr(entry.label),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodyMedium?.copyWith(
              color: fgColor,
              fontWeight: fontWeight,
              fontSize: founderStyle ? 13 : null,
            ),
          ),
          trailing: _buildBadge(context, colors),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget? _buildBadge(BuildContext context, ColorScheme colors) {
    if (entry.badge != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: entry.badgeColor ?? colors.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          entry.badge.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (entry.badgeText != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: entry.badgeColor ?? colors.secondary,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          entry.badgeText!,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    return null;
  }
}
