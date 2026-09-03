import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/enums.dart';
import '../../features/freelancer_dashboard/domain/entities/freelancer.dart';
import '../../features/freelancer_dashboard/domain/repositories/freelancer_repository.dart';
import '../../features/investor_dashboard/domain/entities/investor.dart';
import '../../features/investor_dashboard/domain/repositories/investor_repository.dart';
import '../../features/meetings/domain/entities/meeting.dart';
import '../../features/meetings/domain/repositories/meeting_repository.dart';
import '../../features/messages/domain/repositories/message_repository.dart';
import '../../features/projects/domain/entities/project.dart';
import '../../features/projects/domain/repositories/project_repository.dart';
import '../../features/startup_ideas/domain/entities/startup.dart';
import '../../features/startup_ideas/domain/repositories/startup_repository.dart';
import '../../features/wallet/domain/entities/wallet.dart';
import '../../features/wallet/domain/repositories/wallet_repository.dart';
import '../network/api_client_helper.dart';
import '../network/api_endpoints.dart';

/// Aggregated state powering every role's home dashboard.
class DashboardState extends Equatable {
  const DashboardState({
    this.status = ViewStatus.initial,
    this.meetings = const [],
    this.projects = const [],
    this.freelancers = const [],
    this.startups = const [],
    this.investors = const [],
    this.wallet,
    this.walletBalance = 0.0,
    this.profileCompletionPercent = 0,
    this.activeProjectsCount = 0,
    this.pendingProposalsCount = 0,
    this.monthlyEarnings = 0,
    this.fundingGoal = 0,
    this.topSkills = const [],
    this.earningsChart = const [],
    this.unreadNotificationsCount = 0,
    this.upcomingMeetingsCount = 0,
    this.unreadMessagesCount = 0,
    this.dashboardData = const {},
  });

  final ViewStatus status;
  final List<Meeting> meetings;
  final List<Project> projects;
  final List<Freelancer> freelancers;
  final List<Startup> startups;
  final List<Investor> investors;
  final WalletSummary? wallet;
  final double walletBalance;
  final int profileCompletionPercent;
  final int activeProjectsCount;
  final int pendingProposalsCount;
  final double monthlyEarnings;
  final double fundingGoal;
  final List<String> topSkills;
  final List<double> earningsChart;
  final int unreadNotificationsCount;
  final int upcomingMeetingsCount;
  final int unreadMessagesCount;
  final Map<String, dynamic> dashboardData;

  DashboardState copyWith({
    ViewStatus? status,
    List<Meeting>? meetings,
    List<Project>? projects,
    List<Freelancer>? freelancers,
    List<Startup>? startups,
    List<Investor>? investors,
    WalletSummary? wallet,
    double? walletBalance,
    int? profileCompletionPercent,
    int? activeProjectsCount,
    int? pendingProposalsCount,
    double? monthlyEarnings,
    double? fundingGoal,
    List<String>? topSkills,
    List<double>? earningsChart,
    int? unreadNotificationsCount,
    int? upcomingMeetingsCount,
    int? unreadMessagesCount,
    Map<String, dynamic>? dashboardData,
  }) {
    return DashboardState(
      status: status ?? this.status,
      meetings: meetings ?? this.meetings,
      projects: projects ?? this.projects,
      freelancers: freelancers ?? this.freelancers,
      startups: startups ?? this.startups,
      investors: investors ?? this.investors,
      wallet: wallet ?? this.wallet,
      walletBalance: walletBalance ?? this.walletBalance,
      profileCompletionPercent:
          profileCompletionPercent ?? this.profileCompletionPercent,
      activeProjectsCount: activeProjectsCount ?? this.activeProjectsCount,
      pendingProposalsCount:
          pendingProposalsCount ?? this.pendingProposalsCount,
      monthlyEarnings: monthlyEarnings ?? this.monthlyEarnings,
      fundingGoal: fundingGoal ?? this.fundingGoal,
      topSkills: topSkills ?? this.topSkills,
      earningsChart: earningsChart ?? this.earningsChart,
      unreadNotificationsCount:
          unreadNotificationsCount ?? this.unreadNotificationsCount,
      upcomingMeetingsCount:
          upcomingMeetingsCount ?? this.upcomingMeetingsCount,
      unreadMessagesCount: unreadMessagesCount ?? this.unreadMessagesCount,
      dashboardData: dashboardData ?? this.dashboardData,
    );
  }

