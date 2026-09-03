import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../app/constants/app_colors.dart';
import '../../app/dependency_injection/service_locator.dart';
import '../../features/client_dashboard/presentation/pages/client_home_page.dart';
import '../../features/founder_dashboard/presentation/pages/founder_home_page.dart';
import '../../features/founder_dashboard/presentation/pages/my_startup_view.dart';
import '../../features/freelancer_dashboard/domain/repositories/freelancer_repository.dart';
import '../../features/freelancer_dashboard/presentation/pages/freelancer_home_page.dart';
import '../../features/freelancer_dashboard/presentation/pages/freelancers_list_view.dart';
import '../../features/investor_dashboard/domain/repositories/investor_repository.dart';
import '../../features/investor_dashboard/presentation/pages/deals_list_view.dart';
import '../../features/investor_dashboard/presentation/pages/investor_home_page.dart';
import '../../features/investor_dashboard/presentation/pages/investors_list_view.dart';
import '../../features/meetings/domain/repositories/meeting_repository.dart';
import '../../features/meetings/presentation/pages/meetings_list_view.dart';
import '../../features/messages/domain/repositories/message_repository.dart';
import '../../features/messages/presentation/pages/conversations_list_view.dart';
import '../../features/profile/presentation/pages/my_profile_page.dart';
import '../../features/projects/domain/repositories/project_repository.dart';
import '../../app/constants/app_assets.dart';
import '../../features/projects/presentation/pages/projects_list_view.dart';
import '../../features/startup_ideas/domain/repositories/startup_repository.dart';
import '../../features/startup_ideas/presentation/pages/startups_list_view.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/settings/presentation/pages/bookmarks_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';
import '../network/api_client_helper.dart';
import '../extensions/context_extensions.dart';
import '../utils/enums.dart';
import '../widgets/app_bottom_navigation.dart';
import '../widgets/app_drawer.dart';
import '../widgets/icon_widget.dart';
import '../../app/router/route_names.dart';
import 'dashboard_cubit.dart';

/// A single tab within a role shell.
class _Tab {
  const _Tab(this.item, this.body, {this.title});
  final AppNavItem item;
  final Widget body;
  final String? title;
}

/// The stateful shell hosting bottom navigation, drawer and role tabs.
class RoleShell extends StatefulWidget {
  const RoleShell({super.key, required this.role, this.initialIndex = 0});
  final UserRole role;
  final int initialIndex;

  @override
  State<RoleShell> createState() => _RoleShellState();
}

