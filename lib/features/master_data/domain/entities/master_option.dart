import 'package:equatable/equatable.dart';

class MasterOption extends Equatable {
  const MasterOption({required this.id, required this.name});

  final String id;
  final String name;

  factory MasterOption.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['_id'] ?? json['code'] ?? json['value'])?.toString() ?? '';
    final name = (json['name'] ?? json['label'] ?? json['title'] ?? json['value'])?.toString() ?? id;
    return MasterOption(id: id, name: name);
  }

  @override
  List<Object?> get props => [id, name];
}
