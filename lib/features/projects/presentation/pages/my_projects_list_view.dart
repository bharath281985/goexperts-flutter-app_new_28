import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/bloc/list_bloc.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_filter_bottom_sheet.dart';
import '../../../../core/widgets/catalog_view.dart';
import '../../../master_data/domain/entities/skill_category.dart';
import '../../../master_data/domain/repositories/master_data_repository.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../widgets/project_card.dart';

const _myProjectSortOptions = [
  'Newest',
  'Oldest',
  'Budget: High to Low',
  'Budget: Low to High',
  'Most proposals',
];

const _myProjectSortApiValues = {
  'Newest': 'desc',
  'Oldest': 'asc',
  'Budget: High to Low': 'budget_desc',
  'Budget: Low to High': 'budget_asc',
  'Most proposals': 'proposals_desc',
};

/// Embeddable my-projects catalog (used as a dashboard tab & standalone page).
class MyProjectsListView extends StatefulWidget {
  const MyProjectsListView({super.key});

  @override
  State<MyProjectsListView> createState() => _MyProjectsListViewState();
}

class _MyProjectsListViewState extends State<MyProjectsListView> {
  List<SkillCategory> _categories = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final categoriesResult = await sl<MasterDataRepository>()
        .getSkillCategories(page: 1, pageSize: 200);
    if (!mounted) return;
    setState(() {
      _categories = categoriesResult.valueOrNull ?? const [];
      _loading = false;
    });
  }

  Future<void> _openCreateProject(BuildContext context) async {
    await context.push<bool>(Routes.clientCreateProject);
    if (!context.mounted) return;
    context.read<ListBloc<Project>>().add(const ListRefreshed());
  }

  Future<void> _openEditProject(BuildContext context, String projectId) async {
    await context.push<bool>(
      '${Routes.clientCreateProject}?projectId=${Uri.encodeComponent(projectId)}',
    );
    if (!context.mounted) return;
    context.read<ListBloc<Project>>().add(const ListRefreshed());
  }

  Future<void> _openProjectDetails(
    BuildContext context,
    String projectId,
  ) async {
    await context.push<bool>('${Routes.projectDetails}/$projectId');
    if (!context.mounted) return;
    context.read<ListBloc<Project>>().add(const ListRefreshed());
  }

  List<FilterSection> _filterSections() {
    return [
      FilterSection(
        key: 'status',
        title: 'Status',
        singleSelect: true,
        optionItems: const [
          FilterOption(value: 'draft', label: 'Draft'),
          FilterOption(value: 'open', label: 'Open'),
          FilterOption(value: 'in_progress', label: 'In progress'),
          FilterOption(value: 'completed', label: 'Completed'),
          FilterOption(value: 'cancelled', label: 'Cancelled'),
        ],
      ),
      FilterSection(
        key: 'categoryId',
        title: 'Category',
        searchable: true,
        searchHint: 'Search categories…',
        optionItems: _categories
            .map((c) => FilterOption(value: c.id, label: c.name))
            .toList(),
      ),
      FilterSection(
        key: 'workModes',
        title: 'Work Mode',
        options: const ['Remote', 'On-site', 'Hybrid'],
      ),
      FilterSection(
        key: 'experienceLevels',
        title: 'Experience Level',
        optionItems: const [
          FilterOption(value: 'beginner', label: 'Beginner'),
          FilterOption(value: 'intermediate', label: 'Intermediate'),
          FilterOption(value: 'expert', label: 'Expert'),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final repo = sl<ProjectRepository>();

    return CatalogView<Project>(
      fetcher: (params) {
        final sortLabel = params.sortBy;
        final apiSort = sortLabel == null
            ? null
            : (_myProjectSortApiValues[sortLabel] ?? sortLabel);
        return repo.getMyProjects(
          params.copyWith(
            sortBy: apiSort,
            filters: {
              for (final entry in params.filters.entries)
                if (entry.key == 'categoryId')
                  'categoryId': entry.value
                else if (entry.key == 'workModes')
                  'workModes': entry.value
                else if (entry.key == 'experienceLevels')
                  'experienceLevels': entry.value
                else if (entry.key == 'status' && entry.value is List)
                  'status': (entry.value as List).isNotEmpty
                      ? (entry.value as List).first
                      : null
                else
                  entry.key: entry.value,
            },
          ),
        );
      },
      searchHint: 'Search my projects…',
      emptyTitle: 'No projects created yet',
      emptyMessage:
          'Post a new project to find top talent and start collaborating.',
      emptyIcon: Icons.folder_open_rounded,
      header: _CreateProjectHeader(
        onPressed: () => _openCreateProject(context),
      ),
      sortOptions: _myProjectSortOptions,
      filterSections: _filterSections,
      itemBuilder: (context, project, _) => AppProjectCard(
        project: project.copyWith(isOwner: true),
        onTap: () => _openProjectDetails(context, project.id),
        onEdit: () => _openEditProject(context, project.id),
        onUpdateStatus: () => _openProjectDetails(context, project.id),
      ),
    );
  }
}

class _CreateProjectHeader extends StatelessWidget {
  const _CreateProjectHeader({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add_rounded),
          label: Text(context.tr('Create Project')),
        ),
      ),
    );
  }
}
