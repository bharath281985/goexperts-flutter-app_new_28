import 'package:flutter/material.dart';
import '../../app/constants/app_colors.dart';
import '../../app/constants/app_sizes.dart';
import '../extensions/context_extensions.dart';
import '../utils/enums.dart';
import '../widgets/app_card.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/app_section_header.dart';
import '../widgets/app_stat_card.dart';
import '../../app/dependency_injection/service_locator.dart';
import '../network/api_client_helper.dart';
import '../network/api_endpoints.dart';

class _Metric {
  const _Metric(this.label, this.value, this.icon, this.trend, this.color);
  final String label;
  final String value;
  final IconData icon;
  final String trend;
  final Color color;
}

/// A reusable analytics dashboard rendered per role with headline metrics and
/// a lightweight bar chart. API-ready: swap the seeded series for live data.
class RoleAnalyticsPage extends StatefulWidget {
  const RoleAnalyticsPage({super.key, required this.role, this.title});

  final UserRole role;
  final String? title;

  @override
  State<RoleAnalyticsPage> createState() => _RoleAnalyticsPageState();
}

class _RoleAnalyticsPageState extends State<RoleAnalyticsPage> {
  bool _isLoading = true;
  String _error = '';
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    final client = sl<ApiClientHelper>();
    String endpoint;
    switch (widget.role) {
      case UserRole.freelancer:
        endpoint = ApiEndpoints.freelancerAnalytics;
        break;
      case UserRole.client:
        endpoint = ApiEndpoints.clientAnalytics;
        break;
      case UserRole.investor:
        endpoint = ApiEndpoints.investorAnalytics;
        break;
      case UserRole.founder:
        endpoint = ApiEndpoints.founderAnalytics;
        break;
    }

