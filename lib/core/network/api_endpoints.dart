import '../../app/config/app_config.dart';

/// Centralized API endpoint paths (base URL configured in `AppConfig.baseUrl`).
class ApiEndpoints {
  ApiEndpoints._();

  // ── Auth ──────────────────────────────────────────────────────────────────
  static const register = '/auth/register';
  static const login = '/auth/login';
  static const logout = '/auth/logout';
  static const refreshToken = '/auth/refresh';
  static const me = '/auth/me';
  static const updateMe = '/auth/me';
  static const updateMeAvatar = '/auth/me/avatar';
  static const forgotPassword = '/auth/forgot-password';
  static const resetPassword = '/auth/reset-password';
  static const changePassword = '/auth/change-password';
  static const sendOtp = '/auth/send-otp';
  static const verifyOtp = '/auth/verify-otp';
  static const resendOtp = '/auth/resend-otp';
  static const sendEmailVerification = '/auth/send-email-verification';
  static const verifyEmailVerification = '/auth/verify-email';
  static const resendEmailVerification = '/auth/resend-email-verification';
  static const onboardingDraft = '/auth/onboarding/draft';

  // ── Public ────────────────────────────────────────────────────────────────
  static const publicHome = '/public/home';
  static const publicCategories = '/public/categories';
  static const publicIndustries = '/public/industries';
  static const publicBusinessTypes = '/public/business-types';
  static const publicCountries = '/public/countries';
  static const publicFounderTypes = '/public/founder-types';
  static const publicStartupStages = '/public/startup-stages';
  static const publicInvestorTypes = '/public/investor-types';
  static const publicInvestorStages = '/public/investor-stages';
  static String get publicAccreditedStatuses =>
      '${AppConfig.authBaseUrl}/public/accredited_statuses';
  static const publicHiringGoals = '/public/hiring-goals';
  static const publicHiringBudgetRanges = '/public/hiring-budget-ranges';
  static const publicStartupRoles = '/public/founder-roles';
  static const publicFounderRoles = '/public/founder-roles';
  static const publicFounderGoals = '/public/founder-goals';
  static const publicRootInvestorTypes = '/investor-types';
  static const publicMobileStartupStages = '/startup-stages';
  static const publicMobileCategories = '/categories';
  static const publicInvestmentModes = '/investment-modes';
  static const publicInvestorGoals = '/investor-goals';
  static const publicMobileTicketSizes = '/ticket-sizes';
  static const publicCompanySizes = '/public/company-sizes';
  static const publicTeamSizes = '/public/team-sizes';
  static const publicSkills = '/public/skills';
  static const publicFreelancers = '/public/freelancers';
  static const publicClients = '/public/clients';
  static const publicInvestors = '/public/investors';
  static const publicFounders = '/public/founders';
  static const publicStartups = '/public/startups';
  static const publicProjects = '/public/projects';
  static const publicPricing = '/public/pricing';
  static const publicPricingPlans = '/pricing_plans';
  static const publicPaymentsCheckout = '/payments/checkout';
  static const publicBlogs = '/public/blogs';
  static const publicFaqs = '/public/faqs';
  static const publicTestimonials = '/public/testimonials';
  static const publicSearch = '/public/search';

  static const publicClientGoals = '/client-goals';
  static const publicExpansionGoals = '/expansion-goals';
  static const publicStates = '/public/states';
  static const publicExperienceLevels = '/public/experience-levels';
  static const publicAvailabilities = '/public/availabilities';
  static const publicWorkModes = '/public/work-modes';

  static const publicTasks = '/public/tasks';
  static const publicVerification = '/public/verification';
  static const publicMyStartups = '/public/startups/my-startups';
  static const publicPitchDeck = '/public/pitch-deck';
  static const publicBusinessPlan = '/public/business-plan';
  static const publicFunding = '/public/funding';
  static const publicInvestmentsOffer = '/public/investments/offer';
  static const publicInvestments = '/public/investments';
  static const publicInvestorRequests = '/public/investor-requests';
  static const publicSavedProjects = '/public/projects/saved';
  static const publicSavedFreelancers = '/public/freelancers/saved';
  static const publicSavedStartups = '/public/startups/saved';
  static const publicSavedInvestors = '/public/investors/saved';
  static const publicSavedFounders = '/public/founders/saved';

