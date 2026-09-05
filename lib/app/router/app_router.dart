import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/dashboard/role_shell.dart';
import '../../core/storage/local_storage.dart';
import '../../app/dependency_injection/service_locator.dart';
import '../../core/dashboard/standalone_pages.dart';
import '../../core/utils/enums.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/email_verification_page.dart';
import '../../features/auth/presentation/models/otp_verification_args.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/auth/presentation/pages/phone_verification_page.dart';
import '../../features/auth/presentation/pages/profile_completion_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/success_page.dart';
import '../../features/catalog/presentation/pages/business_plan_page.dart';
import '../../features/catalog/presentation/pages/category_details_page.dart';
import '../../features/catalog/presentation/pages/certificate_details_page.dart';
import '../../features/catalog/presentation/pages/opportunity_details_page.dart';
import '../../features/catalog/presentation/pages/pitch_deck_page.dart';
import '../../features/catalog/presentation/pages/service_details_page.dart';
import '../../features/catalog/presentation/pages/technology_details_page.dart';
import '../../features/profile/presentation/pages/review_details_page.dart';
import '../../features/projects/domain/entities/project.dart';
import '../../features/projects/presentation/pages/contract_details_page.dart';
import '../../features/projects/presentation/pages/contract_form_page.dart';
import '../../features/wallet/presentation/pages/invoice_details_page.dart';
import '../../features/wallet/presentation/pages/transaction_details_page.dart';
import '../../features/applications/presentation/pages/apply_form_page.dart';
import '../../features/invitations/presentation/pages/invitations_page.dart';
import '../../features/documents/presentation/pages/document_viewer_page.dart';
import '../../features/meetings/presentation/pages/calendar_page.dart';
import '../../core/dashboard/analytics_page.dart';
import '../../features/freelancer_dashboard/presentation/pages/freelancer_credentials_pages.dart';
import '../../features/freelancer_dashboard/presentation/pages/freelancer_subpages.dart';
import '../../features/freelancer_dashboard/domain/entities/portfolio_item.dart';
import '../../features/freelancer_dashboard/presentation/pages/freelancer_edit_profile_page.dart';
import '../../features/freelancer_dashboard/presentation/pages/freelancer_professional_details_page.dart';
import '../../features/freelancer_dashboard/presentation/pages/freelancer_verification_page.dart';
import '../../features/freelancer_dashboard/presentation/pages/freelancer_resume_templates_page.dart';
import '../../features/client_dashboard/presentation/pages/client_subpages.dart';
import '../../features/client_dashboard/presentation/pages/client_verification_page.dart';
import '../../features/client_dashboard/presentation/pages/client_blocker_pages.dart';
import '../../features/investor_dashboard/presentation/pages/investor_subpages.dart';
import '../../features/investor_dashboard/presentation/pages/investor_live_pages.dart';
import '../../features/founder_dashboard/presentation/pages/founder_subpages.dart';
import '../../features/founder_dashboard/presentation/pages/founder_verification_page.dart';
import '../../features/investor_dashboard/presentation/pages/investor_verification_page.dart';
import '../../features/founder_dashboard/presentation/pages/founder_live_pages.dart';
import '../../features/founder_dashboard/presentation/pages/founder_proposal_details_page.dart';
import '../../features/client_dashboard/presentation/pages/create_project_page.dart';
import '../../features/meetings/presentation/pages/meeting_details_page.dart';
import '../../features/messages/domain/entities/conversation.dart';
import '../../features/messages/presentation/pages/chat_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/profile/presentation/pages/public_profile_page.dart';
import '../../features/profile/presentation/pages/my_profile_page.dart';
import '../../features/profile/presentation/pages/my_reviews_page.dart';
import '../../features/projects/presentation/pages/project_details_page.dart';
import '../../features/proposals/presentation/pages/proposal_details_page.dart';
import '../../features/referrals/presentation/pages/referral_program_page.dart';
import '../../features/role_selection/presentation/pages/role_selection_page.dart';
import '../../features/settings/presentation/pages/bookmarks_page.dart';
import '../../features/settings/presentation/pages/change_password_page.dart';
import '../../features/settings/presentation/pages/delete_account_page.dart';
import '../../features/settings/presentation/pages/global_search_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/public_content_page.dart';
import '../../features/settings/presentation/pages/legal_document_page.dart';
import '../../features/settings/presentation/pages/security_center_page.dart';
import '../../features/startup_ideas/presentation/pages/startup_details_page.dart';
import '../../features/subscriptions/presentation/pages/current_subscription_page.dart';
import '../../features/subscriptions/presentation/pages/subscription_selection_page.dart';
import '../../features/support/presentation/pages/support_page.dart';
import '../../features/team/data/team_repository.dart';
import '../../features/team/presentation/pages/team_members_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';
import '../../core/widgets/app_error_state.dart';
import 'route_names.dart';

