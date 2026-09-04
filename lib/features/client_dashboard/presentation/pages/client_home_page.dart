import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/dashboard/dashboard_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/widgets/app_loading_shimmer.dart';
import '../../../../core/widgets/dashboard_header.dart';
import '../../../../core/widgets/dashboard_metric_card.dart';
import '../../../../core/widgets/dashboard_action_button.dart';
import '../../../../core/widgets/app_segmented_tabs.dart';
import '../../../../core/widgets/free_plan_prompt_dialog.dart';
import '../../../../core/widgets/verification_prompt_card.dart';
import '../../../../core/widgets/dashboard_recommendations_section.dart';

class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key});

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
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
            context.push(Routes.clientProfile);
          } else {
            context.push(Routes.clientVerification);
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
            await Future.wait([
              context.read<DashboardCubit>().refresh(),
              _loadRecommendations(),
            ]);
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
              //  if (state.shouldShowVerificationPrompt) ...[
              //           VerificationPromptCard(
              //             missingCount: state.verificationMissingCount,
              //             accountVerified: state.accountVerified,
              //             route: Routes.clientVerification,
              //           ),
              //           const SizedBox(height: 16),
              //         ],
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
                    ],
                  ),
                ),
                _buildRecommendationTabs(context),
                const SizedBox(height: 100),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroBanner(BuildContext context, DashboardState state) {
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
        ? 'Verified Client'
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
                    onTap: () => context.push(Routes.clientVerification),
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

  Widget _buildQuickActions(BuildContext context) {
    return LayoutBuilder(
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
              text: 'My Projects',
              subtitle: 'Live sprint boards & task tracking',
              tag: 'Tracking',
              icon: Icons.view_kanban_rounded,
              color: const Color(0xFF8B5CF6),
              onTap: () => context.push(Routes.clientMyProjects),
              width: width,
            ),
            DashboardActionButton(
              text: 'Post Project',
              subtitle: 'Scope deliverables & budget terms',
              tag: 'Create',
              icon: Icons.add_task_rounded,
              color: AppColors.success,
              onTap: () => context.push(Routes.clientCreateProject),
              width: width,
            ),
            DashboardActionButton(
              text: 'Hire Freelancers',
              subtitle: 'Vetted developers & domain experts',
              tag: 'Talent',
              icon: Icons.person_search_rounded,
              color: const Color(0xFF10B981),
              onTap: () => context.push(Routes.clientFreelancers),
              width: width,
            ),
            DashboardActionButton(
              text: 'Active Contracts',
              subtitle: 'Milestones, terms & agreements',
              tag: 'Contracts',
              icon: Icons.description_rounded,
              color: const Color(0xFFF59E0B),
              onTap: () => context.push(Routes.clientContracts),
              width: width,
            ),
            // DashboardActionButton(
            //   text: 'Escrow & Payments',
            //   subtitle: 'Release milestones & invoices',
            //   tag: 'Billing',
            //   icon: Icons.payments_rounded,
            //   color: const Color(0xFF06B6D4),
            //   onTap: () => context.push(Routes.clientPayments),
            //   width: width,
            // ),
            DashboardActionButton(
              text: 'Team Access',
              subtitle: 'Invite project managers & billing leads',
              tag: 'Access',
              icon: Icons.groups_rounded,
              color: const Color(0xFFEC4899),
              onTap: () => context.push(Routes.clientTeams),
              width: width,
            ),
          ],
        );
      },
    );
  }

  
 


  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    try {
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
    } catch (_) {}
    if (mounted) setState(() => _recommendationsLoading = false);
  }

  Widget _buildRecommendationTabs(BuildContext context) {
    return DashboardRecommendationsSection(
      title: 'Top Matches For You',
      subtitle: 'Verified freelance experts, high-growth startups and strategic investors',
      isLoading: _recommendationsLoading,
      items: _recommendedItems,
      onRefresh: _loadRecommendations,
      tabs: const [
        RecommendationTabConfig(
          key: 'freelancers',
          label: 'Freelancers',
          icon: Icons.person_search_rounded,
          accent: Color(0xFF3B82F6),
          viewAllRoute: Routes.clientFreelancers,
        ),
        RecommendationTabConfig(
          key: 'startups',
          label: 'Startups',
          icon: Icons.rocket_launch_rounded,
          accent: Color(0xFF10B981),
          viewAllRoute: Routes.clientStartups,
        ),
        RecommendationTabConfig(
          key: 'investors',
          label: 'Investors',
          icon: Icons.account_balance_rounded,
          accent: Color(0xFF8B5CF6),
          viewAllRoute: Routes.clientInvestors,
        ),
      ],
    );
  }
}
