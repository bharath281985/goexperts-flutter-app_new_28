import '../../../../core/utils/paginated.dart';
import '../../../../core/utils/result.dart';
import '../entities/proposal.dart';

abstract class ProposalRepository {
  Future<Result<Paginated<Proposal>>> getProposals(QueryParams params);
  Future<Result<Paginated<Proposal>>> getProjectProposals(
    String projectId,
    QueryParams params,
  );
  Future<Result<Proposal>> getProposal(String id);
  Future<Result<Proposal>> submitProposal({
    required String projectId,
    required String coverLetter,
    required double bidAmount,
    required int deliveryDays,
    List<String> attachments,
  });
  Future<Result<Proposal>> updateProposal({
    required String proposalId,
    required String coverLetter,
    required double bidAmount,
    int? deliveryDays,
  });
  Future<Result<bool>> withdraw(String id);
  Future<Result<bool>> acceptOffer(String id);
  Future<Result<bool>> deleteProposal(String id);
  Future<Result<bool>> updateStatus(String id, String status);
  Future<Result<bool>> sendMessage(String id, String message);
}