  static String publicFreelancer(String id) => '/public/freelancers/$id';
  static String publicFreelancerPortfolio(String freelancerId) =>
      '/public/freelancers/$freelancerId/portfolio';
  static String publicFreelancerPortfolioItem(
    String freelancerId,
    String itemId,
  ) => '/public/freelancers/$freelancerId/portfolio/$itemId';
  static String publicFreelancerSave(String id) =>
      '/public/freelancers/$id/save';
  static String publicClient(String id) => '/public/clients/$id';
  static String publicInvestor(String id) => '/public/investors/$id';
  static String publicInvestorPortfolio(String investorId) =>
      '/public/investors/$investorId/portfolio';
  static String publicInvestorPortfolioItem(String investorId, String itemId) =>
      '/public/investors/$investorId/portfolio/$itemId';
  static String publicInvestorSave(String id) => '/public/investors/$id/save';
  static String publicStartup(String id) => '/public/startups/$id';
  static String publicStartupSave(String id) => '/public/startups/$id/save';
  static String publicFounder(String id) => '/public/founders/$id';
  static String publicFounderSave(String id) => '/public/founders/$id/save';
  static String publicTask(String id) => '/public/tasks/$id';
  static String publicInvestorRequestAccept(String id) =>
      '/public/investor-requests/$id/accept';
  static String publicInvestorRequestReject(String id) =>
      '/public/investor-requests/$id/reject';
  static String publicInvestorRequestMeeting(String id) =>
      '/public/investor-requests/$id/meeting';

  // ── Shared ────────────────────────────────────────────────────────────────
  static const referrals = '/referrals';
  static const notifications = '/notifications';
  static const notificationsUnreadCount = '/notifications/unread-count';
  static String notificationRead(String id) => '/notifications/$id/read';
  static const notificationsReadAll = '/notifications/read-all';
  static String notificationDelete(String id) => '/notifications/$id';
  static const wallet = '/wallet';
  static const walletTransactions = '/wallet/transactions';
  static const subscriptionPlans = '/subscriptions/plans';
  static const subscriptionCurrent = '/subscriptions/current';
  static const invoices = '/invoices';
  static const supportTickets = '/support/tickets';
  static String supportTicket(String id) => '/support/tickets/$id';
  static String supportTicketReply(String id) => '/support/tickets/$id/reply';
  static String supportTicketClose(String id) => '/support/tickets/$id/close';
  static const files = '/files';
  static const filesUpload = '/files/upload';
  static const favorites = '/favorites';
  static String fileById(String id) => '/files/$id';
  static String filePreview(String id) => '/files/$id/preview';
  static String fileDownload(String id) => '/files/$id/download';
  static const search = '/search';
  static const searchSuggestions = '/search/suggestions';

  static String favoriteById(String id) => '/favorites/$id';
  static const discoveryRecentlyViewed = '/discovery/recently-viewed';
  static const discoveryRecommendations = '/discovery/recommendations';
  static const chatConversations = '/chat/conversations';
  static String chatConversation(String id) => '/chat/conversations/$id';
  static const chatSend = '/chat/send';
  static String chatMessageRead(String id) => '/chat/messages/$id/read';
  static const chatAttachments = '/chat/attachments';
  static const notificationsPreferences = '/notifications/preferences';
  static const appConfig = '/app/config';
  static const appVersion = '/app/version';
  static const appMaintenance = '/app/maintenance';
  static const appFeatureFlags = '/app/feature-flags';
  static const appDeviceToken = '/app-config/device-token';

  // ── Payments ──────────────────────────────────────────────────────────────
  static const paymentsGateways = '/payments/gateways';
  static const paymentsInitiate = '/payments/initiate';
  static const paymentsVerify = '/payments/verify';

