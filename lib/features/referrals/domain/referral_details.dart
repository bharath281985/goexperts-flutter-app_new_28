class ReferralDetails {
  const ReferralDetails({
    required this.referralCode,
    required this.referralLink,
    required this.qrCode,
    required this.stats,
    required this.history,
    this.referralRewardAmount = 25,
    this.commission = 5,
    this.welcomeBonusAmount = 99,
    this.welcomeBonusEnabled = true,
  });

  final String referralCode;
  final String referralLink;
  final String qrCode;
  final ReferralStats stats;
  final List<Map<String, dynamic>> history;
  final num referralRewardAmount;
  final num commission;
  final num welcomeBonusAmount;
  final bool welcomeBonusEnabled;

  factory ReferralDetails.fromJson(dynamic value) {
    final json = value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
    final rawHistory = json['history'];
    num number(dynamic v, num fallback) => v is num ? v : num.tryParse(v?.toString() ?? '') ?? fallback;
    return ReferralDetails(
      referralCode: json['referralCode']?.toString().trim() ?? '',
      referralLink: json['referralLink']?.toString().trim() ?? '',
      qrCode: json['qrCode']?.toString().trim() ?? '',
      stats: ReferralStats.fromJson(json['stats']),
      history: rawHistory is List
          ? rawHistory.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : const [],
      referralRewardAmount: json['referralRewardAmount'] != null ? number(json['referralRewardAmount'], 25) : 25,
      commission: json['commission'] != null ? number(json['commission'], 5) : 5,
      welcomeBonusAmount: json['welcomeBonusAmount'] != null ? number(json['welcomeBonusAmount'], 99) : 99,
      welcomeBonusEnabled: json['welcomeBonusEnabled'] ?? true,
    );
  }
}

class ReferralStats {
  const ReferralStats({required this.total, required this.pending, required this.rewarded, required this.totalReward});
  final int total;
  final int pending;
  final int rewarded;
  final num totalReward;

  static num _number(dynamic value) => value is num ? value : num.tryParse(value?.toString() ?? '') ?? 0;

  factory ReferralStats.fromJson(dynamic value) {
    final json = value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
    return ReferralStats(
      total: _number(json['total']).toInt(),
      pending: _number(json['pending']).toInt(),
      rewarded: _number(json['rewarded']).toInt(),
      totalReward: _number(json['totalReward']),
    );
  }
}
