import '../../../../core/auth/token_role_helper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client_helper.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response.dart';
import '../../../../core/utils/enums.dart';
import '../../../../core/utils/paginated.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/proposal.dart';
import '../../domain/repositories/proposal_repository.dart';

class ProposalRepositoryImpl implements ProposalRepository {
  ProposalRepositoryImpl([this._api, this._tokenRoleHelper]);

  final ApiClientHelper? _api;
  final TokenRoleHelper? _tokenRoleHelper;

  Future<UserRole?> _role() async => await _tokenRoleHelper?.resolve();

  @override
  Future<Result<Paginated<Proposal>>> getProposals(QueryParams params) async {
    if (_api == null) return _apiNotConfigured();

    final role = await _role();
    final path = role != null
        ? ApiEndpoints.roleProposals(role)
        : ApiEndpoints.freelancerProposals;

    var result = await _api.getEnvelope<Paginated<Proposal>>(
      path,
      query: params.toApiQuery(),
      parser: (envelope) => ApiResponse.parsePaginated(
        envelope.data,
        envelope.meta,
        _proposalFromJson,
        fallbackPage: params.page,
      ),
    );
    if (result.isFailure && path != ApiEndpoints.freelancerProposals) {
      final fallback = await _api.getEnvelope<Paginated<Proposal>>(
        ApiEndpoints.freelancerProposals,
        query: params.toApiQuery(),
        parser: (envelope) => ApiResponse.parsePaginated(
          envelope.data,
          envelope.meta,
          _proposalFromJson,
          fallbackPage: params.page,
        ),
      );
      if (fallback.isSuccess) {
        result = fallback;
      }
    }
    return result;
  }

  @override
  Future<Result<Proposal>> getProposal(String id) async {
    if (_api == null) return _apiNotConfigured();

    final role = await _role();
    final path = role != null
        ? ApiEndpoints.roleProposal(role, id)
        : ApiEndpoints.freelancerProposal(id);

    var result = await _api.get<Proposal>(
      path,
      parser: (data) =>
          _proposalFromJson(Map<String, dynamic>.from(data as Map)),
    );
    if (result.isFailure && path != ApiEndpoints.freelancerProposal(id)) {
      final fallback = await _api.get<Proposal>(
        ApiEndpoints.freelancerProposal(id),
        parser: (data) =>
            _proposalFromJson(Map<String, dynamic>.from(data as Map)),
      );
      if (fallback.isSuccess) {
        result = fallback;
      }
    }
    return result;
  }

  @override
  Future<Result<Proposal>> submitProposal({
    required String projectId,
    required String coverLetter,
    required double bidAmount,
    required int deliveryDays,
    List<String> attachments = const [],
  }) async {
    if (_api == null) return _apiNotConfigured();

    final role = await _role();
    final body = <String, dynamic>{
      'projectId': projectId,
      'bidAmount': bidAmount,
      'coverLetter': coverLetter,
      'deliveryTime': deliveryDays,
      if (attachments.isNotEmpty) 'attachments': attachments,
    };

    var res = await _api.post<Proposal>(
      ApiEndpoints.freelancerProposals,
      body: body,
      parser: (data) =>
          _proposalFromJson(Map<String, dynamic>.from(data as Map)),
      allowNullData: false,
    );
    if (res.isFailure && role != null) {
      final rolePath = ApiEndpoints.roleProposals(role);
      if (rolePath != ApiEndpoints.freelancerProposals) {
        final fallbackRes = await _api.post<Proposal>(
          rolePath,
          body: body,
          parser: (data) =>
              _proposalFromJson(Map<String, dynamic>.from(data as Map)),
          allowNullData: false,
        );
        if (fallbackRes.isSuccess) {
          res = fallbackRes;
        }
      }
    }
    return res;
  }

  @override
  Future<Result<Proposal>> updateProposal({
    required String proposalId,
    required String coverLetter,
    required double bidAmount,
    int? deliveryDays,
  }) async {
    if (_api == null) return _apiNotConfigured();

    final role = await _role();
    return _api.putEnvelope<Proposal>(
      ApiEndpoints.roleProposal(role, proposalId),
      body: {
        'bidAmount': bidAmount,
        'coverLetter': coverLetter,
        if (deliveryDays != null) 'deliveryTime': deliveryDays,
      },
      parser: (envelope) =>
          _proposalFromJson(Map<String, dynamic>.from(envelope.data as Map)),
    );
  }

