import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/paginated.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_dropdown.dart';
import '../../../../core/widgets/app_location_field.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/catalog_view.dart';
import '../../../../core/widgets/category_skills_picker.dart';
import '../../../master_data/domain/entities/skill_option.dart';
import '../../domain/entities/freelancer_task.dart';
import '../../domain/entities/portfolio_item.dart';
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
    appBar: AppBar(title: Text(title)),
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
      appBar: AppBar(title: const Text('Withdrawals')),
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
      appBar: AppBar(title: const Text('Tasks')),
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
      (_) => context.showSnack('Skills saved'),
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
  final _roles = <_ExperienceDraft>[];

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
      (p) => _roles
        ..clear()
        ..addAll(
          p.experience
              .split(',')
              .where((e) => e.isNotEmpty)
              .map((role) => _ExperienceDraft(role: role)),
        ),
    );
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final role in _roles) {
      role.dispose();
    }
    super.dispose();
  }

  Future<void> _addRole() async {
    final role = await _experienceFormSheet(context);
    if (!mounted || role == null) return;
    setState(() {
      _roles.add(role);
      _errorMessage = null;
    });
    await _persistExperience('Experience added successfully');
  }

  Future<void> _editRole(_ExperienceDraft role) async {
    final updated = await _experienceFormSheet(context, item: role);
    if (!mounted || updated == null) return;
    final index = _roles.indexOf(role);
    if (index == -1) {
      updated.dispose();
      return;
    }
    setState(() {
      _roles[index] = updated;
      role.dispose();
      _errorMessage = null;
    });
    await _persistExperience('Experience updated successfully');
  }

  Future<void> _removeRole(_ExperienceDraft role) async {
    setState(() {
      _roles.remove(role);
      role.dispose();
      _errorMessage = null;
    });
    await _persistExperience(
      'Experience removed successfully',
      allowEmpty: true,
    );
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
    controller.text = _experienceDateValue(picked);
  }

  Future<void> _persistExperience(
    String successMessage, {
    bool allowEmpty = false,
  }) async {
    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    final payload = {
      'experience': _roles
          .map((role) => role.toProfileValue())
          .where((value) => value.isNotEmpty)
          .toList(),
    };
    if (!allowEmpty && (payload['experience'] as List).isEmpty) {
      setState(() {
        _saving = false;
        _errorMessage = 'Add at least one role.';
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
      },
    );
  }

  Future<_ExperienceDraft?> _experienceFormSheet(
    BuildContext context, {
    _ExperienceDraft? item,
  }) async {
    final draft = item == null
        ? _ExperienceDraft()
        : _ExperienceDraft.copy(item);
    String? errorMessage;
    var saving = false;
    final saved = await showModalBottomSheet<_ExperienceDraft>(
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
                                item == null ? 'Add role' : 'Edit role',
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
                          controller: draft.role,
                          label: 'Role',
                          hint: 'Role',
                          textInputAction: TextInputAction.next,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: draft.company,
                          label: 'Company',
                          hint: 'Company',
                          textInputAction: TextInputAction.next,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: draft.industry,
                          label: 'Industry',
                          hint: 'Industry',
                          textInputAction: TextInputAction.next,
                        ),
                        AppSizes.vGapMd,
                        AppLocationField(
                          controller: draft.location,
                          label: 'Location',
                          hint: 'Search location',
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: draft.start,
                          readOnly: true,
                          label: 'Start',
                          hint: 'Start',
                          suffixIcon: const Icon(Icons.calendar_today_outlined),
                          onTap: saving ? null : () => _pickDate(draft.start),
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: draft.end,
                          readOnly: true,
                          enabled: !draft.currentRole,
                          label: 'End',
                          hint: draft.currentRole ? 'Present' : 'End',
                          suffixIcon: const Icon(Icons.calendar_today_outlined),
                          onTap: saving || draft.currentRole
                              ? null
                              : () => _pickDate(draft.end),
                        ),
                        AppSizes.vGapMd,
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: draft.currentRole,
                          title: const Text('Current role'),
                          onChanged: saving
                              ? null
                              : (value) {
                                  setSheetState(() {
                                    draft.currentRole = value ?? false;
                                    if (draft.currentRole) draft.end.clear();
                                  });
                                },
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: draft.projects,
                          label: 'Projects',
                          hint: '0',
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: draft.achievements,
                          label: 'Achievements',
                          hint: 'Achievements (one per line)',
                          maxLines: 3,
                          textInputAction: TextInputAction.newline,
                        ),
                        AppSizes.vGapMd,
                        AppTextField(
                          controller: draft.tech,
                          label: 'Tech',
                          hint: 'Tech (comma separated)',
                          textInputAction: TextInputAction.done,
                        ),
                        AppSizes.vGapXl,
                        AppPrimaryButton(
                          label: item == null ? 'Add & save' : 'Save',
                          isLoading: saving,
                          onPressed: () {
                            if (draft.role.text.trim().isEmpty) {
                              setSheetState(() {
                                errorMessage = 'Role is required.';
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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Experience'),
        actions: [
          IconButton(
            tooltip: 'Add role',
            onPressed: _saving ? null : _addRole,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              children: [
                _ExperienceSummary(roles: _roles),
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
                                  style: context.text.titleMedium,
                                ),
                                AppSizes.vGapXs,
                                Text(
                                  'Full professional history synced to your public profile',
                                  style: context.text.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          AppPrimaryButton(
                            label: 'Add role',
                            icon: Icons.add_rounded,
                            expanded: false,
                            gradient: false,
                            backgroundColor: AppColors.white,
                            textColor: AppColors.darkText,
                            onPressed: _saving ? null : _addRole,
                          ),
                          AppSizes.hGapSm,
                        ],
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
                      for (final entry in _roles) ...[
                        _ExperienceListCard(
                          entry: entry,
                          onEdit: _saving ? null : () => _editRole(entry),
                          onRemove: _saving ? null : () => _removeRole(entry),
                        ),
                        if (entry != _roles.last) AppSizes.vGapMd,
                      ],
                      if (_roles.isEmpty)
                        const AppCard(child: Text('No experience added yet.')),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  String _experienceDateValue(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _ExperienceSummary extends StatelessWidget {
  const _ExperienceSummary({required this.roles});

  final List<_ExperienceDraft> roles;

  @override
  Widget build(BuildContext context) {
    final filledRoles = roles
        .where((role) => role.role.text.trim().isNotEmpty)
        .length;
    final industries = roles
        .map((role) => role.industry.text.trim())
        .where((industry) => industry.isNotEmpty)
        .toSet()
        .length;
    final companies = roles
        .map((role) => role.company.text.trim())
        .where((company) => company.isNotEmpty)
        .toSet()
        .length;
    final projects = roles.fold<int>(
      0,
      (sum, role) => sum + (int.tryParse(role.projects.text.trim()) ?? 0),
    );
    final current = roles.where((role) => role.currentRole).length;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _ExperienceMetricCard(
            title: 'Roles',
            value: filledRoles,
            label: 'on profile',
            color: AppColors.primary,
          ),
          _ExperienceMetricCard(
            title: 'Industries',
            value: industries,
            label: 'represented',
            color: AppColors.info,
          ),
          _ExperienceMetricCard(
            title: 'Companies',
            value: companies,
            label: 'listed',
            color: AppColors.success,
          ),
          _ExperienceMetricCard(
            title: 'Projects',
            value: projects,
            label: 'delivered',
            color: AppColors.warning,
          ),
          _ExperienceMetricCard(
            title: 'Current',
            value: current,
            label: 'active roles',
            color: AppColors.danger,
          ),
        ],
      ),
    );
  }
}

class _ExperienceMetricCard extends StatelessWidget {
  const _ExperienceMetricCard({
    required this.title,
    required this.value,
    required this.label,
    required this.color,
  });

  final String title;
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
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
                Chip(
                  label: Text(label),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

class _ExperienceListCard extends StatelessWidget {
  const _ExperienceListCard({
    required this.entry,
    required this.onEdit,
    required this.onRemove,
  });

  final _ExperienceDraft entry;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      entry.company.text.trim(),
      entry.industry.text.trim(),
      entry.location.text.trim(),
      if (entry.start.text.trim().isNotEmpty ||
          entry.end.text.trim().isNotEmpty)
        '${entry.start.text.trim()} - ${entry.currentRole ? 'Present' : entry.end.text.trim()}',
    ].where((value) => value.isNotEmpty).join(' - ');

    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.work_outline_rounded, color: AppColors.primary),
          AppSizes.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.role.text.trim(), style: context.text.titleSmall),
                if (subtitle.isNotEmpty) ...[
                  AppSizes.vGapXs,
                  Text(
                    subtitle,
                    style: context.text.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (entry.tech.text.trim().isNotEmpty) ...[
                  AppSizes.vGapSm,
                  Text(entry.tech.text.trim(), style: context.text.labelSmall),
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
class _ExperienceRoleForm extends StatelessWidget {
  const _ExperienceRoleForm({
    required this.entry,
    required this.saving,
    required this.canRemove,
    required this.onChanged,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onRemove,
  });

  final _ExperienceDraft entry;
  final bool saving;
  final bool canRemove;
  final VoidCallback onChanged;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 720;
              final role = AppTextField(
                controller: entry.role,
                label: 'Role',
                hint: 'Role',
                textInputAction: TextInputAction.next,
                onChanged: (_) => onChanged(),
              );
              final company = AppTextField(
                controller: entry.company,
                label: 'Company',
                hint: 'Company',
                textInputAction: TextInputAction.next,
                onChanged: (_) => onChanged(),
              );
              final industry = AppTextField(
                controller: entry.industry,
                label: 'Industry',
                hint: 'Industry',
                textInputAction: TextInputAction.next,
                onChanged: (_) => onChanged(),
              );
              final location = AppLocationField(
                controller: entry.location,
                label: 'Location',
                hint: 'Search location',
                onPlaceSelected: (_) => onChanged(),
              );
              final start = AppTextField(
                controller: entry.start,
                readOnly: true,
                label: 'Start',
                hint: 'Start',
                suffixIcon: const Icon(Icons.calendar_today_outlined),
                onTap: saving ? null : onPickStart,
              );
              final end = AppTextField(
                controller: entry.end,
                readOnly: true,
                enabled: !entry.currentRole,
                label: 'End',
                hint: entry.currentRole ? 'Present' : 'End',
                suffixIcon: const Icon(Icons.calendar_today_outlined),
                onTap: saving || entry.currentRole ? null : onPickEnd,
              );

              if (!twoColumns) {
                return Column(
                  children: [
                    role,
                    AppSizes.vGapMd,
                    company,
                    AppSizes.vGapMd,
                    industry,
                    AppSizes.vGapMd,
                    location,
                    AppSizes.vGapMd,
                    start,
                    AppSizes.vGapMd,
                    end,
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: role),
                      AppSizes.hGapMd,
                      Expanded(child: company),
                    ],
                  ),
                  AppSizes.vGapMd,
                  Row(
                    children: [
                      Expanded(child: industry),
                      AppSizes.hGapMd,
                      Expanded(child: location),
                    ],
                  ),
                  AppSizes.vGapMd,
                  Row(
                    children: [
                      Expanded(child: start),
                      AppSizes.hGapMd,
                      Expanded(child: end),
                    ],
                  ),
                ],
              );
            },
          ),
          AppSizes.vGapMd,
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSizes.md,
            runSpacing: AppSizes.sm,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: entry.currentRole,
                    onChanged: saving
                        ? null
                        : (value) {
                            entry.currentRole = value ?? false;
                            if (entry.currentRole) entry.end.clear();
                            onChanged();
                          },
                  ),
                  Text('Current role', style: context.text.bodyMedium),
                ],
              ),
              SizedBox(
                width: 148,
                child: AppTextField(
                  controller: entry.projects,
                  hint: '0',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.business_center_outlined,
                  onChanged: (_) => onChanged(),
                ),
              ),
              Text('projects', style: context.text.bodyMedium),
              if (canRemove)
                TextButton.icon(
                  onPressed: saving ? null : onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Remove'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                ),
            ],
          ),
          AppSizes.vGapMd,
          AppTextField(
            controller: entry.achievements,
            label: 'Achievements',
            hint: 'Achievements (one per line)',
            maxLines: 3,
            textInputAction: TextInputAction.newline,
          ),
          AppSizes.vGapMd,
          AppTextField(
            controller: entry.tech,
            label: 'Tech',
            hint: 'Tech (comma separated)',
            textInputAction: TextInputAction.done,
            onChanged: (_) => onChanged(),
          ),
        ],
      ),
    );
  }
}

