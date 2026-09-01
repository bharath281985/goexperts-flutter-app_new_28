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

    return _FounderDrawer(
      user: user,
      sections: _sections(role),
      currentPath: currentPath,
      workspaceLabel: switch (role) {
        UserRole.investor => 'INVESTOR OS',
        UserRole.freelancer => 'FREELANCER HQ',
        UserRole.founder => 'FOUNDER OS',
        UserRole.client => 'CLIENT PORTAL',
      },
      role: role,
    );
  }

  /// Consolidated master drawer sections list without role duplication.
  List<DrawerSection> _sections([UserRole? userRole]) {
    final effectiveRole = userRole ?? role;
    return [
      DrawerSection('Overview', [
        DrawerEntry(
          'Dashboard',
          Icons.dashboard_outlined,
          route: switch (effectiveRole) {
            UserRole.freelancer => Routes.freelancerDashboard,
            UserRole.client => Routes.clientDashboard,
            UserRole.investor => Routes.investorDashboard,
            UserRole.founder => Routes.founderDashboard,
          },
        ),
        DrawerEntry(
          'Analytics',
          Icons.insights_outlined,
          route: switch (effectiveRole) {
            UserRole.freelancer => Routes.freelancerAnalytics,
            UserRole.client => Routes.clientAnalytics,
            UserRole.investor => Routes.investorAnalytics,
            UserRole.founder => Routes.founderAnalytics,
          },
        ),
      ]),
       DrawerSection('Profile & Identity', [
        DrawerEntry(
          'My Profile',
          Icons.person_outline_rounded,
          route: Routes.profile,
        ),
        DrawerEntry(
          'Verification',
          Icons.verified_user_outlined,
          route: Routes.verification,
        ),
        DrawerEntry(
          'Portfolio',
          Icons.perm_media_outlined,
          route: switch (effectiveRole) {
            UserRole.freelancer => Routes.freelancerPortfolioPage,
            UserRole.client => Routes.clientProjects,
            UserRole.investor => Routes.investorPortfolio,
            UserRole.founder => Routes.founderStartup,
          },
        ),
        if (effectiveRole == UserRole.freelancer) ...[
          DrawerEntry(
            'Experience',
            Icons.timeline_outlined,
            route: Routes.freelancerExperience,
          ),
          DrawerEntry(
            'Education',
            Icons.school_outlined,
            route: Routes.freelancerEducation,
          ),
          DrawerEntry(
            'Certificates',
            Icons.workspace_premium_outlined,
            route: Routes.freelancerCertificates,
          ),
        ],
      ]),
      DrawerSection('Projects & Tasks', [
        DrawerEntry(
          'Projects/Tasks',
          Icons.work_outline_rounded,
          route: switch (effectiveRole) {
            UserRole.freelancer => Routes.freelancerProjects,
            UserRole.client => Routes.clientProjects,
            UserRole.investor => Routes.investorProjects,
            UserRole.founder => Routes.founderProjects,
          },
        ),
        DrawerEntry(
          'Proposals',
          Icons.send_outlined,
          route: switch (effectiveRole) {
            UserRole.freelancer => Routes.freelancerProposals,
            UserRole.client => Routes.clientProposals,
            UserRole.investor => Routes.investorProposals,
            UserRole.founder => Routes.founderProposals,
          },
        ),
        DrawerEntry(
          'Projects Tracking',
          Icons.view_kanban_outlined,
          route: switch (effectiveRole) {
            UserRole.freelancer => Routes.freelancerTasks,
            UserRole.client => Routes.clientTasks,
            UserRole.investor => Routes.investorTasks,
            UserRole.founder => Routes.founderTasks,
          },
        ),
        DrawerEntry(
          'Contracts',
          Icons.assignment_outlined,
          route: switch (effectiveRole) {
            UserRole.freelancer => Routes.freelancerContracts,
            UserRole.client => Routes.clientContracts,
            UserRole.investor => Routes.investorContracts,
            UserRole.founder => Routes.founderContracts,
          },
        ),
      ]),
      DrawerSection('Talent & Teams', [
        DrawerEntry(
          'Hire Freelancers',
          Icons.person_add_outlined,
          route: switch (effectiveRole) {
            UserRole.freelancer => Routes.freelancerFreelancers,
            UserRole.client => Routes.clientFreelancers,
            UserRole.investor => Routes.investorFreelancers,
            UserRole.founder => Routes.founderFreelancers,
          },
        ),
        DrawerEntry(
          'Applications',
          Icons.inbox_outlined,
          route: switch (effectiveRole) {
            UserRole.freelancer => Routes.freelancerApplications,
            UserRole.client => Routes.clientApplications,
            UserRole.investor => Routes.investorApplications,
            UserRole.founder => Routes.founderApplications,
          },
        ),
        DrawerEntry(
          'Invitations',
          Icons.send_outlined,
          route: Routes.invitations,
        ),
        DrawerEntry(
          'Teams',
          Icons.groups_outlined,
          route: switch (effectiveRole) {
            UserRole.freelancer => Routes.freelancerTeams,
            UserRole.client => Routes.clientTeams,
            UserRole.investor => Routes.investorTeams,
            UserRole.founder => Routes.founderTeams,
          },
        ),
      ]),
      DrawerSection('Startup & Deals', [
        DrawerEntry(
          'My Startup',
          Icons.rocket_launch_outlined,
          route: switch (effectiveRole) {
            UserRole.freelancer => Routes.freelancerCreateStartup,
            UserRole.client => Routes.clientCreateStartup,
            UserRole.investor => Routes.investorCreateStartup,
            UserRole.founder => Routes.founderStartup,
          },
        ),
        DrawerEntry(
          'Startup Discovery',
          Icons.travel_explore_rounded,
          route: switch (effectiveRole) {
            UserRole.freelancer => Routes.freelancerStartups,
            UserRole.client => Routes.clientStartups,
            UserRole.investor => Routes.investorStartups,
            UserRole.founder => Routes.founderStartups,
          },
        ),
        DrawerEntry(
          'Opportunities',
          Icons.handshake_outlined,
          route: switch (effectiveRole) {
            UserRole.freelancer => Routes.freelancerDeals,
            UserRole.client => Routes.clientDeals,
            UserRole.investor => Routes.investorDeals,
            UserRole.founder => Routes.founderDeals,
          },
        ),
        DrawerEntry(
          'Offers',
          Icons.local_offer_outlined,
          route: switch (effectiveRole) {
            UserRole.freelancer => Routes.freelancerOffers,
            UserRole.client => Routes.clientOffers,
            UserRole.investor => Routes.investorOffers,
            UserRole.founder => Routes.founderOffers,
          },
        ),
        DrawerEntry(
          'Pitch Deck',
          Icons.slideshow_outlined,
          route: switch (effectiveRole) {
            UserRole.freelancer => Routes.freelancerPitchDeck,
            UserRole.client => Routes.clientPitchDeck,
            UserRole.investor => Routes.investorPitchDeck,
            UserRole.founder => Routes.founderPitchDeck,
          },
        ),
        DrawerEntry(
          'Business Plan',
          Icons.description_outlined,
          route: switch (effectiveRole) {
            UserRole.freelancer => Routes.freelancerBusinessPlan,
            UserRole.client => Routes.clientBusinessPlan,
            UserRole.investor => Routes.investorBusinessPlan,
            UserRole.founder => Routes.founderBusinessPlan,
          },
        ),
        DrawerEntry(
          'Investors',
          Icons.trending_up_rounded,
          route: switch (effectiveRole) {
            UserRole.freelancer => Routes.freelancerInvestors,
            UserRole.client => Routes.clientInvestors,
            UserRole.investor => Routes.investorInvestors,
            UserRole.founder => Routes.founderInvestors,
          },
        ),
        DrawerEntry(
          'Funding',
          Icons.savings_outlined,
          route: switch (effectiveRole) {
            UserRole.freelancer => Routes.freelancerFunding,
            UserRole.client => Routes.clientFunding,
            UserRole.investor => Routes.investorFunding,
            UserRole.founder => Routes.founderFunding,
          },
        ),
        DrawerEntry(
          'Investments / Portfolio',
          Icons.pie_chart_outline_rounded,
          route: switch (effectiveRole) {
            UserRole.freelancer => Routes.freelancerPortfolioPage,
            UserRole.client => Routes.clientPortfolioPage,
            UserRole.investor => Routes.investorPortfolio,
            UserRole.founder => Routes.founderPortfolioPage,
          },
        ),
        DrawerEntry(
          'Reports',
          Icons.assessment_outlined,
          route: switch (effectiveRole) {
            UserRole.freelancer => Routes.freelancerReports,
            UserRole.client => Routes.clientReports,
            UserRole.investor => Routes.investorReports,
            UserRole.founder => Routes.founderReports,
          },
        ),
      ]),
      DrawerSection('Communication', [
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
          'Watchlist',
          Icons.bookmark_border_rounded,
          route: Routes.bookmarks,
        ),
        DrawerEntry(
          'Messages',
          Icons.chat_bubble_outline_rounded,
          route: Routes.messages,
          badge: unreadMessages > 0 ? unreadMessages : null,
        ),
        DrawerEntry(
          'Notifications',
          Icons.notifications_none_rounded,
          route: Routes.notifications,
          badge: unreadNotifications > 0 ? unreadNotifications : null,
        ),
        DrawerEntry(
          'Reviews',
          Icons.star_border_rounded,
          route: Routes.myReviews,
        ),
      ]),
      DrawerSection('Finance', [
        DrawerEntry(
          'Subscriptions',
          Icons.workspace_premium_outlined,
          route: Routes.subscriptionsManage,
        ),
        DrawerEntry(
          'Documents',
          Icons.description_outlined,
          route: switch (effectiveRole) {
            UserRole.investor => Routes.investorDocuments,
            UserRole.founder => Routes.founderPitchDeck,
            UserRole.freelancer => Routes.freelancerCertificates,
            UserRole.client => Routes.clientReports,
          },
        ),
      ]),
      const DrawerSection('Growth', [
        DrawerEntry(
          'Referral Program',
          Icons.card_giftcard_outlined,
          route: Routes.referrals,
        ),
      ]),
      DrawerSection('System', [
        DrawerEntry(
          'Support',
          Icons.support_agent_outlined,
          route: Routes.support,
        ),
        DrawerEntry(
          'Security',
          Icons.security_outlined,
          route: Routes.changePassword,
        ),
        DrawerEntry(
          'Team Access',
          Icons.people_outline_rounded,
          route: switch (effectiveRole) {
            UserRole.client => Routes.clientTeams,
            UserRole.founder => Routes.founderTeam,
            UserRole.investor => Routes.investorTeams,
            UserRole.freelancer => Routes.freelancerTeams,
          },
        ),
      ]),
    ];
  }

  /*
  List<DrawerSection> _sections1(UserRole role) {
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
              route: Routes.freelancerAnalytics,
            ),
          ]),
          const DrawerSection('Profile', [
            DrawerEntry(
              'My Profile',
              Icons.person_outline_rounded,
              route: Routes.freelancerEditProfile,
            ),
            DrawerEntry(
              'Professional Details',
              Icons.work_outline_rounded,
              route: Routes.freelancerProfessionalDetails,
            ),
            DrawerEntry(
              'Verification',
              Icons.verified_user_outlined,
              route: Routes.freelancerVerification,
            ),
            DrawerEntry(
              'Portfolio',
              Icons.perm_media_outlined,
              route: Routes.freelancerPortfolioPage,
            ),
            DrawerEntry(
              'Experience',
              Icons.timeline_outlined,
              route: Routes.freelancerExperience,
            ),
            DrawerEntry(
              'Education',
              Icons.school_outlined,
              route: Routes.freelancerEducation,
            ),
            DrawerEntry(
              'Certificates',
              Icons.workspace_premium_outlined,
              route: Routes.freelancerCertificates,
            ),
          ]),
          DrawerSection('Work', [
            DrawerEntry(
              'Projects',
              Icons.work_outline_rounded,
              route: Routes.freelancerProjects,
            ),
            DrawerEntry(
              'Proposals',
              Icons.send_outlined,
              route: Routes.freelancerProposals,
            ),
            DrawerEntry(
              'Tracking',
              Icons.art_track_outlined,
              route: Routes.freelancerContracts,
            ),
          ]),
          const DrawerSection('Projects/Tasks', [
            DrawerEntry(
              'Projects/Tasks',
              Icons.work_outline_rounded,
              route: Routes.freelancerProjects,
            ),
            DrawerEntry(
              'Projects/Tasks Tracking',
              Icons.view_kanban_outlined,
            ),
            DrawerEntry(
              'Projects/Tasks Contracts',
              Icons.assignment_outlined,
            ),
          ]),
          DrawerSection('Communication', [
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
            DrawerEntry(
              'Notifications',
              Icons.notifications_none_rounded,
              route: Routes.notifications,
              badge: unreadNotifications > 0 ? unreadNotifications : null,
            ),
            DrawerEntry(
              'Reviews',
              Icons.star_border_rounded,
              route: Routes.freelancerReviews,
            ),
            DrawerEntry('Tasks', Icons.task_alt_outlined),
          ]),
          const DrawerSection('Finance', [
            DrawerEntry(
              'Subscriptions',
              Icons.workspace_premium_outlined,
              route: Routes.subscriptionsManage,
            ),
          ]),
          const DrawerSection('Growth', [
            DrawerEntry(
              'Referral Program',
              Icons.card_giftcard_outlined,
              route: Routes.referrals,
            ),
          ]),
          const DrawerSection('System', [
            DrawerEntry(
              'Support',
              Icons.support_agent_outlined,
              route: Routes.support,
            ),
            DrawerEntry(
              'Security',
              Icons.security_outlined,
              route: Routes.changePassword,
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
              route: Routes.clientAnalytics,
            ),
          ]),
          const DrawerSection('Company', [
            DrawerEntry(
              'Company Profile',
              Icons.business_outlined,
              route: Routes.clientProfile,
            ),
            DrawerEntry(
              'Verification',
              Icons.verified_user_outlined,
              route: Routes.clientVerification,
            ),
            DrawerEntry(
              'Teams',
              Icons.groups_outlined,
              route: Routes.clientTeams,
            ),
          ]),
          const DrawerSection('Projects', [
            DrawerEntry(
              'Projects',
              Icons.work_outline_rounded,
              route: Routes.clientProjects,
            ),
            DrawerEntry(
              'Projects Tracking',
              Icons.view_kanban_outlined,
            ),
            DrawerEntry(
              'Tasks',
              Icons.task_alt_outlined,
              route: Routes.clientTasks,
            ),
            DrawerEntry(
              'Contracts',
              Icons.assignment_outlined,
            ),
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
            ),
            DrawerEntry(
              'Invitations',
              Icons.send_outlined,
              route: Routes.invitations,
            ),
          ]),
          DrawerSection('Communication', [
            DrawerEntry(
              'Notifications',
              Icons.notifications_active_outlined,
              badge: unreadNotifications > 0 ? unreadNotifications : null,
            ),
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
              'Subscriptions',
              Icons.workspace_premium_outlined,
              route: Routes.subscriptionsManage,
            ),
          ]),
          const DrawerSection('Insights', [
            DrawerEntry(
              'Insights',
              Icons.insights_outlined,
              route: Routes.clientReports,
            ),
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
              'Referral Program',
              Icons.card_giftcard_outlined,
              route: Routes.referrals,
            ),
          ]),
          const DrawerSection('System', [
            DrawerEntry(
              'Support',
              Icons.support_agent_outlined,
              route: Routes.support,
            ),
            DrawerEntry(
              'Security',
              Icons.security_outlined,
              route: Routes.changePassword,
            ),
            DrawerEntry('Team Access', Icons.people_outline_rounded),
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
              'Reports',
              Icons.assessment_outlined,
              route: Routes.investorReports,
            ),
          ]),
          DrawerSection('Communication', [
            DrawerEntry(
              'Notifications',
              Icons.notifications_none_rounded,
              route: Routes.notifications,
              badge: unreadNotifications > 0 ? unreadNotifications : null,
            ),
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
          const DrawerSection('Finance', [
            DrawerEntry(
              'Documents',
              Icons.description_outlined,
              route: Routes.investorDocuments,
            ),
            DrawerEntry(
              'Subscription',
              Icons.workspace_premium_outlined,
              route: Routes.subscriptionsManage,
            ),
          ]),
          const DrawerSection('Growth', [
            DrawerEntry(
              'Referral Program',
              Icons.card_giftcard_outlined,
              route: Routes.referrals,
            ),
          ]),
          const DrawerSection('Account', [
            DrawerEntry(
              'Profile',
              Icons.person_outline_rounded,
              route: Routes.investorProfile,
            ),
            DrawerEntry(
              'Verification',
              Icons.verified_user_outlined,
              route: Routes.investorVerification,
            ),
            DrawerEntry(
              'Security',
              Icons.shield_outlined,
              route: Routes.changePassword,
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
          const DrawerSection('Assets & Documents', []),
          DrawerSection('Communication', [
            DrawerEntry(
              'Notifications',
              Icons.notifications_active_outlined,
              route: Routes.notifications,
              badge: unreadNotifications > 0 ? unreadNotifications : null,
            ),
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
              'Subscriptions',
              Icons.workspace_premium_outlined,
              route: Routes.subscriptionsManage,
            ),
          ]),
          const DrawerSection('Growth', [
            DrawerEntry(
              'Referral Program',
              Icons.card_giftcard_outlined,
              route: Routes.referrals,
            ),
          ]),
          const DrawerSection('Account', [
            DrawerEntry(
              'Founder Profile',
              Icons.person_outline_rounded,
              route: Routes.founderProfile,
            ),
            DrawerEntry(
              'Verification',
              Icons.verified_user_outlined,
              route: Routes.founderVerification,
            ),
            DrawerEntry(
              'Security Center',
              Icons.shield_outlined,
              route: Routes.changePassword,
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
  */
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
      _showLogoutLoading(context);
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSizes.md,
              right: AppSizes.md,
              bottom: AppSizes.sm,
            ),
            child: Text(
              context.tr(section.title).toUpperCase(),
              style: context.text.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
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
                } else {
                  context.showSnack('Coming soon');
                }
              },
            ),
        ],
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
        ? colors.onSurface.withValues(alpha: 0.08)
        : Colors.transparent;
    final fgColor = isSelected ? colors.onSurface : colors.onSurfaceVariant;
    final fontWeight = isSelected ? FontWeight.w600 : FontWeight.w500;

    return Container(
      constraints: BoxConstraints(minHeight: founderStyle ? 44 : 0),
      margin: EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
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

void _showLogoutLoading(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: false,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
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
}
