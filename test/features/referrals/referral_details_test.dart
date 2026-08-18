import 'package:flutter_test/flutter_test.dart';
import 'package:goexperts_app/features/referrals/domain/referral_details.dart';


void main() {
  test('parses referral response defensively', () {
    final details = ReferralDetails.fromJson({
      'referralCode': 'GE-123',
      'referralLink': 'https://goexperts.com/ref/GE-123',
      'stats': {'total': '4', 'pending': null, 'rewarded': 2.0, 'totalReward': '125.50'},
      'history': [
        {'email': 'friend@example.com', 'status': 'pending'},
        'invalid',
      ],
    });

    expect(details.referralCode, 'GE-123');
    expect(details.qrCode, isEmpty);
    expect(details.stats.total, 4);
    expect(details.stats.pending, 0);
    expect(details.stats.rewarded, 2);
    expect(details.stats.totalReward, 125.5);
    expect(details.history, hasLength(1));
  });

  test('uses safe defaults for malformed payload', () {
    final details = ReferralDetails.fromJson(null);
    expect(details.referralCode, isEmpty);
    expect(details.stats.total, 0);
    expect(details.history, isEmpty);
  });
}
