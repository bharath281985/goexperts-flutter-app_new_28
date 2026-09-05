class PermissionsData {
  const PermissionsData({
    this.permittedDashboards = const [],
    this.capabilities = const [],
    this.modulePermissions = const {},
  });

  final List<String> permittedDashboards;
  final List<String> capabilities;
  final Map<String, dynamic> modulePermissions;

  factory PermissionsData.fromJson(dynamic value) {
    if (value is! Map) {
      return const PermissionsData();
    }
    
    final json = Map<String, dynamic>.from(value);
    
    List<String> parsedDashboards = [];
    if (json['permittedDashboards'] is List) {
      parsedDashboards = (json['permittedDashboards'] as List).map((e) => e.toString()).toList();
    }

    List<String> parsedCapabilities = [];
    if (json['capabilities'] is List) {
      parsedCapabilities = (json['capabilities'] as List).map((e) => e.toString()).toList();
    }

    Map<String, dynamic> parsedModules = {};
    if (json['modulePermissions'] is Map) {
      parsedModules = Map<String, dynamic>.from(json['modulePermissions'] as Map);
    }

    return PermissionsData(
      permittedDashboards: parsedDashboards,
      capabilities: parsedCapabilities,
      modulePermissions: parsedModules,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'permittedDashboards': permittedDashboards,
      'capabilities': capabilities,
      'modulePermissions': modulePermissions,
    };
  }
}

class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.status,
    required this.permissions,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String department;
  final String status;
  final PermissionsData permissions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TeamMember.fromJson(dynamic value) {
    final json = value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};

    return TeamMember(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      status: json['status']?.toString() ?? 'invited',
      permissions: PermissionsData.fromJson(json['permissions']),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}

class TeamMembersResult {
  const TeamMembersResult({required this.members, required this.total});

  final List<TeamMember> members;
  final int total;

  factory TeamMembersResult.fromJson(dynamic value) {
    if (value is List) {
      final members = value.map(TeamMember.fromJson).toList();
      return TeamMembersResult(members: members, total: members.length);
    }
    final json = value is Map
        ? Map<String, dynamic>.from(value)
        : <String, dynamic>{};
    final rawMembers = json['rows'] ?? json['members'];
    final members = rawMembers is List
        ? rawMembers.map(TeamMember.fromJson).toList()
        : <TeamMember>[];
    final rawTotal = json['total'];
    return TeamMembersResult(
      members: members,
      total: rawTotal is num
          ? rawTotal.toInt()
          : int.tryParse(rawTotal?.toString() ?? '') ?? members.length,
    );
  }
}
