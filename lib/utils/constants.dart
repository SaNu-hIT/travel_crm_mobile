import 'package:flutter/material.dart';

// Lead Status Enum
enum LeadStatus {
  NEW,
  FOLLOWUP,
  INTERESTED,
  PROPOSAL_SENT,
  NOT_INTERESTED,
  BOOKED,
  PENDING,
  CANCELLED,
  CLOSED_WON,
  CLOSED_LOST,
}

// User Role Enum
enum UserRole {
  SAAS_ADMIN,
  ADMIN,
  MANAGER,
  EMPLOYEE,
}

// Extension for LeadStatus
extension LeadStatusExtension on LeadStatus {
  String get value {
    return toString().split('.').last;
  }
  
  String get displayName {
    switch (this) {
      case LeadStatus.NEW:
        return 'New';
      case LeadStatus.FOLLOWUP:
        return 'Follow Up';
      case LeadStatus.INTERESTED:
        return 'Interested';
      case LeadStatus.PROPOSAL_SENT:
        return 'Proposal Sent';
      case LeadStatus.NOT_INTERESTED:
        return 'Not Interested';
      case LeadStatus.BOOKED:
        return 'Booked';
      case LeadStatus.PENDING:
        return 'Pending';
      case LeadStatus.CANCELLED:
        return 'Cancelled';
      case LeadStatus.CLOSED_WON:
        return 'Closed Won';
      case LeadStatus.CLOSED_LOST:
        return 'Closed Lost';
    }
  }
  
  Color get color {
    switch (this) {
      case LeadStatus.NEW:
        return Colors.blue;
      case LeadStatus.FOLLOWUP:
        return Colors.orange;
      case LeadStatus.INTERESTED:
        return Colors.green;
      case LeadStatus.PROPOSAL_SENT:
        return Colors.purple;
      case LeadStatus.NOT_INTERESTED:
        return Colors.grey;
      case LeadStatus.BOOKED:
        return Colors.teal;
      case LeadStatus.PENDING:
        return Colors.amber;
      case LeadStatus.CANCELLED:
        return Colors.red;
      case LeadStatus.CLOSED_WON:
        return Colors.green.shade700;
      case LeadStatus.CLOSED_LOST:
        return Colors.red.shade700;
    }
  }
}

// Helper function to parse LeadStatus from string
LeadStatus parseLeadStatus(String status) {
  return LeadStatus.values.firstWhere(
    (e) => e.value == status,
    orElse: () => LeadStatus.NEW,
  );
}

// Helper function to parse UserRole from string
UserRole parseUserRole(String role) {
  return UserRole.values.firstWhere(
    (e) => e.toString().split('.').last == role,
    orElse: () => UserRole.EMPLOYEE,
  );
}

// App Colors (Modern pastel theme inspired by reference design)
class AppColors {
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color secondary = Color(0xFFFFFFFF); // White
  static const Color background = Color(0xFFF5F3FF); // Light purple background
  static const Color surface = Color(0xFFFFFFFF); // White cards
  static const Color cardBackground = Color(0xFFFAF9FC); // Very light purple
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color accent1 = Color(0xFFFCBFD8); // Pink
  static const Color accent2 = Color(0xFFDDD6FE); // Light purple
  static const Color accent3 = Color(0xFFFDE68A); // Light yellow
}

// Error Messages
class ErrorMessages {
  static const String networkError = 'Network error. Please check your connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unauthorized = 'Unauthorized. Please login again.';
  static const String invalidCredentials = 'Invalid email or password.';
  static const String requiredField = 'This field is required.';
  static const String invalidEmail = 'Please enter a valid email.';
}

// Success Messages
class SuccessMessages {
  static const String loginSuccess = 'Login successful!';
  static const String commentAdded = 'Call log added successfully!';
  static const String leadUpdated = 'Lead updated successfully!';
}