  // --- Investor Dashboard Getters ---
  String get investorName {
    final profile = dashboardData['profile'] as Map? ?? {};
    return profile['firstName']?.toString() ??
        profile['fullName']?.toString() ??
        profile['name']?.toString() ??
        'Investor';
  }

  String get investorPendingDeals =>
      (dashboardData['pendingInvestments'] ?? 0).toString();
  String get investorDealsClosed =>
      (dashboardData['closedInvestments'] ?? 0).toString();
  String get investorTotalInvestments =>
      (dashboardData['totalInvestments'] ?? 0).toString();

  double get investorDeployedRaw {
    final val = dashboardData['portfolioValue'] ?? 0.0;
    if (val is num) return val.toDouble();
    return 0.0;
  }

  String get investorWalletBalance {
    final balanceObj = dashboardData['walletBalance'] ?? 0.0;
    return balanceObj is num ? balanceObj.toStringAsFixed(0) : '0';
  }

  List<Map<dynamic, dynamic>> get investorRecentMessages {
    return [];
  }

  String get debugKeys => dashboardData.keys.toString();

  String get investorStartupsFollowing =>
      (dashboardData['watchlistCount'] ?? 0).toString();

  dynamic _dashboardValue(String camelKey, [String? snakeKey]) {
    dynamic readFrom(Map<dynamic, dynamic> source) =>
        source[camelKey] ?? (snakeKey == null ? null : source[snakeKey]);

    final directValue = readFrom(dashboardData);
    if (directValue != null) return directValue;

    for (final nestedKey in const [
      'data',
      'profile',
      'dashboard',
      'freelancerDetails',
      'founderDetails',
      'investorDetails',
    ]) {
      final nested = dashboardData[nestedKey];
      if (nested is Map) {
        final nestedValue = readFrom(nested);
        if (nestedValue != null) return nestedValue;
      }
    }

    return null;
  }