class _ExperienceDraft {
  _ExperienceDraft({
    String role = '',
    String company = '',
    String industry = '',
    String location = '',
    String start = '',
    String end = '',
    String projects = '0',
    String achievements = '',
    String tech = '',
    this.currentRole = false,
  }) : role = TextEditingController(text: role),
       company = TextEditingController(text: company),
       industry = TextEditingController(text: industry),
       location = TextEditingController(text: location),
       start = TextEditingController(text: start),
       end = TextEditingController(text: end),
       projects = TextEditingController(text: projects),
       achievements = TextEditingController(text: achievements),
       tech = TextEditingController(text: tech);

  factory _ExperienceDraft.copy(_ExperienceDraft entry) => _ExperienceDraft(
    role: entry.role.text,
    company: entry.company.text,
    industry: entry.industry.text,
    location: entry.location.text,
    start: entry.start.text,
    end: entry.end.text,
    projects: entry.projects.text,
    achievements: entry.achievements.text,
    tech: entry.tech.text,
    currentRole: entry.currentRole,
  );

  final TextEditingController role;
  final TextEditingController company;
  final TextEditingController industry;
  final TextEditingController location;
  final TextEditingController start;
  final TextEditingController end;
  final TextEditingController projects;
  final TextEditingController achievements;
  final TextEditingController tech;
  bool currentRole;

