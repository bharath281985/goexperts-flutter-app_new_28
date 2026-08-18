class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.department,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String department;
  final String status;
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
    final rawMembers = json['members'];
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