  int get verificationMissingCount {
    var value = _dashboardValue(
      'verificationMissingCount',
      'verification_missing_count',
    );
    print("verificationMissingCount value inside getter: $value");
  
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  

  bool get accountVerified {
    final value = _dashboardValue('accountVerified', 'account_verified');
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }
  

  bool get shouldShowVerificationPrompt =>
      verificationMissingCount > 0 || accountVerified == false;

  /// True when the user has no active subscription (subscription == null).
  bool get isFreePlan {
    final sub = dashboardData['subscription'];
    return sub == null;
  }

  /// Whether to show the free-plan onboarding popup on the dashboard.
  ///
  /// Sequential logic:
  ///   Step 1 — subscription == null? If not null → no popup
  ///   Step 2 — profileCompletion < 100 → show popup (navigate to profile)
  ///   Step 3 — profileCompletion == 100 + verificationMissingCount > 0
  ///                                    → show popup (navigate to verification)
  ///            verificationMissingCount == 0 → no popup (all done)
  bool get shouldShowFreePlanPrompt {
    // Step 1: only show when subscription is null (free plan)
    if (dashboardData['subscription'] != null) return false;
    // Step 2: profile not complete → show popup
    if (dashboardProfileCompletion < 100) return true;
    // Step 3: profile complete → check verification documents
    return verificationMissingCount > 0;
  }

  /// Generic profile completion % that works across all roles.
  /// Reads 'profileCompletion' directly from dashboardData.
  int get dashboardProfileCompletion {
    final val = dashboardData['profileCompletion'];
    if (val is num) return val.toInt();
    return int.tryParse(val?.toString() ?? '') ?? 0;
  }

  /// Universal KYC status across all roles (APPROVED, PENDING, MISSING)
  String get kycStatus =>
      dashboardData['kycStatus']?.toString().toUpperCase() ??
      (accountVerified
          ? 'APPROVED'
          : (verificationMissingCount > 0 ? 'MISSING' : 'PENDING'));

  /// Universal Referrals count across all roles
  int get referralsCount {
    final val = dashboardData['referralsCount'] ??
        dashboardData['referralCount'] ??
        dashboardData['referrals'];
    if (val is num) return val.toInt();
    return int.tryParse(val?.toString() ?? '') ?? 0;
  }

  /// Universal wallet balance across all roles
  double get effectiveWalletBalance {
    final val = dashboardData['walletBalance'];
    if (val is num) return val.toDouble();
    return walletBalance;
  }

  // --- Founder Dashboard Getters ---
  String get founderProfileStrength =>
      (dashboardData['profileCompletion'] ?? 0).toString();
  String get founderSubscriptionStatus =>
      (dashboardData['subscription']?['planName']?.toString() ??
      'Free Founder Plan');
  String get founderAiSuggestions =>
      (dashboardData['widgets']?['aiSuggestions']?.toString() ?? '');
  String get founderStartupStatus =>
      (dashboardData['startupVerificationStatus']?.toString() ?? 'Pending')
          .toUpperCase();
  String get founderInvestorViews =>
      (dashboardData['profileViews'] ?? 0).toString();
  String get founderInvestorInterests =>
      (dashboardData['investorInterests'] ?? 0).toString();
  String get founderPitchDeckViews =>
      (dashboardData['pitchDeckViews'] ?? 0).toString();
  String get founderContactRequests =>
      (dashboardData['unreadMessages'] ?? 0).toString();
  double get founderFundingRaised =>
      (dashboardData['fundingRaised'] as num?)?.toDouble() ?? 0.0;
  double get founderFundingGoal =>
      (dashboardData['fundingGoal'] as num?)?.toDouble() ?? 0.0;
  double get founderWalletBalance =>
      (dashboardData['walletBalance'] as num?)?.toDouble() ?? walletBalance;
  int get founderReferralsCount {
    final val = dashboardData['referralsCount'] ??
        dashboardData['referralCount'] ??
        dashboardData['referrals'];
    if (val is num) return val.toInt();
    return int.tryParse(val?.toString() ?? '') ?? 0;
  }
  String get founderKycStatus =>
      dashboardData['kycStatus']?.toString().toUpperCase() ??
      (accountVerified
          ? 'APPROVED'
          : (verificationMissingCount > 0 ? 'MISSING' : 'PENDING'));

  // --- Freelancer Dashboard Getters ---
  String get freelancerProfileCompletion =>
      (dashboardData['profileCompletion'] ?? 0).toString();
  double get freelancerWalletBalance =>
      (dashboardData['walletBalance'] as num?)?.toDouble() ?? 0.0;
  double get freelancerMonthlyEarnings =>
      (dashboardData['monthlyEarnings'] as num?)?.toDouble() ?? 0.0;
  double get freelancerLifetimeEarnings =>
      (dashboardData['lifetimeEarnings'] as num?)?.toDouble() ?? 0.0;
  String get freelancerAverageRating =>
      (dashboardData['averageRating'] ?? '0.0').toString();
  String get freelancerReviewCount =>
      (dashboardData['reviewCount'] ?? 0).toString();
  String get freelancerActiveContracts =>
      (dashboardData['currentContracts'] ?? 0).toString();
  String get freelancerPendingProposals =>
      (dashboardData['pendingProposals'] ?? 0).toString();
  String get freelancerCompletedProjects =>
      (dashboardData['completedProjects'] ?? 0).toString();
  String get freelancerTotalProjects =>
      (dashboardData['projectStatistics']?['total'] ?? 0).toString();
  String get freelancerTodaysTasks =>
      (dashboardData['todaysTasks'] ?? 0).toString();

  // --- Client Dashboard Getters ---
  String get clientProfileCompletion =>
      (dashboardData['profileCompletion'] ?? 0).toString();
  double get clientWalletBalance =>
      (dashboardData['walletBalance'] as num?)?.toDouble() ?? 0.0;
  String get clientActiveProjects =>
      (dashboardData['activeProjects'] ?? 0).toString();
  String get clientDraftProjects =>
      (dashboardData['draftProjects'] ?? 0).toString();
  String get clientCompletedProjects =>
      (dashboardData['completedProjects'] ?? 0).toString();
  String get clientPendingProposals =>
      (dashboardData['pendingProposals'] ?? 0).toString();
  String get clientShortlistedFreelancers =>
      (dashboardData['shortlistedFreelancers'] ?? 0).toString();
  String get clientActiveContracts =>
      (dashboardData['activeContracts'] ?? 0).toString();
  String get clientPendingPayments =>
      (dashboardData['pendingPayments'] ?? 0).toString();
  double get clientMonthlySpend =>
      (dashboardData['monthlySpend'] as num?)?.toDouble() ?? 0.0;
  double get clientTotalSpend =>
      (dashboardData['totalSpend'] as num?)?.toDouble() ?? 0.0;

  @override
  List<Object?> get props => [
    status,
    meetings,
    projects,
    freelancers,
    startups,
    investors,
    wallet,
    walletBalance,
    profileCompletionPercent,
    activeProjectsCount,
    pendingProposalsCount,
    monthlyEarnings,
    fundingGoal,
    topSkills,
    earningsChart,
    upcomingMeetingsCount,
    unreadNotificationsCount,
    unreadMessagesCount,
    dashboardData,
  ];
}

/// Loads the data needed by a role's home screen in one shot.
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit({
    required this.role,
    required this.projectRepository,
    required this.freelancerRepository,
    required this.startupRepository,
    required this.investorRepository,
    required this.meetingRepository,
    required this.messageRepository,
    required this.walletRepository,
    required this.apiClient,
  }) : super(const DashboardState());

