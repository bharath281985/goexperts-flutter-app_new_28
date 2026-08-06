import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/bloc/list_bloc.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/catalog_view.dart';
import '../../domain/entities/investor.dart';
import '../../domain/repositories/investor_repository.dart';

/// Embeddable portfolio holdings catalog (Cockpit Mobile View).
class PortfolioListView extends StatelessWidget {
  const PortfolioListView({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = sl<InvestorRepository>();
    return CatalogView<PortfolioItem>(
      fetcher: repo.getPortfolio,
      showSearch: false,
      emptyTitle: 'No holdings yet',
      emptyIcon: Icons.pie_chart_outline_rounded,
      skeletonHeight: 180,
      header: const Padding(
        padding: EdgeInsets.fromLTRB(
          AppSizes.screenPadding,
          AppSizes.md,
          AppSizes.screenPadding,
          0,
        ),
        child: _PortfolioSummary(),
      ),
      itemBuilder: (context, item, _) => Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.md),
        child: _PortfolioTile(item: item),
      ),
    );
  }
}

class _PortfolioSummary extends StatelessWidget {
  const _PortfolioSummary();
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ListBloc<PortfolioItem>, ListState<PortfolioItem>>(
      builder: (context, state) {
        final items = state.items;
        final totalInvested = items.fold<double>(
          0.0,
          (sum, item) => sum + item.investedAmount,
        );
        final totalCurrentValue = items.fold<double>(
          0.0,
          (sum, item) => sum + item.currentValue,
        );
        final overallRoI = totalInvested == 0
            ? 0.0
            : ((totalCurrentValue - totalInvested) / totalInvested) * 100;
        final blendedMoic = totalInvested == 0
            ? 0.0
            : (totalCurrentValue / totalInvested);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Dark Cockpit Header
            Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                gradient: AppColors.darkGradient,
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 12,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB45309).withAlpha(40),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFFB45309).withAlpha(120),
                          ),
                        ),
                        child: Text(
                          'Institutional Portfolio Cockpit',
                          style: TextStyle(
                            color: const Color(0xFFFDE68A),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Updated Live',
                        style: TextStyle(
                          color: Colors.white.withAlpha(120),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    Formatters.compactCurrency(totalCurrentValue),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${overallRoI >= 0 ? '+' : ''}${Formatters.compactCurrency(totalCurrentValue - totalInvested)} ',
                        style: TextStyle(
                          color: overallRoI >= 0
                              ? const Color(0xFF10B981) // emerald
                              : const Color(0xFFEF4444), // red
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '(${overallRoI >= 0 ? '+' : ''}${overallRoI.toStringAsFixed(1)}%) ',
                        style: TextStyle(
                          color: overallRoI >= 0
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Total Unrealized Return',
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _CockpitStat(
                          label: 'TOTAL CAPITAL DEPLOYED',
                          value: Formatters.compactCurrency(totalInvested),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CockpitStat(
                          label: 'PORTFOLIO COMPANIES',
                          value: items.length.toString(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CockpitStat(
                          label: 'BLENDED MOIC',
                          value: '${blendedMoic.toStringAsFixed(2)}x',
                          valueColor: const Color(0xFFFBBF24),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            AppSizes.vGapXl,

            // 2. Section Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Portfolio Ventures',
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkText,
                        ),
                      ),
                      Text(
                        'Detailed breakdown of active equity investments',
                        style: context.text.bodySmall?.copyWith(
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppSizes.vGapMd,
          ],
        );
      },
    );
  }
}

class _CockpitStat extends StatelessWidget {
  const _CockpitStat({
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
  });
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withAlpha(140),
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PortfolioTile extends StatelessWidget {
  const _PortfolioTile({required this.item});
  final PortfolioItem item;

  @override
  Widget build(BuildContext context) {
    final moic = item.investedAmount == 0
        ? 0.0
        : (item.currentValue / item.investedAmount);
    final positiveRoi = item.roi >= 0;

    return AppCard(
      padding: const EdgeInsets.all(AppSizes.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              AppAvatar(
                name: item.startupName,
                imageUrl: item.logoUrl,
                size: 48,
              ),
              AppSizes.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.startupName,
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${item.equity.toStringAsFixed(1)}% Equity',
                      style: context.text.labelSmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Active',
                      style: TextStyle(
                        color: Color(0xFF047857),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSizes.vGapLg,

          // Metrics Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CAPITAL INVESTED',
                      style: context.text.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.subtleText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.compactCurrency(item.investedAmount),
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT VALUATION',
                      style: context.text.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.subtleText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.compactCurrency(item.currentValue),
                      style: context.text.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSizes.vGapXl,

          // Divider
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 12),

          // Footer Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  text: 'MOIC Multiple: ',
                  style: context.text.labelSmall?.copyWith(
                    color: AppColors.mutedText,
                  ),
                  children: [
                    TextSpan(
                      text: '${moic.toStringAsFixed(1)}x',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: positiveRoi
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${positiveRoi ? '+' : ''}${item.roi.toStringAsFixed(0)}% ROI',
                  style: TextStyle(
                    color: positiveRoi
                        ? const Color(0xFF047857)
                        : const Color(0xFFB91C1C),
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
