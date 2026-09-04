import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:video_player/video_player.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../app/config/app_config.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/paginated.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_file_upload.dart';
import '../../../../core/widgets/app_location_field.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/catalog_view.dart';
import '../../../../core/widgets/category_skills_picker.dart';
import '../../../../core/widgets/custom_cached_image.dart';
import '../../../../core/widgets/icon_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/widgets/signup_multi_select_sheet.dart';
import '../../../master_data/domain/entities/skill_category.dart';
import '../../../master_data/domain/entities/skill_option.dart';
import '../../../master_data/domain/repositories/master_data_repository.dart';
import '../../domain/entities/freelancer_credentials.dart';
import '../../domain/entities/freelancer_task.dart';
import '../../domain/entities/portfolio_item.dart';
import '../../domain/repositories/freelancer_credentials_repository.dart';
import '../../domain/repositories/freelancer_profile_repository.dart';
import '../../domain/repositories/freelancer_task_repository.dart';
import '../../domain/repositories/portfolio_repository.dart';
import '../../../profile/domain/entities/review.dart';
import '../../../profile/domain/repositories/review_repository.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/domain/repositories/project_repository.dart';
import '../../../wallet/domain/entities/wallet.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';

class _ListScaffold extends StatelessWidget {
  const _ListScaffold({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(
      leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
      title: Text(title),
    ),
    body: child,
  );
}

class FreelancerContractsPage extends StatelessWidget {
  const FreelancerContractsPage({super.key});
  @override
  Widget build(BuildContext context) => _ListScaffold(
    title: 'Contracts',
    child: CatalogView<Contract>(
      fetcher: (q) => sl<ProjectRepository>().getContracts(q),
      searchHint: 'Search contracts…',
      emptyTitle: 'No contracts yet',
      itemBuilder: (context, c, __) => AppCard(
        onTap: () => context.push('${Routes.contractDetails}/${c.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(c.projectTitle, style: context.text.titleSmall),
                ),
                AppStatusChip.status(c.status, dense: true),
              ],
            ),
            AppSizes.vGapSm,
            Text(
              '${c.counterpartyName} · ${Formatters.compactCurrency(c.amount)}',
              style: context.text.bodySmall,
            ),
            AppSizes.vGapSm,
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: c.progress,
                minHeight: 6,
                backgroundColor: context.theme.dividerColor,
                valueColor: const AlwaysStoppedAnimation(AppColors.success),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class FreelancerReviewsPage extends StatelessWidget {
  const FreelancerReviewsPage({super.key});
  @override
  Widget build(BuildContext context) => _ListScaffold(
    title: 'Reviews',
    child: CatalogView<Review>(
      fetcher: (q) => sl<ReviewRepository>().getReviews(q),
      searchHint: 'Search reviews…',
      itemBuilder: (context, r, __) => AppCard(
        onTap: () => context.push('${Routes.reviewDetails}/${r.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(r.authorName, style: context.text.titleSmall),
                ),
                const Icon(
                  Icons.star_rounded,
                  color: AppColors.warning,
                  size: 16,
                ),
                Text(' ${r.rating}', style: context.text.labelMedium),
              ],
            ),
            AppSizes.vGapXs,
            Text(
              r.comment,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodySmall,
            ),
          ],
        ),
      ),
    ),
  );
}

class FreelancerCertificatesPage extends StatefulWidget {
  const FreelancerCertificatesPage({super.key});
  @override
  State<FreelancerCertificatesPage> createState() =>
      _FreelancerCertificatesPageState();
}

