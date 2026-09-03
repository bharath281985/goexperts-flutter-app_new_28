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
  Future<Result<Paginated<Proposal>>> getProjectProposals(
    String projectId,
    QueryParams params,
  ) async {
    if (_api == null) return _apiNotConfigured();

    var result = await _api.getEnvelope<Paginated<Proposal>>(
      '/public/projects/$projectId/proposals',
      query: params.toApiQuery(),
      parser: (envelope) => ApiResponse.parsePaginated(
        envelope.data,
        envelope.meta,
        _proposalFromJson,
        fallbackPage: params.page,
      ),
    );
    if (result.isFailure) {
      final fallback = await _api.getEnvelope<Paginated<Proposal>>(
        ApiEndpoints.clientProjectProposals(projectId),
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
    if (result.isFailure && path != ApiEndpoints.clientProposal(id)) {
      final clientFallback = await _api.get<Proposal>(
        ApiEndpoints.clientProposal(id),
        parser: (data) =>
            _proposalFromJson(Map<String, dynamic>.from(data as Map)),
      );
      if (clientFallback.isSuccess) {
        result = clientFallback;
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
    final path = role != null
        ? ApiEndpoints.roleProposal(role, proposalId)
        : ApiEndpoints.freelancerProposal(proposalId);

    return _api.putEnvelope<Proposal>(
      path,
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
    final primary = await _api.deleteAction(
      ApiEndpoints.freelancerProposalWithdraw(id),
    );
    if (primary.isSuccess) return primary;

    final role = await _role();
    final fallback = await _api.deleteAction(
      '/${ApiEndpoints.rolePath(role)}/proposals/$id/withdraw',
    );
    if (fallback.isSuccess) return fallback;

    return _api.postAction(ApiEndpoints.freelancerProposalWithdraw(id));
  }

  @override
  Future<Result<bool>> acceptOffer(String id) async {
    if (_api == null) return _apiNotConfigured();

    // 1. Try accepting directly as contract offer if id is contract ID
    var res = await _api.postAction(ApiEndpoints.freelancerContractAccept(id));
    if (res.isSuccess) return res;

    // 2. If id is proposal ID, look up contract matching this proposal
    try {
      final contractsRes = await _api.getEnvelope<List<dynamic>>(
        ApiEndpoints.freelancerContracts,
        parser: (env) => (env.data is List) ? env.data as List : const [],
      );
      if (contractsRes.isSuccess && contractsRes.valueOrNull != null) {
        final list = contractsRes.valueOrNull!;
        for (final item in list) {
          if (item is Map &&
              (item['proposalId']?.toString() == id ||
                  item['proposal_id']?.toString() == id)) {
            final contractId = item['id']?.toString();
            if (contractId != null && contractId.isNotEmpty) {
              final contractAcceptRes = await _api.postAction(
                ApiEndpoints.freelancerContractAccept(contractId),
              );
              if (contractAcceptRes.isSuccess) return contractAcceptRes;
            }
          }
        }
      }
    } catch (_) {}

    // 3. Fallback to POST on proposal endpoints (strictly POST, never PATCH)
    res = await _api.postAction(
      ApiEndpoints.freelancerProposalAcceptOffer(id),
    );
    if (res.isSuccess) return res;

    res = await _api.postAction(
      '/freelancer/proposals/$id/accept',
    );
    if (res.isSuccess) return res;

    return _api.postAction(
      '/client/proposals/$id/accept',
    );
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
    var res = await _api.patchAction(path);
    if (res.isFailure) {
      final fallbackPath = switch (normalized) {
        'shortlisted' || 'shortlist' => ApiEndpoints.clientProposalShortlist(id),
        'rejected' || 'reject' => ApiEndpoints.clientProposalReject(id),
        'interview' => ApiEndpoints.clientProposalInterview(id),
        'accepted' || 'accept' => ApiEndpoints.clientProposalAccept(id),
        _ => null,
      };
      if (fallbackPath != null && fallbackPath != path) {
        final fallback = await _api.patchAction(fallbackPath);
        if (fallback.isSuccess) res = fallback;
      }
    }
    return res;
  }

  @override
  Future<Result<bool>> sendMessage(String id, String message) async {
    if (_api == null) return _apiNotConfigured();
    var res = await _api.postAction(
      ApiEndpoints.clientProposalMessage(id),
      body: {'message': message},
    );
    if (res.isSuccess) return res;
    final role = await _role();
    return _api.postAction(
      '/${ApiEndpoints.rolePath(role)}/proposals/$id/message',
      body: {'message': message},
    );
  }

  static Proposal _proposalFromJson(Map<String, dynamic> json) {
    final rawStatus = json['status'] as String? ?? 'pending';
    final deliveryDays =
        json['deliveryDays'] ?? json['deliveryTime'] ?? json['delivery_time'];

    final project = json['project'] is Map<String, dynamic>
        ? json['project'] as Map<String, dynamic>
        : (json['project'] is Map
            ? Map<String, dynamic>.from(json['project'] as Map)
            : null);

    final projectTitle = json['projectTitle'] as String? ??
        json['project_title'] as String? ??
        project?['title'] as String? ??
        'Project';

    final projectDescription = json['projectDescription'] as String? ??
        json['project_description'] as String? ??
        project?['description'] as String?;

    return Proposal(
      id: json['id']?.toString() ?? '',
      projectId:
          json['projectId']?.toString() ??
          json['project_id']?.toString() ??
          project?['id']?.toString() ??
          '',
      projectTitle: projectTitle,
      projectDescription: projectDescription,
      clientId:
          json['clientId']?.toString() ??
          json['client_id']?.toString() ??
          project?['client']?.toString(),
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
