import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/bloc/list_bloc.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_filter_bottom_sheet.dart';
import '../../../../core/widgets/catalog_view.dart';
import '../../domain/entities/startup.dart';
import '../../domain/repositories/startup_repository.dart';
import '../widgets/startup_card.dart';

/// Embeddable startup discovery catalog.
class StartupsListView extends StatelessWidget {
  const StartupsListView({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = sl<StartupRepository>();

    return CatalogView<Startup>(
      fetcher: repo.getStartups,
      searchHint: 'Search startups, industries…',
      emptyTitle: 'No startups found',
      emptyIcon: Icons.rocket_launch_outlined,
      sortOptions: const ['Most interest', 'Funding: High to Low', 'Newest'],
      filterSections: () => [
        FilterSection(
          key: 'industry',
          title: 'Industry',
          options: const [
            'AgriTech',
            'HealthTech',
            'EdTech',
            'CleanTech',
            'FinTech',
            'SaaS',
          ],
        ),
        FilterSection(
          key: 'stage',
          title: 'Stage',
          options: const [
            'Idea Stage',
            'Prototype',
            'MVP',
            'Early Revenue',
            'Early Traction',
            'Growth',
            'Expansion',
          ],
        ),
      ],
      floatingActionButton: null,
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
              context.push(
                '${Routes.apply}?type=Investment&name=${Uri.encodeComponent(s.name)}&projectId=${s.id}',
              );
            }
          },
          onEdit: null,
          onDelete: null,
        );
      },
    );
  }
}
