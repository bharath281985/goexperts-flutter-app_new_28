import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/auth/token_role_helper.dart';
import '../../../../core/bloc/list_bloc.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/bookmark_manager.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/widgets/app_filter_bottom_sheet.dart';
import '../../../../core/widgets/catalog_view.dart';
import '../../../master_data/domain/entities/skill_category.dart';
import '../../../master_data/domain/repositories/master_data_repository.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../widgets/project_card.dart';

const _projectSortOptions = [
  'Newest',
  'Budget: High to Low',
  'Budget: Low to High',
  'Most proposals',
];

const _projectSortApiValues = {
  'Newest': 'newest',
  'Budget: High to Low': 'budget_desc',
  'Budget: Low to High': 'budget_asc',
  'Most proposals': 'proposals_desc',
};

/// Embeddable discover-projects catalog with Role-Wise Top Tabs.
class ProjectsListView extends StatefulWidget {
  const ProjectsListView({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<ProjectsListView> createState() => _ProjectsListViewState();
}

class _ProjectsListViewState extends State<ProjectsListView> {
  List<SkillCategory> _categories = const [];
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
    final role = await sl<TokenRoleHelper>().resolve();
    final categoriesResult = await sl<MasterDataRepository>()
        .getSkillCategories(page: 1, pageSize: 200);
    if (!mounted) return;
    setState(() {
      _role = role;
      if (role == UserRole.client) {
        _selectedTab = 1;
      }
      _categories = categoriesResult.valueOrNull ?? const [];
      _loading = false;
    });
  }

  Future<void> _openEditProject(BuildContext context, String projectId) async {
    await context.push<bool>(
      '${Routes.clientCreateProject}?projectId=${Uri.encodeComponent(projectId)}',
    );
    if (!mounted) return;
    setState(() => _refreshKey++);
  }

  Future<void> _openProjectDetails(
    BuildContext context,
    String projectId,
  ) async {
    await context.push<bool>('${Routes.projectDetails}/$projectId');
    if (!mounted) return;
    setState(() => _refreshKey++);
  }

  Future<void> _toggleSaveProject(BuildContext context, Project project) async {
    final res = await sl<ProjectRepository>().toggleSave(project.id);
    if (!context.mounted) return;
    res.fold(
      (failure) => context.showSnack(
        failure.message.isNotEmpty
            ? failure.message
            : 'Failed to update saved status',
        isError: true,
      ),
      (_) {
        final newSaved = !project.isSaved;
        BookmarkManager.instance.syncItem(
          BookmarkManager.categoryProjects,
          project.id,
          newSaved,
        );
        try {
          context.read<ListBloc<Project>>().add(
            ListItemUpdated(
              project.copyWith(isSaved: newSaved),
              (existing, updated) =>
                  (existing as Project).id == (updated as Project).id,
            ),
          );
        } catch (_) {}
        context.showSnack(
          newSaved ? 'Project saved' : 'Project removed from saved',
        );
      },
    );
  }

  List<FilterSection> _filterSections() {
    final isClient = _role == UserRole.client;
    final isMyProjects = _selectedTab == 1;

    return [
      if (isMyProjects || isClient)
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
      if (_role != UserRole.client || !isMyProjects)
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

  Widget _buildTopTabs(BuildContext context) {
    if (_role == UserRole.client) {
      return const SizedBox.shrink();
    }
    final isClient = _role == UserRole.client;
    final myTabLabel = isClient ? 'My Posted' : 'My Projects';

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
              label: 'Explore Projects',
              icon: Icons.travel_explore_outlined,
              activeIcon: Icons.travel_explore_rounded,
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
              icon: Icons.folder_shared_outlined,
              activeIcon: Icons.folder_shared_rounded,
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

    final repo = sl<ProjectRepository>();
    final isClient = _role == UserRole.client;
    final isExplore = !isClient && _selectedTab == 0;

    return Column(
      children: [
        _buildTopTabs(context),
        Expanded(
          child: CatalogView<Project>(
            key: ValueKey('projects-tab-$_selectedTab-$_refreshKey'),
            fetcher: (params) {
              final sortLabel = params.sortBy;
              final apiSort = sortLabel == null
                  ? null
                  : (_projectSortApiValues[sortLabel] ?? sortLabel);
              final qp = params.copyWith(
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
              );

              return isExplore
                  ? repo.getExploreProjects(qp)
                  : repo.getMyProjects(qp);
            },
            searchHint: isExplore
                ? 'Search projects, skills…'
                : 'Search my projects…',
            emptyTitle: isExplore
                ? 'No projects found'
                : (isClient
                      ? 'No posted projects yet'
                      : 'No project assignments yet'),
            emptyMessage: isExplore
                ? 'Try adjusting your search or filters.'
                : (isClient
                      ? 'Post a new project to find top talent and receive proposals.'
                      : 'Explore and apply to projects to see your active assignments here.'),
            emptyIcon: isExplore
                ? Icons.work_outline_rounded
                : Icons.folder_open_rounded,
            sortOptions: _projectSortOptions,
            filterSections: _filterSections,
            floatingActionButton: Builder(
              builder: (fabContext) => FloatingActionButton.extended(
                onPressed: () async {
                  await fabContext.push<bool>(Routes.clientCreateProject);
                  if (!fabContext.mounted) return;
                  setState(() => _refreshKey++);
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text(
                  'Post Project',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
            ),
            itemBuilder: (context, project, _) {
              final isOwner = isExplore ? project.isOwner : true;
              return AppProjectCard(
                project: project.copyWith(isOwner: isOwner),
                onTap: () => _openProjectDetails(context, project.id),
                onSave: isOwner
                    ? null
                    : () => _toggleSaveProject(context, project),
                onApply: () => _openProjectDetails(context, project.id),
                onEdit: isOwner
                    ? () => _openEditProject(context, project.id)
                    : null,
                onUpdateStatus: isOwner
                    ? () => _openProjectDetails(context, project.id)
                    : null,
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
                            ? AppColors.darkText
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
