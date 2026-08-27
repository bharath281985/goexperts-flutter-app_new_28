import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/auth/token_role_helper.dart';
import '../../../../core/utils/paginated.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/enums.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';

/// API-backed project repository. Screens show backend data, empty states, or errors.
class ProjectRepositoryImpl implements ProjectRepository {
  ProjectRepositoryImpl([this._api, this._tokenRoleHelper]);

  final ApiClientHelper? _api;
  final TokenRoleHelper? _tokenRoleHelper;

  Future<UserRole?> _role() async => await _tokenRoleHelper?.resolve();
  @override
  Future<Result<Paginated<Project>>> getProjects(QueryParams params) async {
    if (_api == null) return _apiNotConfigured();

    final role = await _role();
    final String path;
    if (role == UserRole.client) {
      path = ApiEndpoints.clientProjects;
    } else {
      path = ApiEndpoints.publicProjects;
    }

    final result = await _api.getEnvelope<Paginated<Project>>(
      path,
      query: params.toApiQuery(),
      parser: (envelope) => ApiResponse.parsePaginated(
        envelope.data,
        envelope.meta,
        Project.fromApiJson,
        fallbackPage: params.page,
      ),
    );
    return result;
  }

  @override
  Future<Result<Project>> getProject(String id) async {
    if (_api == null) return _apiNotConfigured();

    final role = await _role();
    final path = role == UserRole.client
        ? ApiEndpoints.clientProject(id)
        : '${ApiEndpoints.publicProjects}/$id';

    final result = await _api.get<Project>(
      path,
      parser: (data) =>
          Project.fromApiJson(Map<String, dynamic>.from(data as Map)),
    );
    return result;
  }

  @override
  Future<Result<Project>> updateProject(
    String id,
    Map<String, dynamic> data,
  ) async {
    if (_api == null) return _apiNotConfigured();
    return _api.putEnvelope<Project>(
      ApiEndpoints.clientProject(id),
      body: data,
      parser: (envelope) =>
          Project.fromApiJson(Map<String, dynamic>.from(envelope.data as Map)),
    );
  }

  @override
  Future<Result<bool>> updateProjectStatus(String id, String status) async {
    if (_api == null) return _apiNotConfigured();
    return _api.patchAction(
      ApiEndpoints.clientProjectStatus(id),
      body: {'status': status},
    );
  }

  @override
  Future<Result<bool>> deleteProject(String id) async {
    if (_api == null) return _apiNotConfigured();
    return _api.deleteAction(ApiEndpoints.clientProject(id));
  }

  @override
  Future<Result<bool>> trackProjectShare(String id, String platform) async {
    if (_api == null) return _apiNotConfigured();
    // Prefer public share so any role can track; fall back to client path.
    final primary = await _api.postAction(
      '/public/projects/$id/share',
      body: {'platform': platform},
    );
    if (primary.isSuccess) return primary;
    return _api.postAction(
      ApiEndpoints.clientProjectShare(id),
      body: {'platform': platform},
    );
  }

  @override
  Future<Result<bool>> toggleSave(String id) async {
    if (_api == null) return _apiNotConfigured();
    return _api.postAction(
      '${ApiEndpoints.favorites}/toggle',
      body: {'entityType': 'project', 'entityId': id},
    );
  }

  @override
  Future<Result<bool>> apply(String id) async {
    if (_api == null) return _apiNotConfigured();
    // Apply = open proposal create; return success so UI can navigate to Apply form.
    // Actual bid is submitted via ProposalRepository.submitProposal.
    return const Success(true);
  }

  @override
  Future<Result<Paginated<Contract>>> getContracts(QueryParams params) async {
    if (_api == null) return _apiNotConfigured();

    final role = await _role();
    final path = role == UserRole.client
        ? ApiEndpoints.clientContracts
        : ApiEndpoints.freelancerContracts;
    return _api.getEnvelope<Paginated<Contract>>(
      path,
      query: params.toApiQuery(),
      parser: (envelope) => ApiResponse.parsePaginated(
        envelope.data,
        envelope.meta,
        _contractFromJson,
        fallbackPage: params.page,
      ),
    );
  }

  @override
  Future<Result<Contract>> getContract(String id) async {
    if (_api == null) return _apiNotConfigured();

    final role = await _role();
    final path = role == UserRole.client
        ? '${ApiEndpoints.clientContracts}/$id'
        : ApiEndpoints.freelancerContract(id);
    return _api.get<Contract>(
      path,
      parser: (data) =>
          _contractFromJson(Map<String, dynamic>.from(data as Map)),
    );
  }

  @override
  Future<Result<Contract>> createContract(Map<String, dynamic> data) async {
    if (_api == null) return _apiNotConfigured();
    return _api.postEnvelope<Contract>(
      ApiEndpoints.clientContracts,
      body: data,
      parser: (envelope) =>
          _contractFromJson(Map<String, dynamic>.from(envelope.data as Map)),
    );
  }

