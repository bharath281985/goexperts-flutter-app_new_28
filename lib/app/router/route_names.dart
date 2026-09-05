/// Central registry of route paths + names for deep linking and navigation.
class Routes {
  Routes._();

  // Auth flow
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const otp = '/otp';
  static const resetPassword = '/reset-password';
  static const emailVerification = '/email-verification';
  static const phoneVerification = '/phone-verification';
  static const roleSelection = '/role-selection';
  static const profileCompletion = '/profile-completion';
  static const subscription = '/subscription';
  static const authSuccess = '/success';

  // Freelancer
  static const freelancerDashboard = '/freelancer/dashboard';
  static const freelancerProjects = '/freelancer/projects';
  static const freelancerMyProjects = '/freelancer/my-projects';
  static const freelancerProposals = '/freelancer/proposals';
  static const freelancerWallet = '/freelancer/wallet';
  static const freelancerProfile = '/freelancer/profile';
  static const freelancerEditProfile = '/freelancer/edit-profile';
  static const freelancerProfessionalDetails =
      '/freelancer/professional-details';
  static const freelancerVerification = '/freelancer/verification';
  static const freelancerPortfolioPage = '/freelancer/portfolio';
  static const freelancerPortfolioDetails = '/freelancer/portfolio-detail';
  static const freelancerPortfolioForm = '/freelancer/portfolio-form';
  static const freelancerResumeTemplates = '/freelancer/resume-templates';

  // Client
  static const clientDashboard = '/client/dashboard';
  static const clientProjects = '/client/projects';
  static const clientMyProjects = '/client/my-projects';
  static const clientCreateProject = '/client/create-project';
  static const clientTasks = '/client/tasks';
  static const clientAddTask = '/client/tasks/add';
  static const clientFreelancers = '/client/freelancers';
  static const clientPayments = '/client/payments';
  static const clientProfile = '/client/profile';
  static const clientVerification = '/client/verification';

  // Investor
  static const investorDashboard = '/investor/dashboard';
  static const investorMyProjects = '/investor/my-projects';
  static const investorStartups = '/investor/startups';
  static const investorDeals = '/investor/deals';
  static const investorPortfolio = '/investor/portfolio';
  static const investorProfile = '/investor/profile';
  static const investorVerification = '/investor/verification';

  // Founder
  static const founderDashboard = '/founder/dashboard';
  static const founderMyProjects = '/founder/my-projects';
  static const founderStartup = '/founder/startup';
  static const founderListStartup = '/founder/list-startup';
  static const founderInvestors = '/founder/investors';
  static const founderFunding = '/founder/funding';
  static const founderProfile = '/founder/profile';
  static const founderVerification = '/founder/verification';

  // Common
  static const profile = '/profile';
  static const myProjects = '/my-projects';
  static const myReviews = '/my-reviews';
  static const verification = '/verification';
  static const messages = '/messages';
  static const meetings = '/meetings';
  static const notifications = '/notifications';
  static const settings = '/settings';
  static const support = '/support';
  static const search = '/search';
  static const bookmarks = '/bookmarks';
  static const wallet = '/wallet';
  static const subscriptionsManage = '/subscriptions';
  static const referrals = '/referrals';
  static const securityCenter = '/security';
  static const changePassword = '/change-password';
  static const privacyPolicy = '/privacy';
  static const termsOfService = '/terms';
  static const legalDocument = '/legal-document';
  static const aboutGoExperts = '/about-goexperts';
  static const refundPolicy = '/refund-policy';
  static const helpCenter = '/help-center';
  static const contactUs = '/contact-us';
  static const deleteAccount = '/delete-account';

  // Detail routes (deep-link ready)
  static const chat = '/chat'; // /chat/:id
  static const projectDetails = '/project'; // /project/:id
  static const startupDetails = '/startup'; // /startup/:id
  static const proposalDetails = '/proposal'; // /proposal/:id
  static const meetingDetails = '/meeting'; // /meeting/:id
  static const contractDetails = '/contract'; // /contract/:id
  static const contractForm = '/contract-form';
  static const invoiceDetails = '/invoice'; // /invoice/:id
  static const transactionDetails = '/transaction'; // /transaction/:id
  static const certificateDetails = '/certificate'; // /certificate/:id
  static const reviewDetails = '/review'; // /review/:id
  static const opportunityDetails = '/opportunity'; // /opportunity/:id
  static const businessPlanDetails =
      '/business-plan'; // /business-plan/:id (startup id)
  static const pitchDeckDetails = '/pitch-deck'; // /pitch-deck/:id (startup id)
  static const serviceDetails = '/service'; // /service/:id
  static const technologyDetails = '/technology'; // /technology/:id
  static const categoryDetails = '/category'; // /category/:id
  static const publicFreelancer = '/u/freelancer'; // /u/freelancer/:id
  static const publicCompany = '/u/company'; // /u/company/:id
  static const publicInvestor = '/u/investor'; // /u/investor/:id
  static const publicFounder = '/u/founder'; // /u/founder/:id

