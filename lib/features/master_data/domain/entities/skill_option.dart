import 'package:equatable/equatable.dart';

class SkillOption extends Equatable {
  const SkillOption({required this.id, required this.name, this.categoryId});

  final String id;
  final String name;
  final String? categoryId;

  factory SkillOption.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['_id'] ?? json['skillId'] ?? json['code'] ?? json['name'])?.toString() ?? '';
    final name =
        json['name']?.toString() ??
        json['title']?.toString() ??
        json['skillName']?.toString() ??
        json['label']?.toString() ??
        id;
    return SkillOption(
      id: id,
      name: name,
      categoryId:
          json['categoryId']?.toString() ??
          json['category_id']?.toString() ??
          json['industryId']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id];
}
