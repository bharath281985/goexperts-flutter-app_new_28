import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/bloc/list_bloc.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/bookmark_manager.dart';
import '../../../../core/widgets/app_filter_bottom_sheet.dart';
import '../../../../core/widgets/catalog_view.dart';
import '../../domain/entities/investor.dart';
import '../../domain/repositories/investor_repository.dart';
import '../widgets/investor_card.dart';

/// Embeddable investor discovery catalog (used by founders).
class InvestorsListView extends StatelessWidget {
  const InvestorsListView({super.key});

  Future<void> _toggleSave(BuildContext context, Investor i) async {
    final api = sl<ApiClientHelper>();
    final isSaved =
        BookmarkManager.instance.isBookmarked(
          BookmarkManager.categoryInvestors,
          i.id,
        ) ||
        i.isSaved;

    final res = isSaved
        ? await api.deleteAction(ApiEndpoints.publicInvestorSave(i.id))
        : await api.postAction(ApiEndpoints.publicInvestorSave(i.id));

    if (!context.mounted) return;

    res.fold(
      (failure) => context.showSnack(
        failure.message.isNotEmpty
            ? failure.message
            : 'Failed to update saved status',
        isError: true,
      ),
      (_) {
        final newSaved = !isSaved;
        BookmarkManager.instance.syncItem(
          BookmarkManager.categoryInvestors,
          i.id,
          newSaved,
        );
        try {
          context.read<ListBloc<Investor>>().add(
            ListItemUpdated(
              i.copyWith(isSaved: newSaved),
              (existing, updated) =>
                  (existing as Investor).id == (updated as Investor).id,
            ),
          );
        } catch (_) {}
        context.showSnack(
          newSaved ? 'Investor saved' : 'Investor removed from saved',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = sl<InvestorRepository>();
    return CatalogView<Investor>(
      fetcher: repo.getInvestors,
      searchHint: 'Search investors, industries…',
      emptyTitle: 'No investors found',
      emptyIcon: Icons.trending_up_rounded,
      sortOptions: const ['Most deals', 'Ticket: High to Low'],
      filterSections: () => [
        FilterSection(
          key: 'industry',
          title: 'Industries',
          options: const [
            'FinTech',
            'SaaS',
            'AI',
            'HealthTech',
            'EdTech',
            'CleanTech',
            'Manufacturing',
            'AgriTech',
            'E-Commerce',
          ],
        ),
        FilterSection(
          key: 'partnerRole',
          title: 'Partner Role',
          options: const [
            'Working Partner',
            'Sleeping Partner',
            'Strategic Partner',
            'Mentor Investor',
          ],
        ),
      ],
      itemBuilder: (context, i, _) => AppInvestorCard(
        investor: i,
        onTap: () async {
          await context.push('${Routes.publicInvestor}/${i.id}');
          if (context.mounted) {
            context.read<ListBloc<Investor>>().add(const ListRefreshed());
          }
        },
        onSave: () => _toggleSave(context, i),
        // onFollow: () => context.showSnack(
        //   i.isFollowing ? 'Unfollowed' : 'Following ${i.name}',
        // ),
        // onConnect: () =>
        //     context.showSnack('Connection request sent to ${i.name}'),
      ),
    );
  }
}
