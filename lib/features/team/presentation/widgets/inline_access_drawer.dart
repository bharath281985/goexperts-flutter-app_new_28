import 'package:flutter/material.dart';

import '../../domain/team_member.dart';

class InlineAccessDrawer extends StatefulWidget {
  const InlineAccessDrawer({
    super.key,
    required this.member,
    required this.onSave,
    required this.onSavedComplete,
  });

  final TeamMember member;
  final Future<void> Function(List<String> dashboards, PermissionsData permissions) onSave;
  final VoidCallback onSavedComplete;

  @override
  State<InlineAccessDrawer> createState() => _InlineAccessDrawerState();
}

class _InlineAccessDrawerState extends State<InlineAccessDrawer> {
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
    final perms = widget.member.permissions;
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

  Future<void> _submit() async {
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
        permittedDashboards,
        PermissionsData(modulePermissions: modulePermissions),
      );
      widget.onSavedComplete();
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Manage Access: ${widget.member.name}', style: Theme.of(context).textTheme.titleLarge),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Access Settings'),
            ),
          )
        ],
      ),
    );
  }
}