  // ── Social auth ─────────────────────────────────────────────────────────
  static const socialGoogle = '/auth/social/google';
  static const socialApple = '/auth/social/apple';

  // ── Freelancer ────────────────────────────────────────────────────────────
  static const freelancerDashboard = '/freelancer/dashboard';
  static const freelancerProfile = '/freelancer/profile';
  static const freelancerProfileAvatar = '/freelancer/profile/avatar';
  static const freelancerProfileResume = '/freelancer/profile/resume';
  static String get publicResumeTemplates =>
      '${AppConfig.authBaseUrl}/public/resume-templates';
  static const freelancerProfileKyc = '/freelancer/profile/kyc';
  static const freelancerProjects = '/freelancer/projects';
  static String freelancerProject(String id) => '/freelancer/projects/$id';
  static const freelancerProjectsApplied = '/freelancer/projects/applied';
  static const freelancerProjectsInvited = '/freelancer/projects/invited';
  static const freelancerProjectsSaved = '/freelancer/projects/saved';
  // Save / unsave project (freelancer side)
  static String freelancerProjectSave(String id) =>
      '/freelancer/projects/$id/save';
  static String publicProjectSave(String id) => '/public/projects/$id/save';
  static const publicProjectsSaved = '/public/projects/saved';
  static const freelancerProjectsRecommended =
      '/freelancer/projects/recommended';
  static const freelancerProjectsNearby = '/freelancer/projects/nearby';
  static const freelancerProjectsSearch = '/freelancer/projects/search';
  static const freelancerStartups = '/freelancer/startups';
  static const freelancerIdeas = '/freelancer/ideas';
  static const freelancerMyStartups = '/freelancer/startups/my-startups';
  static const freelancerProposals = '/freelancer/proposals';
  static String freelancerProposal(String id) => '/freelancer/proposals/$id';
  static String freelancerProposalWithdraw(String id) =>
      '/freelancer/proposals/$id/withdraw';
  static String freelancerProposalAcceptOffer(String id) =>
      '/freelancer/proposals/$id/accept-offer';
  static const freelancerPortfolio = '/freelancer/portfolio';
  static String freelancerPortfolioItem(String id) =>
      '/freelancer/portfolio/$id';
  static const freelancerEducation = '/freelancer/education';
  static String freelancerEducationItem(String id) =>
      '/freelancer/education/$id';
  static const freelancerCertificates = '/freelancer/certificates';
  static String freelancerCertificateItem(String id) =>
      '/freelancer/certificates/$id';
  static const freelancerExperience = '/freelancer/experience';
  static String freelancerExperienceItem(String id) =>
      '/freelancer/experience/$id';
  static const freelancerProfessionalDetails =
      '/freelancer/professional-details';
  static String freelancerProfessionalDetailsItem(String id) =>
      '/freelancer/professional-details/$id';
  static const freelancerVerification = '/freelancer/verification';
  static const freelancerContracts = '/freelancer/contracts';
  static String freelancerContract(String id) => '/freelancer/contracts/$id';
  static String freelancerContractMilestones(String id) =>
      '/freelancer/contracts/$id/milestones';
  static String freelancerContractTimeline(String id) =>
      '/freelancer/contracts/$id/timeline';
  static String freelancerContractDocuments(String id) =>
      '/freelancer/contracts/$id/documents';
  static String freelancerContractAccept(String id) =>
      '/freelancer/contracts/$id/accept';
  static String freelancerContractReject(String id) =>
      '/freelancer/contracts/$id/reject';
  static const freelancerTasks = '/freelancer/tasks';
  static String freelancerTask(String id) => '/freelancer/tasks/$id';
  static String freelancerTaskStatus(String id) =>
      '/freelancer/tasks/$id/status';
  static String freelancerTaskTimerStart(String id) =>
      '/freelancer/tasks/$id/timer/start';
  static String freelancerTaskTimerStop(String id) =>
      '/freelancer/tasks/$id/timer/stop';
  static String freelancerTaskTimeLog(String id) =>
      '/freelancer/tasks/$id/time-log';
  static const freelancerMeetings = '/freelancer/meetings';
  static const freelancerMeetingsUpcoming = '/freelancer/meetings/upcoming';
  static String freelancerMeeting(String id) => '/freelancer/meetings/$id';
  static const freelancerMessages = '/freelancer/messages';
  static String freelancerMessage(String id) => '/freelancer/messages/$id';
  static const freelancerWallet = '/freelancer/wallet';
  static const freelancerWalletTransactions = '/freelancer/wallet/transactions';
  static const freelancerWalletWithdraw = '/freelancer/wallet/withdraw';
  static const freelancerWalletCredits = '/freelancer/wallet/credits';
  static const freelancerWalletDebits = '/freelancer/wallet/debits';
  static const freelancerWalletPendingPayouts =
      '/freelancer/wallet/pending-payouts';
  static const freelancerWalletPaymentHistory =
      '/freelancer/wallet/payment-history';
  static const freelancerAnalytics = '/freelancer/analytics';
  static const freelancerEarningsMonthly = '/freelancer/earnings/monthly';
  static const freelancerEarningsYearly = '/freelancer/earnings/yearly';
  static const freelancerEarningsByCategory =
      '/freelancer/earnings/by-category';
  static const freelancerEarningsByClient = '/freelancer/earnings/by-client';
  static const freelancerEarningsStatement = '/freelancer/earnings/statement';
  static const freelancerReviews = '/freelancer/reviews';
  static const freelancerReviewsAverage = '/freelancer/reviews/average';
  static const freelancerReviewsBreakdown = '/freelancer/reviews/breakdown';
  static String freelancerReviewReply(String id) =>
      '/freelancer/reviews/$id/reply';

