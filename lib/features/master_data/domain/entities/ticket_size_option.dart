class TicketSizeOption {
  final String id;
  final String label;
  final String value;
  final num min;
  final num max;

  const TicketSizeOption({
    required this.id,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
  });

  factory TicketSizeOption.fromJson(Map<String, dynamic> json) {
    return TicketSizeOption(
      id: (json['id'] ?? json['_id'] ?? json['value'])?.toString() ?? '',
      label: (json['label'] ?? json['name'] ?? json['value'])?.toString() ?? '',
      value: (json['value'] ?? json['id'])?.toString() ?? '',
      min: num.tryParse(json['min']?.toString() ?? '') ?? 0,
      max: num.tryParse(json['max']?.toString() ?? '') ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketSizeOption &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
