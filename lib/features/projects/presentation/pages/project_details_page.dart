import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/config/app_config.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/bookmark_manager.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/paginated.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading_shimmer.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_secondary_button.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/custom_cached_image.dart';
import '../../../../core/widgets/icon_widget.dart';
import '../../../../core/widgets/share_sheet.dart';
import '../../../client_dashboard/domain/repositories/client_proposal_repository.dart';
import '../../../client_dashboard/presentation/widgets/client_proposal_action_bar.dart';
import '../../../messages/domain/repositories/message_repository.dart';
import '../../../proposals/domain/entities/proposal.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';

String _experienceLevelLabel(String? raw) {
  final value = (raw ?? 'intermediate').trim().toLowerCase();
  if (value == 'beginner' || value == 'entry' || value == 'junior') {
    return 'Beginner';
  }
  if (value == 'expert' || value == 'senior' || value == 'advanced') {
    return 'Expert';
  }
  return 'Intermediate';
}

String _resolveAttachmentUrl(String rawUrl) {
  String url = rawUrl.trim();
  if (url.isEmpty) return '';
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }
  final base = AppConfig.baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
  return '$base${url.startsWith('/') ? '' : '/'}$url';
}

String _attachmentName(String url) {
  final clean = url.split('?').first.split('#').first;
  final name = clean.split('/').last;
  return name.isNotEmpty ? name : 'Attachment';
}

String _attachmentType(String url) {
  final ext = url.split('?').first.split('#').first.split('.').last.toLowerCase();
  if (['jpg', 'jpeg', 'png', 'webp', 'gif', 'svg'].contains(ext)) return 'Image';
  if (ext == 'pdf') return 'PDF';
  if (['doc', 'docx'].contains(ext)) return 'Word';
  if (['xls', 'xlsx', 'csv'].contains(ext)) return 'Excel';
  if (['ppt', 'pptx'].contains(ext)) return 'PowerPoint';
  return 'Document';
}

IconData _attachmentIcon(String url) {
  final type = _attachmentType(url);
  switch (type) {
    case 'Image':
      return Icons.image_outlined;
    case 'PDF':
      return Icons.picture_as_pdf_outlined;
    case 'Word':
      return Icons.description_outlined;
    case 'Excel':
      return Icons.table_chart_outlined;
    case 'PowerPoint':
      return Icons.slideshow_outlined;
    default:
      return Icons.attach_file_rounded;
  }
}

Future<void> _openAttachment(BuildContext context, String rawUrl) async {
  final url = _resolveAttachmentUrl(rawUrl);
  if (url.isEmpty) {
    context.showSnack('Attachment URL is empty', isError: true);
    return;
  }
  final name = _attachmentName(rawUrl);
  final type = _attachmentType(rawUrl);

  if (type == 'Image') {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: CustomCachedImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return;
  }

  final uri = Uri.tryParse(url);
  if (uri == null) {
    context.showSnack('Invalid attachment URL', isError: true);
    return;
  }

  try {
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
    );
    if (!launched && context.mounted) {
      final fallback = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!fallback && context.mounted) {
        context.showSnack('Could not open attachment', isError: true);
      }
    }
  } catch (e) {
    if (!context.mounted) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        context.showSnack('Could not open attachment: $e', isError: true);
      }
    }
  }
}

