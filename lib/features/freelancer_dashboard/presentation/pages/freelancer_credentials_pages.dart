import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_file_upload.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/custom_cached_image.dart';
import '../../../../core/widgets/icon_widget.dart';
import '../../domain/entities/freelancer_credentials.dart';
import '../../domain/repositories/freelancer_credentials_repository.dart';

class FreelancerEducationApiPage extends StatefulWidget {
  const FreelancerEducationApiPage({super.key});

  @override
  State<FreelancerEducationApiPage> createState() =>
      _FreelancerEducationApiPageState();
}

class _FreelancerEducationApiPageState
    extends State<FreelancerEducationApiPage> {
  final _search = TextEditingController();
  List<FreelancerEducation> _items = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  FreelancerCredentialsRepository get _repo =>
      sl<FreelancerCredentialsRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repo.getEducation();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = result.valueOrNull ?? const [];
      _error = result.failureOrNull?.message;
    });
  }

  List<FreelancerEducation> get _filtered {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return _items;
    return _items.where((item) {
      return [
        item.institution,
        item.qualification,
        item.specialization,
        item.year,
      ].any((value) => value.toLowerCase().contains(query));
    }).toList();
  }

  Future<void> _openForm([FreelancerEducation? item]) async {
    final payload = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EducationFormSheet(item: item),
    );
    if (!mounted || payload == null) return;

    setState(() => _saving = true);
    final result = item == null
        ? await _repo.addEducation(payload)
        : await _repo.updateEducation(item.id, payload);
    if (!mounted) return;
    setState(() => _saving = false);

    final saved = result.valueOrNull;
    if (saved == null) {
      context.showSnack(
        result.failureOrNull?.message ?? 'Unable to save education',
        isError: true,
      );
      return;
    }
    context.showSnack(
      saved.responseMessage ??
          (item == null ? 'Education added' : 'Education updated'),
    );
    await _load();
  }

  Future<void> _delete(FreelancerEducation item) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete education?',
      message: 'This will remove ${item.institution}.',
      confirmLabel: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed || !mounted) return;

    setState(() => _saving = true);
    final result = await _repo.deleteEducation(item.id);
    if (!mounted) return;
    setState(() => _saving = false);

    final message = result.valueOrNull;
    if (message == null) {
      context.showSnack(
        result.failureOrNull?.message ?? 'Unable to delete education',
        isError: true,
      );
      return;
    }
    context.showSnack(message);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return AppScaffold(
      appBar: AppBar(
        leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
        title: const Text('Education'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Education'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          children: [
            AppCard(
              child: AppTextField(
                controller: _search,
                hint: 'Search institution, qualification, specialization...',
                prefixIcon: Icons.search_rounded,
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (_error != null) ...[
              AppSizes.vGapMd,
              _InlineError(message: _error!, onRetry: _load),
            ],
            AppSizes.vGapLg,
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (items.isEmpty)
              const AppCard(child: Text('No education records found.'))
            else
              for (final item in items) ...[
                _EducationApiCard(
                  item: item,
                  onEdit: _saving ? null : () => _openForm(item),
                  onDelete: _saving ? null : () => _delete(item),
                ),
                if (item != items.last) AppSizes.vGapMd,
              ],
          ],
        ),
      ),
    );
  }
}

class FreelancerCertificatesApiPage extends StatefulWidget {
  const FreelancerCertificatesApiPage({super.key});

  @override
  State<FreelancerCertificatesApiPage> createState() =>
      _FreelancerCertificatesApiPageState();
}

