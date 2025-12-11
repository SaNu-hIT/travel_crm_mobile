
class FieldGroup {
  final String id;
  final String name;
  final int order;
  final bool isActive;

  FieldGroup({
    required this.id,
    required this.name,
    required this.order,
    this.isActive = true,
  });

  factory FieldGroup.fromJson(Map<String, dynamic> json) {
    return FieldGroup(
      id: json['_id'] as String,
      name: json['name'] as String,
      order: json['order'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'order': order,
      'isActive': isActive,
    };
  }
}