  @override
  Future<Result<bool>> withdraw(String id) async {
    if (_api == null) return _apiNotConfigured();
    final role = await _role();
    final primary = await _api.deleteAction(
      '/${ApiEndpoints.rolePath(role)}/proposals/$id/withdraw',
    );
    if (primary.isSuccess) return primary;
    return _api.deleteAction(ApiEndpoints.freelancerProposalWithdraw(id));
  }

  @override
  Future<Result<bool>> deleteProposal(String id) async {
    if (_api == null) return _apiNotConfigured();
    final role = await _role();
    return _api.deleteAction(ApiEndpoints.roleProposal(role, id));
  }

  @override
  Future<Result<bool>> updateStatus(String id, String status) async {
    if (_api == null) return _apiNotConfigured();
    final role = await _role();
    final rolePath = ApiEndpoints.rolePath(role);
    final normalized = status.toLowerCase().trim();
    final path = switch (normalized) {
      'shortlisted' || 'shortlist' => '/$rolePath/proposals/$id/shortlist',
      'rejected' || 'reject' => '/$rolePath/proposals/$id/reject',
      'interview' => '/$rolePath/proposals/$id/interview',
      'accepted' || 'accept' => '/$rolePath/proposals/$id/accept',
      _ => null,
    };
    if (path == null) {
      return Err(ValidationFailure('Unsupported proposal status: $status'));
    }
    return _api.patchAction(path);
  }

  static Proposal _proposalFromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] as String? ?? 'pending';
    final deliveryDays =
        json['deliveryDays'] ?? json['deliveryTime'] ?? json['delivery_time'];

    return Proposal(
      id: json['id']?.toString() ?? '',
      projectId:
          json['projectId']?.toString() ?? json['project_id']?.toString() ?? '',
      projectTitle:
          json['projectTitle'] as String? ??
          json['project_title'] as String? ??
          'Project',
      clientId:
          json['clientId']?.toString() ??
          json['client_id']?.toString() ??
          (json['project'] is Map
              ? (json['project'] as Map)['client']?.toString()
              : null),
      clientName:
          json['clientName'] as String? ?? json['client_name'] as String?,
      freelancerId:
          json['freelancerId']?.toString() ?? json['freelancer_id']?.toString(),
      freelancerName:
          json['freelancerName'] as String? ??
          json['freelancer_name'] as String? ??
          'Freelancer',
      freelancerAvatar:
          json['freelancerAvatar'] as String? ??
          json['freelancer_avatar'] as String? ??
          json['avatarUrl'] as String?,
      contractId:
          json['contractId']?.toString() ??
          json['contract_id']?.toString() ??
          (json['contract'] is Map
              ? (json['contract'] as Map)['id']?.toString()
              : null),
      bidAmount:
          (json['bidAmount'] as num?)?.toDouble() ??
          (json['bid_amount'] as num?)?.toDouble() ??
          0,
      isHourly:
          json['isHourly'] as bool? ?? json['is_hourly'] as bool? ?? false,
      coverLetter:
          json['coverLetter'] as String? ??
          json['cover_letter'] as String? ??
          json['coverletter'] as String? ??
          '',
      status: EntityStatus.fromString(rawStatus),
      submittedAt:
          DateTime.tryParse(
            json['createdAt'] as String? ?? json['created_at'] as String? ?? '',
          ) ??
          DateTime.now(),
      deliveryDays: (deliveryDays as num?)?.toInt() ?? 14,
      freelancerRating:
          (json['freelancerRating'] as num?)?.toDouble() ??
          (json['freelancer_rating'] as num?)?.toDouble() ??
          4.8,
      attachments:
          (json['attachments'] as List?)?.map((e) => e.toString()).toList() ??
          (json['attachmentUrls'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  static Future<Result<T>> _apiNotConfigured<T>() async =>
      const Err(ServerFailure('Live API client is not configured.'));
}
