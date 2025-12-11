import '../utils/constants.dart';

class User {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String tenantId;
  final String tenantName;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.tenantId,
    required this.tenantName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: parseUserRole(json['role'] as String),
      tenantId: json['tenantId'] as String,
      tenantName: json['tenantName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'tenantId': tenantId,
      'tenantName': tenantName,
    };
  }
}
