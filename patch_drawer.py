import re

with open('lib/core/widgets/app_drawer.dart', 'r') as f:
    content = f.read()

# Add import if missing
if \"import '../services/permission_service.dart';\" not in content:
    content = content.replace(
        \"import 'permission_gate.dart';\",
        \"import 'permission_gate.dart';\nimport '../services/permission_service.dart';\"
    )

# Find build method in _FounderDrawer
build_start = content.find('  @override\\n  Widget build(BuildContext context) {', content.find('class _FounderDrawer extends StatelessWidget'))
build_end = content.find('    return Drawer(', build_start)

injection = \"\"\"
    final permissionService = PermissionService(currentUser: user);
    final filteredSections = sections.map((section) {
      final permittedEntries = section.entries.where((entry) {
        if (entry.requiredDashboard != null && !permissionService.hasDashboardAccess(entry.requiredDashboard!)) {
          return false;
        }
        if (entry.requiredModule != null && !permissionService.canRead(entry.requiredModule!)) {
          return false;
        }
        return true;
      }).toList();
      return DrawerSection(section.title, permittedEntries);
    }).where((section) => section.entries.isNotEmpty).toList();
\"\"\"

if 'final permissionService' not in content[build_start:build_end]:
    content = content[:build_end] + injection + content[build_end:]

# Replace sections loop
content = content.replace(
    'for (final section in sections)',
    'for (final section in filteredSections)'
)

with open('lib/core/widgets/app_drawer.dart', 'w') as f:
    f.write(content)

print('Patched app_drawer.dart')
