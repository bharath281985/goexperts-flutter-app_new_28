import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/auth/token_role_helper.dart';
import '../../../../core/bloc/list_bloc.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/app_filter_bottom_sheet.dart';
import '../../../../core/widgets/catalog_view.dart';
import '../../../founder_dashboard/presentation/widgets/edit_idea_bottom_sheet.dart';
import '../../../master_data/domain/entities/master_option.dart';
import '../../../master_data/domain/entities/skill_category.dart';
import '../../../master_data/domain/repositories/master_data_repository.dart';
import '../../domain/entities/startup.dart';
import '../../domain/repositories/startup_repository.dart';
import '../widgets/investment_offer_sheet.dart';
import '../widgets/startup_card.dart';

const _startupSortOptions = [
  'Newest',
  'Funding: High to Low',
  'Funding: Low to High',
  'Most interest',
  'Most viewed',
];

const _startupSortApiValues = {
  'Newest': 'newest',
  'Funding: High to Low': 'funding_desc',
  'Funding: Low to High': 'funding_asc',
  'Most interest': 'trending',
  'Most viewed': 'views',
};

/// Embeddable startup discovery catalog with Role-Wise Top Tabs.
class StartupsListView extends StatefulWidget {
  const StartupsListView({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<StartupsListView> createState() => _StartupsListViewState();
}

class _StartupsListViewState extends State<StartupsListView> {
  List<SkillCategory> _categories = const [];
  List<SkillCategory> _industries = const [];
  List<MasterOption> _stages = const [];
  UserRole? _role;
  bool _loading = true;
  late int _selectedTab;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final masterRepo = sl<MasterDataRepository>();
    final role = await sl<TokenRoleHelper>().resolve();
    final results = await Future.wait([
      masterRepo.getSkillCategories(page: 1, pageSize: 200),
      masterRepo.getIndustries(),
      masterRepo.getStartupStageOptions(),
    ]);

    final categoriesResult = results[0] as Result<List<SkillCategory>>;
    final industriesResult = results[1] as Result<List<SkillCategory>>;
    final stagesResult = results[2] as Result<List<MasterOption>>;

    if (!mounted) return;
    setState(() {
      _role = role;
      _categories = categoriesResult.valueOrNull ?? const [];
      _industries = industriesResult.valueOrNull ?? const [];
      _stages = stagesResult.valueOrNull ?? const [];
      _loading = false;
    });
  }

  List<FilterSection> _filterSections() => [
    if (_categories.isNotEmpty)
      FilterSection(
        key: 'categoryId',
        title: 'Category',
        searchable: true,
        searchHint: 'Search categories…',
        optionItems: _categories
            .map((c) => FilterOption(value: c.id, label: c.name))
            .toList(),
      ),
    if (_industries.isNotEmpty)
      FilterSection(
        key: 'industry',
        title: 'Industry',
        searchable: true,
        searchHint: 'Search industries…',
        optionItems: _industries
            .map((ind) => FilterOption(value: ind.name, label: ind.name))
            .toList(),
      ),
    if (_stages.isNotEmpty)
      FilterSection(
        key: 'stage',
        title: 'Stage',
        optionItems: _stages
            .map((st) => FilterOption(value: st.name, label: st.name))
            .toList(),
      ),
  ];

  Widget _buildTopTabs(BuildContext context) {
    final isFounder = _role == UserRole.founder;
    final myTabLabel = isFounder ? 'My Startup' : 'My Startups';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.isDark ? AppColors.darkCard : const Color(0xFFF1F3F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.isDark
              ? AppColors.darkBorder
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Explore Startups',
              icon: Icons.rocket_launch_outlined,
              activeIcon: Icons.rocket_launch_rounded,
              isSelected: _selectedTab == 0,
              onTap: () {
                if (_selectedTab != 0) {
                  setState(() {
                    _selectedTab = 0;
                    _refreshKey++;
                  });
                }
              },
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _TabButton(
              label: myTabLabel,
              icon: Icons.lightbulb_outline_rounded,
              activeIcon: Icons.lightbulb_rounded,
              isSelected: _selectedTab == 1,
              onTap: () {
                if (_selectedTab != 1) {
                  setState(() {
                    _selectedTab = 1;
                    _refreshKey++;
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final repo = sl<StartupRepository>();
    final isExplore = _selectedTab == 0;
    final isFounder = _role == UserRole.founder;

    return Column(
      children: [
        _buildTopTabs(context),
        Expanded(
          child: CatalogView<Startup>(
            key: ValueKey('startups-tab-$_selectedTab-$_refreshKey'),
            fetcher: (params) {
              final sortLabel = params.sortBy;
              final apiSort = sortLabel == null
                  ? null
                  : (_startupSortApiValues[sortLabel] ?? sortLabel);
              final qp = params.copyWith(
                sortBy: apiSort,
                filters: {
                  for (final entry in params.filters.entries)
                    if (entry.key == 'categoryId')
                      'categoryId': entry.value
                    else if (entry.key == 'industry')
                      'industry': entry.value
                    else if (entry.key == 'stage')
                      'stage': entry.value
                    else
                      entry.key: entry.value,
                },
              );

              return isExplore ? repo.getStartups(qp) : repo.getMyStartups(qp);
            },
            searchHint: isExplore
                ? 'Search startups, industries…'
                : 'Search my startups…',
            emptyTitle: isExplore
                ? 'No startups found'
                : (isFounder
                      ? 'No startups created yet'
                      : 'No startup investments yet'),
            emptyMessage: isExplore
                ? 'Try adjusting your search or filters.'
                : (isFounder
                      ? 'Publish your startup idea to connect with top investors and raise funds.'
                      : 'Explore and invest in startups to see your active investments here.'),
            emptyIcon: isExplore
                ? Icons.rocket_launch_outlined
                : Icons.lightbulb_outline_rounded,
            sortOptions: _startupSortOptions,
            filterSections: _filterSections,
            floatingActionButton: Builder(
              builder: (fabContext) => FloatingActionButton.extended(
                onPressed: () async {
                  final data = await showModalBottomSheet<Map<String, dynamic>>(
                    context: fabContext,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => const EditIdeaBottomSheet(
                      startup: Startup(
                        id: '',
                        name: '',
                        tagline: '',
                        industry: 'General',
                        stage: 'MVP',
                        founderName: '',
                        fundingRequired: 500000,
                        equityOffered: 10,
                        location: 'Remote',
                      ),
                    ),
                  );

                  if (data == null) return;
                  if (!fabContext.mounted) return;

                  showDialog(
                    context: fabContext,
                    barrierDismissible: false,
                    builder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  final res = await repo.createIdea(data);
                  if (fabContext.mounted) Navigator.pop(fabContext);

                  if (fabContext.mounted) {
                    res.fold(
                      (f) => fabContext.showTopSnack(f.message, isError: true),
                      (created) {
                        fabContext.showTopSnack(
                          'Startup Idea published successfully!',
                        );
                        setState(() => _refreshKey++);
                      },
                    );
                  }
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Post Startup'),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
            itemBuilder: (context, s, _) {
              return AppStartupCard(
                startup: s,
                onTap: () async {
                  await context.push('${Routes.startupDetails}/${s.id}');
                  if (context.mounted) {
                    try {
                      context.read<ListBloc<Startup>>().add(
                        const ListRefreshed(),
                      );
                    } catch (_) {}
                    setState(() => _refreshKey++);
                  }
                },
                onSave: () async {
                  final res = await repo.toggleSave(s.id);
                  res.fold(
                    (f) => context.showTopSnack(f.message, isError: true),
                    (success) {
                      if (success) {
                        setState(() => _refreshKey++);
                        context.showTopSnack(
                          !s.isSaved ? 'Saved startup' : 'Removed from saved',
                        );
                      }
                    },
                  );
                },
                onInterest: () async {
                  if (s.hasInvested) {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Withdraw Interest',
                              style: ctx.text.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(ctx, false),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        content: const Text(
                          'Are you sure you want to withdraw your interest in this startup?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: AppColors.danger),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSizes.radiusSm),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 10,
                              ),
                            ),
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text(
                              'Withdraw',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;

                    final res = await repo.withdrawInterest(s.id);
                    res.fold(
                      (f) => context.showTopSnack(f.message, isError: true),
                      (success) {
                        if (success) {
                          setState(() => _refreshKey++);
                          context.showTopSnack(
                            'Withdrew interest successfully',
                          );
                        }
                      },
                    );
                  } else {
                    final submitted = await showInvestmentOfferSheet(
                      context,
                      startupId: s.id,
                      startupName: s.name,
                    );
                    if (submitted == true) {
                      setState(() => _refreshKey++);
                      if (context.mounted) {
                        await context.push('${Routes.startupDetails}/${s.id}');
                        if (context.mounted) {
                          try {
                            context.read<ListBloc<Startup>>().add(
                              const ListRefreshed(),
                            );
                          } catch (_) {}
                          setState(() => _refreshKey++);
                        }
                      }
                    }
                  }
                },
                onEdit: null,
                onDelete: null,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: 18,
                  color: isSelected
                      ? Colors.white
                      : (context.isDark
                            ? AppColors.darkBorder
                            : const Color(0xFF64748B)),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: context.text.labelLarge?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : (context.isDark
                                ? AppColors.darkText
                                : const Color(0xFF475569)),
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
