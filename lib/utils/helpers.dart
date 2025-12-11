import 'package:intl/intl.dart';

// Format date and time
String formatDateTime(DateTime dateTime) {
  return DateFormat('MMM dd, yyyy hh:mm a').format(dateTime);
}

// Format date only
String formatDate(DateTime dateTime) {
  return DateFormat('MMM dd, yyyy').format(dateTime);
}

// Format relative time (e.g., "2 hours ago")
String formatRelativeTime(DateTime dateTime) {
  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inDays > 365) {
    final years = (difference.inDays / 365).floor();
    return '$years ${years == 1 ? 'year' : 'years'} ago';
  } else if (difference.inDays > 30) {
    final months = (difference.inDays / 30).floor();
    return '$months ${months == 1 ? 'month' : 'months'} ago';
  } else if (difference.inDays > 0) {
    return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
  } else if (difference.inHours > 0) {
    return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
  } else {
    return 'Just now';
  }
}

// Format phone number for display
String formatPhoneNumber(String phone) {
  // Remove all non-digit characters
  final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
  
  // Format based on length (assuming 10-digit phone numbers)
  if (digitsOnly.length == 10) {
    return '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
  }
  
  return phone;
}

// Validate email
bool isValidEmail(String email) {
  return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
}
