import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/bloc/list_bloc.dart';
import '../../../../core/extensions/context_extensions.dart';
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

/// Embeddable startup discovery catalog.
class StartupsListView extends StatefulWidget {
  const StartupsListView({super.key});

  @override
  State<StartupsListView> createState() => _StartupsListViewState();
}

class _StartupsListViewState extends State<StartupsListView> {
  List<SkillCategory> _categories = const [];
  List<SkillCategory> _industries = const [];
  List<MasterOption> _stages = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final masterRepo = sl<MasterDataRepository>();
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

  @override
  Widget build(BuildContext context) {
    final repo = sl<StartupRepository>();

    return CatalogView<Startup>(
      fetcher: (params) {
        final sortLabel = params.sortBy;
        final apiSort = sortLabel == null
            ? null
            : (_startupSortApiValues[sortLabel] ?? sortLabel);
        return repo.getStartups(
          params.copyWith(
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
          ),
        );
      },
      searchHint: 'Search startups, industries…',
      emptyTitle: 'No startups found',
      emptyMessage: 'Try adjusting your search or filters.',
      emptyIcon: Icons.rocket_launch_outlined,
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
              builder: (_) => const Center(child: CircularProgressIndicator()),
            );

            final res = await repo.createIdea(data);
            if (fabContext.mounted) Navigator.pop(fabContext);

            if (fabContext.mounted) {
              res.fold(
                (f) => fabContext.showTopSnack(f.message, isError: true),
                (created) {
                  fabContext.showTopSnack('Startup Idea published successfully!');
                  fabContext.read<ListBloc<Startup>>().add(const ListRefreshed());
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
        final bloc = context.read<ListBloc<Startup>>();
        return AppStartupCard(
          startup: s,
          onTap: () => context.push('${Routes.startupDetails}/${s.id}'),
          onSave: () async {
            final res = await repo.toggleSave(s.id);
            res.fold((f) => context.showTopSnack(f.message, isError: true), (
              success,
            ) {
              if (success) {
                final updated = s.copyWith(isSaved: !s.isSaved);
                bloc.add(
                  ListItemUpdated(
                    updated,
                    (existing, newItem) => existing.id == newItem.id,
                  ),
                );
                context.showTopSnack(
                  updated.isSaved ? 'Saved startup' : 'Removed from saved',
                );
              }
            });
          },
          onInterest: () async {
            if (s.hasInvested) {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Withdraw Interest'),
                  content: const Text(
                    'Are you sure you want to withdraw your interest in this startup?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'Withdraw',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm != true) return;

              final res = await repo.withdrawInterest(s.id);
              res.fold((f) => context.showTopSnack(f.message, isError: true), (
                success,
              ) {
                if (success) {
                  final updated = s.copyWith(hasInvested: false);
                  bloc.add(
                    ListItemUpdated(
                      updated,
                      (existing, newItem) => existing.id == newItem.id,
                    ),
                  );
                  context.showTopSnack('Withdrew interest successfully');
                }
              });
            } else {
              final submitted = await showInvestmentOfferSheet(
                context,
                startupId: s.id,
                startupName: s.name,
              );
              if (submitted == true) {
                final updated = s.copyWith(hasInvested: true);
                bloc.add(
                  ListItemUpdated(
                    updated,
                    (existing, newItem) => existing.id == newItem.id,
                  ),
                );
                if (context.mounted) {
                  context.push('${Routes.startupDetails}/${s.id}');
                }
              }
            }
          },
          onEdit: null,
          onDelete: null,
        );
      },
    );
  }
}
