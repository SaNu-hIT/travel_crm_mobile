import '../utils/constants.dart';
import 'comment.dart';
import 'call_log.dart';
import 'quotation.dart';

class AssignedUser {
  final String id;
  final String name;
  final String email;

  AssignedUser({required this.id, required this.name, required this.email});

  factory AssignedUser.fromJson(Map<String, dynamic> json) {
    return AssignedUser(
      id: json['_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }
}

class Lead {
  final String id;
  final String tenantId;
  final String? assignedToId;
  final AssignedUser? assignedTo;
  final AssignedUser? createdBy;
  final LeadStatus status;
  final String source;
  final String? category;
  final List<String> tags;

  // Basic Lead Information
  final String name;
  final String? profileImage;
  final String phone;
  final String? email;

  // Travel Details removed - using customData
  final Map<String, dynamic> customData;

  // Tracking
  final DateTime? followUpDate;
  final List<LeadComment> comments;
  final List<CallLog> callLogs;

  // Metadata
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String createdById;

  // Customer Conversion
  final bool isCustomer;
  final DateTime? convertedAt;

  // Quotation
  final Quotation? quotation;

  Lead({
    required this.id,
    required this.tenantId,
    this.assignedToId,
    this.assignedTo,
    this.createdBy,
    required this.status,
    required this.source,
    this.category,
    this.tags = const [],
    required this.name,
    this.profileImage,
    required this.phone,
    this.email,
    this.customData = const {},
    this.followUpDate,
    this.comments = const [],
    this.callLogs = const [],
    this.createdAt,
    this.updatedAt,
    required this.createdById,
    this.isCustomer = false,
    this.convertedAt,
    this.quotation,
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['_id'] as String,
      tenantId: json['tenantId'] as String,
      assignedToId: json['assignedToId'] is Map
          ? json['assignedToId']['_id'] as String?
          : json['assignedToId'] as String?,
      assignedTo: json['assignedToId'] is Map
          ? AssignedUser.fromJson(json['assignedToId'] as Map<String, dynamic>)
          : null,
      createdBy: json['createdById'] is Map
          ? AssignedUser.fromJson(json['createdById'] as Map<String, dynamic>)
          : null,
      status: parseLeadStatus(json['status'] as String),
      source: json['source'] as String,
      category: json['category'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : [],
      name: json['name'] as String,
      profileImage: json['profileImage'] as String?,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      customData: json['customData'] != null
          ? Map<String, dynamic>.from(json['customData'] as Map)
          : {},
      followUpDate: json['followUpDate'] != null
          ? DateTime.parse(json['followUpDate'] as String)
          : null,
      comments: json['comments'] != null
          ? (json['comments'] as List)
                .map((c) => LeadComment.fromJson(c as Map<String, dynamic>))
                .toList()
          : [],
      callLogs: json['callLogs'] != null
          ? (json['callLogs'] as List)
                .map((c) => CallLog.fromJson(c as Map<String, dynamic>))
                .toList()
          : [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      createdById: json['createdById'] is Map
          ? json['createdById']['_id'] as String
          : json['createdById'] as String,
      isCustomer: json['isCustomer'] as bool? ?? false,
      convertedAt: json['convertedAt'] != null
          ? DateTime.parse(json['convertedAt'] as String)
          : null,
      quotation: json['quotation'] != null
          ? Quotation.fromJson(json['quotation'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'tenantId': tenantId,
      'assignedToId': assignedToId,
      'status': status.value,
      'source': source,
      'category': category,
      'tags': tags,
      'name': name,
      'profileImage': profileImage,
      'phone': phone,
      'email': email,
      'customData': customData,
      'followUpDate': followUpDate?.toIso8601String(),
      'comments': comments.map((c) => c.toJson()).toList(),
      'callLogs': callLogs.map((c) => c.toJson()).toList(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdById': createdById,
      'isCustomer': isCustomer,
      'convertedAt': convertedAt?.toIso8601String(),
      'quotation': quotation?.toJson(),
    };
  }

  // Helper method to create a copy with updated fields
  Lead copyWith({
    String? id,
    String? tenantId,
    String? assignedToId,
    AssignedUser? assignedTo,
    AssignedUser? createdBy,
    LeadStatus? status,
    String? source,
    String? category,
    List<String>? tags,
    String? name,
    String? profileImage,
    String? phone,
    String? email,
    Map<String, dynamic>? customData,
    DateTime? followUpDate,
    List<LeadComment>? comments,
    List<CallLog>? callLogs,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdById,
    bool? isCustomer,
    DateTime? convertedAt,
    Quotation? quotation,
  }) {
    return Lead(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      assignedToId: assignedToId ?? this.assignedToId,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      source: source ?? this.source,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      name: name ?? this.name,
      profileImage: profileImage ?? this.profileImage,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      customData: customData ?? this.customData,
      followUpDate: followUpDate ?? this.followUpDate,
      comments: comments ?? this.comments,
      callLogs: callLogs ?? this.callLogs,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdById: createdById ?? this.createdById,
      isCustomer: isCustomer ?? this.isCustomer,
      convertedAt: convertedAt ?? this.convertedAt,
      quotation: quotation ?? this.quotation,
    );
  }
}
