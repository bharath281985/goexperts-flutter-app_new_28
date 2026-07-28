import 'package:flutter_test/flutter_test.dart';
import 'package:goexperts_app/app/router/app_router.dart';
import 'package:goexperts_app/app/router/route_names.dart';

void main() {
  group('public entry routes', () {
    test('keeps authentication and legal routes public', () {
      expect(isPublicEntryRoute(Routes.login), isTrue);
      expect(isPublicEntryRoute(Routes.forgotPassword), isTrue);
      expect(isPublicEntryRoute(Routes.privacyPolicy), isTrue);
    });

    test('does not expose dashboards after logout', () {
      expect(isPublicEntryRoute(Routes.freelancerDashboard), isFalse);
      expect(isPublicEntryRoute(Routes.clientDashboard), isFalse);
      expect(isPublicEntryRoute(Routes.investorDashboard), isFalse);
      expect(isPublicEntryRoute(Routes.founderDashboard), isFalse);
    });

    test('does not expose account data pages after logout', () {
      expect(isPublicEntryRoute(Routes.messages), isFalse);
      expect(isPublicEntryRoute(Routes.wallet), isFalse);
      expect(isPublicEntryRoute(Routes.settings), isFalse);
      expect(isPublicEntryRoute(Routes.notifications), isFalse);
      expect(isPublicEntryRoute('/client/projects'), isFalse);
    });
  });
}
