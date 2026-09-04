import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/constants/app_assets.dart';
import '../../app/constants/app_colors.dart';
import '../../app/constants/app_sizes.dart';
import '../../app/router/route_names.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../dashboard/dashboard_cubit.dart';
import '../extensions/context_extensions.dart';
import '../utils/enums.dart';
import 'app_avatar.dart';
import 'app_confirm_dialog.dart';
import 'gradient_icon.dart';

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
    this.activeRoute,
    this.onTabSelected,
    this.unreadNotifications = 0,
    this.unreadMessages = 0,
  });

  final UserRole role;
  final String? activeRoute;
  final ValueChanged<int>? onTabSelected;
  final int unreadNotifications;
  final int unreadMessages;

  /// Remembers the last active route selected in the drawer across navigations.
  static String? _lastSelectedRoute;

  static void clearLastSelectedRoute() {
    _lastSelectedRoute = null;
  }

  static void setLastSelectedRoute(String route) {
    _lastSelectedRoute = route;
  }

  static final _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  static (String, Color) _resolveKycBadge(dynamic user, Map<String, dynamic> data) {
    final rawKyc = (data['kycStatus'] ?? data['verificationStatus'] ?? '').toString().toUpperCase();
    final missingCount = data['verificationMissingCount'] ?? data['missingCount'] ?? (data['missing'] is List ? (data['missing'] as List).length : null);
    final missing = missingCount is num ? missingCount.toInt() : (int.tryParse(missingCount?.toString() ?? '') ?? 0);
    final isApproved = (rawKyc == 'APPROVED' || rawKyc == 'VERIFIED');

    // Only mark as Verified if approved AND no documents are missing
    if (isApproved && missing == 0) {
      return ('Verified', const Color(0xFF10B981));
    }
    if (data['accountVerified'] == true && missing == 0 && rawKyc != 'MISSING' && rawKyc != 'NOT_SUBMITTED' && rawKyc.isNotEmpty) {
      return ('Verified', const Color(0xFF10B981));
    }
    if (rawKyc == 'PENDING' || rawKyc == 'UNDER_REVIEW' || rawKyc == 'IN_REVIEW') {
      return ('Pending', const Color(0xFFF59E0B));
    }
    if (rawKyc == 'REJECTED' || rawKyc == 'ACTION_REQUIRED') {
      return ('Action Req', const Color(0xFFEF4444));
    }
    return ('Not Verified', const Color(0xFFEF4444));
  }

  static (String, Color) _resolvePlanBadge(dynamic user, Map<String, dynamic> data) {
    String planName = (data['subscription']?['planName'] ??
        data['planName'] ??
        user?.subscriptionPlan ??
        '').toString().trim();

    if (planName.isEmpty || _uuidPattern.hasMatch(planName) || planName.toLowerCase() == 'null' || planName.toLowerCase() == 'none') {
      final isSubscribed = user?.serverHasSubscription == true ||
          (user?.subscriptionStatus?.toString().toLowerCase() == 'active');
      if (!isSubscribed) {
        return ('Not Verified', const Color(0xFFEF4444)); // Not Verified red badge when subscription is null
      }
      planName = 'Pro';
    }

    final clean = planName.toLowerCase();
    if (clean.contains('gold') || clean.contains('vip') || clean.contains('enterprise') || clean.contains('diamond')) {
      final label = planName.replaceAll(RegExp(r'\s+plan', caseSensitive: false), '').trim();
      return (label.isEmpty ? 'Gold' : label, const Color(0xFFD97706)); // Gold
    }
    if (clean.contains('pro') || clean.contains('premium') || clean.contains('paid') || clean.contains('plus') || clean.contains('growth')) {
      final label = planName.replaceAll(RegExp(r'\s+plan', caseSensitive: false), '').trim();
      return (label.isEmpty ? 'Pro' : label, const Color(0xFF8B5CF6)); // Pro purple
    }
    if (clean.contains('starter') || clean.contains('basic')) {
      final label = planName.replaceAll(RegExp(r'\s+plan', caseSensitive: false), '').trim();
      return (label.isEmpty ? 'Starter' : label, const Color(0xFF3B82F6)); // Blue
    }
    if (clean.contains('free')) {
      return ('Free', const Color(0xFFEAB308)); // Yellow Free badge
    }
    return ('Not Verified', const Color(0xFFEF4444));
  }

  @override
  Widget build(BuildContext context) {
    final pathFromUri = GoRouterState.of(context).uri.path;
    final currentPath = _lastSelectedRoute ?? activeRoute ?? pathFromUri;
    final user = context.select((AuthBloc b) => b.state.user);
    Map<String, dynamic> dashboardData = const {};
    try {
      final cubit = context.read<DashboardCubit?>();
      if (cubit != null) {
        dashboardData = {
          ...cubit.state.dashboardData,
          'kycStatus': cubit.state.kycStatus,
          'verificationMissingCount': cubit.state.verificationMissingCount,
          'accountVerified': cubit.state.accountVerified,
        };
      }
    } catch (_) {}

    return _FounderDrawer(
      user: user,
      sections: _sections(role, user: user, dashboardData: dashboardData),
      currentPath: currentPath,
      onTabSelected: onTabSelected,
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
  List<DrawerSection> _sections(
    UserRole? userRole, {
    dynamic user,
    Map<String, dynamic> dashboardData = const {},
  }) {
    final effectiveRole = userRole ?? role;
    final (kycText, kycColor) = _resolveKycBadge(user, dashboardData);
    final (planText, planColor) = _resolvePlanBadge(user, dashboardData);

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
      ]),
      DrawerSection('Profile Management', [
        DrawerEntry(
          'My Profile',
          Icons.person_outline_rounded,
          route: Routes.profile,
        ),
        DrawerEntry(
          'KYC/Verification',
          Icons.verified_user_outlined,
          route: Routes.verification,
          badgeText: kycText,
          badgeColor: kycColor,
        ),
        DrawerEntry(
          'My Watchlist',
          Icons.bookmark_border_rounded,
          route: Routes.bookmarks,
        ),
        DrawerEntry(
          'My Referrals',
          Icons.card_giftcard_outlined,
          route: Routes.referrals,
        ),
        DrawerEntry(
          'My Subscriptions',
          Icons.workspace_premium_outlined,
          route: Routes.subscriptionsManage,
          badgeText: planText,
          badgeColor: planColor,
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
      DrawerSection('My Teams & Team Access Management', [
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
        DrawerEntry(
          'Team Access',
          Icons.people_outline_rounded,
         
          
        ),
      ]),
      DrawerSection('Invitations', [
        DrawerEntry('Invitations', Icons.send_outlined),
        DrawerEntry('Connections', Icons.people_outline),
      ]),
      DrawerSection('Explore More', [
        if (effectiveRole != UserRole.client) ...[
          DrawerEntry(
            'Explore Businesses', 
            Icons.work_outline_rounded,
            route: switch (effectiveRole) {
              UserRole.freelancer => Routes.freelancerProjects,
              UserRole.client => Routes.clientProjects,
              UserRole.investor => Routes.investorProjects,
              UserRole.founder => Routes.founderProjects,
            },
          ),
        ],
        if (effectiveRole != UserRole.freelancer) ...[
          DrawerEntry(
            'Explore Freelancers',
            Icons.person_add_outlined,
            route: switch (effectiveRole) {
              UserRole.freelancer => Routes.freelancerFreelancers,
              UserRole.client => Routes.clientFreelancers,
              UserRole.investor => Routes.investorFreelancers,
              UserRole.founder => Routes.founderFreelancers,
            },
          ),
        ],
        if (effectiveRole != UserRole.founder) ...[
          DrawerEntry(
            'Explore Startup Ideas',
            Icons.travel_explore_rounded,
            route: switch (effectiveRole) {
              UserRole.freelancer => Routes.freelancerStartups,
              UserRole.client => Routes.clientStartups,
              UserRole.investor => Routes.investorStartups,
              UserRole.founder => Routes.founderStartups,
            },
          ),
        ],
        if (effectiveRole != UserRole.investor) ...[
          DrawerEntry(
            "Explore Investers",
            Icons.monetization_on_outlined,
            route: switch (effectiveRole) {
              UserRole.freelancer => Routes.freelancerInvestors,
              UserRole.client => Routes.clientInvestors,
              UserRole.investor => Routes.investorInvestors,
              UserRole.founder => Routes.founderInvestors,
            },
          ),
        ],
      ]),
      DrawerSection('My Stuff', [

       
        if (effectiveRole == UserRole.client||effectiveRole == UserRole.freelancer) ...[

        if(effectiveRole != UserRole.freelancer)
        DrawerEntry(
          'My Projects/Tasks',
          Icons.folder_special_outlined,
          route: switch (effectiveRole) {
            UserRole.freelancer => Routes.freelancerMyProjects,
            UserRole.client => Routes.clientMyProjects,
            UserRole.investor => Routes.investorMyProjects,
            UserRole.founder => Routes.founderMyProjects,
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
        ],
        
        if (role == UserRole.freelancer || role == UserRole.investor)
          DrawerEntry(
            'My Portfolio',
            Icons.folder_special_outlined,
            route: switch (effectiveRole) {
              UserRole.freelancer => Routes.freelancerPortfolioPage,
              UserRole.client => Routes.clientPortfolioPage,
              UserRole.investor => Routes.investorPortfolio,
              UserRole.founder => Routes.founderPortfolioPage,
            },
          ),
          if (effectiveRole == UserRole.founder||effectiveRole == UserRole.investor) ...[
           if(effectiveRole != UserRole.investor)DrawerEntry(
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
          'My Proposals',
          Icons.send_outlined,
          route: switch (effectiveRole) {
            UserRole.freelancer => Routes.freelancerProposals,
            UserRole.client => Routes.clientProposals,
           UserRole.investor => Routes.investorDeals,
            UserRole.founder => Routes.founderDeals,
          },
        ),
      
        

       
        // DrawerEntry(
        //   'Offers',
        //   Icons.local_offer_outlined,
        //   route: switch (effectiveRole) {
        //     UserRole.freelancer => Routes.freelancerOffers,
        //     UserRole.client => Routes.clientOffers,
        //     UserRole.investor => Routes.investorOffers,
        //     UserRole.founder => Routes.founderOffers,
        //   },
        // ),
        if(effectiveRole != UserRole.investor)...[ DrawerEntry(
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
        ],
        
        
        ]
      
      ]
      ),
      

      DrawerSection('System', [
        DrawerEntry("My Social Links", Icons.public),
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
          "Delete My Account",
          Icons.delete_outline_rounded,
          route: Routes.deleteAccount,
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
          DrawerSection('Projects/Tasks', [
            DrawerEntry(
              'Explore Projects/Tasks',
              Icons.work_outline_rounded,
              route: Routes.freelancerProjects,
            ),
            DrawerEntry(
              'My Projects',
              Icons.folder_special_outlined,
              route: Routes.freelancerMyProjects,
            ),
            DrawerEntry(
              'Projects/Tasks Tracking',
              Icons.view_kanban_outlined,
              route: Routes.freelancerTasks,
            ),
            DrawerEntry(
              'Projects/Tasks Contracts',
              Icons.assignment_outlined,
              route: Routes.freelancerContracts,
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
    this.onTabSelected,
  });

  final AppUser? user;
  final List<DrawerSection> sections;
  final String currentPath;
  final String workspaceLabel;
  final UserRole role;
  final ValueChanged<int>? onTabSelected;

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
              user: user,
              role: role,
              workspaceLabel: workspaceLabel,
              onRefresh: () => _refresh(context),
              onProfileTap: () {
                Navigator.of(context).pop();
                if (onTabSelected != null) {
                  onTabSelected!(4);
                } else {
                  context.push(Routes.profile);
                }
              },
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _refresh(context),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.sm,
                    AppSizes.md,
                    AppSizes.sm,
                    AppSizes.md,
                  ),
                  children: [
                    for (final section in sections)
                      _FounderDrawerSection(
                        section: section,
                        currentPath: currentPath,
                        role: role,
                        onTabSelected: onTabSelected,
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
                    const SizedBox(height: AppSizes.sm),
                    const _FounderDrawerFooter(),
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
    required this.user,
    required this.role,
    required this.workspaceLabel,
    required this.onRefresh,
    this.onProfileTap,
  });

  final AppUser? user;
  final UserRole role;
  final String workspaceLabel;
  final VoidCallback onRefresh;
  final VoidCallback? onProfileTap;

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
                : role == UserRole.client
                ? 'Business Owner'
                : 'Founder',
          )
        : name;

    final completion = (user?.profileCompletion ?? 0).clamp(0, 100);
    final isVerified = user?.isVerified == true;

    return InkWell(
      onTap: onProfileTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.md,
          AppSizes.md,
          AppSizes.md,
          AppSizes.md,
        ),
        decoration: BoxDecoration(
          color: context.isDark ? AppColors.darkCard : Colors.white,
          border: Border(
            bottom: BorderSide(
              color: context.isDark ? AppColors.darkBorder : AppColors.border,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: AppAvatar(
                        name: displayName,
                        imageUrl: user?.avatarUrl,
                        size: 42,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isVerified
                              ? AppColors.success
                              : AppColors.warning,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.isDark
                                ? AppColors.darkCard
                                : Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          workspaceLabel,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 9.5,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.mutedText,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr(
                    completion >= 100
                        ? 'Profile Complete'
                        : 'Profile Completion',
                  ),
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mutedText,
                  ),
                ),
                Text(
                  '$completion%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: completion >= 100
                        ? AppColors.success
                        : AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (completion / 100.0).clamp(0.0, 1.0),
                minHeight: 4.5,
                backgroundColor: context.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(
                  completion >= 100 ? AppColors.success : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FounderDrawerFooter extends StatelessWidget {
  const _FounderDrawerFooter();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.sm,
        AppSizes.md,
        AppSizes.sm,
        AppSizes.xs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            AppAssets.fullBannerImage,
            height: 22,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Image.asset(
              AppAssets.appLogo,
              height: 22,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            '© 2016 Go Experts. All rights reserved.',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.mutedText,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
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
    required this.role,
    this.onTabSelected,
  });

  final DrawerSection section;
  final String currentPath;
  final UserRole role;
  final ValueChanged<int>? onTabSelected;

  int? _resolveTabIndex(String route) {
    if (route == Routes.freelancerDashboard ||
        route == Routes.clientDashboard ||
        route == Routes.founderDashboard ||
        route == Routes.investorDashboard) {
      return 0;
    }
    if (route == Routes.messages) return 1;
    if (route == Routes.bookmarks) return 2;
    if (route == Routes.meetings) return 3;
    if (route == Routes.profile ||
        route == Routes.freelancerProfile ||
        route == Routes.clientProfile ||
        route == Routes.founderProfile ||
        route == Routes.investorProfile) {
      return 4;
    }
    return null;
  }

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
              onTap: () async {
                final route = entry.route;
                final customTap = entry.onTap;
                if (route != null) {
                  AppDrawer._lastSelectedRoute = route;
                }
                final rootScaffold = Scaffold.maybeOf(context);
                Navigator.of(context).pop();
                if (customTap != null) {
                  customTap();
                } else if (route != null) {
                  final tabIndex = _resolveTabIndex(route);
                  if (tabIndex != null && onTabSelected != null) {
                    onTabSelected!(tabIndex);
                    return;
                  }
                  if (currentPath == route) return;
                  await context.push(route);
                  if (rootScaffold != null &&
                      rootScaffold.mounted &&
                      !rootScaffold.isDrawerOpen) {
                    rootScaffold.openDrawer();
                  }
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
      leading: GradientIcon(
        icon: icon,
        size: 19,
        colors: [color, AppColors.primary],
      ),
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
        entry.route != null &&
        (currentPath == entry.route ||
            (entry.route != '/' && currentPath.startsWith('${entry.route}/')));

    final isDestructive = entry.label.toLowerCase().contains('delete');
    final gradientColors = isDestructive
        ? [AppColors.danger, AppColors.primary]
        : [AppColors.primary, AppColors.secondary];

    final backgroundGradient = isSelected
        ? LinearGradient(
            colors: isDestructive
                ? [
                    AppColors.danger.withValues(alpha: 0.16),
                    AppColors.primary.withValues(alpha: 0.06),
                  ]
                : [
                    AppColors.primary.withValues(alpha: 0.16),
                    AppColors.secondary.withValues(alpha: 0.06),
                  ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          )
        : null;

    final borderColor = isSelected
        ? AppColors.primary.withValues(alpha: 0.28)
        : Colors.transparent;

    return Container(
      constraints: BoxConstraints(minHeight: founderStyle ? 44 : 0),
      margin: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? null : Colors.transparent,
        gradient: backgroundGradient,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: borderColor, width: isSelected ? 1.0 : 0.0),
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
          leading: GradientIcon(
            icon: entry.icon,
            size: founderStyle ? 19 : 20,
            colors: gradientColors,
          ),
          title: isSelected
              ? ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    context.tr(entry.label),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: founderStyle ? 13 : null,
                    ),
                  ),
                )
              : Text(
                  context.tr(entry.label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontSize: founderStyle ? 13 : null,
                  ),
                ),
          trailing: _buildBadge(context, colors, isSelected),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget? _buildBadge(
    BuildContext context,
    ColorScheme colors,
    bool isSelected,
  ) {
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
      final badgeColor = entry.badgeColor ?? colors.secondary;
      final isLightBadge = badgeColor.computeLuminance() > 0.55;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
              color: badgeColor.withValues(alpha: 0.25),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          entry.badgeText!,
          style: TextStyle(
            color: isLightBadge ? const Color(0xFF1E293B) : Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      );
    } else if (isSelected) {
      return Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
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