class _FreelancerCertificatesApiPageState
    extends State<FreelancerCertificatesApiPage> {
  final _search = TextEditingController();
  List<FreelancerCertificate> _items = const [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  FreelancerCredentialsRepository get _repo =>
      sl<FreelancerCredentialsRepository>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repo.getCertificates();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _items = result.valueOrNull ?? const [];
      _error = result.failureOrNull?.message;
    });
  }

  List<FreelancerCertificate> get _filtered {
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return _items;
    return _items.where((item) {
      return [
        item.name,
        item.issuer,
        item.issued,
        item.certificateUrl,
      ].any((value) => value.toLowerCase().contains(query));
    }).toList();
  }

  Future<void> _openForm([FreelancerCertificate? item]) async {
    final payload = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _CertificateApiFormSheet(item: item),
    );
    if (!mounted || payload == null) return;

    setState(() => _saving = true);
    final result = item == null
        ? await _repo.addCertificate(payload)
        : await _repo.updateCertificate(item.id, payload);
    if (!mounted) return;
    setState(() => _saving = false);

    final saved = result.valueOrNull;
    if (saved == null) {
      context.showSnack(
        result.failureOrNull?.message ?? 'Unable to save certificate',
        isError: true,
      );
      return;
    }
    context.showSnack(
      saved.responseMessage ??
          (item == null ? 'Certificate added' : 'Certificate updated'),
    );
    await _load();
  }

  Future<void> _delete(FreelancerCertificate item) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Delete certificate?',
      message: 'This will remove ${item.name}.',
      confirmLabel: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed || !mounted) return;

    setState(() => _saving = true);
    final result = await _repo.deleteCertificate(item.id);
    if (!mounted) return;
    setState(() => _saving = false);

    final message = result.valueOrNull;
    if (message == null) {
      context.showSnack(
        result.failureOrNull?.message ?? 'Unable to delete certificate',
        isError: true,
      );
      return;
    }
    context.showSnack(message);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return AppScaffold(
      appBar: AppBar(
        leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
        title: const Text('Certificates'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Certificate'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          children: [
            AppCard(
              child: AppTextField(
                controller: _search,
                hint: 'Search certificate, issuer, date...',
                prefixIcon: Icons.search_rounded,
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (_error != null) ...[
              AppSizes.vGapMd,
              _InlineError(message: _error!, onRetry: _load),
            ],
            AppSizes.vGapLg,
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (items.isEmpty)
              const AppCard(child: Text('No certificates found.'))
            else
              for (final item in items) ...[
                _CertificateApiCard(
                  item: item,
                  onEdit: _saving ? null : () => _openForm(item),
                  onDelete: _saving ? null : () => _delete(item),
                ),
                if (item != items.last) AppSizes.vGapMd,
              ],
          ],
        ),
      ),
    );
  }
}

class _EducationApiCard extends StatelessWidget {
  const _EducationApiCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final FreelancerEducation item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      item.qualification,
      item.specialization,
      item.year,
    ].where((value) => value.trim().isNotEmpty).join(' - ');
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.12),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: const Icon(Icons.school_outlined, color: Colors.white),
                ),
                AppSizes.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.institution,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall?.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                    ],
                  ),
                ),
                _CredentialCardActions(onEdit: onEdit, onDelete: onDelete),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: [
                if (item.qualification.trim().isNotEmpty)
                  _CredentialInfoPill(
                    icon: Icons.workspace_premium_outlined,
                    label: item.qualification,
                  ),
                if (item.specialization.trim().isNotEmpty)
                  _CredentialInfoPill(
                    icon: Icons.auto_awesome_outlined,
                    label: item.specialization,
                  ),
                if (item.year.trim().isNotEmpty)
                  _CredentialInfoPill(
                    icon: Icons.calendar_month_outlined,
                    label: item.year,
                  ),
              ],
            ),
          ),
          if (item.document.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.lg,
                0,
                AppSizes.lg,
                AppSizes.lg,
              ),
              child: _CredentialAttachmentPreview(
                source: item.document,
                fileName: _fileLabel(item.document),
              ),
            ),
        ],
      ),
    );
  }
}