class _FreelancerCertificatesPageState
    extends State<FreelancerCertificatesPage> {
  bool _saving = false;
  String? _errorMessage;
  final _search = TextEditingController();
  final _items = <_CertificateDraft>[];

  @override
  void dispose() {
    _search.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _addCertificate() async {
    final item = await _certificateFormSheet(context);
    if (!mounted || item == null) return;
    setState(() {
      _items.add(item);
      _errorMessage = null;
    });
    await _persistCertificates('Certificate added successfully');
  }

  Future<void> _editCertificate(_CertificateDraft item) async {
    final updated = await _certificateFormSheet(context, item: item);
    if (!mounted || updated == null) return;
    final index = _items.indexOf(item);
    if (index == -1) {
      updated.dispose();
      return;
    }
    setState(() {
      _items[index] = updated;
      item.dispose();
      _errorMessage = null;
    });
    await _persistCertificates('Certificate updated successfully');
  }

  Future<void> _removeCertificate(_CertificateDraft item) async {
    setState(() {
      _items.remove(item);
      item.dispose();
      _errorMessage = null;
    });
    await _persistCertificates(
      'Certificate removed successfully',
      allowEmpty: true,
    );
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final current = DateTime.tryParse(controller.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    controller.text = _certificateDateValue(picked);
  }

  Future<void> _persistCertificates(
    String successMessage, {
    bool allowEmpty = false,
  }) async {
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final payload = {
      'certificates': _items
          .map((item) => item.toPayload())
          .where((item) => item['name']?.toString().isNotEmpty == true)
          .toList(),
    };
    if (!allowEmpty && (payload['certificates'] as List).isEmpty) {
      setState(() {
        _saving = false;
        _errorMessage = 'Add at least one certificate name.';
      });
      return;
    }
    final res = await sl<FreelancerProfileRepository>().updateProfile(payload);
    if (!mounted) return;
    res.fold(
      (f) => setState(() {
        _saving = false;
        _errorMessage = f.message;
      }),
      (_) {
        setState(() => _saving = false);
        context.showSnack(successMessage);
        // Certificates aren't an AppUser field — re-fetch /me to sync cache.
        context.read<AuthBloc>().add(const AuthRefreshUser());
      },
    );
  }

  Future<_CertificateDraft?> _certificateFormSheet(
    BuildContext context, {
    _CertificateDraft? item,
  }) async {
    final draft = item == null
        ? _CertificateDraft()
        : _CertificateDraft.copy(item);
    String? errorMessage;
    var saving = false;
    final saved = await showModalBottomSheet<_CertificateDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        final safeBottom = MediaQuery.of(sheetContext).padding.bottom;
        final sheetHeight = MediaQuery.of(sheetContext).size.height * 0.75;
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: SizedBox(
                height: sheetHeight,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSizes.lg,
                    AppSizes.sm,
                    AppSizes.lg,
                    bottomInset + safeBottom + AppSizes.lg,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item == null
                                    ? 'Add certificate'
                                    : 'Edit certificate',
                                style: Theme.of(
                                  sheetContext,
                                ).textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close',
                              onPressed: saving
                                  ? null
                                  : () => Navigator.of(sheetContext).pop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        if (errorMessage != null) ...[
                          AppSizes.vGapMd,
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMd,
                              ),
                              border: Border.all(
                                color: AppColors.danger.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSizes.md),
                              child: Text(
                                errorMessage!,
                                style: Theme.of(sheetContext)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.danger),
                              ),
                            ),
                          ),
                        ],
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: draft.name,
                          label: 'Name *',
                          hint: 'Certificate name',
                          textInputAction: TextInputAction.next,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: draft.issuer,
                          label: 'Issuer',
                          hint: 'Issuer',
                          textInputAction: TextInputAction.next,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: draft.credentialId,
                          label: 'Credential #',
                          hint: 'Credential #',
                          textInputAction: TextInputAction.next,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: draft.issuedAt,
                          readOnly: true,
                          label: 'Issued (YYYY-MM-DD)',
                          hint: 'Select issued date',
                          suffixIcon: const Icon(Icons.calendar_today_outlined),
                          onTap: saving
                              ? null
                              : () => _pickDate(draft.issuedAt),
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: draft.expiresAt,
                          readOnly: true,
                          label: 'Expires',
                          hint: 'Select expiry date',
                          suffixIcon: const Icon(Icons.calendar_today_outlined),
                          onTap: saving
                              ? null
                              : () => _pickDate(draft.expiresAt),
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: draft.credentialUrl,
                          label: 'Credential URL',
                          hint: 'Credential URL',
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.next,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: draft.skills,
                          label: 'Skills tagged',
                          hint: 'Skills tagged (comma separated)',
                          textInputAction: TextInputAction.done,
                        ),
                        AppSizes.vGapXl,
                        AppPrimaryButton(
                          label: item == null ? 'Add & save' : 'Save',
                          isLoading: saving,
                          onPressed: () {
                            if (draft.name.text.trim().isEmpty) {
                              setSheetState(() {
                                errorMessage = 'Certificate name is required.';
                              });
                              return;
                            }
                            setSheetState(() {
                              saving = true;
                              errorMessage = null;
                            });
                            Navigator.of(sheetContext).pop(draft);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (saved == null) {
      draft.dispose();
    }
    return saved;
  }

  List<_CertificateDraft> get _filteredItems {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return _items;
    return _items.where((item) => item.matches(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final total = _items
        .where((item) => item.name.text.trim().isNotEmpty)
        .length;
    final verified = _items
        .where((item) => item.credentialUrl.text.trim().isNotEmpty)
        .length;
    final pending = total - verified;
    final skillsTagged = _items
        .map((item) => item.skills.text.trim())
        .where((skills) => skills.isNotEmpty)
        .expand((skills) => skills.split(','))
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .toSet()
        .length;

    return _ListScaffold(
      title: 'Certificates',
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CertificateMetricCard(
                  title: 'Total',
                  value: total,
                  color: AppColors.info,
                ),
                _CertificateMetricCard(
                  title: 'Verified',
                  value: verified,
                  color: AppColors.success,
                ),
                _CertificateMetricCard(
                  title: 'Pending',
                  value: pending,
                  color: AppColors.warning,
                ),
                _CertificateMetricCard(
                  title: 'Skills Tagged',
                  value: skillsTagged,
                  color: AppColors.danger,
                ),
              ],
            ),
          ),
          AppSizes.vGapLg,
          AppCard(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 760;
                final search = AppTextField(
                  controller: _search,
                  hint: 'Search by certificate name, issuer, credential #...',
                  prefixIcon: Icons.search_rounded,
                  onChanged: (_) => setState(() {}),
                );
                final actions = Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: [
                    AppPrimaryButton(
                      label: 'Filters',
                      icon: Icons.filter_alt_outlined,
                      expanded: false,
                      gradient: false,
                      backgroundColor: AppColors.white,
                      textColor: AppColors.darkText,
                      onPressed: () =>
                          context.showSnack('Certificate filters coming soon'),
                    ),
                    AppPrimaryButton(
                      label: 'Add certificate',
                      icon: Icons.add_rounded,
                      expanded: false,
                      onPressed: _saving ? null : _addCertificate,
                    ),
                  ],
                );

                if (compact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [search, AppSizes.vGapMd, actions],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: search),
                    AppSizes.hGapMd,
                    actions,
                  ],
                );
              },
            ),
          ),
          if (_errorMessage != null) ...[
            AppSizes.vGapMd,
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.35),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Text(
                  _errorMessage!,
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ),
            ),
          ],
          AppSizes.vGapLg,
          for (final item in _filteredItems) ...[
            _CertificateListCard(
              item: item,
              onEdit: _saving ? null : () => _editCertificate(item),
              onRemove: _saving ? null : () => _removeCertificate(item),
            ),
            if (item != _filteredItems.last) AppSizes.vGapMd,
          ],
          if (_filteredItems.isEmpty)
            const AppCard(child: Text('No certificates match your search.')),
        ],
      ),
    );
  }

  String _certificateDateValue(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _CertificateMetricCard extends StatelessWidget {
  const _CertificateMetricCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: AppCard(
        margin: const EdgeInsets.only(right: AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: context.text.labelMedium?.copyWith(
                      color: AppColors.mutedText,
                      letterSpacing: 0,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.north_east_rounded,
                  size: AppSizes.iconSm,
                  color: AppColors.success,
                ),
              ],
            ),
            AppSizes.vGapLg,
            Text('$value', style: context.text.headlineSmall),
            AppSizes.vGapMd,
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 5,
                value: value == 0 ? 0 : 0.65,
                backgroundColor: color.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CertificateListCard extends StatelessWidget {
  const _CertificateListCard({
    required this.item,
    required this.onEdit,
    required this.onRemove,
  });

  final _CertificateDraft item;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      item.issuer.text.trim(),
      item.credentialId.text.trim(),
      if (item.issuedAt.text.trim().isNotEmpty)
        'Issued ${item.issuedAt.text.trim()}',
      if (item.expiresAt.text.trim().isNotEmpty)
        'Expires ${item.expiresAt.text.trim()}',
    ].where((value) => value.isNotEmpty).join(' - ');

    return AppCard(
      child: Row(
        children: [
          const Icon(
            Icons.workspace_premium_outlined,
            color: AppColors.primary,
          ),
          AppSizes.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name.text.trim(), style: context.text.titleSmall),
                if (subtitle.isNotEmpty) ...[
                  AppSizes.vGapXs,
                  Text(
                    subtitle,
                    style: context.text.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (item.skills.text.trim().isNotEmpty) ...[
                  AppSizes.vGapSm,
                  Text(item.skills.text.trim(), style: context.text.labelSmall),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onRemove,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _CertificateFormCard extends StatelessWidget {
  const _CertificateFormCard({
    required this.item,
    required this.saving,
    required this.canRemove,
    required this.errorMessage,
    required this.onChanged,
    required this.onPickIssued,
    required this.onPickExpires,
    required this.onRemove,
    required this.onSave,
  });

  final _CertificateDraft item;
  final bool saving;
  final bool canRemove;
  final String? errorMessage;
  final VoidCallback onChanged;
  final VoidCallback onPickIssued;
  final VoidCallback onPickExpires;
  final VoidCallback onRemove;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Add certificate', style: context.text.titleMedium),
              ),
              IconButton(
                tooltip: 'Remove',
                onPressed: saving || !canRemove ? null : onRemove,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          if (errorMessage != null) ...[
            AppSizes.vGapMd,
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.35),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Text(
                  errorMessage!,
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ),
            ),
          ],
          AppSizes.vGapMd,
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 720;
              final fields = [
                AppTextField(
                  controller: item.name,
                  label: 'Name *',
                  hint: 'Certificate name',
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => onChanged(),
                ),
                AppTextField(
                  controller: item.issuer,
                  label: 'Issuer',
                  hint: 'Issuer',
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => onChanged(),
                ),
                AppTextField(
                  controller: item.credentialId,
                  label: 'Credential #',
                  hint: 'Credential #',
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => onChanged(),
                ),
                AppTextField(
                  controller: item.issuedAt,
                  readOnly: true,
                  label: 'Issued (YYYY-MM-DD)',
                  hint: 'Select issued date',
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                  onTap: saving ? null : onPickIssued,
                ),
                AppTextField(
                  controller: item.expiresAt,
                  readOnly: true,
                  label: 'Expires',
                  hint: 'Select expiry date',
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                  onTap: saving ? null : onPickExpires,
                ),
                AppTextField(
                  controller: item.credentialUrl,
                  label: 'Credential URL',
                  hint: 'Credential URL',
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => onChanged(),
                ),
                AppTextField(
                  controller: item.skills,
                  label: 'Skills tagged',
                  hint: 'Skills tagged (comma separated)',
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => onChanged(),
                ),
              ];

              if (!twoColumns) {
                return Column(
                  children: [
                    for (final field in fields) ...[
                      field,
                      if (field != fields.last) AppSizes.vGapMd,
                    ],
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: fields[0]),
                      AppSizes.hGapMd,
                      Expanded(child: fields[1]),
                    ],
                  ),
                  AppSizes.vGapMd,
                  Row(
                    children: [
                      Expanded(child: fields[2]),
                      AppSizes.hGapMd,
                      Expanded(child: fields[3]),
                    ],
                  ),
                  AppSizes.vGapMd,
                  Row(
                    children: [
                      Expanded(child: fields[4]),
                      AppSizes.hGapMd,
                      Expanded(child: fields[5]),
                    ],
                  ),
                  AppSizes.vGapMd,
                  fields[6],
                ],
              );
            },
          ),
          AppSizes.vGapLg,
          Align(
            alignment: Alignment.centerLeft,
            child: AppPrimaryButton(
              label: 'Add & save',
              expanded: false,
              isLoading: saving,
              onPressed: onSave,
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificateDraft {
  _CertificateDraft({
    String name = '',
    String issuer = '',
    String credentialId = '',
    String issuedAt = '',
    String expiresAt = '',
    String credentialUrl = '',
    String skills = '',
  }) : name = TextEditingController(text: name),
       issuer = TextEditingController(text: issuer),
       credentialId = TextEditingController(text: credentialId),
       issuedAt = TextEditingController(text: issuedAt),
       expiresAt = TextEditingController(text: expiresAt),
       credentialUrl = TextEditingController(text: credentialUrl),
       skills = TextEditingController(text: skills);

  factory _CertificateDraft.copy(_CertificateDraft item) => _CertificateDraft(
    name: item.name.text,
    issuer: item.issuer.text,
    credentialId: item.credentialId.text,
    issuedAt: item.issuedAt.text,
    expiresAt: item.expiresAt.text,
    credentialUrl: item.credentialUrl.text,
    skills: item.skills.text,
  );

  final TextEditingController name;
  final TextEditingController issuer;
  final TextEditingController credentialId;
  final TextEditingController issuedAt;
  final TextEditingController expiresAt;
  final TextEditingController credentialUrl;
  final TextEditingController skills;

  bool matches(String query) {
    return [
      name.text,
      issuer.text,
      credentialId.text,
      credentialUrl.text,
      skills.text,
    ].any((value) => value.toLowerCase().contains(query));
  }

  Map<String, String> toPayload() {
    return {
      'name': name.text.trim(),
      'issuer': issuer.text.trim(),
      'credentialId': credentialId.text.trim(),
      'issuedAt': issuedAt.text.trim(),
      'expiresAt': expiresAt.text.trim(),
      'credentialUrl': credentialUrl.text.trim(),
      'skills': skills.text.trim(),
    };
  }

  void dispose() {
    name.dispose();
    issuer.dispose();
    credentialId.dispose();
    issuedAt.dispose();
    expiresAt.dispose();
    credentialUrl.dispose();
    skills.dispose();
  }
}

class FreelancerInvoicesPage extends StatelessWidget {
  const FreelancerInvoicesPage({super.key});
  @override
  Widget build(BuildContext context) => _ListScaffold(
    title: 'Invoices',
    child: CatalogView<Invoice>(
      fetcher: (q) => sl<WalletRepository>().getInvoices(q),
      searchHint: 'Search invoices…',
      itemBuilder: (context, inv, __) => AppCard(
        onTap: () => context.push('${Routes.invoiceDetails}/${inv.id}'),
        child: Row(
          children: [
            const Icon(Icons.receipt_long_outlined, color: AppColors.primary),
            AppSizes.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inv.number, style: context.text.titleSmall),
                  Text(
                    '${inv.party} · ${Formatters.date(inv.issuedAt)}',
                    style: context.text.labelSmall,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.compactCurrency(inv.amount),
                  style: context.text.titleSmall,
                ),
                AppStatusChip(
                  label: inv.status,
                  dense: true,
                  color: inv.status == 'Paid'
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class FreelancerWithdrawalsPage extends StatefulWidget {
  const FreelancerWithdrawalsPage({super.key});
  @override
  State<FreelancerWithdrawalsPage> createState() =>
      _FreelancerWithdrawalsPageState();
}

class _FreelancerWithdrawalsPageState extends State<FreelancerWithdrawalsPage> {
  bool _loading = true;
  WalletSummary _summary = const WalletSummary(
    available: 0,
    pending: 0,
    lifetime: 0,
  );
  List<WalletTransaction> _withdrawals = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final walletRepo = sl<WalletRepository>();
    final summaryRes = await walletRepo.getSummary();
    final txRes = await walletRepo.getTransactions(
      const QueryParams(page: 1, pageSize: 50),
    );
    if (!mounted) return;
    summaryRes.fold((_) {}, (s) => _summary = s);
    txRes.fold(
      (_) {},
      (page) => _withdrawals = page.items
          .where((t) => t.type == TransactionType.withdrawal)
          .toList(),
    );
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
        title: const Text('Withdrawals'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              children: [
                AppCard(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available to withdraw',
                        style: context.text.labelMedium,
                      ),
                      AppSizes.vGapXs,
                      Text(
                        Formatters.currency(_summary.available),
                        style: context.text.headlineSmall?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      AppSizes.vGapMd,
                      AppPrimaryButton(
                        label: 'Request Withdrawal',
                        icon: Icons.account_balance_outlined,
                        onPressed: () => _openWithdrawalSheet(context),
                      ),
                    ],
                  ),
                ),
                AppSizes.vGapLg,
                Text('History', style: context.text.titleMedium),
                AppSizes.vGapMd,
                if (_withdrawals.isEmpty)
                  const AppCard(child: Text('No withdrawal history yet'))
                else
                  for (final t in _withdrawals)
                    AppCard(
                      margin: const EdgeInsets.only(bottom: AppSizes.sm),
                      onTap: () =>
                          context.push('${Routes.transactionDetails}/${t.id}'),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.north_east_rounded,
                            color: AppColors.danger,
                          ),
                          AppSizes.hGapMd,
                          Expanded(
                            child: Text(
                              t.title,
                              style: context.text.bodyMedium,
                            ),
                          ),
                          Text(
                            Formatters.compactCurrency(t.amount),
                            style: context.text.titleSmall,
                          ),
                        ],
                      ),
                    ),
              ],
            ),
    );
  }

  Future<void> _openWithdrawalSheet(BuildContext context) async {
    final amount = TextEditingController();
    final accountHolderName = TextEditingController();
    final accountNumber = TextEditingController();
    final ifscCode = TextEditingController();
    final bankName = TextEditingController();
    final upiId = TextEditingController();
    var method = 'bank';
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        final safeBottom = MediaQuery.of(sheetContext).padding.bottom;
        final sheetHeight = MediaQuery.of(sheetContext).size.height * 0.75;
        var saving = false;
        String? errorMessage;
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: SizedBox(
                height: sheetHeight,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSizes.lg,
                    AppSizes.sm,
                    AppSizes.lg,
                    bottomInset + safeBottom + AppSizes.lg,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Request Withdrawal',
                                style: Theme.of(
                                  sheetContext,
                                ).textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close',
                              onPressed: saving
                                  ? null
                                  : () {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      Navigator.of(sheetContext).pop();
                                    },
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        if (errorMessage != null) ...[
                          AppSizes.vGapMd,
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMd,
                              ),
                              border: Border.all(
                                color: AppColors.danger.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSizes.md),
                              child: Text(
                                errorMessage!,
                                style: Theme.of(sheetContext)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.danger),
                              ),
                            ),
                          ),
                        ],
                        AppSizes.vGapMd,
                        Text(
                          'Available: ${Formatters.currency(_summary.available)}',
                          style: context.text.labelMedium,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: amount,
                          label: 'Amount',
                          hint: 'Enter amount',
                          prefixIcon: Icons.currency_rupee_rounded,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                        ),
                        AppSizes.vGapMd,
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                              value: 'bank',
                              label: Text('Bank'),
                              icon: Icon(Icons.account_balance_outlined),
                            ),
                            ButtonSegment(
                              value: 'upi',
                              label: Text('UPI'),
                              icon: Icon(Icons.qr_code_2_rounded),
                            ),
                          ],
                          selected: {method},
                          onSelectionChanged: saving
                              ? null
                              : (values) {
                                  setSheetState(() {
                                    method = values.first;
                                    errorMessage = null;
                                  });
                                },
                        ),
                        if (method == 'bank') ...[
                          AppSizes.vGapMd,
                          AppTextField(
                            controller: accountHolderName,
                            label: 'Account holder name',
                            hint: 'Enter name',
                            textInputAction: TextInputAction.next,
                          ),
                          AppSizes.vGapMd,
                          AppTextField(
                            controller: accountNumber,
                            label: 'Account number',
                            hint: 'Enter account number',
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                          ),
                          AppSizes.vGapMd,
                          AppTextField(
                            controller: ifscCode,
                            label: 'IFSC code',
                            hint: 'Enter Ifsc Code',
                            textInputAction: TextInputAction.next,
                          ),
                          AppSizes.vGapMd,
                          AppTextField(
                            controller: bankName,
                            label: 'Bank name',
                            hint: 'Enter bank name',
                            textInputAction: TextInputAction.done,
                          ),
                        ] else ...[
                          AppSizes.vGapMd,
                          AppTextField(
                            controller: upiId,
                            label: 'UPI ID',
                            hint: 'Enter UPI ID',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                          ),
                        ],
                        AppSizes.vGapXl,
                        AppPrimaryButton(
                          label: 'Submit Request',
                          isLoading: saving,
                          onPressed: () async {
                            final value = double.tryParse(amount.text.trim());
                            if (value == null || value <= 0) {
                              setSheetState(() {
                                errorMessage = 'Enter a valid amount';
                              });
                              return;
                            }
                            if (value > _summary.available) {
                              setSheetState(() {
                                errorMessage =
                                    'Amount cannot exceed available balance';
                              });
                              return;
                            }
                            final bankPayload = {
                              'accountHolderName': accountHolderName.text
                                  .trim(),
                              'accountNumber': accountNumber.text.trim(),
                              'ifscCode': ifscCode.text.trim(),
                              'bankName': bankName.text.trim(),
                            };
                            final upiPayload = {'upiId': upiId.text.trim()};
                            if (method == 'bank' &&
                                bankPayload.values.any((v) => v.isEmpty)) {
                              setSheetState(() {
                                errorMessage = 'Enter all bank details';
                              });
                              return;
                            }
                            if (method == 'upi' &&
                                upiPayload['upiId']!.isEmpty) {
                              setSheetState(() {
                                errorMessage = 'Enter UPI ID';
                              });
                              return;
                            }
                            setSheetState(() {
                              saving = true;
                              errorMessage = null;
                            });
                            final res = await sl<WalletRepository>()
                                .requestWithdrawal(
                                  amount: value,
                                  method: method,
                                  bankDetails: method == 'bank'
                                      ? bankPayload
                                      : null,
                                  upiDetails: method == 'upi'
                                      ? upiPayload
                                      : null,
                                );
                            if (!sheetContext.mounted) return;
                            res.fold(
                              (failure) {
                                setSheetState(() {
                                  saving = false;
                                  errorMessage = failure.message;
                                });
                              },
                              (successMessage) {
                                Navigator.of(sheetContext).pop(successMessage);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    amount.dispose();
    accountHolderName.dispose();
    accountNumber.dispose();
    ifscCode.dispose();
    bankName.dispose();
    upiId.dispose();
    if (!context.mounted || message == null) return;
    context.showSnack(message);
    setState(() => _loading = true);
    await _load();
  }
}

class FreelancerTasksPage extends StatefulWidget {
  const FreelancerTasksPage({super.key});
  @override
  State<FreelancerTasksPage> createState() => _FreelancerTasksPageState();
}

class _FreelancerTasksPageState extends State<FreelancerTasksPage> {
  final _saving = <String, bool>{};

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
        title: const Text('Tasks'),
      ),
      body: CatalogView<FreelancerTask>(
        fetcher: (q) => sl<FreelancerTaskRepository>().getTasks(q),
        searchHint: 'Search tasks…',
        emptyTitle: 'No tasks assigned',
        itemBuilder: (context, task, __) => AppCard(
          margin: const EdgeInsets.only(bottom: AppSizes.sm),
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
          child: CheckboxListTile(
            value: task.isCompleted,
            onChanged: _saving[task.id] == true
                ? null
                : (v) => _updateTaskStatus(task, v ?? false),
            secondary: IconButton(
              onPressed: () => _openTaskDetail(task.id),
              icon: const Icon(Icons.open_in_new_rounded),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
                color: task.isCompleted ? AppColors.mutedText : null,
              ),
            ),
            subtitle: Row(
              children: [
                AppStatusChip(
                  label: task.status,
                  dense: true,
                  color: task.isCompleted ? AppColors.success : AppColors.info,
                ),
                if (_saving[task.id] == true) ...[
                  AppSizes.hGapSm,
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Future<void> _updateTaskStatus(FreelancerTask task, bool completed) async {
    setState(() => _saving[task.id] = true);
    final status = completed ? 'completed' : 'in_progress';
    final res = await sl<FreelancerTaskRepository>().updateTaskStatus(
      task.id,
      status,
    );
    if (!mounted) return;
    res.fold(
      (f) => context.showSnack(f.message),
      (_) => context.showSnack('Task status updated'),
    );
    setState(() => _saving[task.id] = false);
  }

  Future<void> _openTaskDetail(String id) async {
    final res = await sl<FreelancerTaskRepository>().getTask(id);
    if (!mounted) return;
    res.fold((f) => context.showSnack(f.message), (task) async {
      final repo = sl<FreelancerTaskRepository>();
      final commentsRes = await repo.getComments(id);
      final attachmentsRes = await repo.getAttachments(id);
      final timeLogsRes = await repo.getTimeLogs(id);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (sheetContext) {
          final sheetHeight = MediaQuery.of(sheetContext).size.height * 0.75;
          return SafeArea(
            child: SizedBox(
              height: sheetHeight,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title, style: context.text.titleLarge),
                    AppSizes.vGapSm,
                    AppStatusChip(
                      label: task.status,
                      dense: true,
                      color: task.isCompleted
                          ? AppColors.success
                          : AppColors.info,
                    ),
                    AppSizes.vGapMd,
                    Text('Progress: ${task.progress}%'),
                    AppSizes.vGapMd,
                    Text('Comments'),
                    AppSizes.vGapXs,
                    commentsRes.fold(
                      (_) => const Text('Comments unavailable'),
                      (items) => items.isEmpty
                          ? const Text('No comments')
                          : Column(
                              children: items
                                  .map(
                                    (c) => ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(c.text),
                                      subtitle: Text(c.author),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    AppSizes.vGapSm,
                    AppPrimaryButton(
                      label: 'Add comment',
                      onPressed: () async {
                        final ctrl = TextEditingController();
                        await showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Add Comment'),
                            content: AppTextField(controller: ctrl),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final r = await repo.addComment(
                                    id,
                                    ctrl.text.trim(),
                                  );
                                  if (!context.mounted) return;
                                  r.fold(
                                    (f) => context.showSnack(f.message),
                                    (_) => context.showSnack('Comment added'),
                                  );
                                  if (dialogContext.mounted) {
                                    Navigator.pop(dialogContext);
                                  }
                                },
                                child: const Text('Save'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    AppSizes.vGapMd,
                    Text('Attachments'),
                    AppSizes.vGapXs,
                    attachmentsRes.fold(
                      (_) => const Text('Attachments unavailable'),
                      (items) => items.isEmpty
                          ? const Text('No attachments')
                          : Column(
                              children: items
                                  .map(
                                    (a) => ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(a.name),
                                      trailing: const Icon(
                                        Icons.download_rounded,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                    AppSizes.vGapSm,
                    AppPrimaryButton(
                      label: 'Add attachment',
                      onPressed: () async {
                        final pick = await FilePicker.platform.pickFiles(
                          allowMultiple: false,
                        );
                        if (pick == null || pick.files.single.path == null) {
                          return;
                        }
                        final r = await repo.addAttachment(
                          id,
                          pick.files.single.path!,
                        );
                        if (!context.mounted) return;
                        r.fold(
                          (f) => context.showSnack(f.message),
                          (_) => context.showSnack('Attachment uploaded'),
                        );
                      },
                    ),
                    AppSizes.vGapMd,
                    Text('Time Logs'),
                    AppSizes.vGapXs,
                    timeLogsRes.fold(
                      (_) => const Text('Time logs unavailable'),
                      (items) => items.isEmpty
                          ? const Text('No time logs')
                          : Column(
                              children: items
                                  .map(
                                    (t) => ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      title: Text('${t.hours}h · ${t.date}'),
                                      subtitle: Text(t.notes),
                                    ),
                                  )
                                  .toList(),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    });
  }
}

class FreelancerSkillsPage extends StatefulWidget {
  const FreelancerSkillsPage({super.key});
  @override
  State<FreelancerSkillsPage> createState() => _FreelancerSkillsPageState();
}

class _FreelancerSkillsPageState extends State<FreelancerSkillsPage> {
  String? _categoryId;
  final Set<String> _selectedSkillIds = {};
  final Map<String, String> _skillNamesById = {};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _onSkillOptionsLoaded(List<SkillOption> skills) {
    for (final skill in skills) {
      _skillNamesById[skill.id] = skill.name;
    }
  }

  Future<void> _load() async {
    final res = await sl<FreelancerProfileRepository>().getProfile();
    if (!mounted) return;
    res.fold((_) {}, (p) {
      if (p.skills.isNotEmpty) {
        _selectedSkillIds
          ..clear()
          ..addAll(p.skills);
      }
    });
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (_selectedSkillIds.isEmpty) {
      context.showSnack('Select at least one skill', isError: true);
      return;
    }

    setState(() => _saving = true);
    final res = await sl<FreelancerProfileRepository>().updateProfile({
      'skillIds': _selectedSkillIds.toList(),
    });
    if (!mounted) return;
    setState(() => _saving = false);
    res.fold(
      (f) => context.showSnack(f.message, isError: true),
      (_) {
        context.showSnack('Skills saved');
        // skillIds is an AppUser field — patch cache directly, no round-trip.
        final current = context.read<AuthBloc>().state.user;
        if (current != null) {
          context.read<AuthBloc>().add(
            AuthUserUpdated(
              current.copyWith(skillIds: _selectedSkillIds.toList()),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Skills'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        children: [
          Text(
            'Select the skills that best represent you',
            style: context.text.bodyMedium,
          ),
          AppSizes.vGapLg,
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else
            CategorySkillsPicker(
              selectedCategoryId: _categoryId,
              selectedSkillIds: _selectedSkillIds,
              clearSkillsOnCategoryChange: false,
              categorySubtitle: 'Browse skills by category',
              skillsSubtitle: 'Select all skills that apply to you',
              onCategoryChanged: (id, _) => setState(() => _categoryId = id),
              onSkillsChanged: (ids) => setState(() {
                _selectedSkillIds
                  ..clear()
                  ..addAll(ids);
              }),
              onSkillOptionsLoaded: _onSkillOptionsLoaded,
            ),
        ],
      ),
    );
  }
}

class FreelancerExperiencePage extends StatefulWidget {
  const FreelancerExperiencePage({super.key});

  @override
  State<FreelancerExperiencePage> createState() =>
      _FreelancerExperiencePageState();
}

class _FreelancerExperiencePageState extends State<FreelancerExperiencePage> {
  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;
  List<FreelancerExperience> _items = const [];

  FreelancerCredentialsRepository get _repo =>
      sl<FreelancerCredentialsRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final result = await _repo.getExperiences();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = result.valueOrNull ?? const [];
      _errorMessage = result.failureOrNull?.message;
    });
  }

  Future<void> _openForm([FreelancerExperience? item]) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FreelancerExperienceFormPage(item: item),
      ),
    );
    if (result == true) {
      await _load();
    }
  }

  Future<void> _delete(FreelancerExperience item) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete experience?',
      message: 'This will remove ${item.title} at ${item.company}.',
      confirmLabel: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed || !mounted) return;

    setState(() => _saving = true);
    final result = await _repo.deleteExperience(item.id);
    if (!mounted) return;
    setState(() => _saving = false);

    final message = result.valueOrNull;
    if (message == null) {
      context.showSnack(
        result.failureOrNull?.message ?? 'Unable to delete experience',
        isError: true,
      );
      return;
    }
    context.showSnack(message);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final activeRolesCount = _items.where((x) => x.isCurrent).length;
    final totalCount = _items.length;

    return AppScaffold(
      appBar: AppBar(
        leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
        title: const Text('Experience'),
        actions: [
          IconButton(
            tooltip: 'Add role',
            onPressed: _saving ? null : () => _openForm(),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'PROJECTS',
                                    style: context.text.labelSmall?.copyWith(
                                      color: AppColors.mutedText,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSizes.sm,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: Text(
                                      'delivered',
                                      style: context.text.labelSmall,
                                    ),
                                  ),
                                ],
                              ),
                              AppSizes.vGapSm,
                              Text(
                                '$totalCount',
                                style: context.text.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              AppSizes.vGapSm,
                              LinearProgressIndicator(
                                value: totalCount > 0 ? 0.6 : 0.0,
                                backgroundColor: AppColors.warning.withValues(
                                  alpha: 0.1,
                                ),
                                color: AppColors.warning,
                              ),
                            ],
                          ),
                        ),
                      ),
                      AppSizes.hGapMd,
                      Expanded(
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'CURR...',
                                    style: context.text.labelSmall?.copyWith(
                                      color: AppColors.mutedText,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSizes.sm,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: Text(
                                      'active roles',
                                      style: context.text.labelSmall,
                                    ),
                                  ),
                                ],
                              ),
                              AppSizes.vGapSm,
                              Text(
                                '$activeRolesCount',
                                style: context.text.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              AppSizes.vGapSm,
                              LinearProgressIndicator(
                                value: activeRolesCount > 0 ? 0.5 : 0.0,
                                backgroundColor: AppColors.danger.withValues(
                                  alpha: 0.1,
                                ),
                                color: AppColors.danger,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  AppSizes.vGapLg,
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Career timeline',
                                    style: context.text.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  AppSizes.vGapXs,
                                  Text(
                                    'Full professional history synced to your public profile',
                                    style: context.text.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _saving ? null : () => _openForm(),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add role'),
                            ),
                          ],
                        ),
                        if (_errorMessage != null) ...[
                          AppSizes.vGapMd,
                          Container(
                            padding: const EdgeInsets.all(AppSizes.sm),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMd,
                              ),
                              border: Border.all(color: AppColors.danger),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: context.text.bodySmall?.copyWith(
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                        AppSizes.vGapLg,
                        if (_items.isEmpty)
                          const AppCard(
                            child: Text('No experience roles added yet.'),
                          )
                        else
                          for (final item in _items) ...[
                            _ExperienceApiCard(
                              item: item,
                              onEdit: _saving ? null : () => _openForm(item),
                              onDelete: _saving ? null : () => _delete(item),
                            ),
                            if (item != _items.last) AppSizes.vGapMd,
                          ],
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ExperienceApiCard extends StatelessWidget {
  const _ExperienceApiCard({required this.item, this.onEdit, this.onDelete});

  final FreelancerExperience item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (item.company.isNotEmpty) item.company,
      if (item.industryName != null && item.industryName!.isNotEmpty)
        item.industryName!,
      if (item.location.isNotEmpty) item.location,
      if (item.startDate.isNotEmpty)
        '${item.startDate} - ${item.isCurrent ? 'Present' : (item.endDate ?? '')}',
    ];

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.sm),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: const Icon(
              Icons.work_outline_rounded,
              color: AppColors.primary,
            ),
          ),
          AppSizes.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitleParts.isNotEmpty) ...[
                  AppSizes.vGapXs,
                  Text(
                    subtitleParts.join(' • '),
                    style: context.text.bodySmall,
                  ),
                ],
                if (item.description.isNotEmpty) ...[
                  AppSizes.vGapSm,
                  Text(
                    item.description,
                    style: context.text.bodyMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (item.skillNames.isNotEmpty || item.skillIds.isNotEmpty) ...[
                  AppSizes.vGapSm,
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children:
                        (item.skillNames.isNotEmpty
                                ? item.skillNames
                                : item.skillIds)
                            .map(
                              (name) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.border.withValues(
                                    alpha: 0.4,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  name,
                                  style: context.text.labelSmall,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ],
            ),
          ),
          if (onEdit != null)
            IconButton(
              tooltip: 'Edit',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Delete',
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.danger,
              ),
            ),
        ],
      ),
    );
  }
}

class FreelancerExperienceFormPage extends StatefulWidget {
  const FreelancerExperienceFormPage({super.key, this.item});

  final FreelancerExperience? item;

  @override
  State<FreelancerExperienceFormPage> createState() =>
      _FreelancerExperienceFormPageState();
}

class _FreelancerExperienceFormPageState
    extends State<FreelancerExperienceFormPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _companyController;
  late final TextEditingController _locationController;
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;
  late final TextEditingController _descriptionController;

  bool _isCurrent = false;
  bool _saving = false;
  String? _selectedIndustryId;
  String? _selectedIndustryName;

  List<SkillCategory> _industries = [];
  List<String> _availableSkillNames = [];
  List<String> _selectedSkillNames = [];
  Map<String, SkillOption> _skillsMap = {};

  bool _loadingIndustries = true;
  bool _loadingSkills = false;
  String? _error;

  FreelancerCredentialsRepository get _repo =>
      sl<FreelancerCredentialsRepository>();

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _titleController = TextEditingController(text: item?.title ?? '');
    _companyController = TextEditingController(text: item?.company ?? '');
    _locationController = TextEditingController(text: item?.location ?? '');
    _startDateController = TextEditingController(text: item?.startDate ?? '');
    _endDateController = TextEditingController(text: item?.endDate ?? '');
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _isCurrent = item?.isCurrent ?? false;
    _selectedIndustryId = item?.industryId;
    _selectedIndustryName = item?.industryName;
    _selectedSkillNames = List<String>.from(
      item?.skillNames.isNotEmpty == true
          ? item!.skillNames
          : item?.skillIds ?? [],
    );

    _loadIndustries();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _companyController.dispose();
    _locationController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadIndustries() async {
    setState(() => _loadingIndustries = true);
    try {
      final res = await sl<MasterDataRepository>().getIndustries();
      if (!mounted) return;
      res.fold((f) {}, (list) {
        setState(() {
          _industries = list;
          if (_selectedIndustryId == null &&
              _selectedIndustryName != null &&
              _selectedIndustryName!.isNotEmpty) {
            final match = list.firstWhere(
              (x) =>
                  x.name.toLowerCase() == _selectedIndustryName!.toLowerCase(),
              orElse: () => const SkillCategory(id: '', name: ''),
            );
            if (match.id.isNotEmpty) _selectedIndustryId = match.id;
          }
        });
      });
    } catch (_) {}
    setState(() => _loadingIndustries = false);

    if (_selectedIndustryId != null && _selectedIndustryId!.isNotEmpty) {
      _fetchSkillsForIndustry(_selectedIndustryId!);
    }
  }

  Future<void> _fetchSkillsForIndustry(String industryId) async {
    setState(() => _loadingSkills = true);
    try {
      final res = await sl<ApiClientHelper>().getEnvelope<List<SkillOption>>(
        ApiEndpoints.publicSkills,
        query: {'page': 1, 'limit': 100},
        parser: (env) {
          dynamic list = env.data;
          if (list is Map) {
            final map = Map<String, dynamic>.from(list);
            list = map['data'] ?? map['items'] ?? map['skills'] ?? const [];
          }
          if (list is! List) return <SkillOption>[];
          return list
              .map(
                (e) =>
                    SkillOption.fromJson(Map<String, dynamic>.from(e as Map)),
              )
              .toList();
        },
      );
      if (!mounted) return;
      if (res.isSuccess && res.valueOrNull != null) {
        final skills = res.valueOrNull!;
        setState(() {
          _skillsMap = {for (final s in skills) s.name: s};
          _availableSkillNames = skills.map((s) => s.name).toList();
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingSkills = false);
  }

  Future<void> _pickDate(TextEditingController controller) async {
    final current = DateTime.tryParse(controller.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    final month = picked.month.toString().padLeft(2, '0');
    final day = picked.day.toString().padLeft(2, '0');
    controller.text = '${picked.year}-$month-$day';
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final company = _companyController.text.trim();
    final startDate = _startDateController.text.trim();

    if (title.isEmpty) {
      setState(() => _error = 'Role / Title is required.');
      return;
    }
    if (company.isEmpty) {
      setState(() => _error = 'Company name is required.');
      return;
    }
    if (_selectedIndustryId == null || _selectedIndustryId!.isEmpty) {
      setState(() => _error = 'Please select an Industry.');
      return;
    }
    if (startDate.isEmpty) {
      setState(() => _error = 'Start date is required.');
      return;
    }

    final skillIds = _selectedSkillNames
        .map((name) => _skillsMap[name]?.id ?? name)
        .where((id) => id.isNotEmpty)
        .toList();

    final payload = {
      'title': title,
      'company': company,
      'location': _locationController.text.trim(),
      'startDate': startDate,
      'endDate': _isCurrent ? '' : _endDateController.text.trim(),
      'isCurrent': _isCurrent,
      'description': _descriptionController.text.trim(),
      'industryId': _selectedIndustryId,
      'skillIds': skillIds,
    };

    setState(() {
      _saving = true;
      _error = null;
    });

    final result = widget.item == null
        ? await _repo.addExperience(payload)
        : await _repo.updateExperience(widget.item!.id, payload);

    if (!mounted) return;
    setState(() => _saving = false);

    final saved = result.valueOrNull;
    if (saved == null) {
      setState(() {
        _error = result.failureOrNull?.message ?? 'Unable to save experience';
      });
      return;
    }

    context.showSnack(
      saved.responseMessage ??
          (widget.item == null ? 'Experience added' : 'Experience updated'),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
        title: Text(widget.item == null ? 'Add Experience' : 'Edit Experience'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSizes.sm),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  border: Border.all(color: AppColors.danger),
                ),
                child: Text(
                  _error!,
                  style: context.text.bodySmall?.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ),
              AppSizes.vGapMd,
            ],
            AppTextField(
              controller: _titleController,
              label: 'Role / Title *',
              hint: 'e.g. Senior Software Engineer',
              textInputAction: TextInputAction.next,
            ),
            AppSizes.vGapMd,
            AppTextField(
              controller: _companyController,
              label: 'Company *',
              hint: 'e.g. Google',
              textInputAction: TextInputAction.next,
            ),
            AppSizes.vGapMd,
            if (_loadingIndustries)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              AppDropdown<SkillCategory>(
                label: 'Industry *',
                hint: "Choose the industry your business operates in",
                value:
                    _selectedIndustryId == null || _selectedIndustryId!.isEmpty
                    ? null
                    : _industries.firstWhere(
                        (x) => x.id == _selectedIndustryId,
                        orElse: () => SkillCategory(
                          id: _selectedIndustryId!,
                          name: _selectedIndustryName ?? '',
                        ),
                      ),
                items: _industries,
                itemLabel: (ind) => ind.name,
                onChanged: (val) {
                  if (val == null) return;
                  setState(() {
                    _selectedIndustryId = val.id;
                    _selectedIndustryName = val.name;
                    _selectedSkillNames.clear();
                    _availableSkillNames.clear();
                    _skillsMap.clear();
                  });
                  _fetchSkillsForIndustry(val.id);
                },
              ),
            AppSizes.vGapMd,
            AppLocationField(
              controller: _locationController,
              label: 'Location',
              hint: 'Search and select location',
            ),
            AppSizes.vGapMd,
            AppTextField(
              controller: _startDateController,
              readOnly: true,
              label: 'Start Date *',
              hint: 'YYYY-MM-DD',
              suffixIcon: const Icon(Icons.calendar_today_outlined),
              onTap: () => _pickDate(_startDateController),
            ),
            AppSizes.vGapMd,
            AppTextField(
              controller: _endDateController,
              readOnly: true,
              enabled: !_isCurrent,
              label: 'End Date',
              hint: _isCurrent ? 'Present' : 'YYYY-MM-DD',
              suffixIcon: const Icon(Icons.calendar_today_outlined),
              onTap: _isCurrent ? null : () => _pickDate(_endDateController),
            ),
            AppSizes.vGapSm,
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _isCurrent,
              title: const Text('Currently working here'),
              onChanged: (val) {
                setState(() {
                  _isCurrent = val ?? false;
                  if (_isCurrent) _endDateController.clear();
                });
              },
            ),
            AppSizes.vGapMd,
            AppTextField(
              controller: _descriptionController,
              label: 'Description / Achievements',
              hint: 'Describe your role and key achievements...',
              maxLines: 3,
              textInputAction: TextInputAction.newline,
            ),
            AppSizes.vGapMd,
            if (_loadingSkills)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              SignupMultiSelectSheet(
                hint:"Select the skills you want to offer",
                label: 'Skills',
                minSelection: 0,
                selectedItems: _selectedSkillNames,
                availableOptions: _availableSkillNames,
                onChanged: (items) {
                  setState(() => _selectedSkillNames = items);
                },
              ),
            AppSizes.vGapXl,
            AppPrimaryButton(
              label: widget.item == null
                  ? 'Add Experience'
                  : 'Update Experience',
              isLoading: _saving,
              onPressed: _saving ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class FreelancerEducationPage extends StatefulWidget {
  const FreelancerEducationPage({super.key});

  @override
  State<FreelancerEducationPage> createState() =>
      _FreelancerEducationPageState();
}

class _FreelancerEducationPageState extends State<FreelancerEducationPage> {
  bool _loading = true;
  bool _saving = false;
  String? _errorMessage;
  final _search = TextEditingController();
  final _items = <_EducationDraft>[];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await sl<FreelancerProfileRepository>().getProfile();
    if (!mounted) return;
    res.fold(
      (_) {},
      (p) => _items
        ..clear()
        ..addAll(
          p.education
              .split(',')
              .where((e) => e.isNotEmpty)
              .map((education) => _EducationDraft(institution: education)),
        ),
    );
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _search.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _addEducation() async {
    final item = await _educationFormSheet(context);
    if (!mounted || item == null) return;
    setState(() {
      _items.add(item);
      _errorMessage = null;
    });
    await _persistEducation('Education added successfully');
  }

  Future<void> _editEducation(_EducationDraft item) async {
    final updated = await _educationFormSheet(context, item: item);
    if (!mounted || updated == null) return;
    final index = _items.indexOf(item);
    if (index == -1) {
      updated.dispose();
      return;
    }
    setState(() {
      _items[index] = updated;
      item.dispose();
      _errorMessage = null;
    });
    await _persistEducation('Education updated successfully');
  }

  Future<void> _removeEducation(_EducationDraft item) async {
    setState(() {
      _items.remove(item);
      item.dispose();
      _errorMessage = null;
    });
    await _persistEducation('Education removed successfully', allowEmpty: true);
  }

  Future<void> _pickCertificate(
    _EducationDraft item,
    void Function(void Function())? setSheetState,
  ) async {
    final pick = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    final file = pick?.files.single;
    final path = file?.path;
    if (file == null || path == null) return;

    void update(void Function() fn) {
      if (setSheetState == null) {
        setState(fn);
      } else {
        setSheetState(fn);
      }
    }

    update(() {
      item.certificateName = file.name;
      item.uploadingCertificate = true;
      _errorMessage = null;
    });

    final res = await sl<FreelancerProfileRepository>().uploadCertificate(path);
    if (!mounted) return;
    res.fold(
      (f) => update(() {
        item.uploadingCertificate = false;
        _errorMessage = f.message;
      }),
      (url) => update(() {
        item.uploadingCertificate = false;
        item.certificateUrl = url;
      }),
    );
  }

  Future<void> _persistEducation(
    String successMessage, {
    bool allowEmpty = false,
  }) async {
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final payload = {
      'education': _items
          .map((item) => item.toProfileValue())
          .where((value) => value.isNotEmpty)
          .toList(),
    };
    if (!allowEmpty && (payload['education'] as List).isEmpty) {
      setState(() {
        _saving = false;
        _errorMessage = 'Add at least one institution.';
      });
      return;
    }
    final res = await sl<FreelancerProfileRepository>().updateProfile(payload);
    if (!mounted) return;
    res.fold(
      (f) => setState(() {
        _saving = false;
        _errorMessage = f.message;
      }),
      (_) {
        setState(() => _saving = false);
        context.showSnack(successMessage);
        // Education isn't an AppUser field — re-fetch /me to sync cache.
        context.read<AuthBloc>().add(const AuthRefreshUser());
      },
    );
  }

  Future<_EducationDraft?> _educationFormSheet(
    BuildContext context, {
    _EducationDraft? item,
  }) async {
    final draft = item == null ? _EducationDraft() : _EducationDraft.copy(item);
    String? errorMessage;
    var saving = false;
    final saved = await showModalBottomSheet<_EducationDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        final safeBottom = MediaQuery.of(sheetContext).padding.bottom;
        final sheetHeight = MediaQuery.of(sheetContext).size.height * 0.75;
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: SizedBox(
                height: sheetHeight,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSizes.lg,
                    AppSizes.sm,
                    AppSizes.lg,
                    bottomInset + safeBottom + AppSizes.lg,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item == null
                                    ? 'Add education'
                                    : 'Edit education',
                                style: Theme.of(
                                  sheetContext,
                                ).textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close',
                              onPressed: saving
                                  ? null
                                  : () => Navigator.of(sheetContext).pop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        if (errorMessage != null) ...[
                          AppSizes.vGapMd,
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMd,
                              ),
                              border: Border.all(
                                color: AppColors.danger.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSizes.md),
                              child: Text(
                                errorMessage!,
                                style: Theme.of(sheetContext)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.danger),
                              ),
                            ),
                          ),
                        ],
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: draft.institution,
                          label: 'Institution',
                          hint: 'Institution',
                          textInputAction: TextInputAction.next,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: draft.qualification,
                          label: 'Qualification',
                          hint: 'Qualification',
                          textInputAction: TextInputAction.next,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: draft.specialization,
                          label: 'Specialization',
                          hint: 'Specialization',
                          textInputAction: TextInputAction.next,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: draft.year,
                          label: 'Year',
                          hint: 'Year',
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: draft.score,
                          label: 'Score',
                          hint: 'Score',
                          textInputAction: TextInputAction.next,
                        ),
                        AppSizes.vGapMd,
                        _CertificateUploadButton(
                          fileName: draft.certificateName,
                          uploading: draft.uploadingCertificate,
                          showLabel: true,
                          onPressed: saving
                              ? null
                              : () => _pickCertificate(draft, setSheetState),
                        ),
                        AppSizes.vGapXl,
                        AppPrimaryButton(
                          label: item == null ? 'Add & save' : 'Save',
                          isLoading: saving,
                          onPressed: () {
                            if (draft.institution.text.trim().isEmpty) {
                              setSheetState(() {
                                errorMessage = 'Institution is required.';
                              });
                              return;
                            }
                            setSheetState(() {
                              saving = true;
                              errorMessage = null;
                            });
                            Navigator.of(sheetContext).pop(draft);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (saved == null) draft.dispose();
    return saved;
  }

  List<_EducationDraft> get _filteredItems {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return _items;
    return _items.where((item) => item.matches(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Education'),
        actions: [
          IconButton(
            tooltip: 'Add education',
            onPressed: _saving ? null : _addEducation,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              children: [
                AppCard(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 760;
                      final search = AppTextField(
                        controller: _search,
                        hint:
                            'Search institutions, degrees, specializations...',
                        prefixIcon: Icons.search_rounded,
                        onChanged: (_) => setState(() {}),
                      );
                      final actions = Wrap(
                        spacing: AppSizes.sm,
                        runSpacing: AppSizes.sm,
                        children: [
                          AppPrimaryButton(
                            label: 'Filters',
                            icon: Icons.filter_alt_outlined,
                            expanded: false,
                            gradient: false,
                            backgroundColor: AppColors.white,
                            textColor: AppColors.darkText,
                            onPressed: () => context.showSnack(
                              'Education filters coming soon',
                            ),
                          ),
                          AppPrimaryButton(
                            label: 'Export',
                            icon: Icons.download_rounded,
                            expanded: false,
                            gradient: false,
                            backgroundColor: AppColors.white,
                            textColor: AppColors.darkText,
                            onPressed: () => context.showSnack(
                              'Education export coming soon',
                            ),
                          ),
                          AppPrimaryButton(
                            label: 'Add education',
                            icon: Icons.add_rounded,
                            expanded: false,
                            onPressed: _saving ? null : _addEducation,
                          ),
                        ],
                      );

                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [search, AppSizes.vGapMd, actions],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: search),
                          AppSizes.hGapMd,
                          actions,
                        ],
                      );
                    },
                  ),
                ),
                AppSizes.vGapLg,
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Education records',
                        style: context.text.titleMedium,
                      ),
                      AppSizes.vGapXs,
                      Text(
                        'Synced to your freelancer profile',
                        style: context.text.bodySmall,
                      ),
                      if (_errorMessage != null) ...[
                        AppSizes.vGapMd,
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(
                              AppSizes.radiusMd,
                            ),
                            border: Border.all(
                              color: AppColors.danger.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSizes.md),
                            child: Text(
                              _errorMessage!,
                              style: context.text.bodySmall?.copyWith(
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ),
                      ],
                      AppSizes.vGapLg,
                      for (final item in _filteredItems) ...[
                        _EducationListCard(
                          item: item,
                          onEdit: _saving ? null : () => _editEducation(item),
                          onRemove: _saving
                              ? null
                              : () => _removeEducation(item),
                        ),
                        if (item != _filteredItems.last) AppSizes.vGapMd,
                      ],
                      if (_filteredItems.isEmpty)
                        const AppCard(
                          child: Text(
                            'No education records match your search.',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ignore: unused_element
class _EducationRecordForm extends StatelessWidget {
  const _EducationRecordForm({
    required this.item,
    required this.saving,
    required this.canRemove,
    required this.onChanged,
    required this.onPickCertificate,
    required this.onRemove,
  });

  final _EducationDraft item;
  final bool saving;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onPickCertificate;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 860;
          final institution = AppTextField(
            controller: item.institution,
            label: compact ? 'Institution' : null,
            hint: 'Institution',
            textInputAction: TextInputAction.next,
            onChanged: (_) => onChanged(),
          );
          final qualification = AppTextField(
            controller: item.qualification,
            label: compact ? 'Qualification' : null,
            hint: 'Qualification',
            textInputAction: TextInputAction.next,
            onChanged: (_) => onChanged(),
          );
          final specialization = AppTextField(
            controller: item.specialization,
            label: compact ? 'Specialization' : null,
            hint: 'Specialization',
            textInputAction: TextInputAction.next,
            onChanged: (_) => onChanged(),
          );
          final year = AppTextField(
            controller: item.year,
            label: compact ? 'Year' : null,
            hint: 'Year',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            onChanged: (_) => onChanged(),
          );
          final score = AppTextField(
            controller: item.score,
            label: compact ? 'Score' : null,
            hint: 'Score',
            textInputAction: TextInputAction.next,
            onChanged: (_) => onChanged(),
          );
          final certificate = _CertificateUploadButton(
            fileName: item.certificateName,
            uploading: item.uploadingCertificate,
            showLabel: compact,
            onPressed: saving ? null : onPickCertificate,
          );
          final remove = IconButton(
            tooltip: 'Remove',
            onPressed: saving || !canRemove ? null : onRemove,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.danger,
            ),
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                institution,
                AppSizes.vGapMd,
                qualification,
                AppSizes.vGapMd,
                specialization,
                AppSizes.vGapMd,
                Row(
                  children: [
                    Expanded(child: year),
                    AppSizes.hGapMd,
                    Expanded(child: score),
                  ],
                ),
                AppSizes.vGapMd,
                certificate,
                Align(alignment: Alignment.centerRight, child: remove),
              ],
            );
          }

          return Column(
            children: [
              Row(
                children: [
                  Expanded(flex: 3, child: _EducationHeader('Institution')),
                  AppSizes.hGapMd,
                  Expanded(flex: 2, child: _EducationHeader('Qualification')),
                  AppSizes.hGapMd,
                  Expanded(flex: 2, child: _EducationHeader('Specialization')),
                  AppSizes.hGapMd,
                  Expanded(child: _EducationHeader('Year')),
                  AppSizes.hGapMd,
                  Expanded(child: _EducationHeader('Score')),
                  AppSizes.hGapMd,
                  Expanded(flex: 2, child: _EducationHeader('Certificate')),
                  SizedBox(width: AppSizes.iconLg + AppSizes.md),
                ],
              ),
              AppSizes.vGapSm,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: institution),
                  AppSizes.hGapMd,
                  Expanded(flex: 2, child: qualification),
                  AppSizes.hGapMd,
                  Expanded(flex: 2, child: specialization),
                  AppSizes.hGapMd,
                  Expanded(child: year),
                  AppSizes.hGapMd,
                  Expanded(child: score),
                  AppSizes.hGapMd,
                  Expanded(flex: 2, child: certificate),
                  SizedBox(
                    width: AppSizes.iconLg + AppSizes.md,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: remove,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _EducationListCard extends StatelessWidget {
  const _EducationListCard({
    required this.item,
    required this.onEdit,
    required this.onRemove,
  });

  final _EducationDraft item;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      item.qualification.text.trim(),
      item.specialization.text.trim(),
      item.year.text.trim(),
      item.score.text.trim(),
    ].where((value) => value.isNotEmpty).join(' - ');

    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.school_outlined, color: AppColors.primary),
          AppSizes.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.institution.text.trim(),
                  style: context.text.titleSmall,
                ),
                if (subtitle.isNotEmpty) ...[
                  AppSizes.vGapXs,
                  Text(
                    subtitle,
                    style: context.text.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (item.certificateName?.trim().isNotEmpty == true) ...[
                  AppSizes.vGapSm,
                  Text(
                    item.certificateName!.trim(),
                    style: context.text.labelSmall,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete',
            onPressed: onRemove,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}

class _EducationHeader extends StatelessWidget {
  const _EducationHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: context.text.labelMedium?.copyWith(
        color: AppColors.mutedText,
        letterSpacing: 0,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _CertificateUploadButton extends StatelessWidget {
  const _CertificateUploadButton({
    required this.fileName,
    required this.uploading,
    required this.showLabel,
    required this.onPressed,
  });

  final String? fileName;
  final bool uploading;
  final bool showLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final label = fileName?.trim().isNotEmpty == true
        ? fileName!
        : 'Certificate';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text('Certificate', style: context.text.titleSmall),
          AppSizes.vGapSm,
        ],
        OutlinedButton.icon(
          onPressed: uploading ? null : onPressed,
          icon: uploading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file_outlined),
          label: Text(
            uploading ? 'Uploading...' : label,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _EducationDraft {
  _EducationDraft({
    String institution = '',
    String qualification = '',
    String specialization = '',
    String year = '',
    String score = '',
    this.certificateName,
    this.certificateUrl,
  }) : institution = TextEditingController(text: institution),
       qualification = TextEditingController(text: qualification),
       specialization = TextEditingController(text: specialization),
       year = TextEditingController(text: year),
       score = TextEditingController(text: score);

  factory _EducationDraft.copy(_EducationDraft item) => _EducationDraft(
    institution: item.institution.text,
    qualification: item.qualification.text,
    specialization: item.specialization.text,
    year: item.year.text,
    score: item.score.text,
    certificateName: item.certificateName,
    certificateUrl: item.certificateUrl,
  );

  final TextEditingController institution;
  final TextEditingController qualification;
  final TextEditingController specialization;
  final TextEditingController year;
  final TextEditingController score;
  String? certificateName;
  String? certificateUrl;
  bool uploadingCertificate = false;

  bool matches(String query) {
    return [
      institution.text,
      qualification.text,
      specialization.text,
      year.text,
      score.text,
    ].any((value) => value.toLowerCase().contains(query));
  }

  String toProfileValue() {
    final parts = <String>[
      institution.text.trim(),
      if (qualification.text.trim().isNotEmpty)
        '- ${qualification.text.trim()}',
      if (specialization.text.trim().isNotEmpty)
        '- ${specialization.text.trim()}',
      if (year.text.trim().isNotEmpty) '- ${year.text.trim()}',
      if (score.text.trim().isNotEmpty) '- ${score.text.trim()}',
      if (certificateUrl?.trim().isNotEmpty == true)
        '- ${certificateUrl!.trim()}',
    ];
    return parts.join(' ').trim();
  }

  void dispose() {
    institution.dispose();
    qualification.dispose();
    specialization.dispose();
    year.dispose();
    score.dispose();
  }
}

class FreelancerPortfolioPage extends StatefulWidget {
  const FreelancerPortfolioPage({
    super.key,
    this.freelancerId,
    this.isReadOnly = false,
  });

  final String? freelancerId;
  final bool isReadOnly;

  @override
  State<FreelancerPortfolioPage> createState() =>
      _FreelancerPortfolioPageState();
}

class _FreelancerPortfolioPageState extends State<FreelancerPortfolioPage> {
  int _listKey = 0;

  void _reload() => setState(() => _listKey++);

  @override
  Widget build(BuildContext context) {
    final isReadOnly =
        widget.isReadOnly ||
        (widget.freelancerId != null && widget.freelancerId!.isNotEmpty);

    return _ListScaffold(
      title: isReadOnly ? 'Freelancer Portfolio' : 'Portfolio',
      child: CatalogView<PortfolioItem>(
        key: ValueKey(_listKey),
        fetcher: (q) => sl<PortfolioRepository>().getPortfolio(
          q,
          freelancerId: widget.freelancerId,
        ),
        searchHint: 'Search portfolio',
        emptyTitle: 'No portfolio items yet',
        emptyMessage: isReadOnly
            ? 'This freelancer has not added any portfolio items yet.'
            : 'Add your best work so clients can see what you deliver.',
        floatingActionButton: isReadOnly
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _openAdd(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Portfolio'),
              ),
        itemBuilder: (context, item, __) => _PortfolioCard(
          item: item,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FreelancerPortfolioDetailsPage(
                id: item.id,
                freelancerId: widget.freelancerId,
                isReadOnly: isReadOnly,
              ),
            ),
          ),
          onEdit: isReadOnly ? null : () => _openEdit(context, item.id),
          onDelete: isReadOnly ? null : () => _deletePortfolio(context, item),
        ),
      ),
    );
  }

  Future<void> _openAdd(BuildContext context) async {
    final changed = await context.push<bool>(Routes.freelancerPortfolioForm);
    if (!context.mounted || changed != true) return;
    _reload();
  }

  Future<void> _openEdit(BuildContext context, String id) async {
    final res = await sl<PortfolioRepository>().getPortfolioItem(id);
    if (!context.mounted) return;
    final item = res.valueOrNull;
    if (item == null) {
      context.showSnack(
        res.failureOrNull?.message ?? 'Unable to load portfolio item',
        isError: true,
      );
      return;
    }
    final changed = await context.push<bool>(
      Routes.freelancerPortfolioForm,
      extra: item,
    );
    if (!context.mounted || changed != true) return;
    _reload();
  }

  Future<void> _deletePortfolio(
    BuildContext context,
    PortfolioItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete portfolio item?'),
        content: Text('This will remove "${item.title}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final res = await sl<PortfolioRepository>().deletePortfolio(item.id);
    if (!context.mounted) return;
    res.fold((f) => context.showSnack(f.message, isError: true), (message) {
      context.showSnack(message);
      _reload();
    });
  }
}

class FreelancerPortfolioDetailsPage extends StatefulWidget {
  const FreelancerPortfolioDetailsPage({
    super.key,
    required this.id,
    this.freelancerId,
    this.isReadOnly = false,
  });

  final String id;
  final String? freelancerId;
  final bool isReadOnly;

  @override
  State<FreelancerPortfolioDetailsPage> createState() =>
      _FreelancerPortfolioDetailsPageState();
}

class _FreelancerPortfolioDetailsPageState
    extends State<FreelancerPortfolioDetailsPage> {
  late Future<Result<PortfolioItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = sl<PortfolioRepository>().getPortfolioItem(
      widget.id,
      freelancerId: widget.freelancerId,
    );
  }

  void _refresh() {
    setState(() {
      _future = sl<PortfolioRepository>().getPortfolioItem(
        widget.id,
        freelancerId: widget.freelancerId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
        title: const Text('Portfolio Details'),
      ),
      body: FutureBuilder<Result<PortfolioItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final result = snapshot.data!;
          final item = result.valueOrNull;
          if (item == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Text(
                  result.failureOrNull?.message ??
                      'Unable to load portfolio item',
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: context.text.titleLarge,
                            ),
                          ),
                          if (!widget.isReadOnly)
                            IconButton(
                              tooltip: 'Edit',
                              onPressed: () async {
                                final changed = await context.push<bool>(
                                  Routes.freelancerPortfolioForm,
                                  extra: item,
                                );
                                if (!context.mounted || changed != true) return;
                                _refresh();
                              },
                              icon: const Icon(Icons.edit_outlined),
                            ),
                        ],
                      ),
                      if (item.status.isNotEmpty) ...[
                        AppSizes.vGapSm,
                        AppStatusChip(label: item.status, dense: true),
                      ],
                      if (item.displayDescription.isNotEmpty) ...[
                        AppSizes.vGapLg,
                        Text(
                          item.displayDescription,
                          style: context.text.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                AppSizes.vGapMd,
                _PortfolioInfoCard(
                  title: 'Project',
                  rows: [
                    ('Industry', item.industry),
                    ('Industry ID', item.industryId),
                    ('Category', item.category),
                    ('Category ID', item.categoryId),
                    ('Client', item.client),
                    ('Duration', item.duration),
                    ('Team Size', item.teamSize),
                    ('Team Size ID', item.teamSizeId),
                    ('Role', item.role),
                  ],
                ),
                AppSizes.vGapMd,
                _PortfolioInfoCard(
                  title: 'Links & Media',
                  rows: [
                    ('GitHub URL', item.githubUrl),
                    ('Live URL', item.liveUrl),
                    ('Cover Media', item.coverMedia),
                    ('Video Demo', item.videoDemo),
                    ('PDF Case Study', item.pdfCaseStudy),
                    ('Extra Screenshot', item.extraScreenshot),
                  ],
                ),
                if (item.videoDemo.trim().isNotEmpty) ...[
                  AppSizes.vGapMd,
                  _PortfolioVideoPreview(source: item.videoDemo.trim()),
                ],
                if (item.displaySkillNames.isNotEmpty) ...[
                  AppSizes.vGapMd,
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Skills', style: context.text.titleSmall),
                        AppSizes.vGapMd,
                        Wrap(
                          spacing: AppSizes.sm,
                          runSpacing: AppSizes.sm,
                          children: [
                            for (final skill in item.skills)
                              Chip(
                                label: Text(
                                  skill.skillId.isEmpty
                                      ? skill.skillName
                                      : '${skill.skillName} (${skill.skillId})',
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            if (item.skills.isEmpty)
                              for (final skill in item.technologies)
                                Chip(
                                  label: Text(skill),
                                  visualDensity: VisualDensity.compact,
                                ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class FreelancerPortfolioFormPage extends StatefulWidget {
  const FreelancerPortfolioFormPage({super.key, this.item});

  final PortfolioItem? item;

  @override
  State<FreelancerPortfolioFormPage> createState() =>
      _FreelancerPortfolioFormPageState();
}

class _FreelancerPortfolioFormPageState
    extends State<FreelancerPortfolioFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _client;
  late final TextEditingController _duration;
  late final TextEditingController _role;
  late final TextEditingController _githubUrl;
  late final TextEditingController _liveUrl;
  late final TextEditingController _overview;
  late final TextEditingController _coverMedia;
  late final TextEditingController _videoDemo;
  late final TextEditingController _pdfCaseStudy;
  late final TextEditingController _extraScreenshot;
  final _statuses = const [
    'Published',
    'Featured',
    'Case Study',
    'Draft',
    'Archived',
  ];
  late String _status;
  bool _saving = false;
  bool _loadingIndustries = false;
  bool _loadingCategories = false;
  bool _loadingSkills = false;
  bool _loadingTeamSizes = false;
  List<_PortfolioOption> _industryOptions = const [];
  List<_PortfolioOption> _categoryOptions = const [];
  List<_PortfolioOption> _skillOptions = const [];
  List<_PortfolioOption> _teamSizeOptions = const [];
  _PortfolioOption? _selectedIndustry;
  _PortfolioOption? _selectedCategory;
  _PortfolioOption? _selectedTeamSize;
  final Map<String, String> _selectedSkillsById = {};
  String? _coverFileName;
  String? _videoFileName;
  String? _caseStudyFileName;
  String? _screenshotFileName;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _title = TextEditingController(text: item?.title ?? '');
    _description = TextEditingController(text: item?.description ?? '');
    _client = TextEditingController(text: item?.client ?? '');
    _duration = TextEditingController(text: item?.duration ?? '');
    _role = TextEditingController(text: item?.role ?? '');
    _githubUrl = TextEditingController(text: item?.githubUrl ?? '');
    _liveUrl = TextEditingController(text: item?.liveUrl ?? '');
    _overview = TextEditingController(text: item?.overview ?? '');
    _coverMedia = TextEditingController(text: item?.coverMedia ?? '');
    _videoDemo = TextEditingController(text: item?.videoDemo ?? '');
    _pdfCaseStudy = TextEditingController(text: item?.pdfCaseStudy ?? '');
    _extraScreenshot = TextEditingController(text: item?.extraScreenshot ?? '');
    _status = _statuses.contains(item?.status) ? item!.status : _statuses.first;
    if (item != null) {
      _selectedIndustry = _PortfolioOption(
        id: item.industryId,
        label: item.industry,
      );
      _selectedCategory = _PortfolioOption(
        id: item.categoryId,
        label: item.category,
      );
      _selectedTeamSize = _PortfolioOption(
        id: item.teamSizeId,
        label: item.teamSize,
      );
      for (final skill in item.skills) {
        if (skill.skillId.isNotEmpty) {
          _selectedSkillsById[skill.skillId] = skill.skillName;
        }
      }
    }
    _loadInitialOptions();
  }

  Future<void> _loadInitialOptions() async {
    await Future.wait([_loadIndustries(), _loadTeamSizes()]);
    final industry = _selectedIndustry;
    if (industry != null && industry.id.isNotEmpty) {
      await _loadCategories(industry.id);
    }
    final category = _selectedCategory;
    if (category != null && category.id.isNotEmpty) {
      await _loadSkills(category.id);
    }
  }

  Future<List<_PortfolioOption>> _loadOptions(
    String endpoint, {
    Map<String, dynamic>? query,
    String? baseUrl,
  }) async {
    final host = baseUrl ?? AppConfig.baseUrl;
    final response = await Dio().get('$host$endpoint', queryParameters: query);
    final raw = response.data is Map<String, dynamic>
        ? (response.data as Map<String, dynamic>)['data']
        : null;
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .where((item) => item['status'] == null || item['status'] == 'active')
        .map(
          (item) => _PortfolioOption.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.id.isNotEmpty && item.label.isNotEmpty)
        .toList();
  }

  Future<void> _loadIndustries() async {
    setState(() => _loadingIndustries = true);
    try {
      final items = await _loadOptions(ApiEndpoints.publicIndustries);
      if (!mounted) return;
      setState(() {
        _industryOptions = _mergeSelected(items, _selectedIndustry);
        _loadingIndustries = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingIndustries = false);
    }
  }

  Future<void> _loadCategories(String industryId) async {
    setState(() => _loadingCategories = true);
    try {
      final items = await _loadOptions(
        ApiEndpoints.publicCategories,
        query: {
          'industryId': industryId,
          'page': 1,
          'limit': 50,
          'pageSize': 50,
        },
      );
      if (!mounted) return;
      setState(() {
        _categoryOptions = _mergeSelected(items, _selectedCategory);
        _loadingCategories = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _loadSkills(String categoryId) async {
    setState(() => _loadingSkills = true);
    try {
      final items = await _loadOptions(
        ApiEndpoints.publicSkills,
        query: {
          'page': 1,
          'limit': 100,
          'pageSize': 100,
        },
      );
      if (!mounted) return;
      setState(() {
        _skillOptions = items;
        for (final selected in _selectedSkillsById.entries) {
          if (!_skillOptions.any((skill) => skill.id == selected.key)) {
            _skillOptions = [
              ..._skillOptions,
              _PortfolioOption(id: selected.key, label: selected.value),
            ];
          }
        }
        _loadingSkills = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingSkills = false);
    }
  }

  Future<void> _loadTeamSizes() async {
    setState(() => _loadingTeamSizes = true);
    try {
      final items = await _loadOptions(ApiEndpoints.publicTeamSizes);
      if (!mounted) return;
      setState(() {
        _teamSizeOptions = _mergeSelected(items, _selectedTeamSize);
        _loadingTeamSizes = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingTeamSizes = false);
    }
  }

  List<_PortfolioOption> _mergeSelected(
    List<_PortfolioOption> items,
    _PortfolioOption? selected,
  ) {
    if (selected == null || selected.id.isEmpty) return items;
    if (items.any((item) => item.id == selected.id)) return items;
    return [...items, selected];
  }

  void _onIndustryChanged(_PortfolioOption? value) {
    setState(() {
      _selectedIndustry = value;
      _selectedCategory = null;
      _categoryOptions = const [];
      _skillOptions = const [];
      _selectedSkillsById.clear();
    });
    if (value != null) _loadCategories(value.id);
  }

  void _onCategoryChanged(_PortfolioOption? value) {
    setState(() {
      _selectedCategory = value;
      _skillOptions = const [];
      _selectedSkillsById.clear();
    });
    if (value != null) _loadSkills(value.id);
  }

  void _toggleSkill(_PortfolioOption skill) {
    setState(() {
      if (_selectedSkillsById.containsKey(skill.id)) {
        _selectedSkillsById.remove(skill.id);
      } else {
        _selectedSkillsById[skill.id] = skill.label;
      }
    });
  }

  Future<void> _pickMedia(
    TextEditingController controller,
    _PortfolioMediaKind kind,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: switch (kind) {
        _PortfolioMediaKind.video => FileType.video,
        _PortfolioMediaKind.caseStudy => FileType.custom,
        _PortfolioMediaKind.cover ||
        _PortfolioMediaKind.screenshot => FileType.image,
      },
      allowedExtensions: kind == _PortfolioMediaKind.caseStudy
          ? const ['pdf']
          : null,
    );
    final file = result?.files.single;
    if (file == null) return;
    final value = file.path?.trim().isNotEmpty == true ? file.path! : file.name;
    setState(() {
      controller.text = value;
      switch (kind) {
        case _PortfolioMediaKind.cover:
          _coverFileName = file.name;
        case _PortfolioMediaKind.video:
          _videoFileName = file.name;
        case _PortfolioMediaKind.caseStudy:
          _caseStudyFileName = file.name;
        case _PortfolioMediaKind.screenshot:
          _screenshotFileName = file.name;
      }
    });
  }

  void _clearMedia(TextEditingController controller, _PortfolioMediaKind kind) {
    setState(() {
      controller.clear();
      switch (kind) {
        case _PortfolioMediaKind.cover:
          _coverFileName = null;
        case _PortfolioMediaKind.video:
          _videoFileName = null;
        case _PortfolioMediaKind.caseStudy:
          _caseStudyFileName = null;
        case _PortfolioMediaKind.screenshot:
          _screenshotFileName = null;
      }
    });
  }

  final _scrollCtrl = ScrollController();
  final _titleFocus = FocusNode();
  final _liveUrlFocus = FocusNode();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _titleFocus.dispose();
    _liveUrlFocus.dispose();
    _title.dispose();
    _description.dispose();
    _client.dispose();
    _duration.dispose();
    _role.dispose();
    _githubUrl.dispose();
    _liveUrl.dispose();
    _overview.dispose();
    _coverMedia.dispose();
    _videoDemo.dispose();
    _pdfCaseStudy.dispose();
    _extraScreenshot.dispose();
    super.dispose();
  }

  void _scrollTo(double offset) {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        offset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
        title: Text(_isEdit ? 'Edit Portfolio' : 'New Portfolio'),
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          controller: _scrollCtrl,
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          children: [
            AppCard(
              child: Column(
                children: [
                  AppTextField(
                    controller: _title,
                    focusNode: _titleFocus,
                    label: 'Title *',
                    hint: 'LMS Platform Development',
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Title is required'
                        : null,
                  ),
                  AppSizes.vGapMd,
                  AppTextField(
                    controller: _description,
                    label: 'Description *',
                    hint: 'Short project description',
                    maxLines: 3,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Description is required'
                        : null,
                  ),
                  AppSizes.vGapMd,
                  AppDropdown<String>(
                    label: 'Status *',
                    hint: 'Select status',
                    value: _status,
                    items: _statuses,
                    itemLabel: (item) => item,
                    onChanged: _saving
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() => _status = value);
                          },
                  ),
                ],
              ),
            ),
            AppSizes.vGapMd,
            AppCard(
              child: Column(
                children: [
                  if (_loadingIndustries)
                    const LinearProgressIndicator(minHeight: 2)
                  else
                    AppDropdown<_PortfolioOption>(
                      label: 'Industry *',
                      hint: 'Select industry',
                      value: _industryOptions.contains(_selectedIndustry)
                          ? _selectedIndustry
                          : null,
                      items: _industryOptions,
                      itemLabel: (item) => item.label,
                      onChanged: _saving ? null : _onIndustryChanged,
                    ),
                  AppSizes.vGapMd,
                  if (_loadingCategories)
                    const LinearProgressIndicator(minHeight: 2)
                  else
                    AppDropdown<_PortfolioOption>(
                      label: 'Category *',
                      hint: _selectedIndustry == null
                          ? 'Select industry first'
                          : 'Select category',
                      value: _categoryOptions.contains(_selectedCategory)
                          ? _selectedCategory
                          : null,
                      items: _categoryOptions,
                      itemLabel: (item) => item.label,
                      onChanged: _saving || _selectedIndustry == null
                          ? null
                          : _onCategoryChanged,
                    ),
                  AppSizes.vGapMd,
                  _PortfolioSkillPicker(
                    loading: _loadingSkills,
                    options: _skillOptions,
                    selectedIds: _selectedSkillsById.keys.toSet(),
                    onToggle: _saving ? null : _toggleSkill,
                  ),
                ],
              ),
            ),
            AppSizes.vGapMd,
            AppCard(
              child: Column(
                children: [
                  AppTextField(
                    controller: _client,
                    label: 'Client *',
                    hint: 'e.g. Acme Corp / Self-Initiated',
                    validator: (v) => v == null || v.trim().isEmpty ? 'Client name is required' : null,
                  ),
                  AppSizes.vGapMd,
                  AppTextField(
                    controller: _duration,
                    label: 'Duration *',
                    hint: 'e.g. 3 Months / Jan 2024 - Apr 2024',
                    validator: (v) => v == null || v.trim().isEmpty ? 'Duration is required' : null,
                  ),
                  AppSizes.vGapMd,
                  if (_loadingTeamSizes)
                    const LinearProgressIndicator(minHeight: 2)
                  else
                    AppDropdown<_PortfolioOption>(
                      label: 'Team Size *',
                      hint: 'Select team size',
                      value: _teamSizeOptions.contains(_selectedTeamSize)
                          ? _selectedTeamSize
                          : null,
                      items: _teamSizeOptions,
                      itemLabel: (item) => item.label,
                      onChanged: _saving
                          ? null
                          : (value) =>
                                setState(() => _selectedTeamSize = value),
                    ),
                  AppSizes.vGapMd,
                  AppTextField(
                    controller: _role,
                    label: 'Role *',
                    hint: 'e.g. Lead Mobile Developer',
                    validator: (v) => v == null || v.trim().isEmpty ? 'Role is required' : null,
                  ),
                  AppSizes.vGapMd,
                  AppTextField(
                    controller: _overview,
                    label: 'Overview *',
                    hint: 'Detailed overview of goals, architecture, and tech stack',
                    maxLines: 4,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Overview is required' : null,
                  ),
                ],
              ),
            ),
            AppSizes.vGapMd,
            AppCard(
              child: Column(
                children: [
                  _PortfolioUploadTile(
                    label: 'Cover Image *',
                    hint: 'Upload JPG, PNG, or WebP',
                    source: _coverMedia.text,
                    fileName: _coverFileName ?? _fileLabel(_coverMedia.text),
                    icon: Icons.image_outlined,
                    onClear: _saving
                        ? null
                        : () => _clearMedia(
                            _coverMedia,
                            _PortfolioMediaKind.cover,
                          ),
                    onTap: _saving
                        ? null
                        : () => _pickMedia(
                            _coverMedia,
                            _PortfolioMediaKind.cover,
                          ),
                  ),
                  AppSizes.vGapMd,
                  _PortfolioUploadTile(
                    label: 'Video Demo',
                    hint: 'Upload MP4 or MOV',
                    source: _videoDemo.text,
                    fileName: _videoFileName ?? _fileLabel(_videoDemo.text),
                    icon: Icons.video_library_outlined,
                    onClear: _saving
                        ? null
                        : () => _clearMedia(
                            _videoDemo,
                            _PortfolioMediaKind.video,
                          ),
                    onTap: _saving
                        ? null
                        : () =>
                              _pickMedia(_videoDemo, _PortfolioMediaKind.video),
                  ),
                  if (_videoDemo.text.trim().isNotEmpty) ...[
                    AppSizes.vGapMd,
                    _PortfolioVideoPreview(source: _videoDemo.text.trim()),
                  ],
                  AppSizes.vGapMd,
                  _PortfolioUploadTile(
                    label: 'PDF Case Study',
                    hint: 'Upload PDF',
                    source: _pdfCaseStudy.text,
                    fileName:
                        _caseStudyFileName ?? _fileLabel(_pdfCaseStudy.text),
                    icon: Icons.picture_as_pdf_outlined,
                    onClear: _saving
                        ? null
                        : () => _clearMedia(
                            _pdfCaseStudy,
                            _PortfolioMediaKind.caseStudy,
                          ),
                    onTap: _saving
                        ? null
                        : () => _pickMedia(
                            _pdfCaseStudy,
                            _PortfolioMediaKind.caseStudy,
                          ),
                  ),
                  AppSizes.vGapMd,
                  _PortfolioUploadTile(
                    label: 'Extra Screenshot',
                    hint: 'Upload JPG, PNG, or WebP',
                    source: _extraScreenshot.text,
                    fileName:
                        _screenshotFileName ??
                        _fileLabel(_extraScreenshot.text),
                    icon: Icons.add_photo_alternate_outlined,
                    onClear: _saving
                        ? null
                        : () => _clearMedia(
                            _extraScreenshot,
                            _PortfolioMediaKind.screenshot,
                          ),
                    onTap: _saving
                        ? null
                        : () => _pickMedia(
                            _extraScreenshot,
                            _PortfolioMediaKind.screenshot,
                          ),
                  ),
                  AppSizes.vGapLg,
                  AppTextField(
                    controller: _liveUrl,
                    focusNode: _liveUrlFocus,
                    label: 'Live URL / Project Link *',
                    hint: 'https://myproject.com',
                    keyboardType: TextInputType.url,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Live URL is required';
                      final uri = Uri.tryParse(v.trim());
                      if (uri == null || (!v.trim().startsWith('http://') && !v.trim().startsWith('https://'))) {
                        return 'Enter a valid URL (starting with http:// or https://)';
                      }
                      return null;
                    },
                  ),
                  AppSizes.vGapMd,
                  AppTextField(
                    controller: _githubUrl,
                    label: 'GitHub URL',
                    hint: 'https://github.com/username/repo',
                    keyboardType: TextInputType.url,
                  ),
                ],
              ),
            ),
            AppSizes.vGapXl,
            AppPrimaryButton(
              label: _isEdit ? 'Update Portfolio' : 'Add Portfolio',
              isLoading: _saving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    // 1. Title
    if (_title.text.trim().isEmpty) {
      _formKey.currentState?.validate();
      _scrollTo(0);
      _titleFocus.requestFocus();
      context.showSnack('Please enter a Title *', isError: true);
      return;
    }

    // 2. Description
    if (_description.text.trim().isEmpty) {
      _formKey.currentState?.validate();
      _scrollTo(0);
      context.showSnack('Please enter a Description *', isError: true);
      return;
    }

    // 3. Industry
    if (_selectedIndustry == null || _selectedIndustry!.id.isEmpty) {
      _formKey.currentState?.validate();
      _scrollTo(150);
      context.showSnack('Please select an Industry *', isError: true);
      return;
    }

    // 4. Category
    if (_selectedCategory == null || _selectedCategory!.id.isEmpty) {
      _formKey.currentState?.validate();
      _scrollTo(220);
      context.showSnack('Please select a Category *', isError: true);
      return;
    }

    // 5. Skills
    if (_selectedSkillsById.isEmpty) {
      _formKey.currentState?.validate();
      _scrollTo(300);
      context.showSnack('Please select at least one Skill *', isError: true);
      return;
    }

    // 6. Client
    if (_client.text.trim().isEmpty) {
      _formKey.currentState?.validate();
      _scrollTo(380);
      context.showSnack('Please enter a Client *', isError: true);
      return;
    }

    // 7. Duration
    if (_duration.text.trim().isEmpty) {
      _formKey.currentState?.validate();
      _scrollTo(450);
      context.showSnack('Please enter Duration *', isError: true);
      return;
    }

    // 8. Team Size
    if (_selectedTeamSize == null || _selectedTeamSize!.id.isEmpty) {
      _formKey.currentState?.validate();
      _scrollTo(500);
      context.showSnack('Please select a Team Size *', isError: true);
      return;
    }

    // 9. Role
    if (_role.text.trim().isEmpty) {
      _formKey.currentState?.validate();
      _scrollTo(550);
      context.showSnack('Please enter a Role *', isError: true);
      return;
    }

    // 10. Overview
    if (_overview.text.trim().isEmpty) {
      _formKey.currentState?.validate();
      _scrollTo(600);
      context.showSnack('Please enter an Overview *', isError: true);
      return;
    }

    // 11. Cover Media
    if (_coverMedia.text.trim().isEmpty) {
      _formKey.currentState?.validate();
      _scrollTo(700);
      context.showSnack('Please upload a Cover Image *', isError: true);
      return;
    }

    // 12. Live URL
    final liveUrl = _liveUrl.text.trim();
    if (liveUrl.isEmpty) {
      _formKey.currentState?.validate();
      _scrollTo(900);
      _liveUrlFocus.requestFocus();
      context.showSnack('Please enter a Live URL / Project Link *', isError: true);
      return;
    }
    if (!liveUrl.startsWith('http://') && !liveUrl.startsWith('https://')) {
      _formKey.currentState?.validate();
      _scrollTo(900);
      _liveUrlFocus.requestFocus();
      context.showSnack('Live URL must start with http:// or https://', isError: true);
      return;
    }

    if (!_formKey.currentState!.validate()) {
      _scrollTo(0);
      return;
    }

    setState(() => _saving = true);
    final payload = _payload();
    final repo = sl<PortfolioRepository>();
    final result = _isEdit
        ? await repo.updatePortfolio(widget.item!.id, payload)
        : await repo.addPortfolio(payload);
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold((f) => context.showSnack(f.message, isError: true), (saved) {
      context.showSnack(
        saved.responseMessage ??
            (_isEdit ? 'Portfolio updated' : 'Portfolio added'),
      );
      context.pop(true);
    });
  }

  Map<String, dynamic> _payload() => {
    'title': _title.text.trim(),
    'description': _description.text.trim(),
    'industry': _selectedIndustry?.label ?? '',
    'industryId': _selectedIndustry?.id ?? '',
    'category': _selectedCategory?.label ?? '',
    'categoryId': _selectedCategory?.id ?? '',
    'skills': _selectedSkillsById.entries
        .map((entry) => {'skillId': entry.key, 'skillName': entry.value})
        .toList(),
    'status': _status,
    'client': _client.text.trim(),
    'duration': _duration.text.trim(),
    'teamSize': _selectedTeamSize?.label ?? '',
    'teamSizeId': _selectedTeamSize?.id ?? '',
    'role': _role.text.trim(),
    'githubUrl': _githubUrl.text.trim(),
    'liveUrl': _liveUrl.text.trim(),
    'projectUrl': _liveUrl.text.trim(),
    'overview': _overview.text.trim(),
    'coverMedia': _coverMedia.text.trim(),
    'videoDemo': _videoDemo.text.trim(),
    'pdfCaseStudy': _pdfCaseStudy.text.trim(),
    'extraScreenshot': _extraScreenshot.text.trim(),
  };
}

class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({
    required this.item,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final PortfolioItem item;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final skills = item.displaySkillNames;
    final visibleSkills = skills.take(3).toList();
    final remainingSkills = skills.length - visibleSkills.length;
    final cover = item.coverMedia.trim().isNotEmpty
        ? item.coverMedia.trim()
        : item.extraScreenshot.trim();
    final meta = [
      if (item.industry.trim().isNotEmpty) item.industry.trim(),
      if (item.category.trim().isNotEmpty) item.category.trim(),
    ];

    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      radius: AppSizes.radiusXl,
      child: IntrinsicHeight(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 174),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 132,
                child: _PortfolioCardMedia(
                  source: cover,
                  status: item.status,
                  category: item.category,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.md,
                    AppSizes.md,
                    AppSizes.sm,
                    AppSizes.md,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                height: 1.18,
                              ),
                            ),
                          ),
                          if (onEdit != null) ...[
                            const SizedBox(width: AppSizes.xs),
                            _PortfolioActionButton(
                              tooltip: 'Edit',
                              icon: Icons.edit_outlined,
                              onPressed: onEdit!,
                            ),
                          ],
                          if (onDelete != null) ...[
                            const SizedBox(width: AppSizes.xs),
                            _PortfolioActionButton(
                              tooltip: 'Delete',
                              icon: Icons.delete_outline_rounded,
                              color: AppColors.danger,
                              onPressed: onDelete!,
                            ),
                          ],
                        ],
                      ),
                      if (item.displayDescription.isNotEmpty) ...[
                        AppSizes.vGapXs,
                        Text(
                          item.displayDescription,
                          style: context.text.bodySmall?.copyWith(
                            color: AppColors.mutedText,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (meta.isNotEmpty) ...[
                        AppSizes.vGapSm,
                        Wrap(
                          spacing: AppSizes.xs,
                          runSpacing: AppSizes.xs,
                          children: [
                            for (final value in meta.take(2))
                              _PortfolioMetaPill(
                                label: value,
                                icon: value == item.industry
                                    ? Icons.business_center_outlined
                                    : Icons.category_outlined,
                              ),
                          ],
                        ),
                      ],
                      if (visibleSkills.isNotEmpty) ...[
                        AppSizes.vGapSm,
                        Wrap(
                          spacing: AppSizes.xs,
                          runSpacing: AppSizes.xs,
                          children: [
                            for (final skill in visibleSkills)
                              _PortfolioSkillPill(label: skill),
                            if (remainingSkills > 0)
                              _PortfolioSkillPill(
                                label: '+$remainingSkills more',
                                strong: true,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortfolioCardMedia extends StatelessWidget {
  const _PortfolioCardMedia({
    required this.source,
    required this.status,
    required this.category,
  });

  final String source;
  final String status;
  final String category;

  @override
  Widget build(BuildContext context) {
    final hasImage = _isImageSource(source);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasImage)
          _PortfolioCardImage(source: source)
        else
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.primary.withValues(alpha: 0.03),
                  AppColors.warning.withValues(alpha: 0.10),
                ],
              ),
            ),
            child: Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryBlack.withValues(alpha: 0.08),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.business_center_outlined,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: hasImage ? 0.10 : 0),
                Colors.black.withValues(alpha: hasImage ? 0.42 : 0),
              ],
            ),
          ),
        ),
        if (status.trim().isNotEmpty)
          Positioned(
            left: AppSizes.sm,
            top: AppSizes.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.sm,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: hasImage
                    ? Colors.white.withValues(alpha: 0.92)
                    : AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppSizes.radiusPill),
              ),
              child: Text(
                status,
                style: context.text.labelSmall?.copyWith(
                  color: hasImage ? AppColors.primaryBlack : AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        if (category.trim().isNotEmpty)
          Positioned(
            left: AppSizes.sm,
            right: AppSizes.sm,
            bottom: AppSizes.sm,
            child: Center(
              child: Text(
                category,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleSmall?.copyWith(
                  color: hasImage ? Colors.white : AppColors.primaryBlack,
                  fontWeight: FontWeight.w800,
                  shadows: hasImage
                      ? const [Shadow(color: Colors.black54, blurRadius: 8)]
                      : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _PortfolioActionButton extends StatelessWidget {
  const _PortfolioActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color = AppColors.primaryBlack,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 34,
      height: 34,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        icon: Icon(icon, size: 19, color: color),
        style: IconButton.styleFrom(
          backgroundColor: AppColors.primaryBlack.withValues(alpha: 0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          ),
        ),
      ),
    );
  }
}

class _PortfolioCardImage extends StatelessWidget {
  const _PortfolioCardImage({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(source);
    if (uri != null && uri.hasScheme) {
      return CustomCachedImage(imageUrl: source, fit: BoxFit.cover);
    }
    return Image.file(
      File(source),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Center(child: Icon(Icons.image_not_supported_outlined)),
    );
  }
}

class _PortfolioMetaPill extends StatelessWidget {
  const _PortfolioMetaPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: AppSizes.xs),
          Text(
            label,
            style: context.text.labelSmall?.copyWith(
              color: AppColors.primaryBlack,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioSkillPill extends StatelessWidget {
  const _PortfolioSkillPill({required this.label, this.strong = false});

  final String label;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 6),
      decoration: BoxDecoration(
        color: (strong ? AppColors.primary : AppColors.success).withValues(
          alpha: strong ? 0.10 : 0.08,
        ),
        borderRadius: BorderRadius.circular(AppSizes.radiusPill),
        border: Border.all(
          color: (strong ? AppColors.primary : AppColors.success).withValues(
            alpha: strong ? 0.22 : 0.16,
          ),
        ),
      ),
      child: Text(
        label,
        style: context.text.labelSmall?.copyWith(
          color: AppColors.primaryBlack,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PortfolioInfoCard extends StatelessWidget {
  const _PortfolioInfoCard({required this.title, required this.rows});

  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final visible = rows.where((row) => row.$2.trim().isNotEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.text.titleSmall),
          AppSizes.vGapMd,
          for (final row in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSizes.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      row.$1,
                      style: context.text.labelMedium?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                  ),
                  Expanded(child: Text(row.$2, style: context.text.bodySmall)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PortfolioSkillPicker extends StatelessWidget {
  const _PortfolioSkillPicker({
    required this.loading,
    required this.options,
    required this.selectedIds,
    required this.onToggle,
  });

  final bool loading;
  final List<_PortfolioOption> options;
  final Set<String> selectedIds;
  final ValueChanged<_PortfolioOption>? onToggle;

  void _showBottomSheet(BuildContext context) {
    if (onToggle == null) return;
    if (options.isEmpty) {
      context.showSnack('Please select a category first to load skills');
      return;
    }
    final searchController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final query = searchController.text.trim().toLowerCase();
            final filtered = query.isEmpty
                ? options
                : options
                    .where((opt) => opt.label.toLowerCase().contains(query))
                    .toList();

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.75,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.screenPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Skills (${selectedIds.length})',
                            style: context.text.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Done',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      AppSizes.vGapSm,
                      AppTextField(
                        controller: searchController,
                        hint: 'Search skills…',
                        prefixIcon: Icons.search_rounded,
                        onChanged: (_) => setSheetState(() {}),
                      ),
                      AppSizes.vGapMd,
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Text(
                                  'No skills found',
                                  style: context.text.bodyMedium?.copyWith(
                                    color: AppColors.mutedText,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final option = filtered[index];
                                  final isSelected = selectedIds.contains(
                                    option.id,
                                  );
                                  return CheckboxListTile(
                                    title: Text(
                                      option.label,
                                      style: context.text.bodyMedium?.copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    value: isSelected,
                                    activeColor: AppColors.primary,
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity:
                                        ListTileControlAffinity.trailing,
                                    onChanged: (_) {
                                      onToggle!(option);
                                      setSheetState(() {});
                                    },
                                  );
                                },
                              ),
                      ),
                      AppSizes.vGapMd,
                      AppPrimaryButton(
                        label: 'Done (${selectedIds.length} selected)',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      AppSizes.vGapLg,
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const LinearProgressIndicator(minHeight: 2);
    final selectedOptions = options
        .where((opt) => selectedIds.contains(opt.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Skills', style: context.text.titleSmall),
            Text(
              '${selectedIds.length} Selected',
              style: context.text.labelMedium?.copyWith(
                color: selectedIds.isEmpty
                    ? AppColors.mutedText
                    : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        AppSizes.vGapSm,
        InkWell(
          onTap: onToggle == null ? null : () => _showBottomSheet(context),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm + 4,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).dividerColor,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    options.isEmpty
                        ? 'Select a category to load skills'
                        : selectedIds.isEmpty
                        ? 'Select skills'
                        : '${selectedIds.length} skill${selectedIds.length == 1 ? '' : 's'} selected',
                    style: context.text.bodyMedium?.copyWith(
                      color: selectedIds.isEmpty
                          ? AppColors.mutedText
                          : context.text.bodyMedium?.color,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.mutedText,
                ),
              ],
            ),
          ),
        ),
        if (selectedOptions.isNotEmpty) ...[
          AppSizes.vGapSm,
          Wrap(
            spacing: AppSizes.xs,
            runSpacing: AppSizes.xs,
            children: [
              for (final option in selectedOptions)
                Chip(
                  label: Text(option.label),
                  deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  onDeleted: onToggle == null ? null : () => onToggle!(option),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _PortfolioUploadTile extends StatelessWidget {
  const _PortfolioUploadTile({
    required this.label,
    required this.hint,
    required this.source,
    required this.fileName,
    required this.icon,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final String hint;
  final String source;
  final String? fileName;
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final cleanSource = source.trim();
    final showImage = _isImageSource(cleanSource);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: context.text.titleSmall)),
            if (fileName?.trim().isNotEmpty == true)
              IconButton(
                tooltip: 'Clear file',
                onPressed: onClear,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.danger,
                ),
              ),
          ],
        ),
        AppSizes.vGapSm,
        if (showImage)
          _PortfolioImagePreview(
            source: cleanSource,
            fileName: fileName,
            onTap: onTap,
          )
        else
          AppFileUpload(
            label: 'Choose file',
            hint: hint,
            fileName: fileName,
            icon: icon,
            onTap: onTap ?? () {},
          ),
      ],
    );
  }
}

class _PortfolioImagePreview extends StatelessWidget {
  const _PortfolioImagePreview({
    required this.source,
    required this.fileName,
    required this.onTap,
  });

  final String source;
  final String? fileName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(source);
    final image = uri != null && uri.hasScheme
        ? CustomCachedImage(
            imageUrl: source,
            fit: BoxFit.cover,
            errorWidget: _imageFallback(context),
          )
        : Image.file(
            File(source),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _imageFallback(context),
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        child: Ink(
          height: 170,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.16),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
            child: Stack(
              fit: StackFit.expand,
              children: [
                image,
                Positioned(
                  left: AppSizes.sm,
                  right: AppSizes.sm,
                  bottom: AppSizes.sm,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.56),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm,
                        vertical: AppSizes.xs,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.image_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: AppSizes.xs),
                          Expanded(
                            child: Text(
                              fileName ?? 'Image selected',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _imageFallback(BuildContext context) {
    return Center(
      child: Text(
        'Unable to preview image',
        style: context.text.bodySmall?.copyWith(color: AppColors.mutedText),
      ),
    );
  }
}

class _PortfolioVideoPreview extends StatelessWidget {
  const _PortfolioVideoPreview({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        child: _PortfolioVideoPlayer(source: source),
      ),
    );
  }
}

class _PortfolioVideoPlayer extends StatefulWidget {
  const _PortfolioVideoPlayer({required this.source, this.fullscreen = false});

  final String source;
  final bool fullscreen;

  @override
  State<_PortfolioVideoPlayer> createState() => _PortfolioVideoPlayerState();
}

class _PortfolioVideoPlayerState extends State<_PortfolioVideoPlayer> {
  VideoPlayerController? _controller;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant _PortfolioVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _controller?.dispose();
      _controller = null;
      _ready = false;
      _error = null;
      _init();
    }
  }

  Future<void> _init() async {
    try {
      final uri = Uri.tryParse(widget.source);
      final controller = uri != null && uri.hasScheme
          ? VideoPlayerController.networkUrl(uri)
          : VideoPlayerController.file(File(widget.source));
      _controller = controller;
      await controller.initialize();
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to preview this video.');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Text(_error!, style: context.text.bodySmall),
      );
    }
    if (!_ready || controller == null) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final videoSize = controller.value.size;
    final aspectRatio = widget.fullscreen
        ? (controller.value.aspectRatio == 0
              ? 16 / 9
              : controller.value.aspectRatio)
        : 16 / 9;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(
            color: Colors.black,
            child: Center(
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: videoSize.width == 0 ? 16 : videoSize.width,
                  height: videoSize.height == 0 ? 9 : videoSize.height,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _togglePlay,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: controller.value.isPlaying ? 0 : 1,
                    duration: const Duration(milliseconds: 180),
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(AppSizes.md),
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSizes.sm,
            right: AppSizes.sm,
            bottom: AppSizes.sm,
            child: Row(
              children: [
                IconButton.filledTonal(
                  onPressed: _togglePlay,
                  icon: Icon(
                    controller.value.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
                Expanded(
                  child: VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                  ),
                ),
                if (!widget.fullscreen)
                  IconButton.filledTonal(
                    onPressed: _openFullscreen,
                    icon: const Icon(Icons.fullscreen_rounded),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _togglePlay() {
    final controller = _controller;
    if (controller == null) return;
    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  Future<void> _openFullscreen() async {
    await _controller?.pause();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Video Demo'),
          ),
          body: Center(
            child: _PortfolioVideoPlayer(
              source: widget.source,
              fullscreen: true,
            ),
          ),
        ),
      ),
    );
  }
}

class _PortfolioOption {
  const _PortfolioOption({required this.id, required this.label});

  final String id;
  final String label;

  factory _PortfolioOption.fromJson(Map<String, dynamic> json) {
    final label =
        json['name']?.toString().trim() ??
        json['label']?.toString().trim() ??
        json['value']?.toString().trim() ??
        '';
    return _PortfolioOption(id: json['id']?.toString() ?? '', label: label);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _PortfolioOption &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum _PortfolioMediaKind { cover, video, caseStudy, screenshot }

String? _fileLabel(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri != null && uri.pathSegments.isNotEmpty) {
    return uri.pathSegments.last;
  }
  return trimmed.split(Platform.pathSeparator).last;
}

bool _isImageSource(String value) {
  final label = _fileLabel(value)?.toLowerCase() ?? '';
  return label.endsWith('.jpg') ||
      label.endsWith('.jpeg') ||
      label.endsWith('.png') ||
      label.endsWith('.webp') ||
      label.endsWith('.gif') ||
      label.endsWith('.bmp') ||
      label.endsWith('.heic') ||
      label.endsWith('.heif');
}

class _LegacyFreelancerPortfolioPage extends StatefulWidget {
  const _LegacyFreelancerPortfolioPage();

  @override
  State<_LegacyFreelancerPortfolioPage> createState() =>
      _LegacyFreelancerPortfolioPageState();
}

class _LegacyFreelancerPortfolioPageState
    extends State<_LegacyFreelancerPortfolioPage> {
  int _listKey = 0;

  void _reload() => setState(() => _listKey++);

  @override
  Widget build(BuildContext context) => _ListScaffold(
    title: 'Portfolio',
    child: CatalogView<PortfolioItem>(
      key: ValueKey(_listKey),
      fetcher: (q) => sl<PortfolioRepository>().getPortfolio(q),
      searchHint: 'Search portfolio…',
      emptyTitle: 'No portfolio items yet',
      emptyMessage: 'Add your best work so clients can see what you deliver.',
      itemBuilder: (context, item, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(item.title, style: context.text.titleSmall),
                  ),
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: () => _openEdit(context, item),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: () async {
                      final del = await sl<PortfolioRepository>()
                          .deletePortfolio(item.id);
                      if (!context.mounted) return;
                      del.fold((f) => context.showSnack(f.message), (_) {
                        context.showSnack('Portfolio item deleted');
                        _reload();
                      });
                    },
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
              if (item.description.isNotEmpty)
                Text(
                  item.description,
                  style: context.text.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (item.projectUrl != null && item.projectUrl!.isNotEmpty) ...[
                AppSizes.vGapSm,
                Text(item.projectUrl!, style: context.text.labelSmall),
              ],
              if (item.technologies.isNotEmpty) ...[
                AppSizes.vGapSm,
                Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: [
                    for (final tech in item.technologies)
                      Chip(
                        label: Text(tech),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      header: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding,
          AppSizes.md,
          AppSizes.screenPadding,
          AppSizes.sm,
        ),
        child: AppPrimaryButton(
          label: 'Add Portfolio Item',
          icon: Icons.add_rounded,
          onPressed: () => _openAdd(context),
        ),
      ),
    ),
  );

  Future<void> _openAdd(BuildContext context) async {
    final message = await _portfolioFormSheet(context);
    if (!context.mounted || message == null) return;
    context.showSnack(message);
    _reload();
  }

  Future<void> _openEdit(BuildContext context, PortfolioItem item) async {
    final message = await _portfolioFormSheet(context, item: item);
    if (!context.mounted || message == null) return;
    context.showSnack(message);
    _reload();
  }

  Future<String?> _portfolioFormSheet(
    BuildContext context, {
    PortfolioItem? item,
  }) async {
    final title = TextEditingController(text: item?.title ?? '');
    final desc = TextEditingController(text: item?.description ?? '');
    final url = TextEditingController(text: item?.projectUrl ?? '');
    final client = TextEditingController();
    final industry = TextEditingController();
    final tech = TextEditingController(
      text: item?.technologies.join(', ') ?? '',
    );
    final duration = TextEditingController();
    final teamSize = TextEditingController(text: item == null ? '1' : '');
    final role = TextEditingController(text: item?.role ?? '');
    final category = TextEditingController(text: item?.category ?? '');
    final githubUrl = TextEditingController();
    final liveUrl = TextEditingController();
    final overview = TextEditingController();
    final completionDate = TextEditingController(
      text: _portfolioDateValue(item?.completionDate),
    );
    const statuses = ['Draft', 'Published', 'Archived'];
    var status = statuses.first;
    final savedMessage = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        final safeBottom = MediaQuery.of(sheetContext).padding.bottom;
        final sheetHeight = MediaQuery.of(sheetContext).size.height * 0.75;
        var saving = false;
        String? errorMessage;
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return SafeArea(
              child: SizedBox(
                height: sheetHeight,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSizes.lg,
                    AppSizes.sm,
                    AppSizes.lg,
                    bottomInset + safeBottom + AppSizes.lg,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item == null
                                    ? 'Add Portfolio'
                                    : 'Edit Portfolio',
                                style: Theme.of(
                                  sheetContext,
                                ).textTheme.titleMedium,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Close',
                              onPressed: saving
                                  ? null
                                  : () {
                                      FocusManager.instance.primaryFocus
                                          ?.unfocus();
                                      Navigator.of(sheetContext).pop();
                                    },
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        if (errorMessage != null) ...[
                          AppSizes.vGapMd,
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMd,
                              ),
                              border: Border.all(
                                color: AppColors.danger.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSizes.md),
                              child: Text(
                                errorMessage!,
                                style: Theme.of(sheetContext)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: AppColors.danger),
                              ),
                            ),
                          ),
                        ],
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: title,
                          label: 'Title',
                          hint: 'Enter Title',
                          textInputAction: TextInputAction.next,
                        ),
                        AppSizes.vGapMd,
                        AppDropdown<String>(
                          label: 'Status',
                          hint: 'Select status',
                          value: status,
                          items: statuses,
                          itemLabel: (item) => item,
                          onChanged: saving
                              ? null
                              : (value) {
                                  if (value == null) return;
                                  setSheetState(() => status = value);
                                },
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: desc,
                          label: 'Description',
                          hint: 'Enter Description',
                          maxLines: 3,
                          textInputAction: TextInputAction.next,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: url,
                          label: 'Project URL',
                          hint: 'Enter your url',
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.next,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: client,
                          label: 'Client',
                          hint: 'Enter client',
                          textInputAction: TextInputAction.next,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: industry,
                          label: 'Industry',
                          hint: 'Enter industry',
                          textInputAction: TextInputAction.next,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: tech,
                          label: 'Technologies (comma separated)',
                          hint:
                              'Enter technologies used, e.g. Java, Swift, Firebase',
                          textInputAction: TextInputAction.next,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: duration,
                          label: 'Duration',
                          hint: '3 months',
                          textInputAction: TextInputAction.next,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: teamSize,
                          label: 'Team Size',
                          hint: '1',
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: role,
                          label: 'Role',
                          hint: 'Enter your role',
                          textInputAction: TextInputAction.next,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: category,
                          label: 'Category',
                          hint: 'Enter category',
                          textInputAction: TextInputAction.next,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: githubUrl,
                          label: 'GitHub URL',
                          hint: 'Enter GitHub URL',
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.next,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: liveUrl,
                          label: 'Live URL',
                          hint: 'Enter live URL',
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.next,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: overview,
                          label: 'Overview',
                          hint: 'Enter overview',
                          maxLines: 4,
                          textInputAction: TextInputAction.next,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: completionDate,
                          readOnly: true,
                          label: 'Completion date',
                          hint: 'Select date',
                          suffixIcon: const Icon(Icons.calendar_today_outlined),
                          onTap: saving
                              ? null
                              : () async {
                                  final current = DateTime.tryParse(
                                    completionDate.text,
                                  );
                                  final picked = await showDatePicker(
                                    context: sheetContext,
                                    initialDate: current ?? DateTime.now(),
                                    firstDate: DateTime(1970),
                                    lastDate: DateTime.now(),
                                  );
                                  if (picked == null) return;
                                  completionDate.text = _portfolioDateValue(
                                    picked,
                                  );
                                },
                        ),
                        AppSizes.vGapXl,
                        AppPrimaryButton(
                          label: 'Save',
                          isLoading: saving,
                          onPressed: () async {
                            final payload = {
                              'title': title.text.trim(),
                              'description': desc.text.trim(),
                              'projectUrl': url.text.trim(),
                              'status': status,
                              'client': client.text.trim(),
                              'industry': industry.text.trim(),
                              'technologies': tech.text
                                  .split(',')
                                  .map((e) => e.trim())
                                  .where((e) => e.isNotEmpty)
                                  .toList(),
                              'duration': duration.text.trim(),
                              'teamSize': teamSize.text.trim(),
                              'role': role.text.trim(),
                              'category': category.text.trim(),
                              'githubUrl': githubUrl.text.trim(),
                              'liveUrl': liveUrl.text.trim(),
                              'overview': overview.text.trim(),
                              'completionDate': completionDate.text.trim(),
                            };
                            if ((payload['title'] as String).isEmpty) {
                              setSheetState(() {
                                errorMessage = 'Title is required';
                              });
                              return;
                            }
                            if ((payload['description'] as String).isEmpty) {
                              setSheetState(() {
                                errorMessage = 'Description is required';
                              });
                              return;
                            }
                            final pUrl = (payload['projectUrl'] as String?)?.trim() ?? (payload['liveUrl'] as String?)?.trim() ?? '';
                            if (pUrl.isEmpty) {
                              setSheetState(() {
                                errorMessage = 'Project URL is required';
                              });
                              return;
                            }
                            if ((payload['technologies'] as List).isEmpty) {
                              setSheetState(() {
                                errorMessage =
                                    'Enter at least one technology used.';
                              });
                              return;
                            }
                            setSheetState(() {
                              saving = true;
                              errorMessage = null;
                            });
                            final repo = sl<PortfolioRepository>();
                            final res = item == null
                                ? await repo.addPortfolio(payload)
                                : await repo.updatePortfolio(item.id, payload);
                            if (!sheetContext.mounted) return;
                            res.fold(
                              (f) {
                                setSheetState(() {
                                  saving = false;
                                  errorMessage = f.message;
                                });
                              },
                              (saved) {
                                final message =
                                    saved.responseMessage?.trim().isNotEmpty ==
                                        true
                                    ? saved.responseMessage!.trim()
                                    : item == null
                                    ? 'Portfolio added successfully'
                                    : 'Portfolio updated successfully';
                                Navigator.of(sheetContext).pop(message);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      title.dispose();
      desc.dispose();
      url.dispose();
      client.dispose();
      industry.dispose();
      tech.dispose();
      duration.dispose();
      teamSize.dispose();
      role.dispose();
      category.dispose();
      githubUrl.dispose();
      liveUrl.dispose();
      overview.dispose();
      completionDate.dispose();
    });
    return savedMessage;
  }

  String _portfolioDateValue(DateTime? date) {
    if (date == null) return '';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