  // Enterprise flows
  static const apply = '/apply'; // /apply?type=...
  static const invitations = '/invitations';
  static const documentViewer = '/document';
  static const calendar = '/calendar';

  // Role sub-pages — Freelancer
  static const freelancerContracts = '/freelancer/contracts';
  static const freelancerTasks = '/freelancer/tasks';
  static const freelancerReviews = '/freelancer/reviews';
  static const freelancerCertificates = '/freelancer/certificates';
  static const freelancerSkills = '/freelancer/skills';
  static const freelancerExperience = '/freelancer/experience';
  static const freelancerEducation = '/freelancer/education';
  static const freelancerWithdrawals = '/freelancer/withdrawals';
  static const freelancerInvoices = '/freelancer/invoices';
  static const freelancerAnalytics = '/freelancer/analytics';
  static const freelancerFreelancers = '/freelancer/freelancers';
  static const freelancerApplications = '/freelancer/applications';
  static const freelancerTeams = '/freelancer/teams';
  static const freelancerTeamAccess = '/freelancer/team-access';
  static const freelancerStartups = '/freelancer/startups';
  static const freelancerDeals = '/freelancer/deals';
  static const freelancerOffers = '/freelancer/offers';
  static const freelancerPitchDeck = '/freelancer/pitch-deck';
  static const freelancerBusinessPlan = '/freelancer/business-plan';
  static const freelancerInvestors = '/freelancer/investors';
  static const freelancerFunding = '/freelancer/funding';
  static const freelancerReports = '/freelancer/reports';
  static const freelancerCreateProject = '/freelancer/create-project';
  static const freelancerCreateStartup = '/freelancer/create-startup';
  static const freelancerAddTask = '/freelancer/tasks/add';

  // Role sub-pages — Client
  static const clientApplications = '/client/applications';
  static const clientProposals = '/client/proposals';
  static const clientContracts = '/client/contracts';
  static const clientPortfolioPage = '/client/portfolio';
  static const clientShortlisted = '/client/shortlisted';
  static const clientTeams = '/client/teams';
  static const clientTeamAccess = '/client/team-access';
  static const clientReports = '/client/reports';
  static const clientAnalytics = '/client/analytics';
  static const clientStartups = '/client/startups';
  static const clientDeals = '/client/deals';
  static const clientOffers = '/client/offers';
  static const clientPitchDeck = '/client/pitch-deck';
  static const clientBusinessPlan = '/client/business-plan';
  static const clientInvestors = '/client/investors';
  static const clientFunding = '/client/funding';
  static const clientCreateStartup = '/client/create-startup';

  // Role sub-pages — Investor
  static const investorProjects = '/investor/projects';
  static const investorProposals = '/investor/proposals';
  static const investorContracts = '/investor/contracts';
  static const investorTasks = '/investor/tasks';
  static const investorFreelancers = '/investor/freelancers';
  static const investorApplications = '/investor/applications';
  static const investorTeams = '/investor/teams';
  static const investorTeamAccess = '/investor/team-access';
  static const investorPortfolioPage = '/investor/portfolio-page';
  static const investorPreferences = '/investor/preferences';
  static const investorDueDiligence = '/investor/due-diligence';
  static const investorOffers = '/investor/offers';
  static const investorDocuments = '/investor/documents';
  static const investorTransactions = '/investor/transactions';
  static const investorReports = '/investor/reports';
  static const investorAnalytics = '/investor/analytics';
  static const investorPitchDeck = '/investor/pitch-deck';
  static const investorBusinessPlan = '/investor/business-plan';
  static const investorInvestors = '/investor/investors';
  static const investorFunding = '/investor/funding';
  static const investorCreateProject = '/investor/create-project';
  static const investorCreateStartup = '/investor/create-startup';
  static const investorAddTask = '/investor/tasks/add';

  // Role sub-pages — Founder
  static const founderProjects = '/founder/projects';
  static const founderProposals = '/founder/proposals';
  static const founderContracts = '/founder/contracts';
  static const founderTasks = '/founder/tasks';
  static const founderFreelancers = '/founder/freelancers';
  static const founderApplications = '/founder/applications';
  static const founderTeams = '/founder/teams';
  static const founderTeamAccess = '/founder/team-access';
  static const founderPortfolioPage = '/founder/portfolio-page';
  static const founderStartups = '/founder/startups';
  static const founderDeals = '/founder/deals';
  static const founderOffers = '/founder/offers';
  static const founderPitchDeck = '/founder/pitch-deck';
  static const founderBusinessPlan = '/founder/business-plan';
  static const founderTeam = '/founder/team';
  static const founderHiring = '/founder/hiring';
  static const founderMedia = '/founder/media';
  static const founderAnalytics = '/founder/analytics';
  static const founderReports = '/founder/reports';
  static const founderCreateProject = '/founder/create-project';
  static const founderCreateStartup = '/founder/create-startup';
  static const founderAddTask = '/founder/tasks/add';

  // Universal create shortcuts
  static const createProject = '/create-project';
  static const createStartup = '/create-startup';
}