  final UserRole role;
  final ProjectRepository projectRepository;
  final FreelancerRepository freelancerRepository;
  final StartupRepository startupRepository;
  final InvestorRepository investorRepository;
  final MeetingRepository meetingRepository;
  final MessageRepository messageRepository;
  final WalletRepository walletRepository;
  final ApiClientHelper apiClient;

  Future<void> load() async {
    emit(state.copyWith(status: ViewStatus.loading));
    try {
      var next = state.copyWith(status: ViewStatus.success);

      // Freelancer dashboard cards/charts: GET /freelancer/dashboard
      if (role == UserRole.freelancer) {
        final dash = await apiClient.getEnvelope<Map<String, dynamic>>(
          ApiEndpoints.freelancerDashboard,
          parser: (envelope) => Map<String, dynamic>.from(envelope.data as Map),
        );
        dash.fold((failure) {}, (data) {
          final completion = (data['profileCompletion'] as num?)?.toInt() ?? 0;
          final pendingProposals =
              (data['pendingProposals'] as num?)?.toInt() ?? 0;
          final activeProjects =
              (data['acceptedProjects'] as num?)?.toInt() ?? 0;
          final monthlyEarnings =
              (data['monthlyEarnings'] as num?)?.toDouble() ?? 0;
          final topSkills =
              (data['topSkills'] as List?)
                  ?.map((e) => e.toString().trim())
                  .where((s) => s.isNotEmpty && !_looksLikeUuid(s))
                  .toList() ??
              const <String>[];
          final earningsChartRaw =
              (data['charts']?['earnings'] as List?)
                  ?.map((e) => (e as num?)?.toDouble() ?? 0)
                  .toList() ??
              const <double>[];
          final walletBal = (data['walletBalance'] as num?)?.toDouble() ?? 0;
          final meetings = (data['upcomingMeetings'] as num?)?.toInt() ?? 0;
          next = next.copyWith(
            profileCompletionPercent: completion,
            walletBalance: walletBal,
            upcomingMeetingsCount: meetings,
            pendingProposalsCount: pendingProposals,
            activeProjectsCount: activeProjects,
            monthlyEarnings: monthlyEarnings,
            topSkills: topSkills,
            earningsChart: earningsChartRaw,
            unreadNotificationsCount:
                (data['unreadNotifications'] as num?)?.toInt() ?? 0,
            unreadMessagesCount: (data['unreadMessages'] as num?)?.toInt() ?? 0,
            dashboardData: data,
          );
        });
      }

      if (role == UserRole.client) {
        final dash = await apiClient.getEnvelope<Map<String, dynamic>>(
          ApiEndpoints.clientDashboard,
          parser: (envelope) => Map<String, dynamic>.from(envelope.data as Map),
        );
        dash.fold((_) {}, (data) {
          final activeProjects = (data['activeProjects'] as num?)?.toInt() ?? 0;
          final applications = (data['pendingProposals'] as num?)?.toInt() ?? 0;
          final completion = (data['profileCompletion'] as num?)?.toInt() ?? 0;
          final totalSpend = (data['totalSpend'] as num?)?.toDouble() ?? 0;
          final spendChart =
              (data['charts']?['spendTrend'] as List?)
                  ?.map((e) => (e as num?)?.toDouble() ?? 0)
                  .toList() ??
              const <double>[];
          final walletBal = (data['walletBalance'] as num?)?.toDouble() ?? 0;
          final meetings = (data['upcomingMeetings'] as num?)?.toInt() ?? 0;
          next = next.copyWith(
            activeProjectsCount: activeProjects,
            walletBalance: walletBal,
            upcomingMeetingsCount: meetings,
            pendingProposalsCount: applications,
            profileCompletionPercent: completion,
            monthlyEarnings: totalSpend,
            earningsChart: spendChart,
            unreadNotificationsCount:
                (data['unreadNotifications'] as num?)?.toInt() ?? 0,
            unreadMessagesCount: (data['unreadMessages'] as num?)?.toInt() ?? 0,
            dashboardData: data,
          );
        });
      }

      if (role == UserRole.investor) {
        final dash = await apiClient.getEnvelope<Map<String, dynamic>>(
          ApiEndpoints.investorDashboard,
          parser: (envelope) => Map<String, dynamic>.from(envelope.data as Map),
        );
        dash.fold((_) {}, (data) {
          final summaryData = data['data'] ?? data;
          final portfolioValue =
              (summaryData['portfolioValue'] as num?)?.toDouble() ?? 0;
          final profileCompletion =
              (summaryData['profileCompletion'] as num?)?.toInt() ?? 0;
          final activeInvestments =
              (summaryData['activeInvestments'] as num?)?.toInt() ?? 0;
          final pendingInvestments =
              (summaryData['pendingInvestments'] as num?)?.toInt() ?? 0;

          final chartList = summaryData['charts']?['portfolioGrowth'] as List?;
          final chart =
              chartList?.map((e) {
                if (e is num) return e.toDouble();
                if (e is Map) return (e['amount'] as num?)?.toDouble() ?? 0.0;
                return 0.0;
              }).toList() ??
              const <double>[];

          final recommendedList =
              summaryData['recommendedStartups'] as List? ?? [];

          List<Startup> startupsList = recommendedList.map((item) {
            final json = Map<String, dynamic>.from(item as Map);
            final founder = Map<String, dynamic>.from(
              json['founder'] as Map? ?? {},
            );

            final city = founder['city'] as String?;
            final country = founder['country'] as String?;
            String location = 'N/A';
            if (city != null && country != null) {
              location = '$city, $country';
            } else if (city != null) {
              location = city;
            } else if (country != null) {
              location = country;
            }

            return Startup(
              id: json['id']?.toString() ?? '',
              founderId:
                  json['founderId']?.toString() ??
                  founder['id']?.toString() ??
                  '',
              name: json['startup']?.toString() ?? 'Startup',
              tagline: founder['bio']?.toString() ?? '',
              industry: json['industry']?.toString() ?? 'General',
              stage: json['stage']?.toString() ?? 'MVP',
              founderName: founder['fullName']?.toString() ?? 'Founder',
              fundingRequired: (json['funding'] as num?)?.toDouble() ?? 0,
              equityOffered: (json['equity'] as num?)?.toDouble() ?? 0,
              location: location,
              logoUrl:
                  json['logo']?.toString() ??
                  founder['avatarUrl']?.toString() ??
                  '',
              founderAvatar: founder['avatarUrl']?.toString() ?? '',
              fundingRaised: (founder['raised'] as num?)?.toDouble() ?? 0,
              isVerified: true,
            );
          }).toList();

          final walletBal =
              (summaryData['walletBalance'] as num?)?.toDouble() ?? 0;
          final upcomingMeetingsList =
              summaryData['widgets']?['upcomingMeetingsList'] as List? ??
              summaryData['upcomingMeetingsList'] as List?;
          final parsedMeetings = <Meeting>[];
          if (upcomingMeetingsList != null) {
            for (final e in upcomingMeetingsList) {
              final m = e as Map;
              final details = m['investorDetails'] ?? m['founderDetails'] ?? {};
              final name = details['fullName'] ?? details['name'] ?? 'Unknown';
              final avatar = details['avatarUrl'];
              final dateStr = m['date'] ?? '';
              final timeStr = m['time'] ?? '00:00';
              DateTime startTime = DateTime.now();
              try {
                if (dateStr.isNotEmpty) {
                  final ds = DateTime.parse(dateStr.toString());
                  final parts = timeStr.toString().split(':');
                  startTime = DateTime(
                    ds.year,
                    ds.month,
                    ds.day,
                    int.tryParse(parts[0]) ?? 0,
                    int.tryParse(parts[1]) ?? 0,
                  );
                }
              } catch (_) {}

              parsedMeetings.add(
                Meeting(
                  id: m['id']?.toString() ?? '',
                  title: 'Meeting with $name',
                  withId: details['id']?.toString() ?? '',
                  withName: name.toString(),
                  withAvatar: avatar?.toString(),
                  startTime: startTime,
                  durationMinutes: (m['duration'] as num?)?.toInt() ?? 45,
                  status: EntityStatus.fromString(
                    m['status']?.toString() ?? 'pending',
                  ),
                  isVideo: m['mode'] == 'Online',
                  meetingLink:
                      m['meetingLink']?.toString() ??
                      'https://meet.goexperts.example/room',
                ),
              );
            }
          }

          next = next.copyWith(
            monthlyEarnings: portfolioValue,
            walletBalance: walletBal,
            activeProjectsCount: activeInvestments,
            pendingProposalsCount: pendingInvestments,
            profileCompletionPercent: profileCompletion,
            earningsChart: chart,
            startups: startupsList,
            meetings: parsedMeetings,
            upcomingMeetingsCount: parsedMeetings.length,
            unreadNotificationsCount:
                (summaryData['unreadNotifications'] as num?)?.toInt() ?? 0,
            unreadMessagesCount:
                (summaryData['unreadMessages'] as num?)?.toInt() ?? 0,
            dashboardData: data,
          );
          print("================ DEBUG DASHBOARD ==================");
          print("dashboardData keys: ${next.dashboardData.keys}");
          print("verificationMissingCount in data: ${next.dashboardData['verificationMissingCount']}");
          print("accountVerified in data: ${next.dashboardData['accountVerified']}");
          print("===================================================");
        });
      }

      if (role == UserRole.founder) {
        final dash = await apiClient.getEnvelope<Map<String, dynamic>>(
          ApiEndpoints.founderDashboard,
          parser: (envelope) => Map<String, dynamic>.from(envelope.data as Map),
        );
        dash.fold((_) {}, (data) {
          final investorInterests =
              (data['investorInterests'] as num?)?.toInt() ?? 0;
          final pitchViews = (data['pitchDeckViews'] as num?)?.toInt() ?? 0;
          final startupViews = (data['profileViews'] as num?)?.toInt() ?? 0;
          final meetings = (data['pendingMeetings'] as num?)?.toInt() ?? 0;
          final raised = (data['fundingRaised'] as num?)?.toDouble() ?? 0;
          final goal = (data['fundingGoal'] as num?)?.toDouble() ?? 0;
          final fundingChart =
              (data['charts']?['fundingProgress'] as List?)
                  ?.map((e) => (e as num?)?.toDouble() ?? 0)
                  .toList() ??
              const <double>[];

          final recommendedList =
              data['widgets']?['recommendedInvestors'] as List?;
          List<Investor>? investorsList;
          if (recommendedList != null) {
            investorsList = recommendedList.map((item) {
              return Investor.fromApiJson(
                Map<String, dynamic>.from(item as Map),
              );
            }).toList();
          }

          final upcomingMeetingsList =
              data['widgets']?['upcomingMeetingsList'] as List? ??
              data['upcomingMeetingsList'] as List?;
          final parsedMeetings = <Meeting>[];
          if (upcomingMeetingsList != null) {
            for (final e in upcomingMeetingsList) {
              final m = e as Map;
              final details = m['investorDetails'] ?? m['founderDetails'] ?? {};
              final name = details['fullName'] ?? details['name'] ?? 'Unknown';
              final avatar = details['avatarUrl'];
              final dateStr = m['date'] ?? '';
              final timeStr = m['time'] ?? '00:00';
              DateTime startTime = DateTime.now();
              try {
                if (dateStr.isNotEmpty) {
                  final ds = DateTime.parse(dateStr.toString());
                  final parts = timeStr.toString().split(':');
                  startTime = DateTime(
                    ds.year,
                    ds.month,
                    ds.day,
                    int.tryParse(parts[0]) ?? 0,
                    int.tryParse(parts[1]) ?? 0,
                  );
                }
              } catch (_) {}

              parsedMeetings.add(
                Meeting(
                  id: m['id']?.toString() ?? '',
                  title: 'Meeting with $name',
                  withId: details['id']?.toString() ?? '',
                  withName: name.toString(),
                  withAvatar: avatar?.toString(),
                  startTime: startTime,
                  durationMinutes: (m['duration'] as num?)?.toInt() ?? 45,
                  status: EntityStatus.fromString(
                    m['status']?.toString() ?? 'pending',
                  ),
                  isVideo: m['mode'] == 'Online',
                  meetingLink:
                      m['meetingLink']?.toString() ??
                      'https://meet.goexperts.example/room',
                ),
              );
            }
          }

          final walletBal = (data['walletBalance'] as num?)?.toDouble() ?? 0;
          next = next.copyWith(
            activeProjectsCount: investorInterests,
            walletBalance: walletBal,
            upcomingMeetingsCount: meetings,
            pendingProposalsCount: pitchViews,
            profileCompletionPercent: startupViews,
            monthlyEarnings: raised,
            fundingGoal: goal,
            topSkills: ['$meetings'],
            earningsChart: fundingChart,
            investors: investorsList ?? next.investors,
            meetings: parsedMeetings,
            unreadNotificationsCount:
                (data['unreadNotifications'] as num?)?.toInt() ?? 0,
            unreadMessagesCount: (data['unreadMessages'] as num?)?.toInt() ?? 0,
            dashboardData: data,
          );
        });
      }

      emit(next);
    } catch (_) {
      emit(state.copyWith(status: ViewStatus.failure));
    }
  }

  Future<void> refresh() => load();
}

final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
  caseSensitive: false,
);

bool _looksLikeUuid(String value) => _uuidPattern.hasMatch(value.trim());
