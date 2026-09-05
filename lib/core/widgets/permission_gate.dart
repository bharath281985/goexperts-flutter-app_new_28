import 'package:flutter/material.dart';
import '../services/permission_service.dart';
import '../../features/auth/domain/entities/app_user.dart';

enum PermissionAction { read, create, update, delete }

class PermissionGate extends StatelessWidget {
  final AppUser? user;
  final String module;
  final PermissionAction action;
  final Widget child;
  final Widget fallback;
  final String? requiredDashboard;

  const PermissionGate({
    Key? key,
    required this.user,
    required this.module,
    this.action = PermissionAction.read,
    required this.child,
    this.fallback = const SizedBox.shrink(),
    this.requiredDashboard,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (user == null) return fallback;

    final permissionService = PermissionService(currentUser: user);

    // If dashboard access is required and not present
    if (requiredDashboard != null && !permissionService.hasDashboardAccess(requiredDashboard!)) {
      return fallback;
    }

    bool hasAccess = false;
    switch (action) {
      case PermissionAction.read:
        hasAccess = permissionService.canRead(module);
        break;
      case PermissionAction.create:
        hasAccess = permissionService.canCreate(module);
        break;
      case PermissionAction.update:
        hasAccess = permissionService.canUpdate(module);
        break;
      case PermissionAction.delete:
        hasAccess = permissionService.canDelete(module);
        break;
    }

    if (hasAccess) {
      return child;
    } else {
      return fallback;
    }
  }
}
