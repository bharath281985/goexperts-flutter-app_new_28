import 'package:flutter/material.dart';

import '../../domain/team_member.dart';

class AddEditMemberModal extends StatefulWidget {
  const AddEditMemberModal({
    super.key,
    this.member,
    required this.onSave,
  });

  final TeamMember? member;
  final Future<void> Function(
    String name,
    String email,
    String role,
    String department,
    List<String> permittedDashboards,
    PermissionsData permissions,
  ) onSave;

  @override
  State<AddEditMemberModal> createState() => _AddEditMemberModalState();
}

class _AddEditMemberModalState extends State<AddEditMemberModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _roleController;
  late TextEditingController _departmentController;

  final Map<String, bool> _dashboards = {
    'client': false,
    'freelancer': false,
    'founder': false,
    'investor': false,
  };

  final Map<String, Map<String, bool>> _crudMatrix = {
    'contracts': {'create': false, 'read': false, 'update': false, 'delete': false},
    'payments': {'create': false, 'read': false, 'update': false, 'delete': false},
    'projects': {'create': false, 'read': false, 'update': false, 'delete': false},
    'analytics': {'create': false, 'read': false, 'update': false, 'delete': false},
    'team': {'create': false, 'read': false, 'update': false, 'delete': false},
  };

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member?.name ?? '');
    _emailController = TextEditingController(text: widget.member?.email ?? '');
    _roleController = TextEditingController(text: widget.member?.role ?? '');
    _departmentController = TextEditingController(text: widget.member?.department ?? '');

    if (widget.member != null) {
      final perms = widget.member!.permissions;
      for (final db in perms.permittedDashboards) {
        if (_dashboards.containsKey(db)) _dashboards[db] = true;
      }
      
      for (final entry in perms.modulePermissions.entries) {
        if (_crudMatrix.containsKey(entry.key)) {
          final capabilities = entry.value as List<dynamic>? ?? [];
          for (final cap in capabilities) {
            final capStr = cap.toString();
            if (_crudMatrix[entry.key]!.containsKey(capStr)) {
              _crudMatrix[entry.key]![capStr] = true;
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final permittedDashboards = _dashboards.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (permittedDashboards.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one dashboard.')),
      );
      return;
    }

    final modulePermissions = <String, dynamic>{};
    for (final entry in _crudMatrix.entries) {
      final selectedCaps = entry.value.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();
      if (selectedCaps.isNotEmpty) {
        modulePermissions[entry.key] = selectedCaps;
      }
    }

    setState(() => _isLoading = true);
    try {
      await widget.onSave(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _roleController.text.trim(),
        _departmentController.text.trim(),
        permittedDashboards,
        PermissionsData(modulePermissions: modulePermissions),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.member == null ? 'Invite Team Member' : 'Edit Access',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                // Basics
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  enabled: widget.member == null,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _roleController,
                        decoration: const InputDecoration(labelText: 'Role (e.g., Manager)', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _departmentController,
                        decoration: const InputDecoration(labelText: 'Department', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Dashboard Access
                Text('Portal Access', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _dashboards.keys.map((key) {
                    return FilterChip(
                      label: Text(key.toUpperCase()),
                      selected: _dashboards[key]!,
                      onSelected: (val) {
                        setState(() => _dashboards[key] = val);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // CRUD Matrix
                Text('Module Permissions', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Table(
                  border: TableBorder.all(color: Colors.grey.shade300),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade100),
                      children: const [
                        Padding(padding: EdgeInsets.all(8), child: Text('Module', style: TextStyle(fontWeight: FontWeight.bold))),
                        Padding(padding: EdgeInsets.all(8), child: Center(child: Text('Create', style: TextStyle(fontWeight: FontWeight.bold)))),
                        Padding(padding: EdgeInsets.all(8), child: Center(child: Text('Read', style: TextStyle(fontWeight: FontWeight.bold)))),
                        Padding(padding: EdgeInsets.all(8), child: Center(child: Text('Update', style: TextStyle(fontWeight: FontWeight.bold)))),
                        Padding(padding: EdgeInsets.all(8), child: Center(child: Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)))),
                      ],
                    ),
                    for (final module in _crudMatrix.keys)
                      TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(module.toUpperCase()),
                          ),
                          for (final action in ['create', 'read', 'update', 'delete'])
                            Checkbox(
                              value: _crudMatrix[module]![action],
                              onChanged: (val) {
                                setState(() => _crudMatrix[module]![action] = val!);
                              },
                            )
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : Text(widget.member == null ? 'Send Invite' : 'Save Changes'),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
