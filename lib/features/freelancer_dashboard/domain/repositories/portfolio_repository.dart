import '../../../../core/utils/paginated.dart';
import '../../../../core/utils/result.dart';
import '../entities/portfolio_item.dart';

abstract class PortfolioRepository {
  Future<Result<Paginated<PortfolioItem>>> getPortfolio(
    QueryParams params, {
    String? freelancerId,
  });
  Future<Result<PortfolioItem>> getPortfolioItem(
    String id, {
    String? freelancerId,
  });
  Future<Result<PortfolioItem>> addPortfolio(Map<String, dynamic> data);
  Future<Result<PortfolioItem>> updatePortfolio(
    String id,
    Map<String, dynamic> data,
  );
  Future<Result<String>> deletePortfolio(String id);
}