/// Bridges a Bloc stream to a [Listenable] so GoRouter re-evaluates redirects.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

String dashboardPathFor(UserRole role) {
  switch (role) {
    case UserRole.freelancer:
      return Routes.freelancerDashboard;
    case UserRole.client:
      return Routes.clientDashboard;
    case UserRole.investor:
      return Routes.investorDashboard;
    case UserRole.founder:
      return Routes.founderDashboard;
  }
}

const _publicRoutes = {
  Routes.splash,
  Routes.onboarding,
  Routes.login,
  Routes.signup,
  Routes.forgotPassword,
  Routes.emailVerification,
  Routes.phoneVerification,
  Routes.otp,
  Routes.resetPassword,
  Routes.privacyPolicy,
  Routes.termsOfService,
  Routes.subscription,
};

bool isPublicEntryRoute(String location) => _publicRoutes.contains(location);

const _onboardingRoutes = {
  Routes.roleSelection,
  Routes.profileCompletion,
};

GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    errorBuilder: (context, state) => Scaffold(
      body: AppErrorState(
        title: 'Page Not Found',
        message: state.error?.message ?? 'The page you\'re looking for doesn\'t exist.',
        onRetry: () => context.go(Routes.splash),
      ),
    ),
    redirect: (context, state) {
      final auth = authBloc.state;
      final loc = state.matchedLocation;

      // Determine if it's an authentication/entry route
      final isAuthRoute = const {
        Routes.splash,
        Routes.login,
        Routes.signup,
        Routes.forgotPassword,
        Routes.emailVerification,
        Routes.phoneVerification,
        Routes.otp,
        Routes.resetPassword,
      }.contains(loc);

      final isPublic = isPublicEntryRoute(loc);

      // While unknown, stay on splash.
      if (auth.status == AuthStatus.unknown) {
        return loc == Routes.splash ? null : Routes.splash;
      }

      final authed = auth.status == AuthStatus.authenticated;
      if (!authed) {
        if (auth.pendingSignup != null) {
          if (loc == Routes.roleSelection || loc == Routes.signup) return null;
          return '${Routes.roleSelection}?from=signup';
        }
        if (loc == Routes.splash) {
          final seen = sl<LocalStorage>().getBool(LocalStorage.kOnboardingSeen);
          return seen ? Routes.login : Routes.onboarding;
        }
        return isPublic ? null : Routes.login;
      }

      // Authenticated — navigate directly to role dashboard after login
      if (loc == Routes.signup) return null;

      if (!auth.hasRole) {
        return loc == Routes.roleSelection ? null : Routes.roleSelection;
      }

      // If user's profile is incomplete (new user / social signup), redirect to step 2 of signup flow
      final isOnboardingComplete = auth.user?.onboardingStatus?.toUpperCase() == 'COMPLETED';
      
      if (!isOnboardingComplete) {
        if (loc == Routes.signup) return null;
        final stepParam = (auth.user?.isSocialLogin ?? false) ? '&step=2' : '';
        return '${Routes.signup}?role=${auth.user?.role?.name ?? ''}$stepParam';
      }

      if (isAuthRoute || _onboardingRoutes.contains(loc)) {
        return dashboardPathFor(auth.user!.role!);
      }

      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashPage()),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, __) => const OnboardingPage(),
      ),
      GoRoute(path: Routes.login, builder: (_, __) => const LoginPage()),
      GoRoute(
        path: Routes.signup,
        builder: (_, s) => SignupPage(
          initialRole: s.uri.queryParameters['role'],
          initialStep: int.tryParse(s.uri.queryParameters['step'] ?? ''),
        ),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (_, __) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: Routes.emailVerification,
        builder: (_, __) => const EmailVerificationPage(),
      ),
      GoRoute(
        path: Routes.phoneVerification,
        builder: (_, __) => const PhoneVerificationPage(),
      ),
      GoRoute(
        path: Routes.otp,
        builder: (_, s) {
          final extra = s.extra;
          if (extra is OtpVerificationArgs) {
            return OtpVerificationPage(args: extra);
          }
          return OtpVerificationPage(
            args: OtpVerificationArgs(destination: extra as String? ?? ''),
          );
        },
      ),
      GoRoute(
        path: Routes.resetPassword,
        builder: (_, __) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: Routes.authSuccess,
        builder: (_, s) =>
            SuccessPage(args: (s.extra as SuccessArgs?) ?? const SuccessArgs()),
      ),
      GoRoute(
        path: Routes.roleSelection,
        builder: (_, s) => RoleSelectionPage(
          fromSignup:
              s.uri.queryParameters['from'] == 'signup' ||
              authBloc.state.pendingSignup != null,
        ),
      ),
      GoRoute(
        path: Routes.profileCompletion,
        builder: (_, __) => const ProfileCompletionPage(),
      ),
      GoRoute(
        path: Routes.subscription,
        builder: (_, __) => const SubscriptionSelectionPage(),
      ),

      // Dashboards
      GoRoute(
        path: Routes.freelancerDashboard,
        builder: (_, __) => const RoleShell(role: UserRole.freelancer),
      ),
      GoRoute(
        path: Routes.clientDashboard,
        builder: (_, __) => const RoleShell(role: UserRole.client),
      ),
      GoRoute(
        path: Routes.investorDashboard,
        builder: (_, __) => const RoleShell(role: UserRole.investor),
      ),
      GoRoute(
        path: Routes.founderDashboard,
        builder: (_, __) => const RoleShell(role: UserRole.founder),
      ),

      // Freelancer standalone
      GoRoute(
        path: Routes.freelancerProjects,
        builder: (_, __) => const ProjectsStandalonePage(),
      ),
      GoRoute(
        path: Routes.freelancerMyProjects,
        builder: (_, __) => const MyProjectsStandalonePage(),
      ),
      GoRoute(
        path: Routes.freelancerProposals,
        builder: (_, __) => const ProposalsStandalonePage(),
      ),
      GoRoute(
        path: Routes.freelancerProfile,
        builder: (_, __) => const ProfileStandalonePage(),
      ),
      GoRoute(
        path: Routes.freelancerEditProfile,
        builder: (_, __) => const FreelancerEditProfilePage(),
      ),
      GoRoute(
        path: Routes.freelancerProfessionalDetails,
        builder: (_, __) => const FreelancerProfessionalDetailsPage(),
      ),
      GoRoute(
        path: Routes.freelancerVerification,
        builder: (_, __) => const FreelancerVerificationPage(),
      ),
      GoRoute(
        path: Routes.freelancerPortfolioPage,
        builder: (_, __) => const FreelancerPortfolioPage(),
      ),
      GoRoute(
        path: '${Routes.freelancerPortfolioDetails}/:id',
        builder: (_, s) =>
            FreelancerPortfolioDetailsPage(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.freelancerPortfolioForm,
        builder: (_, s) => FreelancerPortfolioFormPage(
          item: s.extra is PortfolioItem ? s.extra as PortfolioItem : null,
        ),
      ),
      GoRoute(
        path: Routes.freelancerResumeTemplates,
        builder: (_, __) => const FreelancerResumeTemplatesPage(),
      ),
      GoRoute(
        path: Routes.freelancerWallet,
        builder: (_, __) => const WalletPage(),
      ),

      // Client standalone
      GoRoute(
        path: Routes.clientProjects,
        builder: (_, __) => const ProjectsStandalonePage(),
      ),
      GoRoute(
        path: Routes.clientMyProjects,
        builder: (_, __) => const MyProjectsStandalonePage(),
      ),
      GoRoute(
        path: Routes.clientCreateProject,
        builder: (_, s) =>
            CreateProjectPage(projectId: s.uri.queryParameters['projectId']),
      ),
      GoRoute(
        path: Routes.clientTasks,
        builder: (_, __) => const ClientTasksPage(),
      ),
      GoRoute(
        path: Routes.clientAddTask,
        builder: (_, s) => ClientAddTaskPage(
          task: s.extra is ClientTask ? s.extra as ClientTask : null,
        ),
      ),
      GoRoute(
        path: Routes.clientFreelancers,
        builder: (_, __) => const FreelancersStandalonePage(),
      ),
      GoRoute(
        path: Routes.clientPayments,
        builder: (_, __) => const WalletPage(),
      ),
      GoRoute(
        path: Routes.clientProfile,
        builder: (_, __) => const ClientCompanyProfilePage(),
      ),
      GoRoute(
        path: Routes.clientVerification,
        builder: (_, __) => const ClientVerificationPage(),
      ),
      GoRoute(
        path: Routes.investorVerification,
        builder: (_, __) => const InvestorVerificationPage(),
      ),
      GoRoute(
        path: Routes.founderVerification,
        builder: (_, __) => const FounderVerificationPage(),
      ),

      // Investor standalone
      GoRoute(
        path: Routes.investorStartups,
        builder: (_, __) => const StartupsStandalonePage(),
      ),
      GoRoute(
        path: Routes.investorDeals,
        builder: (_, __) => const DealsStandalonePage(),
      ),
      GoRoute(
        path: Routes.investorPortfolio,
        builder: (_, __) => const PortfolioStandalonePage(),
      ),
      GoRoute(
        path: Routes.investorProfile,
        builder: (_, __) => const InvestorProfilePage(),
      ),

      // Founder standalone
      GoRoute(
        path: Routes.founderStartup,
        builder: (_, __) => const MyStartupStandalonePage(),
      ),
      GoRoute(
        path: Routes.founderListStartup,
        builder: (_, __) =>
            const RoleShell(role: UserRole.founder, initialIndex: 1),
      ),
      GoRoute(
        path: Routes.founderInvestors,
        builder: (_, __) => const InvestorsStandalonePage(),
      ),
      GoRoute(
        path: Routes.founderFunding,
        builder: (_, __) => const FounderFundingLivePage(),
      ),
      GoRoute(
        path: Routes.founderProfile,
        builder: (_, __) => const FounderProfileLivePage(),
      ),

      // Common
      GoRoute(
        path: Routes.profile,
        builder: (_, __) => const MyProfilePage(),
      ),
      GoRoute(
        path: Routes.myReviews,
        builder: (_, __) => const MyReviewsPage(),
      ),
      GoRoute(
        path: Routes.verification,
        builder: (context, _) {
          final role =
              context.read<AuthBloc>().state.user?.role ?? UserRole.freelancer;
          return switch (role) {
            UserRole.freelancer => const FreelancerVerificationPage(),
            UserRole.client => const ClientVerificationPage(),
            UserRole.investor => const InvestorVerificationPage(),
            UserRole.founder => const FounderVerificationPage(),
          };
        },
      ),
      GoRoute(
        path: Routes.legalDocument,
        builder: (_, __) => LegalDocumentPage.privacy(),
      ),
      GoRoute(
        path: Routes.messages,
        builder: (_, __) => const MessagesStandalonePage(),
      ),
      GoRoute(
        path: Routes.meetings,
        builder: (_, __) => const MeetingsStandalonePage(),
      ),
      GoRoute(
        path: Routes.notifications,
        builder: (_, __) => const NotificationsPage(),
      ),
      GoRoute(path: Routes.settings, builder: (_, __) => const SettingsPage()),
      GoRoute(path: Routes.support, builder: (_, __) => const SupportPage()),
      GoRoute(
        path: Routes.privacyPolicy,
        builder: (_, __) =>
            const PublicContentPage(title: 'Privacy Policy', path: 'privacy'),
      ),
      GoRoute(
        path: Routes.termsOfService,
        builder: (_, __) =>
            const PublicContentPage(title: 'Terms & Conditions', path: 'legal'),
      ),
      GoRoute(
        path: Routes.aboutGoExperts,
        builder: (_, __) =>
            const PublicContentPage(title: 'About Go Experts', path: 'about'),
      ),
      GoRoute(
        path: Routes.refundPolicy,
        builder: (_, __) => const PublicContentPage(
          title: 'Refund Policy',
          path: 'refund-policy',
        ),
      ),
      GoRoute(
        path: Routes.helpCenter,
        builder: (_, __) =>
            const PublicContentPage(title: 'Help Center', path: 'help-center'),
      ),
      GoRoute(
        path: Routes.contactUs,
        builder: (_, __) =>
            const PublicContentPage(title: 'Contact Us', path: 'contact'),
      ),
      GoRoute(
        path: Routes.deleteAccount,
        builder: (_, __) => const DeleteAccountPage(),
      ),
      GoRoute(
        path: Routes.search,
        builder: (_, __) => const GlobalSearchPage(),
      ),
      GoRoute(
        path: Routes.bookmarks,
        builder: (_, __) => const BookmarksPage(),
      ),
      GoRoute(path: Routes.wallet, builder: (_, __) => const WalletPage()),
      GoRoute(
        path: Routes.securityCenter,
        builder: (_, __) => const SecurityCenterPage(),
      ),
      GoRoute(
        path: Routes.changePassword,
        builder: (_, __) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: Routes.subscriptionsManage,
        builder: (_, __) => const CurrentSubscriptionPage(),
      ),
      GoRoute(
        path: Routes.referrals,
        builder: (_, __) => const ReferralProgramPage(),
      ),

      // Detail / deep-link routes
      GoRoute(
        path: '${Routes.chat}/:id',
        builder: (_, s) {
          final id = s.pathParameters['id']!;
          Conversation? conversation = s.extra as Conversation?;
          final qName = s.uri.queryParameters['name'];
          final qAvatar = s.uri.queryParameters['avatarUrl'];
          if (conversation == null && qName != null) {
            conversation = Conversation(
              id: id,
              name: qName,
              avatarUrl: qAvatar,
              lastMessage: '',
              lastMessageAt: DateTime.now(),
              unreadCount: 0,
              isOnline: true,
            );
          }
          return ChatPage(conversationId: id, conversation: conversation);
        },
      ),
      GoRoute(
        path: '${Routes.projectDetails}/:id',
        builder: (_, s) => ProjectDetailsPage(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '${Routes.startupDetails}/:id',
        builder: (_, s) => StartupDetailsPage(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '${Routes.proposalDetails}/:id',
        builder: (context, s) {
          final id = s.pathParameters['id']!;
          final isFounder =
              context.read<AuthBloc>().state.user?.role == UserRole.founder;
          if (isFounder) {
            return FounderProposalDetailsPage(id: id);
          }
          return ProposalDetailsPage(id: id);
        },
      ),
      GoRoute(
        path: '${Routes.meetingDetails}/:id',
        builder: (_, s) => MeetingDetailsPage(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '${Routes.contractDetails}/:id',
        builder: (_, s) => ContractDetailsPage(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.contractForm,
        builder: (_, s) => ContractFormPage(
          contract: s.extra is Contract ? s.extra as Contract : null,
          initialProposalId: s.uri.queryParameters['proposalId'],
          initialProjectId: s.uri.queryParameters['projectId'],
          initialFreelancerName: s.uri.queryParameters['freelancerName'],
        ),
      ),
      GoRoute(
        path: '${Routes.invoiceDetails}/:id',
        builder: (_, s) => InvoiceDetailsPage(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '${Routes.transactionDetails}/:id',
        builder: (_, s) => TransactionDetailsPage(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '${Routes.certificateDetails}/:id',
        builder: (_, s) => CertificateDetailsPage(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '${Routes.reviewDetails}/:id',
        builder: (_, s) => ReviewDetailsPage(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '${Routes.opportunityDetails}/:id',
        builder: (_, s) => OpportunityDetailsPage(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '${Routes.businessPlanDetails}/:id',
        builder: (_, s) => BusinessPlanPage(startupId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '${Routes.pitchDeckDetails}/:id',
        builder: (_, s) => PitchDeckPage(startupId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '${Routes.serviceDetails}/:id',
        builder: (_, s) => ServiceDetailsPage(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '${Routes.technologyDetails}/:id',
        builder: (_, s) => TechnologyDetailsPage(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '${Routes.categoryDetails}/:id',
        builder: (_, s) => CategoryDetailsPage(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.apply,
        builder: (_, s) => ApplyFormPage(
          type: s.uri.queryParameters['type'] ?? 'Project',
          targetName: s.uri.queryParameters['name'],
          projectId: s.uri.queryParameters['projectId'],
          proposalId: s.uri.queryParameters['proposalId'],
          initialBid: s.uri.queryParameters['bid'],
          initialCover: s.uri.queryParameters['cover'],
          initialDeliveryDays: s.uri.queryParameters['deliveryDays'],
        ),
      ),
      GoRoute(
        path: Routes.myProjects,
        builder: (_, __) => const MyProjectsStandalonePage(),
      ),
      GoRoute(
        path: Routes.invitations,
        builder: (_, __) => const InvitationsPage(),
      ),
      GoRoute(path: Routes.calendar, builder: (_, __) => const CalendarPage()),
      GoRoute(
        path: Routes.documentViewer,
        builder: (_, s) => DocumentViewerPage(
          type: s.uri.queryParameters['type'] ?? 'PDF',
          name: s.uri.queryParameters['name'],
          url: s.uri.queryParameters['url'],
        ),
      ),

      // Role sub-pages — Freelancer
      GoRoute(
        path: Routes.freelancerContracts,
        builder: (_, __) => const FreelancerContractsPage(),
      ),
      GoRoute(
        path: Routes.freelancerTasks,
        builder: (_, __) => const FreelancerTasksPage(),
      ),
      GoRoute(
        path: Routes.freelancerReviews,
        builder: (_, __) => const FreelancerReviewsPage(),
      ),
      GoRoute(
        path: Routes.freelancerCertificates,
        builder: (_, __) => const FreelancerCertificatesApiPage(),
      ),
      GoRoute(
        path: Routes.freelancerSkills,
        builder: (_, __) => const FreelancerSkillsPage(),
      ),
      GoRoute(
        path: Routes.freelancerExperience,
        builder: (_, __) => const FreelancerExperiencePage(),
      ),
      GoRoute(
        path: Routes.freelancerEducation,
        builder: (_, __) => const FreelancerEducationApiPage(),
      ),
      GoRoute(
        path: Routes.freelancerWithdrawals,
        builder: (_, __) => const FreelancerWithdrawalsPage(),
      ),
      GoRoute(
        path: Routes.freelancerInvoices,
        builder: (_, __) => const FreelancerInvoicesPage(),
      ),
      GoRoute(
        path: Routes.freelancerAnalytics,
        builder: (_, __) => const RoleAnalyticsPage(role: UserRole.freelancer),
      ),
      GoRoute(
        path: Routes.freelancerFreelancers,
        builder: (_, __) => const FreelancersStandalonePage(),
      ),
      GoRoute(
        path: Routes.freelancerApplications,
        builder: (_, __) => const ClientApplicationsPage(),
      ),
      GoRoute(
        path: Routes.freelancerTeams,
        builder: (_, __) => const TeamMembersPage(),
      ),
      GoRoute(
        path: Routes.freelancerStartups,
        builder: (_, __) => const StartupsStandalonePage(),
      ),
      GoRoute(
        path: Routes.freelancerDeals,
        builder: (_, __) => const DealsStandalonePage(),
      ),
      GoRoute(
        path: Routes.freelancerOffers,
        builder: (_, __) => const InvestorOffersPage(),
      ),
      GoRoute(
        path: Routes.freelancerPitchDeck,
        builder: (_, __) => const FounderPitchDeckLivePage(),
      ),
      GoRoute(
        path: Routes.freelancerBusinessPlan,
        builder: (_, __) => const FounderBusinessPlanLivePage(),
      ),
      GoRoute(
        path: Routes.freelancerInvestors,
        builder: (_, __) => const InvestorsStandalonePage(),
      ),
      GoRoute(
        path: Routes.freelancerFunding,
        builder: (_, __) => const FounderFundingLivePage(),
      ),
      GoRoute(
        path: Routes.freelancerReports,
        builder: (_, __) => const ClientReportsHubPage(),
      ),
      GoRoute(
        path: Routes.freelancerCreateProject,
        builder: (_, s) =>
            CreateProjectPage(projectId: s.uri.queryParameters['projectId']),
      ),
      GoRoute(
        path: Routes.freelancerCreateStartup,
        builder: (_, __) => const MyStartupStandalonePage(),
      ),
      GoRoute(
        path: Routes.freelancerAddTask,
        builder: (_, s) => ClientAddTaskPage(
          task: s.extra is ClientTask ? s.extra as ClientTask : null,
        ),
      ),

      // Role sub-pages — Client
      GoRoute(
        path: Routes.clientApplications,
        builder: (_, __) => const ClientApplicationsPage(),
      ),
      GoRoute(
        path: Routes.clientShortlisted,
        builder: (_, __) => const ClientShortlistedPage(),
      ),
      GoRoute(
        path: Routes.clientTeams,
        builder: (_, __) => const TeamMembersPage(),
      ),
      GoRoute(
        path: Routes.clientReports,
        builder: (_, __) => const ClientReportsHubPage(),
      ),
      GoRoute(
        path: Routes.clientAnalytics,
        builder: (_, __) => const RoleAnalyticsPage(role: UserRole.client),
      ),
      GoRoute(
        path: Routes.clientProposals,
        builder: (_, __) => const ClientApplicationsPage(),
      ),
      GoRoute(
        path: Routes.clientContracts,
        builder: (_, __) => const FreelancerContractsPage(),
      ),
      GoRoute(
        path: Routes.clientPortfolioPage,
        builder: (_, __) => const FreelancerPortfolioPage(),
      ),
      GoRoute(
        path: Routes.clientStartups,
        builder: (_, __) => const StartupsStandalonePage(),
      ),
      GoRoute(
        path: Routes.clientDeals,
        builder: (_, __) => const DealsStandalonePage(),
      ),
      GoRoute(
        path: Routes.clientOffers,
        builder: (_, __) => const InvestorOffersPage(),
      ),
      GoRoute(
        path: Routes.clientPitchDeck,
        builder: (_, __) => const FounderPitchDeckLivePage(),
      ),
      GoRoute(
        path: Routes.clientBusinessPlan,
        builder: (_, __) => const FounderBusinessPlanLivePage(),
      ),
      GoRoute(
        path: Routes.clientInvestors,
        builder: (_, __) => const InvestorsStandalonePage(),
      ),
      GoRoute(
        path: Routes.clientFunding,
        builder: (_, __) => const FounderFundingLivePage(),
      ),
      GoRoute(
        path: Routes.clientCreateStartup,
        builder: (_, __) => const MyStartupStandalonePage(),
      ),

      // Role sub-pages — Investor
      GoRoute(
        path: Routes.investorProjects,
        builder: (_, __) => const ProjectsStandalonePage(),
      ),
      GoRoute(
        path: Routes.investorMyProjects,
        builder: (_, __) => const MyProjectsStandalonePage(),
      ),
      GoRoute(
        path: Routes.investorProposals,
        builder: (_, __) => const ProposalsStandalonePage(),
      ),
      GoRoute(
        path: Routes.investorContracts,
        builder: (_, __) => const InvestorOffersPage(),
      ),
      GoRoute(
        path: Routes.investorTasks,
        builder: (_, __) => const ClientTasksPage(),
      ),
      GoRoute(
        path: Routes.investorFreelancers,
        builder: (_, __) => const FreelancersStandalonePage(),
      ),
      GoRoute(
        path: Routes.investorApplications,
        builder: (_, __) => const DealsStandalonePage(),
      ),
      GoRoute(
        path: Routes.investorTeams,
        builder: (_, __) => const TeamMembersPage(),
      ),
      GoRoute(
        path: Routes.investorPortfolioPage,
        builder: (_, __) => const PortfolioStandalonePage(),
      ),
      GoRoute(
        path: Routes.investorPitchDeck,
        builder: (_, __) => const FounderPitchDeckLivePage(),
      ),
      GoRoute(
        path: Routes.investorBusinessPlan,
        builder: (_, __) => const FounderBusinessPlanLivePage(),
      ),
      GoRoute(
        path: Routes.investorInvestors,
        builder: (_, __) => const InvestorsStandalonePage(),
      ),
      GoRoute(
        path: Routes.investorFunding,
        builder: (_, __) => const FounderFundingLivePage(),
      ),
      GoRoute(
        path: Routes.investorCreateProject,
        builder: (_, s) =>
            CreateProjectPage(projectId: s.uri.queryParameters['projectId']),
      ),
      GoRoute(
        path: Routes.investorCreateStartup,
        builder: (_, __) => const MyStartupStandalonePage(),
      ),
      GoRoute(
        path: Routes.investorAddTask,
        builder: (_, s) => ClientAddTaskPage(
          task: s.extra is ClientTask ? s.extra as ClientTask : null,
        ),
      ),
      GoRoute(
        path: Routes.investorPreferences,
        builder: (_, __) => const InvestorPreferencesPage(),
      ),
      GoRoute(
        path: Routes.investorDueDiligence,
        builder: (_, __) => const InvestorDueDiligencePage(),
      ),
      GoRoute(
        path: Routes.investorOffers,
        builder: (_, __) => const InvestorOffersPage(),
      ),
      GoRoute(
        path: Routes.investorDocuments,
        builder: (_, __) => const InvestorDocumentsLivePage(),
      ),
      GoRoute(
        path: Routes.investorTransactions,
        builder: (_, __) => const InvestorTransactionsPage(),
      ),
      GoRoute(
        path: Routes.investorReports,
        builder: (_, __) => const InvestorReportsLivePage(),
      ),
      GoRoute(
        path: Routes.investorAnalytics,
        builder: (_, __) => const RoleAnalyticsPage(role: UserRole.investor),
      ),

      // Role sub-pages — Founder
      GoRoute(
        path: Routes.founderProjects,
        builder: (_, __) => const ProjectsStandalonePage(),
      ),
      GoRoute(
        path: Routes.founderMyProjects,
        builder: (_, __) => const MyProjectsStandalonePage(),
      ),
      GoRoute(
        path: Routes.founderProposals,
        builder: (_, __) => const ProposalsStandalonePage(),
      ),
      GoRoute(
        path: Routes.founderContracts,
        builder: (_, __) => const FounderFundingLivePage(),
      ),
      GoRoute(
        path: Routes.founderTasks,
        builder: (_, __) => const ClientTasksPage(),
      ),
      GoRoute(
        path: Routes.founderFreelancers,
        builder: (_, __) => const FreelancersStandalonePage(),
      ),
      GoRoute(
        path: Routes.founderApplications,
        builder: (_, __) => const InvestorsStandalonePage(),
      ),
      GoRoute(
        path: Routes.founderTeams,
        builder: (_, __) => const TeamMembersPage(),
      ),
      GoRoute(
        path: Routes.founderPortfolioPage,
        builder: (_, __) => const MyStartupStandalonePage(),
      ),
      GoRoute(
        path: Routes.founderStartups,
        builder: (_, __) => const StartupsStandalonePage(),
      ),
      GoRoute(
        path: Routes.founderDeals,
        builder: (_, __) => const DealsStandalonePage(),
      ),
      GoRoute(
        path: Routes.founderOffers,
        builder: (_, __) => const InvestorOffersPage(),
      ),
      GoRoute(
        path: Routes.founderPitchDeck,
        builder: (_, __) => const FounderPitchDeckLivePage(),
      ),
      GoRoute(
        path: Routes.founderBusinessPlan,
        builder: (_, __) => const FounderBusinessPlanLivePage(),
      ),
      GoRoute(
        path: Routes.founderTeam,
        builder: (_, __) => const TeamMembersPage(),
      ),
      GoRoute(
        path: Routes.founderHiring,
        builder: (_, __) => const FounderHiringPage(),
      ),
      GoRoute(
        path: Routes.founderMedia,
        builder: (_, __) => const FounderMediaLivePage(),
      ),
      GoRoute(
        path: Routes.founderAnalytics,
        builder: (_, __) => const RoleAnalyticsPage(role: UserRole.founder),
      ),
      GoRoute(
        path: Routes.founderReports,
        builder: (_, __) => const ClientReportsHubPage(),
      ),
      GoRoute(
        path: Routes.founderCreateProject,
        builder: (_, s) =>
            CreateProjectPage(projectId: s.uri.queryParameters['projectId']),
      ),
      GoRoute(
        path: Routes.founderCreateStartup,
        builder: (_, __) => const MyStartupStandalonePage(),
      ),
      GoRoute(
        path: Routes.founderAddTask,
        builder: (_, s) => ClientAddTaskPage(
          task: s.extra is ClientTask ? s.extra as ClientTask : null,
        ),
      ),
      GoRoute(
        path: Routes.createProject,
        builder: (_, s) =>
            CreateProjectPage(projectId: s.uri.queryParameters['projectId']),
      ),
      GoRoute(
        path: Routes.createStartup,
        builder: (_, __) => const MyStartupStandalonePage(),
      ),
      GoRoute(
        path: '${Routes.publicFreelancer}/:id',
        builder: (_, s) => PublicProfilePage(
          type: PublicProfileType.freelancer,
          id: s.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '${Routes.publicCompany}/:id',
        builder: (_, s) => PublicProfilePage(
          type: PublicProfileType.company,
          id: s.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '${Routes.publicInvestor}/:id',
        builder: (_, s) => PublicProfilePage(
          type: PublicProfileType.investor,
          id: s.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '${Routes.publicFounder}/:id',
        builder: (_, s) => PublicProfilePage(
          type: PublicProfileType.founder,
          id: s.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '${Routes.freelancerProfile}/:id',
        builder: (_, s) => PublicProfilePage(
          type: PublicProfileType.freelancer,
          id: s.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '${Routes.clientProfile}/:id',
        builder: (_, s) => PublicProfilePage(
          type: PublicProfileType.company,
          id: s.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '${Routes.investorProfile}/:id',
        builder: (_, s) => PublicProfilePage(
          type: PublicProfileType.investor,
          id: s.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '${Routes.founderProfile}/:id',
        builder: (_, s) => PublicProfilePage(
          type: PublicProfileType.founder,
          id: s.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '${Routes.profile}/:id',
        builder: (_, s) {
          final qType = s.uri.queryParameters['type']?.toLowerCase();
          final type = switch (qType) {
            'client' || 'company' => PublicProfileType.company,
            'investor' => PublicProfileType.investor,
            'founder' => PublicProfileType.founder,
            _ => PublicProfileType.freelancer,
          };
          return PublicProfilePage(
            type: type,
            id: s.pathParameters['id']!,
          );
        },
      ),
      GoRoute(
        path: '/u/:id',
        builder: (_, s) {
          final qType = s.uri.queryParameters['type']?.toLowerCase();
          final type = switch (qType) {
            'client' || 'company' => PublicProfileType.company,
            'investor' => PublicProfileType.investor,
            'founder' => PublicProfileType.founder,
            _ => PublicProfileType.freelancer,
          };
          return PublicProfilePage(
            type: type,
            id: s.pathParameters['id']!,
          );
        },
      ),
    ],
  );
}

