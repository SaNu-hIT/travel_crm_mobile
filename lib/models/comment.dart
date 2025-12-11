class LeadComment {
  final String userId;
  final String userName;
  final String comment;
  final DateTime createdAt;

  LeadComment({
    required this.userId,
    required this.userName,
    required this.comment,
    required this.createdAt,
  });

  factory LeadComment.fromJson(Map<String, dynamic> json) {
    return LeadComment(
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      comment: json['comment'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
