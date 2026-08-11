import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/detail_actions.dart';
import '../../../../core/widgets/detail_view.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../catalog/presentation/widgets/detail_widgets.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';

class ContractDetailsPage extends StatelessWidget {
  const ContractDetailsPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final role = context.select((AuthBloc b) => b.state.user?.role);
    return DetailView<Contract>(
      title: 'Contract',
      fetcher: () => sl<ProjectRepository>().getContract(id),
      actions: [
        if (role == UserRole.client)
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final contract = await sl<ProjectRepository>().getContract(id);
              if (!context.mounted) return;
              contract.fold(
                (f) => context.showSnack(f.message, isError: true),
                (c) => context.push(Routes.contractForm, extra: c),
              );
            },
          ),
        ...detailActions(
          context,
          shareTitle: 'this contract',
          shareLink: '${Routes.contractDetails}/$id',
          reportType: 'contract',
        ),
      ],
      bottomBar: (context, c) => Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: role == UserRole.client
            ? Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'Cancel',
                      onPressed: () => _confirmAndExecute(
                        context,
                        title: 'Cancel Contract?',
                        message: 'Are you sure you want to cancel this contract?',
                        confirmLabel: 'Cancel Contract',
                        isDestructive: true,
                        endpoint: ApiEndpoints.clientContractCancel(c.id),
                        successMsg: 'Contract cancelled',
                      ),
                    ),
                  ),
                  AppSizes.hGapMd,
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'Activate',
                      onPressed: () => _confirmAndExecute(
                        context,
                        title: 'Activate Contract?',
                        message: 'This will mark the contract active and notify the freelancer.',
                        confirmLabel: 'Activate',
                        endpoint: ApiEndpoints.clientContractActivate(c.id),
                        successMsg: 'Contract activated',
                      ),
                    ),
                  ),
                  AppSizes.hGapMd,
                  Expanded(
                    child: AppPrimaryButton(
                      label: 'Complete',
                      onPressed: () => _confirmAndExecute(
                        context,
                        title: 'Complete Contract?',
                        message: 'Mark this contract as completed and release remaining milestones?',
                        confirmLabel: 'Complete',
                        endpoint: ApiEndpoints.clientContractComplete(c.id),
                        successMsg: 'Contract completed',
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: AppSecondaryButton(
                      label: 'Message',
                      icon: Icons.chat_bubble_outline_rounded,
                      onPressed: () => context.push(Routes.messages),
                    ),
                  ),
                  AppSizes.hGapMd,
                  Expanded(
                    flex: 2,
                    child: AppPrimaryButton(
                      label: 'View Milestones',
                      icon: Icons.flag_outlined,
                      onPressed: () =>
                          context.showSnack('Showing contract milestones'),
                    ),
                  ),
                ],
              ),
      ),
      builder: (context, c) => ListView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        children: [
          DetailHeroBanner(
            icon: Icons.assignment_turned_in_outlined,
            title: c.projectTitle,
            subtitle: 'with ${c.counterpartyName}',
            chips: [
              DetailStatChip(
                icon: Icons.payments_outlined,
                label: Formatters.compactCurrency(c.amount),
              ),
            ],
          ),
          AppSizes.vGapLg,
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Progress', style: context.text.titleSmall),
                    ),
                    AppStatusChip.status(c.status, dense: true),
                  ],
                ),
                AppSizes.vGapSm,
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: c.progress,
                    minHeight: 8,
                    backgroundColor: context.theme.dividerColor,
                    valueColor: const AlwaysStoppedAnimation(AppColors.success),
                  ),
                ),
                AppSizes.vGapSm,
                Text(
                  '${(c.progress * 100).toStringAsFixed(0)}% complete · Started ${Formatters.date(c.startDate)}',
                  style: context.text.labelSmall,
                ),
              ],
            ),
          ),
          AppSizes.vGapLg,
          DetailSection(
            title: 'Milestones',
            child: DetailTimeline(
              events: [
                for (final m in c.milestones)
                  TimelineEvent(
                    m.title,
                    subtitle:
                        '${Formatters.compactCurrency(m.amount)} · ${m.status.label} · due ${Formatters.date(m.dueDate)}',
                    done: m.status == EntityStatus.completed,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Future<void> _confirmAndExecute(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required String endpoint,
    required String successMsg,
    bool isDestructive = false,
  }) async {
    final ok = await AppConfirmDialog.show(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      isDestructive: isDestructive,
    );
    if (!ok || !context.mounted) return;
    final res = await sl<ApiClientHelper>().patchAction(endpoint);
    if (!context.mounted) return;
    res.fold(
      (f) => context.showSnack(f.message, isError: true),
      (_) => context.showSnack(successMsg),
    );
  }

  Future<void> _contractAction(
    BuildContext context,
    String endpoint,
    String msg,
  ) async {
    final res = await sl<ApiClientHelper>().patchAction(endpoint);
    if (!context.mounted) return;
    res.fold(
      (f) => context.showSnack(f.message),
      (_) => context.showSnack(msg),
    );
  }
}
