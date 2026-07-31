import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../utils/enums.dart';
import '../utils/paginated.dart';
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
    this.profileCompletionPercent = 0,
    this.activeProjectsCount = 0,
    this.pendingProposalsCount = 0,
    this.monthlyEarnings = 0,
    this.fundingGoal = 0,
    this.topSkills = const [],
    this.earningsChart = const [],
    this.unreadNotificationsCount = 0,
    this.unreadMessagesCount = 0,
    this.investorData = const {},
  });

  final ViewStatus status;
  final List<Meeting> meetings;
  final List<Project> projects;
  final List<Freelancer> freelancers;
  final List<Startup> startups;
  final List<Investor> investors;
  final WalletSummary? wallet;
  final int profileCompletionPercent;
  final int activeProjectsCount;
  final int pendingProposalsCount;
  final double monthlyEarnings;
  final double fundingGoal;
  final List<String> topSkills;
  final List<double> earningsChart;
  final int unreadNotificationsCount;
  final int unreadMessagesCount;
  final Map<String, dynamic> investorData;

  DashboardState copyWith({
    ViewStatus? status,
    List<Meeting>? meetings,
    List<Project>? projects,
    List<Freelancer>? freelancers,
    List<Startup>? startups,
    List<Investor>? investors,
    WalletSummary? wallet,
    int? profileCompletionPercent,
    int? activeProjectsCount,
    int? pendingProposalsCount,
    double? monthlyEarnings,
    double? fundingGoal,
    List<String>? topSkills,
    List<double>? earningsChart,
    int? unreadNotificationsCount,
    int? unreadMessagesCount,
    Map<String, dynamic>? investorData,
  }) {
    return DashboardState(
      status: status ?? this.status,
      meetings: meetings ?? this.meetings,
      projects: projects ?? this.projects,
      freelancers: freelancers ?? this.freelancers,
      startups: startups ?? this.startups,
      investors: investors ?? this.investors,
      wallet: wallet ?? this.wallet,
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
      unreadMessagesCount: unreadMessagesCount ?? this.unreadMessagesCount,
      investorData: investorData ?? this.investorData,
    );
  }

  // --- Investor Dashboard Getters ---
  String get investorName {
    final profile = investorData['profile'] as Map? ?? {};
    return profile['firstName']?.toString() ??
        profile['fullName']?.toString() ??
        profile['name']?.toString() ??
        'Investor';
  }

  String get investorPendingDeals =>
      (investorData['pendingInvestments'] ?? 0).toString();
  String get investorDealsClosed =>
      (investorData['closedInvestments'] ?? 0).toString();
  String get investorTotalInvestments =>
      (investorData['totalInvestments'] ?? 0).toString();

  double get investorDeployedRaw {
    final val = investorData['portfolioValue'] ?? 0.0;
    if (val is num) return val.toDouble();
    return 0.0;
  }

  String get investorWalletBalance {
    final balanceObj = investorData['walletBalance'] ?? 0.0;
    return '${balanceObj is num ? balanceObj.toStringAsFixed(0) : '0'}';
  }

  List<Map<dynamic, dynamic>> get investorRecentMessages {
    return [];
  }

  String get investorStartupsFollowing =>
      (investorData['watchlistCount'] ?? 0).toString();

  @override
  List<Object?> get props => [
    status,
    meetings,
    projects,
    freelancers,
    startups,
    investors,
    wallet,
    profileCompletionPercent,
    activeProjectsCount,
    pendingProposalsCount,
    monthlyEarnings,
    fundingGoal,
    topSkills,
    earningsChart,
    unreadNotificationsCount,
    unreadMessagesCount,
    investorData,
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

  static const _q = QueryParams(pageSize: 5);

  Future<void> load() async {
    emit(state.copyWith(status: ViewStatus.loading));
    try {
      final meetings = await meetingRepository.getMeetings(_q);
      final wallet = await walletRepository.getSummary();

      var next = state.copyWith(
        status: ViewStatus.success,
        meetings: meetings.valueOrNull?.items ?? const [],
        wallet: wallet.valueOrNull,
      );

      switch (role) {
        case UserRole.freelancer:
          final projects = await projectRepository.getProjects(_q);
          next = next.copyWith(
            projects: projects.valueOrNull?.items ?? const [],
          );
          break;
        case UserRole.client:
          final freelancers = await freelancerRepository.getFreelancers(_q);
          final projects = await projectRepository.getProjects(_q);
          next = next.copyWith(
            freelancers: freelancers.valueOrNull?.items ?? const [],
            projects: projects.valueOrNull?.items ?? const [],
          );
          break;
        case UserRole.investor:
          // Fully relying on the bottom /investor/dashboard API to populate state.
          break;
        case UserRole.founder:
          final investors = await investorRepository.getInvestors(_q);
          next = next.copyWith(
            investors: investors.valueOrNull?.items ?? const [],
          );
          break;
      }

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
          next = next.copyWith(
            profileCompletionPercent: completion,
            pendingProposalsCount: pendingProposals,
            activeProjectsCount: activeProjects,
            monthlyEarnings: monthlyEarnings,
            topSkills: topSkills,
            earningsChart: earningsChartRaw,
            unreadNotificationsCount:
                (data['unreadNotifications'] as num?)?.toInt() ?? 0,
            unreadMessagesCount: (data['unreadMessages'] as num?)?.toInt() ?? 0,
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
          next = next.copyWith(
            activeProjectsCount: activeProjects,
            pendingProposalsCount: applications,
            profileCompletionPercent: completion,
            monthlyEarnings: totalSpend,
            earningsChart: spendChart,
            unreadNotificationsCount:
                (data['unreadNotifications'] as num?)?.toInt() ?? 0,
            unreadMessagesCount: (data['unreadMessages'] as num?)?.toInt() ?? 0,
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
              chartList?.map((e) => (e as num?)?.toDouble() ?? 0).toList() ??
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

          next = next.copyWith(
            monthlyEarnings: portfolioValue,
            activeProjectsCount: activeInvestments,
            pendingProposalsCount: pendingInvestments,
            profileCompletionPercent: profileCompletion,
            earningsChart: chart,
            startups: startupsList,
            unreadNotificationsCount:
                (summaryData['unreadNotifications'] as num?)?.toInt() ?? 0,
            unreadMessagesCount:
                (summaryData['unreadMessages'] as num?)?.toInt() ?? 0,
            investorData: summaryData as Map<String, dynamic>,
          );
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
              final nested = (item as Map)['investorProfile'] as Map? ?? item;
              return Investor.fromApiJson(Map<String, dynamic>.from(nested));
            }).toList();
          }

          next = next.copyWith(
            activeProjectsCount: investorInterests,
            pendingProposalsCount: pitchViews,
            profileCompletionPercent: startupViews,
            monthlyEarnings: raised,
            fundingGoal: goal,
            topSkills: ['$meetings'],
            earningsChart: fundingChart,
            investors: investorsList ?? next.investors,
            unreadNotificationsCount:
                (data['unreadNotifications'] as num?)?.toInt() ?? 0,
            unreadMessagesCount: (data['unreadMessages'] as num?)?.toInt() ?? 0,
          );
        });
      }

      final conversations = await messageRepository.getConversations(
        const QueryParams(page: 1, pageSize: 50),
      );
      conversations.fold((_) {}, (page) {
        final unreadMessages = page.items.fold<int>(
          0,
          (total, conversation) => total + conversation.unreadCount,
        );
        next = next.copyWith(unreadMessagesCount: unreadMessages);
      });

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
