import 'package:equatable/equatable.dart';

class MasterOption extends Equatable {
  const MasterOption({
    required this.id,
    required this.name,
    this.sortOrder = 0,
    this.min,
    this.max,
  });

  final String id;
  final String name;
  final int sortOrder;
  final double? min;
  final double? max;

  factory MasterOption.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['_id'] ?? json['code'] ?? json['value'])?.toString() ?? '';
    final name = (json['name'] ?? json['label'] ?? json['title'] ?? json['value'])?.toString() ?? id;
    return MasterOption(
      id: id,
      name: name,
      sortOrder: int.tryParse((json['sortOrder'] ?? json['sort_order'] ?? '0').toString()) ?? 0,
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [id, name, sortOrder, min, max];
}
