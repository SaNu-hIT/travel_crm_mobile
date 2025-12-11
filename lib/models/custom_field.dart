
class CustomField {
  final String id;
  final String tenantId;
  final String label;
  final String key;
  final String type; // text, number, date, select, textarea
  final List<String> options;
  final bool required;
  final int order;
  final String group;
  final String width; // full, half, third
  final bool isActive;

  CustomField({
    required this.id,
    required this.tenantId,
    required this.label,
    required this.key,
    required this.type,
    this.options = const [],
    this.required = false,
    this.order = 0,
    this.group = "General Info",
    this.width = "full",
    this.isActive = true,
  });

  factory CustomField.fromJson(Map<String, dynamic> json) {
    return CustomField(
      id: json['_id'] as String,
      tenantId: json['tenantId'] as String,
      label: json['label'] as String,
      key: json['key'] as String,
      type: json['type'] as String,
      options: json['options'] != null
          ? List<String>.from(json['options'] as List)
          : [],
      required: json['required'] as bool? ?? false,
      order: json['order'] as int? ?? 0,
      group: json['group'] as String? ?? "General Info",
      width: json['width'] as String? ?? "full",
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'tenantId': tenantId,
      'label': label,
      'key': key,
      'type': type,
      'options': options,
      'required': required,
      'order': order,
      'group': group,
      'width': width,
      'isActive': isActive,
    };
  }
}