  static const freelancerSubscription = '/freelancer/subscription';
  static const freelancerSubscriptionPlans = '/freelancer/subscription/plans';
  static const freelancerSubscriptionUpgrade =
      '/freelancer/subscription/upgrade';
  static const freelancerSubscriptionRenew = '/freelancer/subscription/renew';
  static const freelancerSubscriptionCancel = '/freelancer/subscription/cancel';
  static const freelancerSubscriptionUsage = '/freelancer/subscription/usage';
  static const freelancerSubscriptionBenefits =
      '/freelancer/subscription/benefits';

  static const freelancerDocuments = '/freelancer/documents';
  static const freelancerDocumentsUpload = '/freelancer/documents/upload';
  static String freelancerDocumentDownload(String id) =>
      '/freelancer/documents/$id/download';
  static String freelancerDocumentPreview(String id) =>
      '/freelancer/documents/$id/preview';
  static String freelancerDocumentDelete(String id) =>
      '/freelancer/documents/$id';

  static const freelancerNotifications = '/freelancer/notifications';
  static const freelancerNotificationsUnreadCount =
      '/freelancer/notifications/unread-count';
  static String freelancerNotificationRead(String id) =>
      '/freelancer/notifications/$id/read';
  static const freelancerNotificationsReadAll =
      '/freelancer/notifications/read-all';
  static String freelancerNotificationDelete(String id) =>
      '/freelancer/notifications/$id';
  static const freelancerNotificationPreferences =
      '/freelancer/notifications/preferences';

  static const freelancerSettings = '/freelancer/settings';
  static const freelancerSearch = '/freelancer/search';
  static const freelancerSearchProjects = '/freelancer/search/projects';
  static const freelancerSearchClients = '/freelancer/search/clients';
  static const freelancerSearchSkills = '/freelancer/search/skills';

