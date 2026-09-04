import '../../../../core/utils/paginated.dart';
import '../../../../core/utils/result.dart';
import '../entities/investor.dart';

abstract class InvestorRepository {
  Future<Result<Paginated<Investor>>> getInvestors(QueryParams params);

  Future<Result<Investor>> getInvestor(String id);

  Future<Result<Paginated<Deal>>> getDeals(QueryParams params);

  Future<Result<Deal>> getDeal(String id);

  Future<Result<Paginated<PortfolioItem>>> getPortfolio(
    QueryParams params, {
    String? investorId,
  });

  Future<Result<PortfolioItem>> addPortfolioItem(Map<String, dynamic> data);

  Future<Result<PortfolioItem>> updatePortfolioItem(
    String id,
    Map<String, dynamic> data,
  );

  Future<Result<String>> deletePortfolioItem(String id);

  Future<Result<void>> expressInterest(Map<String, dynamic> data);

  Future<Result<void>> updateInvestment(
    String id,
    Map<String, dynamic> data,
  );

  Future<Result<void>> updateInvestmentStatus(String id, String status);

  Future<Result<void>> followInvestor(String id);

  Future<Result<void>> unfollowInvestor(String id);

  Future<Result<void>> saveInvestor(String id);

  Future<Result<void>> unsaveInvestor(String id);

  Future<Result<Map<String, dynamic>>> getVerificationDetails();

  Future<Result<String>> updateVerificationDetail({
    required String key,
    required String value,
    required String status,
    String? documentUrl,
  });

  Future<Result<String>> deleteVerificationDetail({required String key});
}
