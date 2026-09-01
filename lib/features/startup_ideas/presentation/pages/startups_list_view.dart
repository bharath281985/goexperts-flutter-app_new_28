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
import '../../../founder_dashboard/presentation/widgets/edit_idea_bottom_sheet.dart';
import '../../domain/entities/startup.dart';
import '../../domain/repositories/startup_repository.dart';
import '../widgets/investment_offer_sheet.dart';
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
      /*
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final data = await showModalBottomSheet<Map<String, dynamic>>(
            context: context,
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
          if (!context.mounted) return;

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );

          final res = await repo.createIdea(data);
          if (context.mounted) Navigator.pop(context);

          if (context.mounted) {
            res.fold(
              (f) => context.showTopSnack(f.message, isError: true),
              (created) {
                context.showTopSnack('Startup Idea published successfully!');
                context.read<ListBloc<Startup>>().add(const ListStarted());
              },
            );
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Post Startup'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      */
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
