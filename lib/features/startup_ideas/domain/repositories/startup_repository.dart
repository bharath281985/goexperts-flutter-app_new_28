import '../../../../core/utils/paginated.dart';
import '../../../../core/utils/result.dart';
import '../entities/startup.dart';

abstract class StartupRepository {
  Future<Result<Paginated<Startup>>> getStartups(QueryParams params);
  Future<Result<Paginated<Startup>>> getMyStartups(QueryParams params);
  Future<Result<Startup>> getStartup(String id);
  Future<Result<bool>> toggleSave(String id);
  Future<Result<bool>> toggleFollow(String id);
  Future<Result<bool>> submitOffer(Map<String, dynamic> data);
  Future<Result<bool>> expressInterest(Map<String, dynamic> data);
  Future<Result<bool>> withdrawInterest(String id);
  Future<Result<Startup>> createIdea(Map<String, dynamic> data);
  Future<Result<bool>> updateIdea(String id, Map<String, dynamic> data);
  Future<Result<bool>> deleteIdea(String id);

  // Offers & Deals
  Future<Result<Paginated<dynamic>>> getMyInvestments(QueryParams params);
  Future<Result<Paginated<dynamic>>> getIncomingOffers({
    String? startupId,
    QueryParams? params,
  });
  Future<Result<bool>> acceptOffer(String id);
  Future<Result<bool>> rejectOffer(String id);
  Future<Result<bool>> scheduleOfferMeeting(
    String id, {
    String? date,
    String? time,
    Map<String, dynamic>? data,
  });

  // Pitch Deck & Business Plan
  Future<Result<Map<String, dynamic>>> getFundingOverview();
  Future<Result<bool>> createFundingRound(Map<String, dynamic> data);
  Future<Result<Map<String, dynamic>>> getPitchDeck();
  Future<Result<bool>> saveBusinessPlan(Map<String, dynamic> data);
  Future<Result<Map<String, dynamic>>> getBusinessPlan();
}