  @override
  Future<Result<Contract>> updateContract(
    String id,
    Map<String, dynamic> data,
  ) async {
    if (_api == null) return _apiNotConfigured();
    return _api.putEnvelope<Contract>(
      '${ApiEndpoints.clientContracts}/$id',
      body: data,
      parser: (envelope) =>
          _contractFromJson(Map<String, dynamic>.from(envelope.data as Map)),
    );
  }

  static Contract _contractFromJson(Map<String, dynamic> json) {
    final milestonesRaw = json['milestones'] as List?;
    final milestones =
        milestonesRaw
            ?.whereType<Map>()
            .map(
              (m) => Milestone(
                title:
                    m['title']?.toString() ??
                    m['milestoneTitle']?.toString() ??
                    '',
                amount: (m['amount'] as num?)?.toDouble() ?? 0,
                status: EntityStatus.fromString(
                  m['status']?.toString() ?? 'pending',
                ),
                dueDate:
                    DateTime.tryParse(m['dueDate']?.toString() ?? '') ??
                    DateTime.now(),
              ),
            )
            .toList() ??
        const <Milestone>[];

    final project = json['project'] as Map<String, dynamic>?;
    final freelancer = json['freelancer'] as Map<String, dynamic>?;
    final client = json['client'] as Map<String, dynamic>?;
    final proposal = json['proposal'] as Map<String, dynamic>?;
    final fProfile = freelancer?['freelancerProfile'] as Map<String, dynamic>?;

    final freelancerName =
        freelancer?['fullName'] as String? ??
        json['freelancerName'] as String? ??
        json['counterpartyName'] as String? ??
        'Freelancer';
    final freelancerAvatar =
        freelancer?['avatarUrl'] as String? ??
        json['freelancerAvatar'] as String? ??
        json['counterpartyAvatar'] as String? ??
        json['avatarUrl'] as String?;

    final clientName =
        client?['fullName'] as String? ??
        json['clientName'] as String? ??
        json['client_name'] as String?;
    final clientAvatar =
        client?['avatarUrl'] as String? ??
        json['clientAvatar'] as String? ??
        json['client_avatar'] as String?;

    final projectTitle =
        project?['title'] as String? ??
        json['projectTitle'] as String? ??
        json['project_title'] as String? ??
        'Project Contract';

    final amount =
        (proposal?['bidAmount'] as num?)?.toDouble() ??
        (json['amount'] as num?)?.toDouble() ??
        (json['bidAmount'] as num?)?.toDouble() ??
        0.0;

    final proposalBid =
        (proposal?['bidAmount'] as num?)?.toDouble() ??
        (json['bidAmount'] as num?)?.toDouble() ??
        amount;
    final proposalDelivery =
        (proposal?['deliveryTime'] as num?)?.toInt() ??
        (proposal?['deliveryDays'] as num?)?.toInt() ??
        (json['deliveryTime'] as num?)?.toInt();
    final proposalCover =
        proposal?['coverLetter'] as String? ??
        json['coverLetter'] as String? ??
        json['cover_letter'] as String?;
    final proposalStatus =
        proposal?['status'] as String? ?? json['proposalStatus'] as String?;

    return Contract(
      id: json['id']?.toString() ?? '',
      contractNumber:
          json['contractNumber'] as String? ??
          json['contract_number'] as String?,
      projectId: json['projectId']?.toString() ?? project?['id']?.toString(),
      projectTitle: projectTitle,
      clientId: json['clientId']?.toString() ?? client?['id']?.toString(),
      clientName: clientName,
      clientAvatar: clientAvatar,
      freelancerId:
          json['freelancerId']?.toString() ?? freelancer?['id']?.toString(),
      freelancerName: freelancerName,
      freelancerAvatar: freelancerAvatar,
      freelancerTitle: fProfile?['titleHeadline'] as String?,
      freelancerRating: (fProfile?['rating'] as num?)?.toDouble(),
      proposalId:
          json['proposalId']?.toString() ?? proposal?['id']?.toString(),
      proposalBidAmount: proposalBid,
      proposalDeliveryTime: proposalDelivery,
      proposalCoverLetter: proposalCover,
      proposalStatus: proposalStatus,
      counterpartyName: freelancerName,
      counterpartyAvatar: freelancerAvatar,
      amount: amount,
      status: EntityStatus.fromString(json['status'] as String? ?? 'pending'),
      startDate:
          DateTime.tryParse(
            json['startDate'] as String? ??
                json['start_date'] as String? ??
                json['createdAt'] as String? ??
                json['created_at'] as String? ??
                '',
          ) ??
          DateTime.now(),
      milestones: milestones,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
    );
  }

  Future<Result<T>> _apiNotConfigured<T>() async =>
      const Err(ServerFailure('Live API client is not configured.'));
}
