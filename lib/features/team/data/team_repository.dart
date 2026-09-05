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
    Map<String, List<String>>? permissions,
  }) => _api.post(
    ApiEndpoints.mobileTeamInvite,
    body: {
      'name': name,
      'email': email,
      'role': role,
      if (department?.isNotEmpty == true) 'department': department,
      if (permissions != null) 'permissions': permissions,
    },
    parser: TeamMember.fromJson,
  );

  Future<Result<TeamMember>> update(
    TeamMember member, {
    String? name,
    String? email,
    String? role,
    String? status,
    Map<String, List<String>>? permissions,
  }) {
    return _api.patchEnvelope(
      ApiEndpoints.mobileTeamMemberPermissions(member.id),
      body: {
        if (role != null) 'role': role,
        if (permissions != null) 'permissions': permissions,
        if (status != null) 'status': status,
      },
      parser: (envelope) => TeamMember.fromJson(envelope.data),
    );
  }

  Future<Result<bool>> remove(String memberId) => _api.deleteAction(
    ApiEndpoints.mobileTeamMember(memberId),
  );
}