  // ── Client ────────────────────────────────────────────────────────────────
  static const clientDashboard = '/client/dashboard';
  static const clientProfile = '/client/profile';
  static const clientProfileLogo = '/client/profile/logo';
  static const clientProfileDocuments = '/client/profile/documents';
  static const clientVerification = '/client/verification';
  static const clientStartups = '/client/startups';
  static const clientIdeas = '/client/ideas';
  static const clientMyStartups = '/client/startups/my-startups';
  static const clientProjects = '/client/projects';
  static String clientProject(String id) => '/client/projects/$id';
  static String clientProjectInvite(String id) => '/client/projects/$id/invite';
  static String clientProjectStatus(String id) => '/client/projects/$id/status';
  static String clientProjectShare(String id) => '/client/projects/$id/share';
  static String clientProjectProposals(String projectId) =>
      '/client/projects/$projectId/proposals';
  static const clientProposals = '/client/proposals';
  static String clientProposal(String id) => '/client/proposals/$id';
  static String clientProposalShortlist(String id) =>
      '/client/proposals/$id/shortlist';
  static String clientProposalReject(String id) =>
      '/client/proposals/$id/reject';
  static String clientProposalInterview(String id) =>
      '/client/proposals/$id/interview';
  static String clientProposalAccept(String id) =>
      '/client/proposals/$id/accept';
  static String clientProposalMessage(String id) =>
      '/client/proposals/$id/message';
  static const clientFreelancers = '/client/freelancers';
  // Save / unsave freelancer (client side)
  static String clientFreelancerSave(String id) =>
      '/client/freelancers/$id/save';
  static const clientFreelancersSaved = '/client/freelancers/saved';
  static const clientContracts = '/client/contracts';
  static String clientContract(String id) => '/client/contracts/$id';
  static String clientContractActivate(String id) =>
      '/client/contracts/$id/activate';
  static String clientContractComplete(String id) =>
      '/client/contracts/$id/complete';
  static String clientContractCancel(String id) =>
      '/client/contracts/$id/cancel';
  static const clientTasks = '/client/tasks';
  static String clientTaskStatus(String id) => '/client/tasks/$id/status';
  static const clientMilestones = '/client/milestones';
  static String clientMilestoneApprove(String id) =>
      '/client/milestones/$id/approve';
  static String clientMilestoneReject(String id) =>
      '/client/milestones/$id/reject';
  static const clientMeetings = '/client/meetings';
  static const clientMessagesConversations = '/client/messages/conversations';
  static String clientMessageConversation(String id) =>
      '/client/messages/conversations/$id';
  static const clientMessagesSend = '/client/messages/send';
  static String clientMessageRead(String id) => '/client/messages/$id/read';
  static const clientMessagesAttachments = '/client/messages/attachments';
  static const clientPayments = '/client/payments';
  static const clientPaymentsInitiate = '/client/payments/initiate';
  static const clientPaymentsVerify = '/client/payments/verify';
  static const clientInvoices = '/client/invoices';
  static const clientWallet = '/client/wallet';
  static const clientWalletTransactions = '/client/wallet/transactions';
  static const clientReviews = '/client/reviews';
  static const clientAnalytics = '/client/analytics';
  static const clientSupportTickets = '/client/support/tickets';
  static const clientDocuments = '/client/documents';