  String toProfileValue() {
    final parts = <String>[
      role.text.trim(),
      if (company.text.trim().isNotEmpty) 'at ${company.text.trim()}',
      if (industry.text.trim().isNotEmpty) '- ${industry.text.trim()}',
      if (location.text.trim().isNotEmpty) '- ${location.text.trim()}',
      if (start.text.trim().isNotEmpty || end.text.trim().isNotEmpty)
        '- ${start.text.trim()} - ${currentRole ? 'Present' : end.text.trim()}',
      if (projects.text.trim().isNotEmpty) '- ${projects.text.trim()} projects',
      if (tech.text.trim().isNotEmpty) '- ${tech.text.trim()}',
      if (achievements.text.trim().isNotEmpty) '- ${achievements.text.trim()}',
    ];
    return parts.join(' ').trim();
  }

  void dispose() {
    role.dispose();
    company.dispose();
    industry.dispose();
    location.dispose();
    start.dispose();
    end.dispose();
    projects.dispose();
    achievements.dispose();
    tech.dispose();
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
  const FreelancerPortfolioPage({super.key});

  @override
  State<FreelancerPortfolioPage> createState() =>
      _FreelancerPortfolioPageState();
}

class _FreelancerPortfolioPageState extends State<FreelancerPortfolioPage> {
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
