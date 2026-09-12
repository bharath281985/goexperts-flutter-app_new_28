import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/bookmark_manager.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading_shimmer.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../../../core/widgets/icon_widget.dart';
import '../../domain/entities/startup.dart';
import '../../domain/repositories/startup_repository.dart';
import '../../../../core/utils/result.dart';
import '../widgets/investment_offer_sheet.dart';
import '../widgets/startup_details_content.dart';

class StartupDetailsPage extends StatefulWidget {
  const StartupDetailsPage({super.key, required this.id});
  final String id;

  @override
  State<StartupDetailsPage> createState() => _StartupDetailsPageState();
}

class _StartupDetailsPageState extends State<StartupDetailsPage> {
  late Future<Result<Startup>> _future;
  bool? _hasInvestedOverride;
  bool? _isSavedOverride;
  bool _isLoadingAction = false;

  @override
  void initState() {
    super.initState();
    _future = sl<StartupRepository>().getStartup(widget.id);
  }

  void _refresh() {
    setState(() {
      _future = sl<StartupRepository>().getStartup(widget.id);
    });
  }

  Future<void> _shareStartup(Startup startup) async {
    final shareUrl = 'https://goexperts.in${Routes.startupDetails}/${startup.id}';
    final text = '${startup.name}\n${startup.tagline}\n\n$shareUrl';
    await Share.share(text, subject: '${startup.name} on GoExperts');
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
                appBar: AppBar(
                  leading: IconTapWidget(
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  title: const Text('Startup Details'),
                ),
                body: const AppLoadingShimmer(itemCount: 4, height: 120),
              );
            }
            final s = snapshot.data?.valueOrNull;
            if (s == null) {
              return Scaffold(
                appBar: AppBar(
                  leading: IconTapWidget(
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  title: const Text('Startup Details'),
                ),
                body: const AppErrorState(),
              );
            }

            final isSaved = _isSavedOverride ?? s.isSaved;
            final compactActions = MediaQuery.sizeOf(context).width < 360;

            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                leading: IconTapWidget(
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                title: const Text('Startup Details'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    tooltip: 'Share startup',
                    onPressed: () => _shareStartup(s),
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
              body: RefreshIndicator(
                onRefresh: () async {
                  _refresh();
                  await _future;
                },
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: StartupDetailsContent(startup: s),
                ),
              ),
              bottomNavigationBar: SafeArea(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.md,
                    AppSizes.sm,
                    AppSizes.md,
                    AppSizes.md,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.card,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
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
                                '${Routes.chat}/${s.founderId}?name=$nameEncoded&avatarUrl=$avatarEncoded&role=founder',
                              );
                            } else {
                              final nameEncoded = Uri.encodeComponent(s.name);
                              final avatarEncoded = Uri.encodeComponent(
                                s.logoUrl ?? '',
                              );
                              context.push(
                                '${Routes.chat}/su_${widget.id}?name=$nameEncoded&avatarUrl=$avatarEncoded&role=founder',
                              );
                            }
                          },
                        ),
                      ),
                      AppSizes.hGapSm,
                      Expanded(
                        child: AppPrimaryButton(
                          label: (_hasInvestedOverride ?? s.hasInvested)
                              ? 'Withdraw Interest'
                              : compactActions
                              ? 'Express Interest'
                              : 'Invest / Express Interest',
                          icon: (_hasInvestedOverride ?? s.hasInvested)
                              ? Icons.cancel_outlined
                              : Icons.trending_up_rounded,
                          isLoading: _isLoadingAction,
                          backgroundColor:
                              (_hasInvestedOverride ?? s.hasInvested)
                              ? AppColors.danger
                              : AppColors.primary.withValues(alpha: 0.8),
                          onPressed: () async {
                            if (_hasInvestedOverride ?? s.hasInvested) {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Withdraw Interest',
                                        style: ctx.text.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close_rounded),
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  ),
                                  content: const Text(
                                    'Are you sure you want to withdraw your interest in this startup?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text(
                                        'Cancel',
                                        style:
                                            TextStyle(color: AppColors.danger),
                                      ),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.danger,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppSizes.radiusSm,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 10,
                                        ),
                                      ),
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text(
                                        'Withdraw',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
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
                                    _hasInvestedOverride = false;
                                    _refresh();
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
                                _hasInvestedOverride = true;
                                _refresh();
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
}