  // ── Investor ──────────────────────────────────────────────────────────────
  static const investorDashboard = '/investor/dashboard';
  static const investorProfile = '/investor/profile';
  static const investorProfileAvatar = '/investor/profile/avatar';
  static const investorProfileDocuments = '/investor/profile/documents';
  static const investorStartups = '/investor/startups';
  static const investorIdeas = '/investor/ideas';
  static const investorMyStartups = '/investor/startups/my-startups';
  static String investorStartup(String id) => '/investor/startups/$id';
  static const investorStartupsRecommended = '/investor/startups/recommended';
  static const investorStartupsTrending = '/investor/startups/trending';
  static String investorStartupSave(String id) => '/investor/startups/$id/save';
  static String investorFounderSave(String id) => '/investor/founders/$id/save';
  static const investorWatchlist = '/investor/watchlist';
  static const investorWatchlistFounders = '/investor/watchlist/founders';
  static String investorWatchlistItem(String id) => '/investor/watchlist/$id';
  static String investorWatchlistNotes(String id) =>
      '/investor/watchlist/$id/notes';
  static String investorWatchlistPriority(String id) =>
      '/investor/watchlist/$id/priority';
  static const investorInvestments = '/investor/investments';
  static String investorInvestment(String id) => '/investor/investments/$id';
  static String investorCancelInvestment(String id) =>
      '/investor/investments/$id/cancel';
  static const investorInvestmentsExpressInterest =
      '/investor/investments/express-interest';
  static const investorOffer = '/investor/investments/offer';
  static String investorInvestmentStatus(String id) =>
      '/investor/investments/$id/status';
  static const investorPortfolio = '/investor/portfolio';
  static String investorPortfolioItem(String id) => '/investor/portfolio/$id';
  static const investorPortfolioPerformance = '/investor/portfolio/performance';
  static const investorPortfolioAllocation = '/investor/portfolio/allocation';
  static const investorPortfolioRoi = '/investor/portfolio/roi';
  static const investorMeetings = '/investor/meetings';
  static const investorMessagesConversations =
      '/investor/messages/conversations';
  static const investorMessagesSend = '/investor/messages/send';
  static const investorDocuments = '/investor/documents';
  static const investorDocumentsUpload = '/investor/documents/upload';
  static const investorReports = '/investor/reports';
  static const investorReportsPortfolio = '/investor/reports/portfolio';
  static const investorReportsRoi = '/investor/reports/roi';
  static const investorAnalytics = '/investor/analytics';
  static const investorWallet = '/investor/wallet';
  static const investorWalletTransactions = '/investor/wallet/transactions';
  static const investorWalletWithdraw = '/investor/wallet/withdraw';
  static const investorVerification = '/investor/verification';

  // ── Founder ───────────────────────────────────────────────────────────────
  static const founderIdeas = '/founder/ideas';
  static String founderIdea(String id) => '/founder/ideas/$id';
  static const founderDashboard = '/founder/dashboard';
  // Founder personal profile uses the startup profile endpoints on the API.
  static const founderProfile = '/founder/profile';
  static const founderVerification = '/founder/verification';
  static const founderStartup = '/founder/startup';
  static const founderFunding = '/founder/funding';
  static String founderFundingById(String id) => '/founder/funding/$id';
  static String founderFundingStatus(String id) =>
      '/founder/funding/$id/status';
  static const founderInvestorRequests = '/founder/investor-requests';
  static String founderInvestorRequest(String id) =>
      '/founder/investor-requests/$id';
  static String founderInvestorRequestAccept(String id) =>
      '/founder/investor-requests/$id/accept';
  static String founderInvestorRequestReject(String id) =>
      '/founder/investor-requests/$id/reject';
  static String founderInvestorRequestMeeting(String id) =>
      '/founder/investor-requests/$id/meeting';
  static String founderInvestorRequestMessage(String id) =>
      '/founder/investor-requests/$id/message';
  static const founderInvestors = '/founder/investors';
  static String founderInvestor(String id) => '/founder/investors/$id';
  static const founderInvestorsRecommended = '/founder/investors/recommended';
  static const founderInvestorsInterested = '/founder/investors/interested';
  static const founderInvestorsActive = '/founder/investors/active';
  static const founderPitchDeck = '/founder/pitch-deck';
  static const founderBusinessPlan = '/founder/business-plan';
  static const founderDocuments = '/founder/documents';
  static const founderDocumentsUpload = '/founder/documents/upload';
  static const founderMeetings = '/founder/meetings';
  static const founderMessagesConversations = '/founder/messages/conversations';
  static const founderMessagesSend = '/founder/messages/send';
  static const founderReports = '/founder/reports';
  static const founderAnalytics = '/founder/analytics';
  static const founderWallet = '/founder/wallet';
  static const founderWalletWithdraw = '/founder/wallet/withdraw';
  static const founderInvoices = '/founder/invoices';
  static const founderSubscriptionsCurrent = '/founder/subscriptions/current';
  static const founderSubscriptionsPlans = '/founder/subscriptions/plans';
  static String founderProposal(String id) => '/founder/proposals/$id';
  static String founderProposalAccept(String id) =>
      '/founder/proposals/$id/accept';
  static String founderProposalReject(String id) =>
      '/founder/proposals/$id/reject';

