import 'dart:convert';

void main() {
  const jsonStr = '''
  {
         "success": true,
         "message": "Investor dashboard retrieved",
         "data": {
             "profileCompletion": 100,
             "isProfileComplete": true,
             "accountVerified": false,
             "verificationMissingCount": 4,
             "verificationTrustScore": 20,
             "walletBalance": 1900.32,
             "portfolioValue": 0,
             "totalInvestments": 4,
             "activeInvestments": 0,
             "pendingInvestments": 0,
             "unreadMessages": 0,
             "unreadNotifications": 0,
             "watchlistCount": 2,
             "supportTickets": 0,
             "charts": {
                 "portfolioGrowth": [
                  {"date": "2026-08-06T14:04:19.879Z", "amount": 50000, "status": "Offer"}
                 ]
            },
             "widgets": {
                 "recommendedStartups": [
                   {
                         "id": "2e1eb4c2-a3eb-4dc9-906c-a4ab3237dbe2",
                         "startup": "Nexus AI Inc.cccc",
                         "user": {
                             "id": "ddb2b54c-6c2b-43f3-9329-441e324c5d65"
                         }
                   }
                 ]
             }
        }
  }
  ''';
  
  final Map<String, dynamic> data = jsonDecode(jsonStr);
  
  try {
          final summaryData = data['data'] ?? data;
          final portfolioValue =
              (summaryData['portfolioValue'] as num?)?.toDouble() ?? 0;
          final profileCompletion =
              (summaryData['profileCompletion'] as num?)?.toInt() ?? 0;
          final activeInvestments =
              (summaryData['activeInvestments'] as num?)?.toInt() ?? 0;
          final pendingInvestments =
              (summaryData['pendingInvestments'] as num?)?.toInt() ?? 0;

          final chartList = summaryData['charts']?['portfolioGrowth'] as List?;
          final chart =
              chartList?.map((e) {
                if (e is num) return e.toDouble();
                if (e is Map) return (e['amount'] as num?)?.toDouble() ?? 0.0;
                return 0.0;
              }).toList() ??
              const <double>[];

          final recommendedList =
              summaryData['widgets']?['recommendedStartups'] as List? ??
              summaryData['recommendedStartups'] as List? ?? [];
              
          List startupsList = recommendedList.map((item) {
            final json = Map<String, dynamic>.from(item as Map);
            final founder = Map<String, dynamic>.from(
              json['founder'] as Map? ?? {},
            );

            final city = founder['city'] as String?;
            final country = founder['country'] as String?;
            String location = 'N/A';
            if (city != null && country != null) {
              location = '$city, $country';
            } else if (city != null) {
              location = city;
            } else if (country != null) {
              location = country;
            }

            return {
              'id': json['id']?.toString() ?? '',
              'founderId':
                  json['founderId']?.toString() ??
                  founder['id']?.toString() ??
                  '',
              'name': json['startup']?.toString() ?? 'Startup',
              'tagline': founder['bio']?.toString() ?? '',
              'industry': json['industry']?.toString() ?? 'General',
              'stage': json['stage']?.toString() ?? 'MVP',
              'founderName': founder['fullName']?.toString() ?? 'Founder',
              'fundingRequired': (json['funding'] as num?)?.toDouble() ?? 0,
              'equityOffered': (json['equity'] as num?)?.toDouble() ?? 0,
              'location': location,
              'logoUrl':
                  json['logo']?.toString() ??
                  founder['avatarUrl']?.toString() ??
                  '',
              'founderAvatar': founder['avatarUrl']?.toString() ?? '',
              'fundingRaised': (founder['raised'] as num?)?.toDouble() ?? 0,
              'isVerified': true,
            };
          }).toList();

          final walletBal =
              (summaryData['walletBalance'] as num?)?.toDouble() ?? 0;
          final upcomingMeetingsList =
              summaryData['widgets']?['upcomingMeetingsList'] as List? ??
              summaryData['upcomingMeetingsList'] as List?;
              
          print("SUCCESS! ALL PARSED");
          print("dashboardData keys: ${summaryData.keys}");
  } catch (e, stack) {
    print("CRASHED: $e");
    print(stack);
  }
}
