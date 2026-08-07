import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/bookmark_manager.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading_shimmer.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../domain/entities/startup.dart';
import '../../domain/repositories/startup_repository.dart';
import '../../../../core/utils/result.dart';
import '../widgets/investment_offer_sheet.dart';

class StartupDetailsPage extends StatefulWidget {
  const StartupDetailsPage({super.key, required this.id});
  final String id;

  @override
  State<StartupDetailsPage> createState() => _StartupDetailsPageState();
}

class _StartupDetailsPageState extends State<StartupDetailsPage> {
  late final Future<Result<Startup>> _future;
  bool? _hasInvestedOverride;
  bool? _isSavedOverride;
  bool _isLoadingAction = false;

  @override
  void initState() {
    super.initState();
    _future = sl<StartupRepository>().getStartup(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BookmarkManager.instance,
      builder: (context, _) {
        return FutureBuilder<Result<Startup>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                appBar: AppBar(title: const Text('Startup Details')),
                body: const AppLoadingShimmer(itemCount: 4, height: 120),
              );
            }
            final s = snapshot.data?.valueOrNull;
            if (s == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Startup Details')),
                body: const AppErrorState(),
              );
            }

            final isSaved = _isSavedOverride ?? s.isSaved;

            return Scaffold(
              appBar: AppBar(
                title: const Text('Startup Details'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => context.showSnack('Link copied'),
                  ),
                  IconButton(
                    icon: Icon(
                      isSaved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_outline_rounded,
                      color: isSaved ? AppColors.primary : null,
                    ),
                    onPressed: () async {
                      if (_isLoadingAction) return;
                      setState(() => _isSavedOverride = !isSaved);

                      final repo = sl<StartupRepository>();
                      final res = await repo.toggleSave(widget.id);

                      if (mounted) {
                        res.fold(
                          (f) {
                            setState(() => _isSavedOverride = isSaved);
                            context.showSnack(f.message, isError: true);
                          },
                          (success) {
                            context.showSnack(
                              !isSaved ? 'Saved startup' : 'Removed from saved',
                            );
                          },
                        );
                      }
                    },
                  ),
                ],
              ),
              body: _content(context, s),
              bottomNavigationBar: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppSecondaryButton(
                          label: 'Message',
                          icon: Icons.chat_bubble_outline_rounded,
                          onPressed: () {
                            if (s.founderId != null &&
                                s.founderId!.isNotEmpty) {
                              final nameEncoded = Uri.encodeComponent(
                                s.founderName,
                              );
                              final avatarEncoded = Uri.encodeComponent(
                                s.founderAvatar ?? '',
                              );
                              context.push(
                                '${Routes.chat}/${s.founderId}?name=$nameEncoded&avatarUrl=$avatarEncoded',
                              );
                            } else {
                              final nameEncoded = Uri.encodeComponent(s.name);
                              final avatarEncoded = Uri.encodeComponent(
                                s.logoUrl ?? '',
                              );
                              context.push(
                                '${Routes.chat}/su_${widget.id}?name=$nameEncoded&avatarUrl=$avatarEncoded',
                              );
                            }
                          },
                        ),
                      ),
                      AppSizes.hGapMd,
                      Expanded(
                        flex: 2,
                        child: AppPrimaryButton(
                          label: (_hasInvestedOverride ?? s.hasInvested)
                              ? 'Withdraw Interest'
                              : 'Invest / Express Interest',
                          icon: (_hasInvestedOverride ?? s.hasInvested)
                              ? Icons.cancel_outlined
                              : Icons.trending_up_rounded,
                          isLoading: _isLoadingAction,
                          backgroundColor:
                              (_hasInvestedOverride ?? s.hasInvested)
                              ? AppColors.danger
                              : AppColors.primary,
                          onPressed: () async {
                            if (_hasInvestedOverride ?? s.hasInvested) {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Withdraw Interest'),
                                  content: const Text(
                                    'Are you sure you want to withdraw your interest in this startup?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text(
                                        'Withdraw',
                                        style: TextStyle(
                                          color: AppColors.danger,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm != true) return;

                              setState(() {
                                _isLoadingAction = true;
                              });

                              final res = await sl<StartupRepository>()
                                  .withdrawInterest(s.id);

                              if (mounted) {
                                setState(() {
                                  _isLoadingAction = false;
                                });
                                res.fold((f) => context.showSnack(f.message), (
                                  success,
                                ) {
                                  if (success) {
                                    setState(() {
                                      _hasInvestedOverride = false;
                                    });
                                    context.showSnack(
                                      'Withdrew interest successfully',
                                    );
                                  }
                                });
                              }
                            } else {
                              final submitted = await showInvestmentOfferSheet(
                                context,
                                startupId: s.id,
                                startupName: s.name,
                              );
                              if (submitted == true && mounted) {
                                setState(() {
                                  _hasInvestedOverride = true;
                                  _future = sl<StartupRepository>().getStartup(
                                    widget.id,
                                  );
                                });
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _content(BuildContext context, Startup s) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // 1. Sleek Gradient Banner Image with premium fade
        Container(
          height: 190,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/startup_banner.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Theme.of(context).scaffoldBackgroundColor.withOpacity(0.4),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
                stops: const [0.4, 0.8, 1.0],
              ),
            ),
          ),
        ),

        // 2. Avatar & Title Section (Overlapping)
        Transform.translate(
          offset: const Offset(0, -42),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with premium border
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AppAvatar(name: s.name, imageUrl: s.logoUrl, size: 84),
                ),
                AppSizes.vGapSm,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        s.name,
                        style: context.text.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 2,
                      ),
                    ),
                    if (s.isVerified)
                      const Padding(
                        padding: EdgeInsets.only(left: 6, top: 4),
                        child: Icon(
                          Icons.verified_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  s.tagline,
                  style: context.text.bodyLarge?.copyWith(
                    color: AppColors.mutedText,
                    height: 1.3,
                  ),
                ),
                AppSizes.vGapMd,

                // Tags
                Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: [
                    _pill(context, s.industry, icon: Icons.category_outlined),
                    _pill(context, s.stage, icon: Icons.trending_up_rounded),
                    _pill(
                      context,
                      s.location,
                      icon: Icons.location_on_outlined,
                    ),
                  ],
                ),

                AppSizes.vGapLg,
                AppSizes.vGapLg,
                // 3. Premium Interactive Financial Overview
                AppSectionHeader(title: 'Overview'),
                AppSizes.vGapSm,
                Container(
                  padding: const EdgeInsets.all(AppSizes.xl),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.08),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _financialStat(
                              context,
                              'Ask',
                              Formatters.compactCurrency(s.fundingRequired),
                              Icons.payments_rounded,
                              AppColors.primary,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 48,
                            color: AppColors.border.withOpacity(0.5),
                          ),
                          Expanded(
                            child: _financialStat(
                              context,
                              'Equity',
                              '${s.equityOffered.toStringAsFixed(s.equityOffered.truncateToDouble() == s.equityOffered ? 0 : 1)}%',
                              Icons.pie_chart_rounded,
                              AppColors.primary,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 48,
                            color: AppColors.border.withOpacity(0.5),
                          ),
                          Expanded(
                            child: _financialStat(
                              context,
                              'Valuation',
                              Formatters.compactCurrency(s.valuation),
                              Icons.show_chart_rounded,
                              AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      AppSizes.vGapXl,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Funding Raised',
                                style: context.text.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${(s.fundingProgress * 100).toStringAsFixed(0)}%',
                                  style: context.text.labelMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          AppSizes.vGapMd,
                          Stack(
                            children: [
                              Container(
                                height: 10,
                                decoration: BoxDecoration(
                                  color: AppColors.border.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              LayoutBuilder(
                                builder: (ctx, constraints) {
                                  return Container(
                                    height: 10,
                                    width:
                                        constraints.maxWidth *
                                        (s.fundingProgress.clamp(0.02, 1)),
                                    decoration: BoxDecoration(
                                      gradient: AppColors.primaryGradient,
                                      borderRadius: BorderRadius.circular(999),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.primary.withOpacity(
                                            0.4,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          AppSizes.vGapMd,
                          Row(
                            children: [
                              Text(
                                Formatters.compactCurrency(s.fundingRaised),
                                style: context.text.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.darkText,
                                ),
                              ),
                              Text(
                                ' raised',
                                style: context.text.bodySmall?.copyWith(
                                  color: AppColors.subtleText,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.favorite_rounded,
                                size: 14,
                                color: AppColors.danger.withOpacity(0.8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${s.investorInterests} interested',
                                style: context.text.labelSmall?.copyWith(
                                  color: AppColors.subtleText,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                AppSizes.vGapLg,

                // 4. Founder Card
                AppSectionHeader(title: 'Team'),
                AppSizes.vGapSm,
                AppCard(
                  onTap: () =>
                      context.push('${Routes.publicFounder}/${s.founderId}'),
                  padding: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.md),
                    child: Row(
                      children: [
                        AppAvatar(
                          name: s.founderName,
                          imageUrl: s.founderAvatar,
                          size: 50,
                        ),
                        AppSizes.hGapMd,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.founderName,
                                style: context.text.titleMedium,
                              ),
                              Text(
                                'Founder',
                                style: context.text.labelSmall?.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (s.problem.isNotEmpty) ...[
                  AppSizes.vGapLg,
                  const AppSectionHeader(title: 'The Problem'),
                  AppSizes.vGapSm,
                  _readingBlock(context, s.problem, AppColors.primary),
                ],

                if (s.solution.isNotEmpty) ...[
                  AppSizes.vGapLg,
                  const AppSectionHeader(title: 'The Solution'),
                  AppSizes.vGapSm,
                  _readingBlock(context, s.solution, AppColors.primary),
                ],

                if (s.businessModel.isNotEmpty ||
                    s.revenueModel.isNotEmpty ||
                    s.marketSize.isNotEmpty) ...[
                  AppSizes.vGapLg,
                  const AppSectionHeader(title: 'Business Models'),
                  AppSizes.vGapSm,
                  AppCard(
                    padding: const EdgeInsets.all(AppSizes.lg),
                    child: Column(
                      children: [
                        if (s.businessModel.isNotEmpty)
                          _detail(context, 'Business', s.businessModel),
                        if (s.businessModel.isNotEmpty &&
                            (s.revenueModel.isNotEmpty ||
                                s.marketSize.isNotEmpty))
                          const Divider(height: AppSizes.lg),

                        if (s.revenueModel.isNotEmpty)
                          _detail(context, 'Revenue', s.revenueModel),
                        if (s.revenueModel.isNotEmpty &&
                            s.marketSize.isNotEmpty)
                          const Divider(height: AppSizes.lg),

                        if (s.marketSize.isNotEmpty)
                          _detail(context, 'Market Size', s.marketSize),
                      ],
                    ),
                  ),
                ],

                if ((s.pitchDeckUrl != null && s.pitchDeckUrl!.isNotEmpty) ||
                    (s.businessPlanUrl != null &&
                        s.businessPlanUrl!.isNotEmpty)) ...[
                  AppSizes.vGapLg,
                  const AppSectionHeader(title: 'Documents'),
                  AppSizes.vGapSm,
                  if (s.pitchDeckUrl != null && s.pitchDeckUrl!.isNotEmpty)
                    _doc(
                      context,
                      'Pitch Deck',
                      Icons.slideshow_rounded,
                      s.pitchDeckUrl!,
                    ),
                  if (s.businessPlanUrl != null &&
                      s.businessPlanUrl!.isNotEmpty)
                    _doc(
                      context,
                      'Business Plan',
                      Icons.description_rounded,
                      s.businessPlanUrl!,
                    ),
                ],

                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _financialStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      AppSizes.vGapMd,
      Text(
        value,
        style: context.text.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.darkText,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: context.text.labelSmall?.copyWith(color: AppColors.subtleText),
        textAlign: TextAlign.center,
      ),
    ],
  );

  Widget _pill(BuildContext context, String text, {IconData? icon}) =>
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: AppColors.mutedText),
              const SizedBox(width: 4),
            ],
            Text(
              text,
              style: const TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );

  Widget _readingBlock(
    BuildContext context,
    String text,
    Color indicatorColor,
  ) => AppCard(
    padding: EdgeInsets.zero,
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: indicatorColor,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(AppSizes.radiusLg),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Text(
                text,
                style: context.text.bodyMedium?.copyWith(
                  height: 1.5,
                  color: AppColors.darkText.withValues(alpha: 0.9),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _detail(BuildContext context, String label, String value) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(flex: 2, child: Text(label, style: context.text.labelMedium)),
      Expanded(
        flex: 3,
        child: Text(
          value.isEmpty ? '—' : value,
          style: context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          textAlign: TextAlign.right,
        ),
      ),
    ],
  );

  Widget _doc(
    BuildContext context,
    String name,
    IconData icon,
    String url,
  ) => AppCard(
    margin: const EdgeInsets.only(bottom: AppSizes.sm),
    onTap: () async {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        try {
          final launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (!launched && context.mounted) {
            // Fallback to in-app viewer
            context.push(
              '${Routes.documentViewer}?url=${Uri.encodeComponent(url)}&name=${Uri.encodeComponent(name)}&type=PDF',
            );
          }
        } catch (_) {
          if (context.mounted) {
            context.push(
              '${Routes.documentViewer}?url=${Uri.encodeComponent(url)}&name=${Uri.encodeComponent(name)}&type=PDF',
            );
          }
        }
      } else {
        context.showSnack('Invalid document URL', isError: true);
      }
    },
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        AppSizes.hGapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: context.text.titleSmall),
              Text('PDF Document', style: context.text.labelSmall),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(
            Icons.open_in_new_rounded,
            size: 16,
            color: AppColors.mutedText,
          ),
        ),
      ],
    ),
  );
}
