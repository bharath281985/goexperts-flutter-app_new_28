import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/auth/token_role_helper.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_search_bar.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/icon_widget.dart';

class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  List<String> _recent = const [];
  List<Map<String, dynamic>> _recommendedRoles = const [];
  List<_SearchTab> _tabs = const [];
  bool _loading = true;

  List<dynamic>? _searchResults;
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = sl<ApiClientHelper>();
    final recent = await api.getEnvelope<List<String>>(
      ApiEndpoints.discoveryRecentlyViewed,
      parser: (e) =>
          (e.data as List?)?.map((x) => x.toString()).toList() ?? const [],
    );
    final rec = await api.getEnvelope<List<Map<String, dynamic>>>(
      ApiEndpoints.discoveryRecommendations,
      parser: (e) {
        final data = e.data;
        if (data is Map && data['recommendedRoles'] is List) {
          return (data['recommendedRoles'] as List)
              .map((x) => Map<String, dynamic>.from(x as Map))
              .toList();
        }
        return const [];
      },
    );
    if (!mounted) return;
    _recent = recent.valueOrNull?.isNotEmpty == true
        ? recent.valueOrNull!
        : ['Flutter developer', 'FinTech startups', 'UI/UX design'];
    final role = await sl<TokenRoleHelper>().resolve();
    _tabs = _tabsForRole(role?.name);
    _recommendedRoles = rec.valueOrNull?.isNotEmpty == true
        ? rec.valueOrNull!
        : _tabs
              .map(
                (tab) => {
                  'role': tab.key,
                  'label': tab.label,
                  'description': tab.description,
                  'route': tab.route,
                },
              )
              .toList();
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = null;
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final res = await sl<ApiClientHelper>().getEnvelope<List<dynamic>>(
      ApiEndpoints.search,
      query: {'q': query},
      parser: (e) => (e.data as List?) ?? const [],
    );

    if (!mounted) return;

    setState(() {
      _searchResults = res.valueOrNull ?? [];
      _isSearching = false;
    });
  }

  Future<void> _openSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final route = await _defaultSearchRoute();
    if (!mounted) return;
    context.push('$route?q=${Uri.encodeComponent(trimmed)}');
  }

  Future<String> _defaultSearchRoute() async {
    final role = await sl<TokenRoleHelper>().resolve();
    return switch (role?.name) {
      'client' => Routes.clientFreelancers,
      'investor' => Routes.investorStartups,
      'founder' => Routes.founderInvestors,
      _ => Routes.freelancerProjects,
    };
  }

  Future<void> _openRecommended(Map<String, dynamic> item) async {
    final route = await _routeForRecommended(item);
    if (!mounted) return;
    context.push(route);
  }

  Future<String> _routeForRecommended(Map<String, dynamic> item) async {
    final directRoute = item['route']?.toString();
    if (directRoute != null && directRoute.isNotEmpty) return directRoute;

    final raw = [
      item['role'],
      item['type'],
      item['label'],
      item['title'],
    ].whereType<Object>().map((e) => e.toString().toLowerCase()).join(' ');
    final query = item['query']?.toString().trim();
    final suffix = query == null || query.isEmpty
        ? ''
        : '?q=${Uri.encodeComponent(query)}';
    final id = item['id']?.toString() ?? item['entityId']?.toString();

    if (id != null && id.isNotEmpty) {
      if (raw.contains('project')) {
        return '${Routes.projectDetails}/${Uri.encodeComponent(id)}';
      }
      if (raw.contains('startup')) {
        return '${Routes.startupDetails}/${Uri.encodeComponent(id)}';
      }
      if (raw.contains('freelancer') || raw.contains('talent')) {
        return '${Routes.publicFreelancer}/${Uri.encodeComponent(id)}';
      }
      if (raw.contains('client') || raw.contains('company')) {
        return '${Routes.publicCompany}/${Uri.encodeComponent(id)}';
      }
      if (raw.contains('investor')) {
        return '${Routes.publicInvestor}/${Uri.encodeComponent(id)}';
      }
      if (raw.contains('founder')) {
        return '${Routes.publicFounder}/${Uri.encodeComponent(id)}';
      }
    }

    if (raw.contains('project')) {
      final role = await sl<TokenRoleHelper>().resolve();
      final base = switch (role?.name) {
        'client' => Routes.clientProjects,
        'investor' => Routes.investorProjects,
        'founder' => Routes.founderProjects,
        _ => Routes.freelancerProjects,
      };
      return '$base$suffix';
    }
    if (raw.contains('client') || raw.contains('company')) {
      return '${Routes.clients}$suffix';
    }
    if (raw.contains('startup') || raw.contains('founder')) {
      final role = await sl<TokenRoleHelper>().resolve();
      final base = switch (role?.name) {
        'client' => Routes.clientStartups,
        'investor' => Routes.investorStartups,
        'founder' => Routes.founderStartups,
        _ => Routes.freelancerStartups,
      };
      return '$base$suffix';
    }
    if (raw.contains('freelancer') || raw.contains('talent')) {
      final role = await sl<TokenRoleHelper>().resolve();
      final base = switch (role?.name) {
        'client' => Routes.clientFreelancers,
        'investor' => Routes.investorFreelancers,
        'founder' => Routes.founderFreelancers,
        _ => Routes.freelancerFreelancers,
      };
      return '$base$suffix';
    }
    if (raw.contains('investor')) {
      final role = await sl<TokenRoleHelper>().resolve();
      final base = switch (role?.name) {
        'client' => Routes.clientInvestors,
        'founder' => Routes.founderInvestors,
        _ => Routes.freelancerInvestors,
      };
      return '$base$suffix';
    }
    final matchedTab = _tabs.cast<_SearchTab?>().firstWhere(
          (tab) =>
              tab != null &&
              (raw.contains(tab.key) || raw.contains(tab.label.toLowerCase())),
          orElse: () => null,
        );
    if (matchedTab != null) return '${matchedTab.route}$suffix';

    final base = await _defaultSearchRoute();
    return '$base$suffix';
  }

  List<_SearchTab> _tabsForRole(String? role) {
    return switch (role) {
      'client' => const [
        _SearchTab('freelancers', 'Freelancers', Icons.person_search_rounded,
            Routes.clientFreelancers,
            'Find verified freelance experts for your project.'),
        _SearchTab('startups', 'Startups', Icons.rocket_launch_rounded,
            Routes.clientStartups,
            'Discover startups looking for support and partnerships.'),
        _SearchTab('investors', 'Investors', Icons.account_balance_rounded,
            Routes.clientInvestors,
            'Explore strategic investors and funding partners.'),
      ],
      'investor' => const [
        _SearchTab('startups', 'Startups', Icons.rocket_launch_rounded,
            Routes.investorStartups,
            'Find verified startups and founders raising capital.'),
        _SearchTab('projects', 'Projects', Icons.task_alt_rounded,
            Routes.investorProjects,
            'Browse active client projects and market demand.'),
        _SearchTab('freelancers', 'Freelancers', Icons.code_rounded,
            Routes.clientFreelancers,
            'Discover specialized talent building in your thesis.'),
      ],
      'founder' => const [
        _SearchTab('investors', 'Investors', Icons.monetization_on_rounded,
            Routes.founderInvestors,
            'Connect with active investors and funding partners.'),
        _SearchTab('freelancers', 'Freelancers', Icons.engineering_rounded,
            Routes.founderFreelancers,
            'Find elite freelancers to build and launch faster.'),
        _SearchTab('projects', 'Projects', Icons.work_rounded,
            Routes.freelancerProjects,
            'Browse active projects that match your skills.'),
      ],
      _ => const [
        _SearchTab('projects', 'Projects', Icons.work_rounded,
            Routes.freelancerProjects,
            'Browse active projects that match your skills.'),
        _SearchTab('investors', 'Investors', Icons.business_rounded,
            Routes.freelancerInvestors,
            'Discover investors and long-term startup opportunities.'),
        _SearchTab('startups', 'Startups', Icons.rocket_launch_rounded,
            Routes.freelancerStartups,
            'Explore high-growth startups looking for help.'),
      ],
    };
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: AppSizes.md),
          child: AppSearchBar(
            autofocus: true,
            hint: 'Search everything…',
            onChanged: (v) {
              if (_debounce?.isActive ?? false) _debounce!.cancel();
              _debounce = Timer(const Duration(milliseconds: 500), () {
                _performSearch(v);
              });
            },
            onSubmitted: (v) {
              if (_debounce?.isActive ?? false) _debounce!.cancel();
              _performSearch(v);
              _openSearch(v);
            },
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _searchResults != null
                  ? _buildSearchResults()
                  : ListView(
                      padding: const EdgeInsets.all(AppSizes.screenPadding),
                      children: [
                        const AppSectionHeader(title: 'Top Matches For You'),
                        AppSizes.vGapSm,
                        for (final item in _recommendedRoles)
                          _roleCard(
                            context,
                            icon: _roleIcon(item['role']?.toString() ?? ''),
                            title: item['label']?.toString() ?? 'Role',
                            description: item['description']?.toString() ?? '',
                            onTap: () => _openRecommended(item),
                          ),
                        AppSizes.vGapLg,
                        const AppSectionHeader(title: 'Recent Searches'),
                        AppSizes.vGapSm,
                        for (final r in _recent)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.history_rounded,
                              color: AppColors.mutedText,
                            ),
                            title: Text(r),
                            trailing: const Icon(Icons.north_west_rounded, size: 16),
                            onTap: () => _openSearch(r),
                          ),
                      ],
                    ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults!.isEmpty) {
      return const Center(child: Text('No results found.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      itemCount: _searchResults!.length,
      itemBuilder: (context, index) {
        final item = _searchResults![index];
        // For now, render a simple ListTile since we don't know the exact structure
        // of the search results from the API.
        final map = item is Map ? Map<String, dynamic>.from(item) : null;
        final title =
            map?['title']?.toString() ??
            map?['name']?.toString() ??
            map?['label']?.toString() ??
            item.toString();
        final subtitle =
            map?['description']?.toString() ??
            map?['role']?.toString() ??
            map?['type']?.toString();
        return ListTile(
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: subtitle == null || subtitle.isEmpty
              ? null
              : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => map == null ? _openSearch(title) : _openRecommended(map),
        );
      },
    );
  }

  IconData _roleIcon(String role) {
    return switch (role) {
      'freelancer' || 'freelancers' => Icons.person_search_outlined,
      'client' || 'clients' || 'company' || 'companies' =>
        Icons.business_center_outlined,
      'startup' || 'startups' => Icons.rocket_launch_outlined,
      'project' || 'projects' => Icons.work_outline_rounded,
      'investor' || 'investors' => Icons.trending_up_rounded,
      'founder' || 'founders' => Icons.rocket_launch_outlined,
      _ => Icons.layers_outlined,
    };
  }

  Widget _roleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Row(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSizes.sm),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.subtleText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchTab {
  const _SearchTab(
    this.key,
    this.label,
    this.icon,
    this.route,
    this.description,
  );

  final String key;
  final String label;
  final IconData icon;
  final String route;
  final String description;
}
