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
        profile['name']?.toString() ??
        'Investor';
  }

  String get investorPendingDeals => _getKpi('pending', '0');
  String get investorDealsClosed => _getKpi('deals', '0');
  String get investorTotalInvestments => _getKpi('total', '0');

  String _getKpi(String key, String fallback) {
    final kpis = investorData['kpis'] as List? ?? [];
    try {
      final item = kpis.firstWhere(
        (e) => (e as Map)['key'] == key,
        orElse: () => null,
      );
      if (item != null) return (item as Map)['value']?.toString() ?? fallback;
    } catch (_) {}
    return fallback;
  }

  double get investorDeployedRaw {
    final val = investorData['totalDeployed'];
    if (val is num) return val.toDouble();
    return 0.0;
  }

  String get investorWalletBalance {
    final balanceObj = investorData['wallet']?['balance'] ?? 0.0;
    return '₹${balanceObj is num ? balanceObj.toStringAsFixed(0) : '0'}';
  }

  List<Map<dynamic, dynamic>> get investorRecentMessages {
    final msgs = investorData['messages'] as List? ?? [];
    return msgs.map((e) => e as Map<dynamic, dynamic>).toList();
  }

  String get investorStartupsFollowing =>
      (investorData['startups'] as List?)?.length.toString() ?? '9';

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
          final applications = (data['applications'] as num?)?.toInt() ?? 0;
          final hiredFreelancers =
              (data['hiredFreelancers'] as num?)?.toInt() ?? 0;
          final monthlySpend = (data['monthlySpend'] as num?)?.toDouble() ?? 0;
          final spendChart =
              (data['charts']?['spend'] as List?)
                  ?.map((e) => (e as num?)?.toDouble() ?? 0)
                  .toList() ??
              const <double>[];
          next = next.copyWith(
            activeProjectsCount: activeProjects,
            pendingProposalsCount: applications,
            profileCompletionPercent: hiredFreelancers,
            monthlyEarnings: monthlySpend,
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
              (summaryData['totalDeployed'] as num?)?.toDouble() ?? 0;
          final profileCompletion =
              (summaryData['profileCompletion'] as num?)?.toInt() ?? 0;
          final activeInvestments =
              (summaryData['activeInvestments'] as num?)?.toInt() ?? 0;
          final watchlist = (summaryData['totalDeals'] as num?)?.toInt() ?? 0;

          final chartList =
              (summaryData['charts']?['pipeline'] ??
                      summaryData['charts']?['portfolioGrowth'] ??
                      summaryData['charts']?['monthlyInvestments'])
                  as List?;
          final chart =
              chartList?.map((e) => (e as num?)?.toDouble() ?? 0).toList() ??
              const <double>[];

          final recommendedList =
              (summaryData['recommendations'] as Map?)?['startupIdeas']
                  as List? ??
              summaryData['recommendedStartups'] as List? ??
              summaryData['startups'] as List?;

          List<Startup>? startupsList;
          if (recommendedList != null) {
            startupsList = recommendedList.map((item) {
              final json = Map<String, dynamic>.from(item as Map);
              final profile = Map<String, dynamic>.from(
                (json['founderDetails'] ??
                        json['founderProfile'] ??
                        json['founder_profile'] ??
                        {})
                    as Map,
              );

              final city =
                  profile['city'] as String? ?? json['city'] as String?;
              final country =
                  profile['country'] as String? ?? json['country'] as String?;
              String location = 'N/A';
              if (city != null && country != null) {
                location = '$city, $country';
              } else if (city != null) {
                location = city;
              } else if (country != null) {
                location = country;
              }

              // Retrieve fields falling back to the top level
              final bio =
                  profile['bio'] as String? ?? json['bio'] as String? ?? '';
              final avatar =
                  profile['avatarUrl'] as String? ??
                  json['logo'] as String? ??
                  json['avatarUrl'] as String?;

              final name =
                  json['startup'] as String? ??
                  profile['startupName'] as String? ??
                  json['fullName'] as String? ??
                  'Startup';
              final industry =
                  json['category'] as String? ??
                  profile['founderIndustry'] as String? ??
                  profile['industry'] as String? ??
                  'General';
              final stage =
                  json['stage'] as String? ??
                  profile['founderStage'] as String? ??
                  profile['stage'] as String? ??
                  'MVP';
              final funding =
                  (json['funding'] as num? ?? profile['raised'] as num?)
                      ?.toDouble() ??
                  0;
              final equity = (json['equity'] as num?)?.toDouble() ?? 0;
              final founderName =
                  profile['fullName'] as String? ??
                  json['fullName'] as String? ??
                  'Founder';

              return Startup(
                id: json['id']?.toString() ?? '',
                founderId: profile['id']?.toString() ?? json['id']?.toString(),
                name: name,
                tagline: bio,
                industry: industry,
                stage: stage,
                founderName: founderName,
                fundingRequired: funding,
                equityOffered: equity,
                location: location,
                logoUrl: json['logo'] as String? ?? avatar,
                founderAvatar: avatar,
                fundingRaised: (profile['raised'] as num?)?.toDouble() ?? 0,
                isVerified:
                    profile['isVerified'] as bool? ??
                    json['isVerified'] as bool? ??
                    false,
              );
            }).toList();
          }

          next = next.copyWith(
            monthlyEarnings: portfolioValue,
            activeProjectsCount: activeInvestments,
            pendingProposalsCount: watchlist,
            profileCompletionPercent: profileCompletion,
            earningsChart: chart,
            startups: startupsList ?? next.startups,
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
          final startupViews =
              (data['profileViews'] as num?)?.toInt() ??
              (data['startupViews'] as num?)?.toInt() ??
              0;
          final meetings =
              (data['pendingMeetings'] as num?)?.toInt() ??
              (data['meetingsCount'] as num?)?.toInt() ??
              0;
          final raised = (data['fundingRaised'] as num?)?.toDouble() ?? 0;
          final goal = (data['fundingGoal'] as num?)?.toDouble() ?? 0;
          final fundingChart =
              (data['charts']?['funding'] as List? ??
                      data['charts']?['fundingProgress'] as List?)
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

          next = next.copyWith(
            activeProjectsCount: investorInterests,
            pendingProposalsCount: pitchViews,
            profileCompletionPercent: startupViews,
            monthlyEarnings: raised,
            fundingGoal: goal,
            topSkills: ['$meetings'],
            earningsChart: fundingChart,
            unreadNotificationsCount:
                (data['unreadNotifications'] as num?)?.toInt() ?? 0,
            unreadMessagesCount: (data['unreadMessages'] as num?)?.toInt() ?? 0,
            investors: investorsList ?? next.investors,
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
