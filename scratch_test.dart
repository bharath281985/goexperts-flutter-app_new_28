void main() {
  final Map<String, dynamic> data = {
    "success": true,
    "message": "Investor dashboard retrieved",
    "data": {
      "profileCompletion": 100,
      "isProfileComplete": true,
      "accountVerified": false,
      "verificationMissingCount": 4,
    }
  };

  dynamic readFrom(Map<dynamic, dynamic> source, String camelKey, String snakeKey) =>
      source[camelKey] ?? source[snakeKey];

  dynamic dashboardValue(String camelKey, String snakeKey) {
    final directValue = readFrom(data, camelKey, snakeKey);
    if (directValue != null) return directValue;

    for (final nestedKey in const ['data', 'profile']) {
      final nested = data[nestedKey];
      if (nested is Map) {
        final nestedValue = readFrom(nested, camelKey, snakeKey);
        if (nestedValue != null) return nestedValue;
      }
    }
    return null;
  }

  print("verificationMissingCount: ${dashboardValue('verificationMissingCount', 'verification_missing_count')}");
  print("accountVerified: ${dashboardValue('accountVerified', 'account_verified')}");
}
