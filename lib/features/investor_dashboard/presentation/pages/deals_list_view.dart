import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/catalog_view.dart';
import '../../domain/entities/investor.dart';
import '../../domain/repositories/investor_repository.dart';
import '../../../meetings/presentation/pages/meetings_list_view.dart';

/// Embeddable deal-room catalog.
class DealsListView extends StatelessWidget {
  const DealsListView({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = sl<InvestorRepository>();
    return CatalogView<Deal>(
      fetcher: repo.getDeals,
      searchHint: 'Search deals…',
      emptyTitle: 'No active deals',
      emptyIcon: Icons.handshake_outlined,
      skeletonHeight: 100,
      itemBuilder: (context, deal, _) => _DealCard(deal: deal),
    );
  }
}

class _DealCard extends StatelessWidget {
  const _DealCard({required this.deal});
  final Deal deal;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Top Header block
          InkWell(
            onTap: () =>
                context.push('${Routes.startupDetails}/${deal.startupId}'),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.radiusLg),
            ),
            child: Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSizes.radiusLg),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            width: 2,
                          ),
                        ),
                        child: AppAvatar(
                          name: deal.startupName,
                          imageUrl: deal.startupLogo,
                          size: 52,
                        ),
                      ),
                      AppSizes.hGapMd,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deal.startupName,
                              style: context.text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.category_outlined,
                                  size: 14,
                                  color: AppColors.mutedText,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  deal.stage,
                                  style: context.text.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      AppStatusChip.status(deal.status, dense: true),
                    ],
                  ),
                  AppSizes.vGapLg,

                  // Deal Financials Container
                  Container(
                    padding: const EdgeInsets.all(AppSizes.md),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusSm,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.payments_rounded,
                                  color: AppColors.success,
                                  size: 16,
                                ),
                              ),
                              AppSizes.hGapSm,
                              Expanded(
                                child: _stat(
                                  context,
                                  'Offer',
                                  Formatters.compactCurrency(deal.amount),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 32,
                          color: AppColors.border,
                        ),
                        AppSizes.hGapMd,
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppSizes.radiusSm,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.pie_chart_rounded,
                                  color: AppColors.warning,
                                  size: 16,
                                ),
                              ),
                              AppSizes.hGapSm,
                              Expanded(
                                child: _stat(
                                  context,
                                  'Equity',
                                  '${deal.equity.toStringAsFixed(1)}%',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Documents & NDAs
                  if (deal.documentsCount > 0 || deal.hasNda) ...[
                    AppSizes.vGapMd,
                    Row(
                      children: [
                        if (deal.documentsCount > 0)
                          InkWell(
                            onTap: () => _showDocs(context, deal.documents),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusPill,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.info.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  AppSizes.radiusPill,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.description_outlined,
                                    size: 14,
                                    color: AppColors.info,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${deal.documentsCount} Documents',
                                    style: context.text.labelSmall?.copyWith(
                                      color: AppColors.info,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (deal.hasNda) ...[
                          AppSizes.hGapSm,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusPill,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'NDA Signed',
                                  style: context.text.labelSmall?.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      minimumSize: const Size(0, 42),
                    ),
                    icon: const Icon(Icons.person_outline_rounded, size: 16),
                    label: const Text('Founder'),
                    onPressed: () {
                      final founderId = deal.founderId ?? deal.startupId;
                      context.push('${Routes.publicFounder}/$founderId');
                    },
                  ),
                ),
                AppSizes.hGapMd,
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      minimumSize: const Size(0, 42),
                    ),
                    icon: const Icon(Icons.event_rounded, size: 16),
                    label: const Text('Schedule'),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => ScheduleMeetingSheet(
                          onScheduled: () {},
                          preselectedParticipantId:
                              deal.founderId ?? deal.startupId,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(value, style: context.text.titleSmall),
      Text(label, style: context.text.labelSmall),
    ],
  );

  void _showDocs(BuildContext context, Map<String, dynamic> docs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final validDocs = docs.entries
            .where(
              (e) => e.value != null && e.value.toString().trim().isNotEmpty,
            )
            .toList();

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Documents & Links',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              AppSizes.vGapMd,
              if (validDocs.isEmpty) const Text('No documents available.'),
              for (var entry in validDocs) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    entry.key.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  subtitle: SelectableText(
                    entry.value.toString(),
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
                const Divider(),
              ],
              AppSizes.vGapLg,
              AppSizes.vGapLg,
            ],
          ),
        );
      },
    );
  }
}