    final result = await client.getEnvelope<Map<String, dynamic>>(
      '$endpoint?period=30d',
      parser: (env) => Map<String, dynamic>.from(env.data as Map),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        result.fold(
          (failure) => _error = failure.message,
          (data) => _data = data,
        );
      });
    }
  }

  List<_Metric> _metrics() {
    switch (widget.role) {
      case UserRole.founder:
        return [
          _Metric(
            'Profile Views',
            '${_data['profileViews'] ?? 0}',
            Icons.visibility_outlined,
            '',
            AppColors.info,
          ),
          _Metric(
            'Deck Downloads',
            '${_data['pitchDeckDownloads'] ?? 0}',
            Icons.slideshow_outlined,
            '',
            AppColors.primary,
          ),
          _Metric(
            'Meetings',
            '${_data['meetingsScheduled'] ?? 0}',
            Icons.event_outlined,
            '',
            AppColors.success,
          ),
          _Metric(
            'Interest Rate',
            '${_data['investorInterestRate'] ?? "0%"}',
            Icons.favorite_border_rounded,
            '',
            AppColors.warning,
          ),
        ];

      case UserRole.investor:
        return [
          _Metric(
            'Total Invested',
            '₹${_data['totalInvested'] ?? 0}',
            Icons.savings_outlined,
            '',
            AppColors.success,
          ),
          _Metric(
            'Active Portfolios',
            '${_data['activePortfolios'] ?? 0}',
            Icons.business_center_outlined,
            '',
            AppColors.primary,
          ),
          _Metric(
            'Meetings',
            '${_data['totalMeetings'] ?? 0}',
            Icons.event_outlined,
            '',
            AppColors.info,
          ),
          _Metric(
            'Pipeline',
            '${_data['pipelineStartups'] ?? 0}',
            Icons.rocket_launch_outlined,
            '',
            AppColors.warning,
          ),
        ];

      case UserRole.freelancer:
        return [
          _Metric(
            'Earnings',
            '₹${_data['totalEarnings'] ?? 0}',
            Icons.payments_outlined,
            '',
            AppColors.success,
          ),
          _Metric(
            'Completed',
            '${_data['completedProjects'] ?? 0}',
            Icons.task_alt_outlined,
            '',
            AppColors.primary,
          ),
          _Metric(
            'Active',
            '${_data['activeProjects'] ?? 0}',
            Icons.work_outline_rounded,
            '',
            AppColors.info,
          ),
          _Metric(
            'Win Rate',
            '${_data['proposalSuccessRate'] ?? "0%"}',
            Icons.emoji_events_outlined,
            '',
            AppColors.warning,
          ),
        ];

      case UserRole.client:
        return [
          _Metric(
            'Total Spent',
            '₹${_data['totalSpent'] ?? 0}',
            Icons.account_balance_wallet_outlined,
            '',
            AppColors.info,
          ),
          _Metric(
            'Projects Posted',
            '${_data['projectsPosted'] ?? 0}',
            Icons.work_outline_rounded,
            '',
            AppColors.primary,
          ),
          _Metric(
            'Active Hires',
            '${_data['activeHires'] ?? 0}',
            Icons.how_to_reg_outlined,
            '',
            AppColors.success,
          ),
          _Metric(
            'Completed',
            '${_data['completedContracts'] ?? 0}',
            Icons.task_alt_outlined,
            '',
            AppColors.warning,
          ),
        ];
    }
  }



  (List<double>, List<String>) _chartData() {
    if (_data.isEmpty) return ([], []);

    List<double> series = [];
    List<String> labels = [];

    if (widget.role == UserRole.founder && _data['viewsTrend'] != null) {
      for (var item in _data['viewsTrend']) {
        series.add((item['views'] as num?)?.toDouble() ?? 0);
        labels.add(item['date']?.toString().split('-').last ?? ''); // get day
      }
    } else if (widget.role == UserRole.investor &&
        _data['investmentGrowth'] != null) {
      for (var item in _data['investmentGrowth']) {
        series.add((item['amount'] as num?)?.toDouble() ?? 0);
        labels.add(item['month']?.toString() ?? '');
      }
    } else if (widget.role == UserRole.freelancer &&
        _data['earningsHistory'] != null) {
      for (var item in _data['earningsHistory']) {
        series.add((item['earnings'] as num?)?.toDouble() ?? 0);
        labels.add(item['month']?.toString() ?? '');
      }
    } else if (widget.role == UserRole.client &&
        _data['spendingBreakdown'] != null) {
      for (var item in _data['spendingBreakdown']) {
        series.add((item['amount'] as num?)?.toDouble() ?? 0);
        labels.add(item['category']?.toString() ?? '');
      }
    }

    if (series.isEmpty) return ([], []);

    final maxVal = series.reduce((a, b) => a > b ? a : b);
    if (maxVal > 0) {
      series = series.map((e) => e / maxVal).toList();
    } else {
      series = series.map((e) => 0.0).toList();
    }

    return (series, labels);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AppScaffold(
        appBar: AppBar(title: Text(widget.title ?? 'Analytics')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty) {
      return AppScaffold(
        appBar: AppBar(title: Text(widget.title ?? 'Analytics')),
        body: Center(
          child: Text(_error, style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    final metrics = _metrics();
    final (series, labels) = _chartData();

    return AppScaffold(
      appBar: AppBar(title: Text(widget.title ?? 'Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        children: [
          GridView.count(
            crossAxisCount: context.isMobile ? 2 : 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: AppSizes.md,
            mainAxisSpacing: AppSizes.md,
            childAspectRatio: 1.5,
            children: [
              for (final m in metrics)
                AppStatCard(
                  label: m.label,
                  value: m.value,
                  icon: m.icon,
                  color: m.color,
                  trend: m.trend,
                ),
            ],
          ),
          if (series.isNotEmpty) ...[
            AppSizes.vGapLg,
            const AppSectionHeader(title: 'Overview'),
            AppSizes.vGapMd,
            AppCard(
              child: SizedBox(
                height: 180,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < series.length; i++)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 130 * series[i],
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusSm,
                                ),
                              ),
                            ),
                            AppSizes.vGapSm,
                            Text(
                              labels[i].length > 5
                                  ? labels[i].substring(0, 3)
                                  : labels[i],
                              style: context.text.labelSmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
