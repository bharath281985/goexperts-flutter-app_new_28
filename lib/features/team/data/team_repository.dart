import '../../../core/network/api_client_helper.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/utils/result.dart';
import '../domain/team_member.dart';

enum TeamOwner { client, founder }

class TeamRepository {
  TeamRepository(this._api, this.owner);

  final ApiClientHelper _api;
  final TeamOwner owner;

  String get _base => owner == TeamOwner.client
      ? ApiEndpoints.clientTeam
      : ApiEndpoints.founderTeam;

  Future<Result<TeamMembersResult>> getTeam() =>
      _api.get(_base, parser: TeamMembersResult.fromJson);

  Future<Result<TeamMember>> invite({
    required String name,
    required String email,
    required String role,
    String? department,
  }) => _api.post(
    owner == TeamOwner.client ? ApiEndpoints.clientTeamInvite : _base,
    body: {
      'name': name,
      'email': email,
      'role': role,
      if (owner == TeamOwner.client && department?.isNotEmpty == true)
        'department': department,
    },
    parser: TeamMember.fromJson,
  );

  Future<Result<TeamMember>> update(
    TeamMember member, {
    required String name,
    required String email,
    required String role,
    required String status,
  }) {
    final path = owner == TeamOwner.client
        ? ApiEndpoints.clientTeamMemberRole(member.id)
        : ApiEndpoints.founderTeamMember(member.id);
    if (owner == TeamOwner.client) {
      return _api.patchEnvelope(
        path,
        body: {'role': role},
        parser: (envelope) => TeamMember.fromJson(envelope.data),
      );
    }
    return _api.put(
      path,
      body: {'name': name, 'email': email, 'role': role, 'status': status},
      parser: TeamMember.fromJson,
    );
  }

  Future<Result<bool>> remove(String memberId) => _api.deleteAction(
    owner == TeamOwner.client
        ? ApiEndpoints.clientTeamMember(memberId)
        : ApiEndpoints.founderTeamMember(memberId),
  );
}