class ProjectDetailsPage extends StatefulWidget {
  const ProjectDetailsPage({super.key, required this.id});
  final String id;

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  late Future<ResultLike> _future;
  List<Proposal> _proposals = const [];
  bool _loadingProposals = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = sl<ProjectRepository>().getProject(widget.id).then((res) {
      final project = res.valueOrNull;
      if (project?.isOwner == true) {
        _loadProposals();
      }
      return ResultLike(project: project, error: res.failureOrNull?.message);
    });
    setState(() {});
  }

  Future<void> _loadProposals() async {
    setState(() => _loadingProposals = true);
    final res = await sl<ClientProposalRepository>().getProjectProposals(
      widget.id,
      const QueryParams(page: 1, pageSize: 50),
    );
    if (!mounted) return;
    setState(() {
      _loadingProposals = false;
      _proposals = res.valueOrNull?.items ?? const [];
    });
  }

  Future<void> _deleteProject() async {
    final ok = await AppConfirmDialog.show(
      context,
      title: 'Delete project?',
      message:
          'This will permanently remove the project from your listings. This cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || !mounted) return;
    final res = await sl<ProjectRepository>().deleteProject(widget.id);
    if (!mounted) return;
    res.fold((f) => context.showSnack(f.message, isError: true), (_) {
      context.showSnack('Project deleted');
      Navigator.of(context).maybePop(true);
    });
  }

  Future<void> _toggleSave(bool currentlySaved) async {
    final res = await sl<ProjectRepository>().toggleSave(widget.id);
    if (!mounted) return;
    res.fold(
      (failure) => context.showSnack(
        failure.message.isNotEmpty
            ? failure.message
            : 'Failed to update saved status',
        isError: true,
      ),
      (_) {
        // Sync local state
        BookmarkManager.instance.syncItem(
          BookmarkManager.categoryProjects,
          widget.id,
          !currentlySaved,
        );
        context.showSnack(
          currentlySaved ? 'Project removed from saved' : 'Project saved',
        );
      },
    );
  }

  Future<void> _updateStatus(Project project) async {
    const options = [
      _ProjectStatusOption(value: 'draft', label: 'Draft'),
      _ProjectStatusOption(value: 'open', label: 'Open'),
      _ProjectStatusOption(value: 'in_progress', label: 'In Progress'),
      _ProjectStatusOption(value: 'completed', label: 'Completed'),
      _ProjectStatusOption(value: 'cancelled', label: 'Cancelled'),
    ];
    final current = options.firstWhere(
      (option) => EntityStatus.fromString(option.value) == project.status,
      orElse: () => options.first,
    );
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) =>
          _ProjectStatusSheet(options: options, initialValue: current),
    );
    if (selected == null || !mounted) return;
    final res = await sl<ProjectRepository>().updateProjectStatus(
      widget.id,
      selected,
    );
    if (!mounted) return;
    res.fold((f) => context.showSnack(f.message, isError: true), (_) {
      final label = options
          .firstWhere(
            (option) => option.value == selected,
            orElse: () => _ProjectStatusOption(
              value: selected,
              label: selected.replaceAll('_', ' '),
            ),
          )
          .label;
      context.showSnack('Status updated to $label');
      _reload();
    });
  }

  Future<void> _shareProject(Project project) async {
    final link = 'https://goexperts.in/projects/${project.id}';
    await ShareSheet.show(
      context,
      title: project.title,
      subtitle: 'Share with freelancers via WhatsApp, email, SMS, and more',
      link: link,
      onShared: (platform) {
        sl<ProjectRepository>().trackProjectShare(project.id, platform);
      },
    );
  }

  Future<void> _messageAboutProject(Project project) async {
    final recipientId = project.clientId;
    if (recipientId == null || recipientId.isEmpty) {
      context.showSnack('Client unavailable for messaging', isError: true);
      return;
    }
    final res = await sl<MessageRepository>().startChat(
      recipientId: recipientId,
      projectId: project.id,
    );
    if (!mounted) return;
    res.fold((f) => context.showSnack(f.message, isError: true), (msg) {
      final convId = msg.conversationId;
      if (convId.isEmpty) {
        context.push(Routes.messages);
        return;
      }
      final nameParam = Uri.encodeComponent(
        project.clientName.isNotEmpty ? project.clientName : 'Client',
      );
      final avatarParam = Uri.encodeComponent(project.clientAvatar ?? '');
      context.push(
        '${Routes.chat}/$convId?name=$nameParam&avatarUrl=$avatarParam',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BookmarkManager.instance,
      builder: (context, _) {
        final isSaved = BookmarkManager.instance.isBookmarked(
          BookmarkManager.categoryProjects,
          widget.id,
        );
        return FutureBuilder<ResultLike>(
          future: _future,
          builder: (context, snapshot) {
            final project = snapshot.data?.project;
            final isOwner = project?.isOwner == true;

            return Scaffold(
              appBar: AppBar(
                leading: IconTapWidget(
                  onTap: () => Navigator.of(context).maybePop(true),
                ),
                title: const Text('Project Details'),
                actions: [
                  if (isOwner)
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.danger,
                      ),
                      onPressed: _deleteProject,
                    ),
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: project == null
                        ? null
                        : () => _shareProject(project),
                  ),
                  if (!isOwner)
                    IconButton(
                      icon: Icon(
                        isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        color: isSaved ? AppColors.primary : null,
                      ),
                      onPressed: () => _toggleSave(isSaved),
                    ),
                ],
              ),
              body: snapshot.connectionState == ConnectionState.waiting
                  ? const AppLoadingShimmer(itemCount: 4, height: 120)
                  : project == null
                  ? AppErrorState(
                      message: snapshot.data?.error,
                      onRetry: _reload,
                    )
                  : _content(context, project),
              bottomNavigationBar: project == null
                  ? null
                  : SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.lg),
                        child: isOwner
                            ? Row(
                                children: [
                                  Expanded(
                                    child: AppSecondaryButton(
                                      label: 'Edit',
                                      icon: Icons.edit_outlined,
                                      onPressed: () async {
                                        await context.push(
                                          '${Routes.clientCreateProject}?projectId=${Uri.encodeComponent(widget.id)}',
                                        );
                                        if (mounted) _reload();
                                      },
                                    ),
                                  ),
                                  AppSizes.hGapMd,
                                  Expanded(
                                    child: AppPrimaryButton(
                                      label: 'Update Status',
                                      icon: Icons.flag_outlined,
                                      onPressed: () => _updateStatus(project),
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
                                      onPressed: () =>
                                          _messageAboutProject(project),
                                    ),
                                  ),
                                  AppSizes.hGapMd,
                                  Expanded(
                                    child: AppPrimaryButton(
                                      label: project.isApplied
                                          ? 'Applied'
                                          : 'Apply Now',
                                      icon: project.isApplied
                                          ? Icons.check_rounded
                                          : Icons.send_rounded,
                                      gradient: !project.isApplied,
                                      onPressed: project.isApplied
                                          ? null
                                          : () async {
                                              final applied = await context.push<bool>(
                                                '${Routes.apply}?type=Project'
                                                '&projectId=${Uri.encodeComponent(project.id)}'
                                                '&name=${Uri.encodeComponent(project.title)}',
                                              );
                                              if (applied == true && mounted) {
                                                _reload();
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

  Widget _content(BuildContext context, Project p) {
    final String budget;
    if (p.isHourly) {
      if (p.budgetMin > 0 && p.budgetMax > 0 && p.budgetMin != p.budgetMax) {
        budget =
            '${Formatters.currency(p.budgetMin)} - ${Formatters.currency(p.budgetMax)} / hr';
      } else {
        final val = p.budgetMax > 0 ? p.budgetMax : p.budgetMin;
        budget = '${Formatters.currency(val)} / hr';
      }
    } else {
      if (p.budgetMin > 0 && p.budgetMax > 0 && p.budgetMin != p.budgetMax) {
        budget =
            '${Formatters.currency(p.budgetMin)} - ${Formatters.currency(p.budgetMax)}';
      } else {
        final val = p.budgetMax > 0 ? p.budgetMax : p.budgetMin;
        budget = Formatters.currency(val);
      }
    }
    return ListView(
      padding: const EdgeInsets.all(AppSizes.screenPadding),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          child: Image.asset(
            'assets/images/project_banner.png',
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
        AppSizes.vGapLg,
        Text(p.title, style: context.text.headlineSmall),
        AppSizes.vGapSm,
        Row(
          children: [
            AppStatusChip.status(p.status, dense: true),
            AppSizes.hGapSm,
            Text(
              'Posted ${Formatters.relative(p.postedAt)}',
              style: context.text.labelSmall,
            ),
          ],
        ),
        AppSizes.vGapLg,
        AppCard(
          onTap: (p.clientId != null && p.clientId!.isNotEmpty)
              ? () => context.push('${Routes.publicCompany}/${p.clientId}')
              : null,
          child: Row(
            children: [
              AppAvatar(name: p.clientName, imageUrl: p.clientAvatar, size: 44),
              AppSizes.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            p.clientName,
                            style: context.text.titleSmall?.copyWith(
                              decoration: (p.clientId != null && p.clientId!.isNotEmpty)
                                  ? TextDecoration.underline
                                  : null,
                              decorationColor: context.text.titleSmall?.color
                                  ?.withValues(alpha: 0.4),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (p.clientVerified)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: AppColors.info,
                            ),
                          ),
                      ],
                    ),
                    Text(
                      p.category,
                      style: context.text.labelSmall?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              if (p.clientId != null && p.clientId!.isNotEmpty)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppColors.mutedText,
                ),
            ],
          ),
        ),
        AppSizes.vGapLg,
        Row(
          children: [
            Expanded(
              child: _stat(context, Icons.payments_outlined, 'Budget', budget),
            ),
            Expanded(
              child: _stat(
                context,
                Icons.schedule_rounded,
                'Timeline',
                p.timeline.isEmpty ? '—' : p.timeline,
              ),
            ),
          ],
        ),
        AppSizes.vGapSm,
        Row(
          children: [
            Expanded(
              child: _stat(
                context,
                Icons.work_history_outlined,
                'Level',
                _experienceLevelLabel(p.experienceLevel),
              ),
            ),
            Expanded(
              child: _stat(
                context,
                Icons.location_on_outlined,
                'Work Mode',
                p.workMode,
              ),
            ),
          ],
        ),
        AppSizes.vGapLg,
        const AppSectionHeader(title: 'Category'),
        AppSizes.vGapSm,
        Align(
          alignment: Alignment.centerLeft,
          child: _chip(context, p.category),
        ),
        AppSizes.vGapLg,
        const AppSectionHeader(title: 'Project Overview'),
        AppSizes.vGapSm,
        Text(
          p.description.isEmpty ? 'No description provided.' : p.description,
          style: context.text.bodyMedium,
        ),
        AppSizes.vGapLg,
        const AppSectionHeader(title: 'Skills Required'),
        AppSizes.vGapSm,
        if (p.skills.isEmpty)
          Text('No skills listed', style: context.text.bodySmall)
        else
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.sm,
            children: [for (final s in p.skills) _chip(context, s)],
          ),
        AppSizes.vGapLg,
        const AppSectionHeader(title: 'Attachments'),
        AppSizes.vGapSm,
        if (p.attachments.isEmpty)
          AppCard(
            child: Text(
              'No attachments for this project.',
              style: context.text.bodyMedium,
            ),
          )
        else
          for (final url in p.attachments)
            AppCard(
              margin: const EdgeInsets.only(bottom: AppSizes.sm),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                onTap: () => _openAttachment(context, url),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSizes.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                      ),
                      child: Icon(
                        _attachmentIcon(url),
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    AppSizes.hGapMd,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _attachmentName(url),
                            style: context.text.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _attachmentType(url),
                            style: context.text.labelSmall?.copyWith(
                              color: AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _openAttachment(context, url),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text('View'),
                    ),
                  ],
                ),
              ),
            ),
        AppSizes.vGapLg,
        AppCard(
          child: Row(
            children: [
              const Icon(Icons.groups_outlined, color: AppColors.primary),
              AppSizes.hGapMd,
              Text(
                '${p.proposalsCount} freelancers have applied',
                style: context.text.bodyMedium,
              ),
            ],
          ),
        ),
        if (p.isOwner) ...[
          AppSizes.vGapLg,
          const AppSectionHeader(
            title: 'Proposals',
            subtitle: 'Review and update freelancer applications',
          ),
          AppSizes.vGapSm,
          if (_loadingProposals)
            const AppLoadingShimmer(itemCount: 2, height: 90)
          else if (_proposals.isEmpty)
            AppCard(
              child: Text(
                'No proposals yet for this project.',
                style: context.text.bodyMedium,
              ),
            )
          else
            for (final proposal in _proposals) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: (proposal.freelancerId != null &&
                                  proposal.freelancerId!.isNotEmpty)
                              ? () => context.push(
                                  '${Routes.publicFreelancer}/${proposal.freelancerId}')
                              : null,
                          borderRadius: BorderRadius.circular(20),
                          child: AppAvatar(
                            name: proposal.freelancerName,
                            imageUrl: proposal.freelancerAvatar,
                            size: 40,
                          ),
                        ),
                        AppSizes.hGapMd,
                        Expanded(
                          child: InkWell(
                            onTap: (proposal.freelancerId != null &&
                                    proposal.freelancerId!.isNotEmpty)
                                ? () => context.push(
                                    '${Routes.publicFreelancer}/${proposal.freelancerId}')
                                : null,
                            borderRadius: BorderRadius.circular(4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  proposal.freelancerName,
                                  style: context.text.titleSmall?.copyWith(
                                    decoration: (proposal.freelancerId != null &&
                                            proposal.freelancerId!.isNotEmpty)
                                        ? TextDecoration.underline
                                        : null,
                                    decorationColor: context.text.titleSmall?.color
                                        ?.withValues(alpha: 0.4),
                                  ),
                                ),
                                Text(
                                  Formatters.currency(proposal.bidAmount),
                                  style: context.text.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                        AppStatusChip.status(proposal.status, dense: true),
                      ],
                    ),
                    if (proposal.coverLetter.trim().isNotEmpty) ...[
                      AppSizes.vGapSm,
                      Text(
                        proposal.coverLetter,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall,
                      ),
                    ],
                    AppSizes.vGapMd,
                    ClientProposalActionBar(
                      proposal: proposal,
                      onStatusChanged: _reload,
                    ),
                  ],
                ),
              ),
              AppSizes.vGapMd,
            ],
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _stat(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) => AppCard(
    margin: const EdgeInsets.all(AppSizes.xs),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        AppSizes.vGapSm,
        Text(
          value,
          style: context.text.titleSmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Text(label, style: context.text.labelSmall),
      ],
    ),
  );

  Widget _chip(BuildContext context, String s) => Container(
    padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppSizes.radiusPill),
    ),
    child: Text(
      s,
      style: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    ),
  );
}

