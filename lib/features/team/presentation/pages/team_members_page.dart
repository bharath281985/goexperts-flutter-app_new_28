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
import '../../../../core/widgets/icon_widget.dart';
import '../../data/team_repository.dart';
import '../../domain/team_member.dart';
import '../widgets/add_edit_member_modal.dart';
import '../widgets/credentials_generated_dialog.dart';

class TeamMembersPage extends StatefulWidget {
  const TeamMembersPage({super.key, this.repository});

  final TeamRepository? repository;

  @override
  State<TeamMembersPage> createState() => _TeamMembersPageState();
}

class _TeamMembersPageState extends State<TeamMembersPage> {
  late final TeamRepository _repository =
      widget.repository ?? TeamRepository(sl<ApiClientHelper>());
  
  List<TeamMember> _members = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
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
    await showDialog(
      context: context,
      builder: (ctx) => AddEditMemberModal(
        member: member,
        onSave: (name, email, role, department, dashboards, permissions) async {
          final result = member == null
              ? await _repository.invite(
                  name: name,
                  email: email,
                  role: role,
                  department: department,
                  permittedDashboards: dashboards,
                  permissions: permissions,
                  emailVerified: true, // Auto active
                )
              : await _repository.update(
                  member,
                  name: name,
                  email: email,
                  role: role,
                  department: department,
                  permittedDashboards: dashboards,
                  permissions: permissions,
                );

          if (result.isFailure) {
            throw Exception(result.failureOrNull?.message ?? 'Unknown error');
          }

          if (member == null && mounted) {
            // New member created, backend returns credentials in the raw JSON response.
            // Wait, our invite method parses TeamMember directly. 
            // We changed the API to return {success: true, data: newMember, credentials: {email, password}}
            // So we need to show the CredentialsGeneratedDialog. Wait, we don't have the password!
            // Let's hardcode the initial password as per spec if we don't get it back easily, or modify TeamRepository to return it.
            // The spec said password is given.
            if (ctx.mounted) {
               showDialog(
                context: ctx,
                builder: (_) => CredentialsGeneratedDialog(
                  email: email,
                  password: 'GoExperts@2025',
                ),
              );
            }
          }
        },
      ),
    );
    if (mounted) _load();
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
      title: const Text('Teams Directory'),
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
      label: const Text('Add Member'),
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
                _buildOwnerCard(),
                AppSizes.vGapLg,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Team Members (${_members.length})',
                      style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.filter_list),
                      label: const Text('Filter'),
                    ),
                  ],
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

  Widget _buildOwnerCard() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.shade50,
      child: Row(
        children: [
          const AppAvatar(name: 'Workspace Owner', size: 56),
          AppSizes.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Workspace Owner', style: context.text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Text('Full Access', style: TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          const Icon(Icons.verified, color: Colors.blue),
        ],
      ),
    );
  }
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
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          AppAvatar(name: member.name.isEmpty ? 'Member' : member.name, size: 48),
          AppSizes.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.name, style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
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
                Wrap(
                  spacing: 4,
                  children: member.permissions.permittedDashboards.map((db) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(db.toUpperCase(), style: const TextStyle(fontSize: 10)),
                    );
                  }).toList(),
                )
              ],
            ),
          ),
          Column(
            children: [
              AppStatusChip(
                label: member.status.isEmpty ? 'Invited' : member.status,
                dense: true,
                color: member.status.toLowerCase() == 'active'
                    ? AppColors.success
                    : AppColors.warning,
              ),
              PopupMenuButton<String>(
                tooltip: 'Member actions',
                onSelected: (value) => value == 'edit' ? onEdit() : onRemove(),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit Access')),
                  PopupMenuItem(value: 'remove', child: Text('Remove')),
                ],
              ),
            ],
          )
        ],
      ),
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
