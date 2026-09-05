import '../../features/auth/domain/entities/app_user.dart';

/// Service to handle role-based access management.
class PermissionService {
  final AppUser? currentUser;

  PermissionService({this.currentUser});

  /// Check if the user is a workspace owner.
  bool get isOwner => currentUser?.isOwner ?? false;

  /// Check if the user has access to a specific dashboard.
  bool hasDashboardAccess(String dashboard) {
    if (isOwner) return true;
    return currentUser?.permittedDashboards.contains(dashboard) ?? false;
  }

  /// Check if the user has read access to a specific module.
  bool canRead(String moduleName) {
    if (isOwner) return true;
    final perms = currentUser?.modulePermissions[moduleName] as Map<String, dynamic>?;
    return perms?['read'] == true;
  }

  /// Check if the user has create access to a specific module.
  bool canCreate(String moduleName) {
    if (isOwner) return true;
    final perms = currentUser?.modulePermissions[moduleName] as Map<String, dynamic>?;
    return perms?['create'] == true;
  }

  /// Check if the user has update access to a specific module.
  bool canUpdate(String moduleName) {
    if (isOwner) return true;
    final perms = currentUser?.modulePermissions[moduleName] as Map<String, dynamic>?;
    return perms?['update'] == true;
  }

  /// Check if the user has delete access to a specific module.
  bool canDelete(String moduleName) {
    if (isOwner) return true;
    final perms = currentUser?.modulePermissions[moduleName] as Map<String, dynamic>?;
    return perms?['delete'] == true;
  }
}