class ResultLike {
  ResultLike({this.project, this.error});
  final Project? project;
  final String? error;
}

class _ProjectStatusOption {
  const _ProjectStatusOption({required this.value, required this.label});

  final String value;
  final String label;
}

class _ProjectStatusSheet extends StatefulWidget {
  const _ProjectStatusSheet({
    required this.options,
    required this.initialValue,
  });

  final List<_ProjectStatusOption> options;
  final _ProjectStatusOption initialValue;

  @override
  State<_ProjectStatusSheet> createState() => _ProjectStatusSheetState();
}

class _ProjectStatusSheetState extends State<_ProjectStatusSheet> {
  late _ProjectStatusOption _selected = widget.initialValue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSizes.xl,
          right: AppSizes.xl,
          bottom: MediaQuery.viewInsetsOf(context).bottom + AppSizes.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Update project status',
                    style: context.text.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            AppSizes.vGapMd,
            AppDropdown<_ProjectStatusOption>(
              label: 'Status',
              hint: 'Select status',
              value: _selected,
              items: widget.options,
              itemLabel: (option) => option.label,
              prefixIcon: Icons.flag_outlined,
              onChanged: (option) {
                if (option == null) return;
                setState(() => _selected = option);
              },
            ),
            AppSizes.vGapXl,
            AppPrimaryButton(
              label: 'Submit',
              icon: Icons.check_rounded,
              onPressed: () => Navigator.of(context).pop(_selected.value),
            ),
          ],
        ),
      ),
    );
  }
}
