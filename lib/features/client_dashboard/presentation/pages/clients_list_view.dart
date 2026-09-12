import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/catalog_view.dart';
import '../../domain/entities/company.dart';
import '../../domain/repositories/company_repository.dart';

class ClientsListView extends StatelessWidget {
  const ClientsListView({super.key, this.initialSearch = ''});

  final String initialSearch;

  @override
  Widget build(BuildContext context) {
    final repo = sl<CompanyRepository>();
    return CatalogView<Company>(
      fetcher: repo.getCompanies,
      searchHint: 'Search clients, companies…',
      initialSearch: initialSearch,
      emptyTitle: 'No clients found',
      emptyIcon: Icons.business_center_outlined,
      itemBuilder: (context, company, _) => AppCard(
        onTap: () => context.push('${Routes.publicCompany}/${company.id}'),
        child: Row(
          children: [
            AppAvatar(
              name: company.name,
              imageUrl: company.logoUrl,
              size: 48,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    company.name,
                    style: context.text.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [company.industry, company.location]
                        .where((part) => part.trim().isNotEmpty)
                        .join(' • '),
                    style: context.text.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
