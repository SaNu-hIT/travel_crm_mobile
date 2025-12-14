import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/call_log.dart' as app_model;

class CallLogService {
  /// Checks and requests the required permissions for accessing call logs.
  Future<bool> checkPermission() async {
    final status = await Permission.phone.status;
    if (status.isGranted) {
      return true;
    }

    // Request permission
    final result = await Permission.phone.request();
    return result.isGranted;
  }

  /// Fetches call logs from the device (last 60 days).
  /// If [phoneNumber] is provided, filters the logs for that specific number.
  Future<Iterable<CallLogEntry>> fetchCallLogs({String? phoneNumber}) async {
    final hasPermission = await checkPermission();
    if (!hasPermission) {
      print('CallLogService: Permission denied');
      return [];
    }

    // Optimization: Fetch only logs from the last 60 days
    final now = DateTime.now();
    final fromDate = now.subtract(const Duration(days: 60));
    final fromTimestamp = fromDate.millisecondsSinceEpoch;

    // Use query to filter by date at native level
    // This helps avoid Parcel errors on very old/corrupt logs
    var entries = await CallLog.query(dateFrom: fromTimestamp);

    if (phoneNumber != null) {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

      return entries.where((entry) {
        if (entry.number == null) return false;
        final entryNumber = entry.number!.replaceAll(RegExp(r'[^0-9+]'), '');
        // Check if numbers end with the same sequence (last 10 digits) to handle country codes
        if (entryNumber.length >= 10 && cleanNumber.length >= 10) {
          return entryNumber.endsWith(
            cleanNumber.substring(cleanNumber.length - 10),
          );
        }
        return entryNumber == cleanNumber;
      });
    } else {
      return entries;
    }
  }

  /// Filters device logs to find ones that haven't been synced yet.
  /// Matches based on approximate timestamp overlapping.
  List<CallLogEntry> getUnsyncedLogs(
    Iterable<CallLogEntry> deviceLogs,
    List<app_model.CallLog> existingLogs,
  ) {
    final unsynced = <CallLogEntry>[];

    for (final deviceLog in deviceLogs) {
      if (deviceLog.timestamp == null) continue;

      final deviceTime = deviceLog.timestamp!; // Call Start Time
      // deviceLog.duration is in seconds.
      final deviceDuration = deviceLog.duration ?? 0;
      final deviceEndTime = deviceTime + (deviceDuration * 1000);

      // Check if this log matches any existing log
      bool exists = existingLogs.any((existing) {
        final existingCreated = existing.createdAt.millisecondsSinceEpoch;

        // DEDUPLICATION STRATEGY:
        // Manual logs are created AFTER the call.
        // So existingCreated (API time) should be > deviceTime (Start time).
        // It could be closely after (auto-log) or distinct.

        // Case 1: Auto-synced log (same start time).
        // If we previously synced this exact device log, the backend 'createdAt'
        // *might* be the device timestamp if we mapped it that way in mapToCallLog.
        // Let's check mapToCallLog:
        // It uses: createdAt: DateTime.fromMillisecondsSinceEpoch(entry.timestamp)
        // So Synced logs have Start Time.
        final diffRaw = (existingCreated - deviceTime).abs();
        if (diffRaw < 5000 && existing.duration == deviceDuration) {
          return true; // Exact match (Synced Log)
        }

        // Case 2: Manual log (Created after call).
        // The manual log 'createdAt' should be roughly between Start Time and (End Time + reasonable buffer).
        // Let's say user logs it within 10 minutes of finishing.
        // And Duration should match moderately (within 10s?).

        // Wait, if user logs manually, they input duration manually (or 0).
        // If duration matches, it's strong signal.
        if (existing.duration > 0 &&
            (existing.duration - deviceDuration).abs() < 10) {
          // Duration matches. Check time.
          // Manual Log must be AFTER start time.
          if (existingCreated >= deviceTime &&
              existingCreated < (deviceEndTime + 600000)) {
            // Within 10 mins of call end
            return true;
          }
        }

        // Simplistic dedupe: If exist log is within [Start, End + 1min] window?
        // Let's be conservative. If we find *any* log in that window, assume it's this call?
        // Might skip distinct short calls. But safer than dupe.

        return false;
      });

      if (!exists) {
        unsynced.add(deviceLog);
      }
    }

    return unsynced;
  }

  /// Maps a device [CallLogEntry] to the app's [app_model.CallLog] model.
  app_model.CallLog mapToCallLog(
    CallLogEntry entry,
    String userId,
    String userName,
  ) {
    app_model.CallType type;
    switch (entry.callType) {
      case CallType.incoming:
        type = app_model.CallType.incoming;
        break;
      case CallType.outgoing:
        type = app_model.CallType.outgoing;
        break;
      case CallType.missed:
        type = app_model.CallType.missed;
        break;
      case CallType.rejected:
      case CallType.blocked:
        type =
            app_model.CallType.missed; // Map rejected/blocked to missed for now
        break;
      default:
        type = app_model.CallType.incoming; // Default to incoming
    }

    return app_model.CallLog(
      userId: userId,
      userName: userName,
      callType: type,
      duration: entry.duration ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        entry.timestamp ?? DateTime.now().millisecondsSinceEpoch,
      ),
      notes: '',
      outcome: app_model.CallOutcome.noAnswer, // Default outcome
    );
  }
}