class _RoleShellState extends State<RoleShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _index = widget.initialIndex;
  int _walletRefreshToken = 0;
  late final DashboardCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = DashboardCubit(
      role: widget.role,
      projectRepository: sl<ProjectRepository>(),
      freelancerRepository: sl<FreelancerRepository>(),
      startupRepository: sl<StartupRepository>(),
      investorRepository: sl<InvestorRepository>(),
      meetingRepository: sl<MeetingRepository>(),
      messageRepository: sl<MessageRepository>(),
      walletRepository: sl<WalletRepository>(),
      apiClient: sl<ApiClientHelper>(),
    )..load();
    context.read<AuthBloc>().add(const AuthRefreshUser());
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  List<_Tab> _buildTabs() {
    final homeView = switch (widget.role) {
      UserRole.freelancer => const FreelancerHomePage(),
      UserRole.client => const ClientHomePage(),
      UserRole.founder => const FounderHomePage(),
      UserRole.investor => const InvestorHomePage(),
    };

    return [
      _Tab(
        const AppNavItem(
          label: 'Home',
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
        ),
        homeView,
      ),
      _Tab(
        const AppNavItem(
          label: 'Chats',
          icon: Icons.chat_bubble_outline_rounded,
          activeIcon: Icons.chat_bubble_rounded,
        ),
        ConversationsListView(),
        title: 'Messages',
      ),
      const _Tab(
        AppNavItem(
          label: 'My Wishlist',
          icon: Icons.workspace_premium_outlined,
          activeIcon: Icons.workspace_premium_rounded,
        ),
        BookmarksPage(embedded: true),
        title: 'My Wishlist',
      ),
      _Tab(
        const AppNavItem(
          label: 'Meetings',
          icon: Icons.event_outlined,
          activeIcon: Icons.event_rounded,
        ),
        MeetingsListView(),
        title: 'Meetings',
      ),
      const _Tab(
        AppNavItem(
          label: 'Profile',
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
        ),
        MyProfilePage(),
      ),
    ];
  }

  List<AppNavItem> _navItems(
    List<_Tab> tabs,
    int unreadMessages,
    dynamic user,
    DashboardState state,
  ) {
    final kycStatus = (state.dashboardData['kycStatus'] ??
            state.dashboardData['kyc_status'] ??
            state.dashboardData['verificationStatus'] ??
            '')
        .toString()
        .trim()
        .toUpperCase();

    final missingCount = (state.dashboardData['missingCount'] ??
            state.dashboardData['missing_count'] as num?)
        ?.toInt() ??
        0;

    final isVerified = (kycStatus == 'APPROVED' || kycStatus == 'VERIFIED') &&
        missingCount == 0;

    final isPending = kycStatus == 'PENDING' ||
        kycStatus == 'UNDER_REVIEW' ||
        kycStatus == 'IN_REVIEW';

    return [
      for (final tab in tabs)
        AppNavItem(
          label: tab.item.label,
          icon: tab.item.icon,
          activeIcon: tab.item.activeIcon,
          badgeText: tab.item.label == 'Chats'
              ? (unreadMessages == 0
                    ? null
                    : (unreadMessages > 99 ? '99+' : '$unreadMessages'))
              : null,
          badgeWidget: tab.item.label == 'Profile'
              ? _buildProfileVerificationBadge(isVerified, isPending)
              : null,
        ),
    ];
  }

  Widget _buildProfileVerificationBadge(bool isVerified, bool isPending) {
    if (isVerified) {
      return Container(
        padding: const EdgeInsets.all(1),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.verified_rounded,
          color: AppColors.success,
          size: 11,
        ),
      );
    } else if (isPending) {
      return Container(
        padding: const EdgeInsets.all(1),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.schedule_rounded,
          color: AppColors.warning,
          size: 11,
        ),
      );
    } else {
      return Container(
        width: 7.5,
        height: 7.5,
        decoration: BoxDecoration(
          color: AppColors.warning,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 1.2),
        ),
      );
    }
  }

  String _activeRouteForCurrentTab() {
    switch (_index) {
      case 0:
        return switch (widget.role) {
          UserRole.freelancer => Routes.freelancerDashboard,
          UserRole.client => Routes.clientDashboard,
          UserRole.founder => Routes.founderDashboard,
          UserRole.investor => Routes.investorDashboard,
        };
      case 1:
        return Routes.messages;
      case 2:
        return Routes.bookmarks;
      case 3:
        return Routes.meetings;
      case 4:
        return switch (widget.role) {
          UserRole.freelancer => Routes.freelancerProfile,
          UserRole.client => Routes.clientProfile,
          UserRole.founder => Routes.founderProfile,
          UserRole.investor => Routes.investorProfile,
        };
      default:
        return Routes.freelancerDashboard;
    }
  }

  void _selectTab(List<_Tab> tabs, int index) {
    AppDrawer.clearLastSelectedRoute();
    if (index == 0 && _index == index) {
      _cubit.refresh();
    }
    if (tabs[index].item.label == 'Profile') {
      context.read<AuthBloc>().add(const AuthRefreshUser());
    }
    setState(() {
      if (tabs[index].item.label == 'Wallet') {
        _walletRefreshToken++;
      }
      _index = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _buildTabs();
    final current = tabs[_index];
    return BlocProvider<DashboardCubit>.value(
      value: _cubit,
      child: BlocBuilder<DashboardCubit, DashboardState>(
        buildWhen: (prev, next) =>
            prev.unreadMessagesCount != next.unreadMessagesCount ||
            prev.unreadNotificationsCount != next.unreadNotificationsCount,
        builder: (context, state) {
          return PopScope(
            canPop: _index == 0,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop && _index != 0) {
                _selectTab(tabs, 0);
              }
            },
            child: Scaffold(
              key: _scaffoldKey,
              drawer: AppDrawer(
                role: widget.role,
                activeRoute: _activeRouteForCurrentTab(),
                onTabSelected: (tabIdx) => _selectTab(tabs, tabIdx),
                unreadNotifications: state.unreadNotificationsCount,
                unreadMessages: state.unreadMessagesCount,
              ),
              appBar: current.title == null
                  ? null
                  : AppBar(
                      leading: Builder(
                        builder: (scaffoldContext) => IconTapWidget(
                          onTap: () {
                            AppDrawer.clearLastSelectedRoute();
                            Scaffold.of(scaffoldContext).openDrawer();
                          },
                          iconImage: AppAssets.menuIcon,
                          padding: 8,
                        ),
                      ),
                      title: Text(context.tr(current.title!)),
                    ),
              body: current.body,
              bottomNavigationBar: AppBottomNavigation(
                items: _navItems(
                  tabs,
                  state.unreadMessagesCount,
                  context.watch<AuthBloc>().state.user,
                  state,
                ),
                currentIndex: _index,
                onTap: (i) => _selectTab(tabs, i),
              ),
            ),
          );
        },
      ),
    );
  }
}
