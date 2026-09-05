import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/bloc/detail_cubit.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/detail_actions.dart';
import '../../../../core/widgets/detail_view.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../catalog/presentation/widgets/detail_widgets.dart';
import '../../../messages/domain/repositories/message_repository.dart';
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
        ...detailActions(
          context,
          shareTitle: 'this contract',
          shareLink: '${Routes.contractDetails}/$id',
          reportType: 'contract',
        ),
      ],
      bottomBar: (context, c) {
        if (role == UserRole.client) {
          if (c.status == EntityStatus.completed) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Row(
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
                      endpoint: '/${ApiEndpoints.rolePath(role)}/contracts/${c.id}/cancel',
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
                      message:
                          'This will mark the contract active and notify the freelancer.',
                      confirmLabel: 'Activate',
                      endpoint: '/${ApiEndpoints.rolePath(role)}/contracts/${c.id}/activate',
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
                      message:
                          'Mark this contract as completed and release remaining milestones?',
                      confirmLabel: 'Complete',
                      endpoint: '/${ApiEndpoints.rolePath(role)}/contracts/${c.id}/complete',
                      successMsg: 'Contract completed',
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        if (c.status == EntityStatus.pending && role != UserRole.client) {
          return Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: 'Reject Offer',
                    icon: Icons.close_rounded,
                    onPressed: () => _confirmAndExecutePost(
                      context,
                      title: 'Reject Contract Offer?',
                      message: 'Are you sure you want to reject this contract offer?',
                      confirmLabel: 'Reject',
                      isDestructive: true,
                      action: () => sl<ProjectRepository>().rejectContract(c.id),
                      successMsg: 'Contract offer rejected',
                    ),
                  ),
                ),
                AppSizes.hGapMd,
                Expanded(
                  child: AppPrimaryButton(
                    label: 'Accept Offer',
                    icon: Icons.check_rounded,
                    onPressed: () => _confirmAndExecutePost(
                      context,
                      title: 'Accept Contract Offer?',
                      message: 'Accept this contract offer to begin work and milestone tracking.',
                      confirmLabel: 'Accept Offer',
                      action: () => sl<ProjectRepository>().acceptContract(c.id),
                      successMsg: 'Contract accepted successfully',
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  label: 'Message',
                  icon: Icons.chat_bubble_outline_rounded,
                  onPressed: () => _openChat(context, c, role),
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
        );
      },
      builder: (context, c) => ListView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        children: [
          // 1. Hero Summary Banner
          DetailHeroBanner(
            icon: Icons.assignment_turned_in_outlined,
            title: c.contractNumber?.isNotEmpty == true
                ? c.projectTitle
                : 'Contract Agreement',
            subtitle: c.contractNumber?.isNotEmpty == true
                ? c.contractNumber!
                : (c.projectTitle.isNotEmpty
                      ? c.projectTitle
                      : 'Contract #${c.id.substring(0, c.id.length > 8 ? 8 : c.id.length)}'),
            chips: [
              DetailStatChip(
                icon: Icons.payments_outlined,
                label: Formatters.compactCurrency(c.amount),
              ),
              DetailStatChip(
                icon: Icons.schedule_rounded,
                label: Formatters.date(c.startDate),
              ),
            ],
          ),
          AppSizes.vGapLg,

          // 2. Status & Progress Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Contract Status', style: context.text.titleSmall),
                    AppStatusChip.status(c.status, dense: true),
                  ],
                ),
                if (c.progress > 0) ...[
                  AppSizes.vGapSm,
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: c.progress,
                      minHeight: 6,
                      backgroundColor: context.theme.dividerColor,
                      valueColor: const AlwaysStoppedAnimation(
                        AppColors.primary,
                      ),
                    ),
                  ),
                  AppSizes.vGapSm,
                  Text(
                    '${(c.progress * 100).toInt()}% completed',
                    style: context.text.labelSmall,
                  ),
                ],
              ],
            ),
          ),
          AppSizes.vGapLg,

          // 3. Project Details Card
          // const AppSectionHeader(title: 'Project Details'),
          // AppSizes.vGapSm,
          // AppCard(
          //   child: Row(
          //     children: [
          //       Container(
          //         padding: const EdgeInsets.all(AppSizes.sm),
          //         decoration: BoxDecoration(
          //           color: AppColors.primary.withAlpha(20),
          //           borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          //         ),
          //         child: const Icon(
          //           Icons.work_outline_rounded,
          //           color: AppColors.primary,
          //           size: 22,
          //         ),
          //       ),
          //       AppSizes.hGapMd,
          //       Expanded(
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.start,
          //           children: [
          //             Text(
          //               c.projectTitle.isNotEmpty
          //                   ? c.projectTitle
          //                   : 'Linked Project',
          //               style: context.text.titleSmall?.copyWith(
          //                 fontWeight: FontWeight.w600,
          //               ),
          //             ),
          //             if (c.projectId != null && c.projectId!.isNotEmpty)
          //               Text(
          //                 'ID: ${c.projectId}',
          //                 style: context.text.labelSmall?.copyWith(
          //                   color: AppColors.mutedText,
          //                 ),
          //               ),
          //           ],
          //         ),
          //       ),
          //       if (c.projectId != null && c.projectId!.isNotEmpty)
          //         IconButton(
          //           icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          //           onPressed: () =>
          //               context.push('${Routes.projectDetails}/${c.projectId}'),
          //         ),
          //     ],
          //   ),
          // ),
          // AppSizes.vGapLg,

          // 4. Freelancer Details Card
          const AppSectionHeader(title: 'Freelancer Details'),
          AppSizes.vGapSm,
          AppCard(
            onTap: (c.freelancerId != null && c.freelancerId!.isNotEmpty)
                ? () => context.push('${Routes.publicFreelancer}/${c.freelancerId}')
                : null,
            child: Row(
              children: [
                AppAvatar(
                  name: c.freelancerName,
                  imageUrl: c.freelancerAvatar,
                  size: 48,
                ),
                AppSizes.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.freelancerName,
                        style: context.text.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: (c.freelancerId != null &&
                                  c.freelancerId!.isNotEmpty)
                              ? TextDecoration.underline
                              : null,
                          decorationColor: context.text.titleSmall?.color
                              ?.withValues(alpha: 0.4),
                        ),
                      ),
                      if (c.freelancerTitle != null &&
                          c.freelancerTitle!.isNotEmpty)
                        Text(
                          c.freelancerTitle!,
                          style: context.text.bodySmall?.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                      if (c.freelancerRating != null) ...[
                        AppSizes.vGapXs,
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              c.freelancerRating!.toStringAsFixed(1),
                              style: context.text.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (role == UserRole.client &&
                    c.freelancerId != null &&
                    c.freelancerId!.isNotEmpty)
                  IconButton(
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    onPressed: () => _openChat(context, c, role),
                  )
                else if (c.freelancerId != null && c.freelancerId!.isNotEmpty)
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.mutedText,
                  ),
              ],
            ),
          ),
          AppSizes.vGapLg,

          // 5. Client Details Card
          if (c.clientName != null && c.clientName!.isNotEmpty) ...[
            const AppSectionHeader(title: 'Client Details'),
            AppSizes.vGapSm,
            AppCard(
              onTap: (c.clientId != null && c.clientId!.isNotEmpty)
                  ? () => context.push('${Routes.publicCompany}/${c.clientId}')
                  : null,
              child: Row(
                children: [
                  AppAvatar(
                    name: c.clientName!,
                    imageUrl: c.clientAvatar,
                    size: 48,
                  ),
                  AppSizes.hGapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.clientName!,
                          style: context.text.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: (c.clientId != null &&
                                    c.clientId!.isNotEmpty)
                                ? TextDecoration.underline
                                : null,
                            decorationColor: context.text.titleSmall?.color
                                ?.withValues(alpha: 0.4),
                          ),
                        ),
                        Text(
                          'Project Client',
                          style: context.text.labelSmall?.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (c.clientId != null && c.clientId!.isNotEmpty)
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: AppColors.mutedText,
                    ),
                ],
              ),
            ),
            AppSizes.vGapLg,
          ],

          // 6. Proposal Details Card
          const AppSectionHeader(title: 'Proposal Details'),
          AppSizes.vGapSm,
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (c.proposalId != null && c.proposalId!.isNotEmpty) ...[
                  _Row(
                    'Proposal ID',
                    c.proposalId!,
                    valueStyle: context.text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Divider(height: AppSizes.lg),
                ],
                _Row(
                  'Bid Amount',
                  Formatters.currency(c.proposalBidAmount ?? c.amount),
                ),
                const Divider(height: AppSizes.lg),
                _Row(
                  'Delivery Timeline',
                  c.proposalDeliveryTime != null
                      ? '${c.proposalDeliveryTime} days'
                      : '—',
                ),
                const Divider(height: AppSizes.lg),
                _Row(
                  'Proposal Status',
                  (c.proposalStatus?.isNotEmpty == true
                          ? c.proposalStatus!
                          : 'Accepted')
                      .toUpperCase(),
                ),
                if (c.proposalId != null && c.proposalId!.isNotEmpty) ...[
                  const Divider(height: AppSizes.lg),
                  AppSecondaryButton(
                    label: 'View Proposal',
                    icon: Icons.description_outlined,
                    onPressed: () =>
                        context.push('${Routes.proposalDetails}/${c.proposalId}'),
                  ),
                ],
                if (c.proposalCoverLetter != null &&
                    c.proposalCoverLetter!.trim().isNotEmpty) ...[
                  const Divider(height: AppSizes.lg),
                  Text(
                    'Cover Letter',
                    style: context.text.labelMedium?.copyWith(
                      color: AppColors.mutedText,
                    ),
                  ),
                  AppSizes.vGapXs,
                  Text(c.proposalCoverLetter!, style: context.text.bodyMedium),
                ],
              ],
            ),
          ),
          AppSizes.vGapLg,

          // 7. Milestones
          if (c.milestones.isNotEmpty) ...[
            const AppSectionHeader(title: 'Milestones'),
            AppSizes.vGapSm,
            for (final m in c.milestones)
              AppCard(
                margin: const EdgeInsets.only(bottom: AppSizes.sm),
                child: Row(
                  children: [
                    Icon(
                      m.status == EntityStatus.completed
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: m.status == EntityStatus.completed
                          ? AppColors.success
                          : AppColors.mutedText,
                      size: 20,
                    ),
                    AppSizes.hGapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.title, style: context.text.titleSmall),
                          Text(
                            'Due ${Formatters.date(m.dueDate)}',
                            style: context.text.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      Formatters.currency(m.amount),
                      style: context.text.titleSmall,
                    ),
                  ],
                ),
              ),
            AppSizes.vGapLg,
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Future<void> _openChat(
    BuildContext context,
    Contract c,
    UserRole? role,
  ) async {
    final isClient = role == UserRole.client;
    final targetId = isClient ? c.freelancerId : c.clientId;
    final targetName = isClient ? c.freelancerName : (c.clientName ?? 'Client');
    final targetAvatar = isClient ? c.freelancerAvatar : c.clientAvatar;
    if (targetId == null || targetId.isEmpty) {
      context.showSnack('User unavailable for messaging', isError: true);
      return;
    }
    final res = await sl<MessageRepository>().startChat(
      recipientId: targetId,
      projectId: c.projectId,
    );
    if (!context.mounted) return;
    res.fold(
      (f) => context.showSnack(f.message, isError: true),
      (msg) {
        final convId = msg.conversationId;
        if (convId.isEmpty) {
          context.push(Routes.messages);
          return;
        }
        final nameParam = Uri.encodeComponent(
          targetName.isNotEmpty ? targetName : 'User',
        );
        final avatarParam = Uri.encodeComponent(targetAvatar ?? '');
        context.push(
          '${Routes.chat}/$convId?name=$nameParam&avatarUrl=$avatarParam',
        );
      },
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
    res.fold((f) => context.showSnack(f.message, isError: true), (_) {
      context.showSnack(successMsg);
      context.read<DetailCubit<Contract>>().load();
    });
  }

  Future<void> _confirmAndExecutePost(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Future<Result<bool>> Function() action,
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
    final res = await action();
    if (!context.mounted) return;
    res.fold(
      (f) => context.showSnack(f.message, isError: true),
      (_) {
        context.showSnack(successMsg);
        context.read<DetailCubit<Contract>>().load();
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.valueStyle});
  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: context.text.bodyMedium?.copyWith(color: AppColors.mutedText),
        ),
        Text(
          value,
          style:
              valueStyle ??
              context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
