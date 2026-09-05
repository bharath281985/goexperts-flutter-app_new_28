import '../../../core/network/api_client_helper.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/utils/result.dart';
import '../domain/team_member.dart';

class TeamRepository {
  TeamRepository(this._api);

  final ApiClientHelper _api;

  String get _base => ApiEndpoints.mobileTeam;

  Future<Result<TeamMembersResult>> getTeam() =>
      _api.get(_base, parser: TeamMembersResult.fromJson);

  Future<Result<TeamMember>> invite({
    required String name,
    required String email,
    required String role,
    String? department,
    String? password,
    bool? emailVerified,
    required List<String> permittedDashboards,
    PermissionsData? permissions,
  }) => _api.post(
    ApiEndpoints.mobileTeamInvite,
    body: {
      'name': name,
      'email': email,
      'role': role,
      if (department?.isNotEmpty == true) 'department': department,
      if (password?.isNotEmpty == true) 'password': password,
      if (emailVerified != null) 'emailVerified': emailVerified,
      'permittedDashboards': permittedDashboards,
      if (permissions != null) 'permissions': permissions.toJson(),
    },
    parser: (data) {
      if (data is Map && data['data'] != null) {
        return TeamMember.fromJson(data['data']);
      }
      return TeamMember.fromJson(data);
    },
  );

  Future<Result<TeamMember>> update(
    TeamMember member, {
    String? name,
    String? role,
    String? department,
    String? status,
    List<String>? permittedDashboards,
    PermissionsData? permissions,
  }) {
    return _api.patchEnvelope(
      ApiEndpoints.mobileTeamMemberPermissions(member.id),
      body: {
        if (name != null) 'name': name,
        if (role != null) 'role': role,
        if (department != null) 'department': department,
        if (status != null) 'status': status,
        if (permittedDashboards != null) 'permittedDashboards': permittedDashboards,
        if (permissions != null) 'permissions': permissions.toJson(),
      },
      parser: (envelope) => TeamMember.fromJson(envelope.data),
    );
  }

  Future<Result<bool>> remove(String memberId) => _api.deleteAction(
    ApiEndpoints.mobileTeamMember(memberId),
  );
}