  // ── Universal Dynamic Role Endpoints ─────────────────────────────────────
  static String rolePath(dynamic role) {
    if (role == null) return 'client';
    final name = role.toString().split('.').last.toLowerCase();
    switch (name) {
      case 'freelancer':
        return 'freelancer';
      case 'client':
      case 'company':
        return 'client';
      case 'investor':
        return 'investor';
      case 'founder':
        return 'founder';
      default:
        return name;
    }
  }

  static String roleProjects(dynamic role) => '/${rolePath(role)}/projects';
  static String roleProject(dynamic role, String id) =>
      '/${rolePath(role)}/projects/$id';
  static String roleProjectStatus(dynamic role, String id) =>
      '/${rolePath(role)}/projects/$id/status';
  static String roleProjectShare(dynamic role, String id) =>
      '/${rolePath(role)}/projects/$id/share';
  static String roleProjectProposals(dynamic role, String projectId) =>
      '/${rolePath(role)}/projects/$projectId/proposals';

  static String roleTasks(dynamic role) => '/${rolePath(role)}/tasks';
  static String roleTask(dynamic role, String id) =>
      '/${rolePath(role)}/tasks/$id';
  static String roleTaskStatus(dynamic role, String id) =>
      '/${rolePath(role)}/tasks/$id/status';

  static String roleStartups(dynamic role) => '/${rolePath(role)}/startups';
  static String roleStartup(dynamic role, String id) =>
      '/${rolePath(role)}/startups/$id';

  static String roleDeals(dynamic role) => '/${rolePath(role)}/deals';
  static String roleOffers(dynamic role) => '/${rolePath(role)}/offers';
  static String roleOffer(dynamic role, String id) =>
      '/${rolePath(role)}/offers/$id';

  static String roleProposals(dynamic role) => '/${rolePath(role)}/proposals';
  static String roleProposal(dynamic role, String id) =>
      '/${rolePath(role)}/proposals/$id';

  static String roleContracts(dynamic role) => '/${rolePath(role)}/contracts';
  static String roleContract(dynamic role, String id) =>
      '/${rolePath(role)}/contracts/$id';

  static String roleFreelancers(dynamic role) =>
      '/${rolePath(role)}/freelancers';
  static String roleSavedFreelancers(dynamic role) =>
      '/${rolePath(role)}/freelancers/saved';
  static String roleSavedProjects(dynamic role) =>
      '/${rolePath(role)}/projects/saved';
  static String roleSavedStartups(dynamic role) =>
      '/${rolePath(role)}/startups/saved';
  static String roleWatchlist(dynamic role) => '/${rolePath(role)}/watchlist';
  static String roleTeams(dynamic role) => '/${rolePath(role)}/teams';
  static String roleReports(dynamic role) => '/${rolePath(role)}/reports';
  static String roleAnalytics(dynamic role) => '/${rolePath(role)}/analytics';
  static String roleDashboard(dynamic role) => '/${rolePath(role)}/dashboard';
  static String roleWallet(dynamic role) => '/${rolePath(role)}/wallet';

  // ── Legacy aliases (kept for gradual migration) ─────────────────────────────
  static const signup = register;
  static const proposals = '/proposals';
  static const projects = '/projects';
  static String project(String id) => '/projects/$id';
  static const contracts = '/contracts';
  static const freelancers = '/freelancers';
  static const startups = '/startups';
  static const portfolio = '/portfolio';
  static const messages = '/messages';
  static const conversations = '/conversations';
  static const meetings = '/meetings';
  static const transactions = '/wallet/transactions';
  static const subscriptions = '/subscriptions';
  static const bookmarks = '/favorites';
  static const reviews = '/reviews';
  static const support = '/support/tickets';
  static const analytics = '/analytics';
  // Unified Mobile Endpoints
  static const mobileTeam = '/v1/mobile/team';
  static const mobileTeamInvite = '/v1/mobile/team/invite';
  static String mobileTeamMember(String id) => '/v1/mobile/team/$id';
  static String mobileTeamMemberPermissions(String id) => '/v1/mobile/team/$id/permissions';
}
