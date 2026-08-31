import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/bloc/list_bloc.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/bookmark_manager.dart';
import '../../../../core/widgets/app_filter_bottom_sheet.dart';
import '../../../../core/widgets/catalog_view.dart';
import '../../../../core/widgets/invite_freelancer_dialog.dart';
import '../../../master_data/domain/entities/skill_category.dart';
import '../../../master_data/domain/repositories/master_data_repository.dart';
import '../../domain/entities/freelancer.dart';
import '../../domain/repositories/freelancer_repository.dart';
import '../widgets/freelancer_card.dart';

/// Embeddable freelancer discovery catalog.
class FreelancersListView extends StatefulWidget {
  const FreelancersListView({super.key});

  @override
  State<FreelancersListView> createState() => _FreelancersListViewState();
}

class _FreelancersListViewState extends State<FreelancersListView> {
  List<SkillCategory> _categories = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final result = await sl<MasterDataRepository>().getSkillCategories(
      page: 1,
      pageSize: 200,
    );
    if (!mounted) return;
    setState(() {
      _categories = result.valueOrNull ?? const [];
      _loading = false;
    });
  }

  Future<void> _toggleSave(BuildContext context, Freelancer f) async {
    final repo = sl<FreelancerRepository>();
    final res = await repo.toggleSave(f.id);
    if (!context.mounted) return;
    res.fold(
      (failure) => context.showSnack(
        failure.message.isNotEmpty
            ? failure.message
            : 'Failed to update saved status',
        isError: true,
      ),
      (_) {
        final newSaved = !f.isSaved;
        BookmarkManager.instance.syncItem(
          BookmarkManager.categoryFreelancers,
          f.id,
          newSaved,
        );
        try {
          context.read<ListBloc<Freelancer>>().add(
            ListItemUpdated(
              f.copyWith(isSaved: newSaved),
              (existing, updated) =>
                  (existing as Freelancer).id == (updated as Freelancer).id,
            ),
          );
        } catch (_) {}
        context.showSnack(
          newSaved ? 'Freelancer saved' : 'Freelancer removed from saved',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final repo = sl<FreelancerRepository>();
    return CatalogView<Freelancer>(
      fetcher: repo.getFreelancers,
      searchHint: 'Search freelancers, skills…',
      emptyTitle: 'No freelancers found',
      emptyIcon: Icons.groups_outlined,
      sortOptions: const ['Top rated', 'Rate: Low to High', 'Most experienced'],
      filterSections: () => [
        FilterSection(
          key: 'categoryIds',
          title: 'Category',
          searchable: true,
          searchHint: 'Search categories…',
          optionItems: _categories
              .map((c) => FilterOption(value: c.id, label: c.name))
              .toList(),
        ),
        FilterSection(
          key: 'availability',
          title: 'Availability',
          options: const ['Available now', 'Within a week'],
        ),
      ],
      itemBuilder: (context, f, _) => AppFreelancerCard(
        freelancer: f,
        onTap: () => context.push('${Routes.publicFreelancer}/${f.id}'),
        onSave: () => _toggleSave(context, f),
        onInvite: () => InviteFreelancerDialog.show(
          context,
          freelancerId: f.id,
          freelancerName: f.name,
          freelancerAvatar: f.avatarUrl,
        ),
      ),
    );
  }
}

