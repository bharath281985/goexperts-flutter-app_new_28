import 'package:flutter/material.dart';

import '../../../../app/constants/app_colors.dart';
import '../../../../app/constants/app_sizes.dart';
import '../../../../app/dependency_injection/service_locator.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_confirm_dialog.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_status_chip.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/icon_widget.dart';
import '../../../master_data/domain/repositories/master_data_repository.dart';
import '../../data/team_repository.dart';
import '../../domain/team_member.dart';

class TeamMembersPage extends StatefulWidget {
  const TeamMembersPage({super.key, required this.owner, this.repository});

  final TeamOwner owner;
  final TeamRepository? repository;

  @override
  State<TeamMembersPage> createState() => _TeamMembersPageState();
}

class _TeamMembersPageState extends State<TeamMembersPage> {
  late final TeamRepository _repository =
      widget.repository ?? TeamRepository(sl<ApiClientHelper>(), widget.owner);
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _roleController = TextEditingController();
  final _departmentController = TextEditingController();
  List<TeamMember> _members = const [];
  bool _loading = true;
  String? _error;
  List<String> _roleOptions = const [];
  List<String> _departmentOptions = const [];

  bool get _isClient => widget.owner == TeamOwner.client;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
    _loadDropdownOptions();
  }

  Future<void> _loadDropdownOptions() async {
    final masters = sl<MasterDataRepository>();
    final roles = _isClient
        ? await masters.getDesignations()
        : await masters.getStartupRoles();
    final departments = _isClient
        ? await masters.getMasters('department')
        : null;
    if (!mounted) return;
    setState(() {
      _roleOptions = roles.valueOrNull ?? const [];
      _departmentOptions = departments?.valueOrNull ?? const [];
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.getTeam();
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _error = failure.message;
        _loading = false;
      }),
      (team) => setState(() {
        _members = team.members;
        _loading = false;
      }),
    );
  }

  Future<void> _showMemberForm([TeamMember? member]) async {
    _nameController.text = member?.name ?? '';
    _emailController.text = member?.email ?? '';
    _roleController.text = member?.role ?? '';
    _departmentController.text = member?.department ?? '';
    var status = member?.status.isNotEmpty == true ? member!.status : 'invited';
    var submitting = false;
    String? formError;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: context.isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSizes.lg,
              AppSizes.xs,
              AppSizes.lg,
              MediaQuery.viewInsetsOf(context).bottom + AppSizes.lg,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member == null ? 'Invite team member' : 'Update team member',
                    style: context.text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AppSizes.vGapLg,
                  AppTextField(
                    controller: _nameController,
                    label: 'Name',
                    hint: 'Full name',
                  ),
                  AppSizes.vGapMd,
                  AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'name@example.com',
                    keyboardType: TextInputType.emailAddress,
                    enabled: member == null || !_isClient,
                  ),
                  AppSizes.vGapMd,
                  _SuggestionField(
                    controller: _roleController,
                    label: 'Role',
                    hint: _isClient ? 'Developer' : 'Co-Founder',
                    options: _roleOptions.isNotEmpty
                        ? _roleOptions
                        : _isClient
                        ? const [
                            'Project Manager',
                            'Developer',
                            'Designer',
                            'Quality Analyst',
                            'Finance',
                            'Operations',
                          ]
                        : const [
                            'Co-Founder',
                            'CEO',
                            'CTO',
                            'COO',
                            'CMO',
                            'Advisor',
                          ],
                  ),
                  if (_isClient && member == null) ...[
                    AppSizes.vGapMd,
                    _SuggestionField(
                      controller: _departmentController,
                      label: 'Department',
                      hint: 'Engineering',
                      options: _departmentOptions.isNotEmpty
                          ? _departmentOptions
                          : const [
                              'Engineering',
                              'Product',
                              'Design',
                              'Marketing',
                              'Sales',
                              'Finance',
                              'Operations',
                              'Human Resources',
                            ],
                    ),
                  ],
                  if (!_isClient && member != null) ...[
                    AppSizes.vGapMd,
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(labelText: 'Status'),
                      items: const [
                        DropdownMenuItem(
                          value: 'invited',
                          child: Text('Invited'),
                        ),
                        DropdownMenuItem(value: 'active', child: Text('Active')),
                        DropdownMenuItem(
                          value: 'inactive',
                          child: Text('Inactive'),
                        ),
                      ],
                      onChanged: (value) => status = value ?? status,
                    ),
                  ],
                  if (formError != null) ...[
                    AppSizes.vGapMd,
                    Text(
                      formError!,
                      style: const TextStyle(color: AppColors.danger),
                    ),
                  ],
                  AppSizes.vGapXl,
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        ),
                      ),
                      onPressed: submitting
                          ? null
                          : () async {
                              final trimmedName = _nameController.text.trim();
                              final trimmedEmail = _emailController.text.trim();
                              final trimmedRole = _roleController.text.trim();
                              if (trimmedName.isEmpty ||
                                  trimmedEmail.isEmpty ||
                                  trimmedRole.isEmpty ||
                                  !trimmedEmail.contains('@')) {
                                setSheetState(
                                  () => formError =
                                      'Enter a valid name, email, and role.',
                                );
                                return;
                              }
                              setSheetState(() {
                                submitting = true;
                                formError = null;
                              });
                              final result = member == null
                                  ? await _repository.invite(
                                      name: trimmedName,
                                      email: trimmedEmail,
                                      role: trimmedRole,
                                      department: _departmentController.text
                                          .trim(),
                                    )
                                  : await _repository.update(
                                      member,
                                      name: trimmedName,
                                      email: trimmedEmail,
                                      role: trimmedRole,
                                      status: status,
                                    );
                              if (!sheetContext.mounted) return;
                              if (result.isFailure) {
                                setSheetState(() {
                                  submitting = false;
                                  formError = result.failureOrNull!.message;
                                });
                                return;
                              }

                              // Close any editable DropdownMenu overlay before
                              // removing the sheet's inherited widget subtree.
                              FocusManager.instance.primaryFocus?.unfocus();
                              await Future<void>.delayed(
                                const Duration(milliseconds: 100),
                              );
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            },
                      icon: submitting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              member == null
                                  ? Icons.person_add_alt_1_rounded
                                  : Icons.save_outlined,
                            ),
                      label: Text(
                        member == null ? 'Send invitation' : 'Save changes',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _remove(TeamMember member) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: 'Remove team member?',
      message: 'Remove ${member.name} from your team?',
      confirmLabel: 'Remove',
      isDestructive: true,
      icon: Icons.person_remove_outlined,
    );
    if (!confirmed) return;
    final result = await _repository.remove(member.id);
    if (!mounted) return;
    result.fold((failure) => context.showSnack(failure.message), (_) {
      context.showSnack('Team member removed');
      _load();
    });
  }

  @override
  Widget build(BuildContext context) => AppScaffold(
    appBar: AppBar(
      leading: IconTapWidget(onTap: () => Navigator.of(context).maybePop()),
      title: const Text('Team members'),
      actions: [
        IconButton(
          tooltip: 'Invite member',
          onPressed: () => _showMemberForm(),
          icon: const Icon(Icons.person_add_alt_1_outlined),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _showMemberForm(),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Invite'),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? _TeamError(message: _error!, onRetry: _load)
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              children: [
                Text(
                  '${_members.length} ${_members.length == 1 ? 'member' : 'members'}',
                  style: context.text.titleMedium,
                ),
                AppSizes.vGapMd,
                if (_members.isEmpty) const _EmptyTeam(),
                for (final member in _members)
                  _MemberCard(
                    member: member,
                    onEdit: () => _showMemberForm(member),
                    onRemove: () => _remove(member),
                  ),
              ],
            ),
          ),
  );
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.onEdit,
    required this.onRemove,
  });

  final TeamMember member;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => AppCard(
    margin: const EdgeInsets.only(bottom: AppSizes.sm),
    child: Row(
      children: [
        AppAvatar(name: member.name.isEmpty ? 'Member' : member.name, size: 48),
        AppSizes.hGapMd,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(member.name, style: context.text.titleSmall),
              AppSizes.vGapXs,
              Text(
                [
                  member.role,
                  member.department,
                ].where((value) => value.isNotEmpty).join(' • '),
                style: context.text.bodySmall,
              ),
              Text(member.email, style: context.text.labelSmall),
              AppSizes.vGapSm,
              AppStatusChip(
                label: member.status.isEmpty ? 'Invited' : member.status,
                dense: true,
                color: member.status.toLowerCase() == 'active'
                    ? AppColors.success
                    : AppColors.warning,
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          tooltip: 'Member actions',
          onSelected: (value) => value == 'edit' ? onEdit() : onRemove(),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'remove', child: Text('Remove')),
          ],
        ),
      ],
    ),
  );
}

