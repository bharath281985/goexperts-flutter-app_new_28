import 'package:flutter/material.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
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
  bool _loading = true;

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
    _recommendedRoles = rec.valueOrNull?.isNotEmpty == true
        ? rec.valueOrNull!
        : [
            {
              'role': 'founder',
              'label': 'Founders',
              'description': 'Match with startup leaders, investors and product teams.',
            },
            {
              'role': 'freelancer',
              'label': 'Freelancers',
              'description': 'Find vetted execution support for your work.',
            },
            {
              'role': 'client',
              'label': 'Clients',
              'description': 'Discover companies actively hiring and buying services.',
            },
          ];
    setState(() => _loading = false);
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
            onSubmitted: (v) async {
              final res = await sl<ApiClientHelper>()
                  .getEnvelope<List<dynamic>>(
                    ApiEndpoints.search,
                    query: {'q': v},
                    parser: (e) => (e.data as List?) ?? const [],
                  );
              if (!context.mounted) return;
              res.fold(
                (f) => context.showSnack(f.message),
                (list) => context.showSnack('Found ${list.length} results'),
              );
            },
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              children: [
                const AppSectionHeader(title: 'Recommended Roles'),
                AppSizes.vGapSm,
                for (final item in _recommendedRoles)
                  _roleCard(
                    context,
                    icon: _roleIcon(item['role']?.toString() ?? ''),
                    title: item['label']?.toString() ?? 'Role',
                    description: item['description']?.toString() ?? '',
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
                    onTap: () => context.showSnack('Searching "$r"'),
                  ),
              ],
            ),
    );
  }

  IconData _roleIcon(String role) {
    return switch (role) {
      'freelancer' => Icons.person_search_outlined,
      'client' => Icons.business_center_outlined,
      'investor' => Icons.trending_up_rounded,
      'founder' => Icons.rocket_launch_outlined,
      _ => Icons.layers_outlined,
    };
  }

  Widget _roleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
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
        ],
      ),
    );
  }
}
