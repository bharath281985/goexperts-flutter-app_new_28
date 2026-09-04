import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/catalog_view.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/domain/repositories/project_repository.dart';
import '../../domain/entities/investor.dart';
import '../../domain/repositories/investor_repository.dart';
import '../widgets/investment_edit_sheet.dart';
import '../../../meetings/presentation/widgets/schedule_meeting_sheet.dart';

/// Embeddable deal-room & contracts catalog with 2 top tabs.
class DealsListView extends StatefulWidget {
  const DealsListView({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<DealsListView> createState() => _DealsListViewState();
}

class _DealsListViewState extends State<DealsListView> {
  late int _selectedTab;
  int _refreshKey = 0;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
  }

  Widget _buildTopTabs(BuildContext context) {
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
              label: 'Investment Deals',
              icon: Icons.handshake_outlined,
              activeIcon: Icons.handshake_rounded,
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
              label: 'Project Contracts',
              icon: Icons.description_outlined,
              activeIcon: Icons.description_rounded,
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
    final isDeals = _selectedTab == 0;
    final projectRepo = sl<ProjectRepository>();
    final investorRepo = sl<InvestorRepository>();

    return Column(
      children: [
        _buildTopTabs(context),
        Expanded(
          child: isDeals
              ? CatalogView<Deal>(
                  key: ValueKey('deals-tab-$_selectedTab-$_refreshKey'),
                  fetcher: investorRepo.getDeals,
                  searchHint: 'Search deals…',
                  emptyTitle: 'No active investment deals',
                  emptyMessage:
                      'Startup investment offers and deal room opportunities will appear here.',
                  emptyIcon: Icons.handshake_outlined,
                  skeletonHeight: 120,
                  itemBuilder: (context, deal, _) => _DealCard(deal: deal),
                )
              : CatalogView<Contract>(
                  key: ValueKey('contracts-tab-$_selectedTab-$_refreshKey'),
                  fetcher: projectRepo.getContracts,
                  searchHint: 'Search contracts…',
                  emptyTitle: 'No project contracts yet',
                  emptyMessage:
                      'Accepted proposals and active project contracts will appear here.',
                  emptyIcon: Icons.description_outlined,
                  skeletonHeight: 120,
                  itemBuilder: (context, contract, _) =>
                      _ContractCard(contract: contract),
                ),
        ),
      ],
    );
  }
}

String _formatStage(String raw) {
  if (raw.isEmpty) return 'MVP';
  if (raw.contains('name:')) {
    final match = RegExp(r'name:\s*([^,}]+)').firstMatch(raw);
    if (match != null) return match.group(1)!.trim();
  }
  if (raw.contains('label:')) {
    final match = RegExp(r'label:\s*([^,}]+)').firstMatch(raw);
    if (match != null) return match.group(1)!.trim();
  }
  if (raw.contains('id:')) {
    final match = RegExp(r'id:\s*([^,}]+)').firstMatch(raw);
    if (match != null) return match.group(1)!.trim();
  }
  return raw.replaceAll(RegExp(r'[{}]'), '').trim();
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
                                  _formatStage(deal.stage),
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
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit Offer'),
                    onPressed: () {
                      showInvestmentEditSheet(context, deal: deal);
                    },
                  ),
                ),
                AppSizes.hGapMd,
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.event_rounded, size: 16),
                    label: const Text('Schedule'),
                    onPressed: () => ScheduleMeetingSheet.show(
                      context,
                      targetId: deal.founderId ?? deal.startupId,
                      targetName: deal.founderName,
                      targetAvatar: deal.startupLogo,
                    ),
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
      useSafeArea: true,
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

class _ContractCard extends StatelessWidget {
  const _ContractCard({required this.contract});
  final Contract contract;

  @override
  Widget build(BuildContext context) {
    final hasMilestones = contract.milestones.isNotEmpty;
    final counterparty = contract.counterpartyName.isNotEmpty
        ? contract.counterpartyName
        : (contract.freelancerName.isNotEmpty
            ? contract.freelancerName
            : (contract.clientName ?? 'Contract'));

    final avatarUrl = contract.counterpartyAvatar ??
        contract.freelancerAvatar ??
        contract.clientAvatar;

    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push('${Routes.contractDetails}/${contract.id}'),
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppAvatar(
                    name: counterparty,
                    imageUrl: avatarUrl,
                    size: 48,
                  ),
                  AppSizes.hGapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contract.projectTitle,
                          style: context.text.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              size: 14,
                              color: AppColors.mutedText,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                counterparty,
                                style: context.text.bodySmall?.copyWith(
                                  color: context.isDark
                                      ? AppColors.mutedText
                                      : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppStatusChip.status(contract.status, dense: true),
                ],
              ),
              AppSizes.vGapMd,
              Container(
                padding: const EdgeInsets.all(AppSizes.md),
                decoration: BoxDecoration(
                  color: context.isDark
                      ? AppColors.darkCard
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(
                    color: context.isDark
                        ? AppColors.darkBorder
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Contract Value',
                            style: context.text.labelSmall?.copyWith(
                              color: AppColors.mutedText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            Formatters.compactCurrency(contract.amount),
                            style: context.text.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasMilestones) ...[
                      Container(
                        height: 28,
                        width: 1,
                        color: context.isDark
                            ? AppColors.darkBorder
                            : const Color(0xFFE2E8F0),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Milestones',
                              style: context.text.labelSmall?.copyWith(
                                color: AppColors.mutedText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${contract.milestones.where((m) => m.status == EntityStatus.completed).length}/${contract.milestones.length} Completed',
                              style: context.text.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              AppSizes.vGapMd,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: context.text.labelSmall?.copyWith(
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${(contract.progress * 100).toInt()}%',
                    style: context.text.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: contract.progress.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: context.isDark
                      ? AppColors.darkBorder
                      : const Color(0xFFE2E8F0),
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.success),
                ),
              ),
            ],
          ),
        ),
      ),
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
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
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