class _SuggestionField extends StatelessWidget {
  const _SuggestionField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.options,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final List<String> options;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => DropdownMenu<String>(
      controller: controller,
      width: constraints.maxWidth,
      enableFilter: true,
      enableSearch: true,
      requestFocusOnTap: true,
      label: Text(label),
      hintText: hint,
      dropdownMenuEntries: options
          .map((option) => DropdownMenuEntry(value: option, label: option))
          .toList(),
    ),
  );
}

class _EmptyTeam extends StatelessWidget {
  const _EmptyTeam();

  @override
  Widget build(BuildContext context) => AppCard(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.xxl),
      child: Column(
        children: [
          Icon(
            Icons.groups_2_outlined,
            size: 52,
            color: context.theme.colorScheme.primary,
          ),
          AppSizes.vGapMd,
          Text('Build your team', style: context.text.titleLarge),
          AppSizes.vGapSm,
          Text(
            'Invite your first member to start collaborating.',
            textAlign: TextAlign.center,
            style: context.text.bodyMedium,
          ),
        ],
      ),
    ),
  );
}

class _TeamError extends StatelessWidget {
  const _TeamError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSizes.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          AppSizes.vGapMd,
          Text(message, textAlign: TextAlign.center),
          AppSizes.vGapMd,
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}
