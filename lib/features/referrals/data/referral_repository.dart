import '../../../core/network/api_client_helper.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/utils/result.dart';
import '../domain/referral_details.dart';

abstract class ReferralRepository {
  Future<Result<ReferralDetails>> getReferrals();
}

class ReferralRepositoryImpl implements ReferralRepository {
  ReferralRepositoryImpl(this._client);
  final ApiClientHelper _client;

  @override
  Future<Result<ReferralDetails>> getReferrals() => _client.get(
        ApiEndpoints.referrals,
        parser: ReferralDetails.fromJson,
      );
}