class _CertificateApiCard extends StatelessWidget {
  const _CertificateApiCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final FreelancerCertificate item;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      item.issuer,
      if (item.issued.isNotEmpty) 'Issued ${item.issued}',
    ].where((value) => value.trim().isNotEmpty).join(' - ');
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.lg),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.warning.withValues(alpha: 0.16),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_outlined,
                    color: Colors.white,
                  ),
                ),
                AppSizes.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (item.verified)
                            const Icon(
                              Icons.verified_rounded,
                              color: AppColors.success,
                              size: 18,
                            ),
                        ],
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.bodySmall?.copyWith(
                            color: AppColors.mutedText,
                          ),
                        ),
                    ],
                  ),
                ),
                _CredentialCardActions(onEdit: onEdit, onDelete: onDelete),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSizes.sm,
                  runSpacing: AppSizes.sm,
                  children: [
                    if (item.issuer.trim().isNotEmpty)
                      _CredentialInfoPill(
                        icon: Icons.apartment_outlined,
                        label: item.issuer,
                      ),
                    if (item.issued.trim().isNotEmpty)
                      _CredentialInfoPill(
                        icon: Icons.event_available_outlined,
                        label: item.issued,
                      ),
                    _CredentialInfoPill(
                      icon: item.verified
                          ? Icons.verified_outlined
                          : Icons.pending_actions_outlined,
                      label: item.verified ? 'Verified' : 'Pending',
                    ),
                  ],
                ),
                if (item.certificateUrl.trim().isNotEmpty) ...[
                  AppSizes.vGapMd,
                  Text(
                    item.certificateUrl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.labelSmall?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
                if (item.certificateFile.trim().isNotEmpty) ...[
                  AppSizes.vGapMd,
                  _CredentialAttachmentPreview(
                    source: item.certificateFile,
                    fileName: _fileLabel(item.certificateFile),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CredentialInfoPill extends StatelessWidget {
  const _CredentialInfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.primaryBlack.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppSizes.radiusPill),
          border: Border.all(
            color: AppColors.primaryBlack.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: AppSizes.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelSmall?.copyWith(
                  color: AppColors.primaryBlack,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CredentialCardActions extends StatelessWidget {
  const _CredentialCardActions({required this.onEdit, required this.onDelete});

  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CredentialIconButton(
          tooltip: 'Edit',
          icon: Icons.edit_outlined,
          onPressed: onEdit,
        ),
        const SizedBox(width: AppSizes.xs),
        _CredentialIconButton(
          tooltip: 'Delete',
          icon: Icons.delete_outline_rounded,
          color: AppColors.danger,
          onPressed: onDelete,
        ),
      ],
    );
  }
}

class _CredentialIconButton extends StatelessWidget {
  const _CredentialIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color = AppColors.primaryBlack,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
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
        icon: Icon(icon, size: 18, color: color),
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

class _EducationFormSheet extends StatefulWidget {
  const _EducationFormSheet({this.item});

  final FreelancerEducation? item;

  @override
  State<_EducationFormSheet> createState() => _EducationFormSheetState();
}

class _EducationFormSheetState extends State<_EducationFormSheet> {
  late final TextEditingController _institution;
  late final TextEditingController _qualification;
  late final TextEditingController _specialization;
  late final TextEditingController _year;
  late String _document;
  String? _fileName;
  String? _error;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _institution = TextEditingController(text: item?.institution ?? '');
    _qualification = TextEditingController(text: item?.qualification ?? '');
    _specialization = TextEditingController(text: item?.specialization ?? '');
    _year = TextEditingController(text: item?.year ?? '');
    _document = item?.document ?? '';
    _fileName = _document.isEmpty ? null : _fileLabel(_document);
  }

  @override
  void dispose() {
    _institution.dispose();
    _qualification.dispose();
    _specialization.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _pickYear() async {
    final currentYear = DateTime.now().year;
    final parsedYear = int.tryParse(_year.text.trim());
    final initialDate = DateTime(parsedYear ?? currentYear);
    final selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Year'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: YearPicker(
              firstDate: DateTime(1950),
              lastDate: DateTime(currentYear + 10),
              selectedDate: initialDate,
              onChanged: (DateTime dateTime) {
                Navigator.pop(context, dateTime);
              },
            ),
          ),
        );
      },
    );
    if (selectedDate != null) {
      setState(() {
        _year.text = selectedDate.year.toString();
      });
    }
  }

  Future<void> _pickFile() async {
    final file = await _pickCredentialFile(const [
      'pdf',
      'jpg',
      'jpeg',
      'png',
      'doc',
      'docx',
    ]);
    if (file == null) return;
    setState(() {
      _fileName = file.name;
      _document = file.path?.trim().isNotEmpty == true ? file.path! : file.name;
    });
  }

  void _submit() {
    if (_institution.text.trim().isEmpty) {
      setState(() => _error = 'Institution is required.');
      return;
    }
    Navigator.of(context).pop({
      'institution': _institution.text.trim(),
      'qualification': _qualification.text.trim(),
      'specialization': _specialization.text.trim(),
      'year': _year.text.trim(),
      'document': _document.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return _CredentialSheetFrame(
      title: widget.item == null ? 'Add Education' : 'Edit Education',
      error: _error,
      child: Column(
        children: [
          AppTextField(
            controller: _institution,
            label: 'Institution *',
            hint: 'Enter institution',
            textInputAction: TextInputAction.next,
          ),
          AppSizes.vGapMd,
          AppTextField(
            controller: _qualification,
            label: 'Qualification',
            hint: 'Enter qualification',
            textInputAction: TextInputAction.next,
          ),
          AppSizes.vGapMd,
          AppTextField(
            controller: _specialization,
            label: 'Specialization',
            hint: 'Enter specialization',
            textInputAction: TextInputAction.next,
          ),
          AppSizes.vGapMd,
          AppTextField(
            controller: _year,
            label: 'Year',
            hint: 'Select Year (YYYY)',
            readOnly: true,
            onTap: _pickYear,
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today_rounded),
              onPressed: _pickYear,
            ),
          ),
          AppSizes.vGapMd,
          _CredentialUploadField(
            label: 'Upload Document',
            hint: 'Upload JPG, PNG, PDF, DOC, or DOCX',
            fileName: _fileName,
            source: _document,
            onTap: _pickFile,
            onClear: _fileName == null
                ? null
                : () => setState(() {
                    _fileName = null;
                    _document = '';
                  }),
          ),
          AppSizes.vGapXl,
          AppPrimaryButton(
            label: widget.item == null ? 'Add Education' : 'Update Education',
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _CertificateApiFormSheet extends StatefulWidget {
  const _CertificateApiFormSheet({this.item});

  final FreelancerCertificate? item;

  @override
  State<_CertificateApiFormSheet> createState() =>
      _CertificateApiFormSheetState();
}

class _CertificateApiFormSheetState extends State<_CertificateApiFormSheet> {
  late final TextEditingController _name;
  late final TextEditingController _issuer;
  late final TextEditingController _issued;
  late final TextEditingController _certificateUrl;
  late String _certificateFile;
  String? _fileName;
  String? _error;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.name ?? '');
    _issuer = TextEditingController(text: item?.issuer ?? '');
    _issued = TextEditingController(text: item?.issued ?? '');
    _certificateUrl = TextEditingController(text: item?.certificateUrl ?? '');
    _certificateFile = item?.certificateFile ?? '';
    _fileName = _certificateFile.isEmpty ? null : _fileLabel(_certificateFile);
  }

  @override
  void dispose() {
    _name.dispose();
    _issuer.dispose();
    _issued.dispose();
    _certificateUrl.dispose();
    super.dispose();
  }

  Future<void> _pickIssuedDate() async {
    final current = DateTime.tryParse(_issued.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _issued.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _pickFile() async {
    final file = await _pickCredentialFile(const ['pdf', 'jpg', 'jpeg', 'png']);
    if (file == null) return;
    setState(() {
      _fileName = file.name;
      _certificateFile = file.path?.trim().isNotEmpty == true
          ? file.path!
          : file.name;
    });
  }

  void _submit() {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Certificate name is required.');
      return;
    }
    Navigator.of(context).pop({
      'name': _name.text.trim(),
      'issuer': _issuer.text.trim(),
      'issued': _issued.text.trim(),
      'certificateUrl': _certificateUrl.text.trim(),
      'certificateFile': _certificateFile.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return _CredentialSheetFrame(
      title: widget.item == null ? 'Add Certificate' : 'Edit Certificate',
      error: _error,
      child: Column(
        children: [
          AppTextField(
            controller: _name,
            label: 'Name *',
            hint: 'Enter certificate name',
            textInputAction: TextInputAction.next,
          ),
          AppSizes.vGapMd,
          AppTextField(
            controller: _issuer,
            label: 'Issuer',
            hint: 'Enter issuer',
            textInputAction: TextInputAction.next,
          ),
          AppSizes.vGapMd,
          AppTextField(
            controller: _issued,
            label: 'Issued (YYYY-MM-DD)',
            hint: 'Select issued date',
            readOnly: true,
            suffixIcon: const Icon(Icons.calendar_today_outlined),
            onTap: _pickIssuedDate,
          ),
          AppSizes.vGapMd,
          AppTextField(
            controller: _certificateUrl,
            label: 'Certificate Url',
            hint: 'Enter certificate URL',
            keyboardType: TextInputType.url,
          ),
          AppSizes.vGapMd,
          _CredentialUploadField(
            label: 'Upload Certificate Document (Image / PDF)',
            hint: 'Upload JPG, PNG, or PDF',
            fileName: _fileName,
            source: _certificateFile,
            onTap: _pickFile,
            onClear: _fileName == null
                ? null
                : () => setState(() {
                    _fileName = null;
                    _certificateFile = '';
                  }),
          ),
          AppSizes.vGapXl,
          AppPrimaryButton(
            label: widget.item == null
                ? 'Add Certificate'
                : 'Update Certificate',
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _CredentialSheetFrame extends StatelessWidget {
  const _CredentialSheetFrame({
    required this.title,
    required this.child,
    this.error,
  });

  final String title;
  final Widget child;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSizes.lg,
          AppSizes.sm,
          AppSizes.lg,
          bottomInset + safeBottom + AppSizes.lg,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Text(title, style: context.text.titleLarge)),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              if (error != null) ...[
                AppSizes.vGapMd,
                _InlineError(message: error!),
              ],
              AppSizes.vGapLg,
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _CredentialUploadField extends StatelessWidget {
  const _CredentialUploadField({
    required this.label,
    required this.hint,
    required this.fileName,
    required this.source,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final String hint;
  final String? fileName;
  final String source;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: context.text.titleSmall)),
            if (onClear != null)
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
        if (_isCredentialImageSource(source))
          _CredentialImagePreview(
            source: source,
            fileName: fileName,
            onTap: onTap,
          )
        else
          AppFileUpload(
            label: 'Choose file',
            hint: hint,
            fileName: fileName,
            icon: Icons.upload_file_rounded,
            onTap: onTap,
          ),
      ],
    );
  }
}

class _CredentialAttachmentPreview extends StatelessWidget {
  const _CredentialAttachmentPreview({
    required this.source,
    required this.fileName,
  });

  final String source;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    if (_isCredentialImageSource(source)) {
      return _CredentialImagePreview(source: source, fileName: fileName);
    }
    return _FileLine(label: source);
  }
}

class _CredentialImagePreview extends StatelessWidget {
  const _CredentialImagePreview({
    required this.source,
    required this.fileName,
    this.onTap,
  });

  final String source;
  final String? fileName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final image = _isNetworkCredentialSource(source)
        ? CustomCachedImage(
            imageUrl: source,
            fit: BoxFit.cover,
            errorWidget: _fallback(context),
          )
        : Image.file(
            File(source),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallback(context),
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
                              fileName?.trim().isNotEmpty == true
                                  ? fileName!.trim()
                                  : 'Image selected',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodySmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (onTap != null)
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

  Widget _fallback(BuildContext context) {
    return Center(
      child: Text(
        'Unable to preview image',
        style: context.text.bodySmall?.copyWith(color: AppColors.mutedText),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.32)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.danger),
            AppSizes.hGapSm,
            Expanded(
              child: Text(
                message,
                style: context.text.bodySmall?.copyWith(
                  color: AppColors.danger,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _FileLine extends StatelessWidget {
  const _FileLine({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.attach_file_rounded,
          size: 16,
          color: AppColors.mutedText,
        ),
        AppSizes.hGapXs,
        Expanded(
          child: Text(
            _fileLabel(label),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelSmall,
          ),
        ),
      ],
    );
  }
}

Future<PlatformFile?> _pickCredentialFile(
  List<String> allowedExtensions,
) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: allowedExtensions,
  );
  return result?.files.single;
}

String _fileLabel(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  final uri = Uri.tryParse(trimmed);
  final path = uri?.path.isNotEmpty == true ? uri!.path : trimmed;
  return path.split('/').where((part) => part.isNotEmpty).last;
}

bool _isNetworkCredentialSource(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
}

bool _isCredentialImageSource(String value) {
  final clean = value.trim().split('?').first.toLowerCase();
  return clean.endsWith('.jpg') ||
      clean.endsWith('.jpeg') ||
      clean.endsWith('.png') ||
      clean.endsWith('.webp');
}
