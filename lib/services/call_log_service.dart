import 'package:call_log/call_log.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/call_log.dart' as app_model;

class CallLogService {
  /// Checks and requests the required permissions for accessing call logs.
  /// Returns true if permission is granted, false otherwise.
  Future<bool> checkPermission() async {
    final status = await Permission.phone.status;
    if (status.isGranted) {
      return true;
    }

    // Permission not granted, try to request it
    final result = await Permission.phone.request();

    if (result.isGranted) {
      print('CallLogService: Permission granted');
      return true;
    } else if (result.isDenied) {
      print('CallLogService: Permission denied by user');
      return false;
    } else if (result.isPermanentlyDenied) {
      print('CallLogService: Permission permanently denied - user must enable in settings');
      return false;
    }

    return false;
  }

  /// Fetches call logs from the device (last 60 days).
  /// If [phoneNumber] is provided, filters the logs for that specific number.
  Future<Iterable<CallLogEntry>> fetchCallLogs({String? phoneNumber}) async {
    final hasPermission = await checkPermission();
    if (!hasPermission) {
      print('CallLogService: Cannot fetch call logs - permission denied');
      return [];
    }

    try {
      // Optimization: Fetch only logs from the last 60 days
      final now = DateTime.now();
      final fromDate = now.subtract(const Duration(days: 60));
      final fromTimestamp = fromDate.millisecondsSinceEpoch;

      print('CallLogService: Fetching call logs from ${fromDate.toString()}');
      print('CallLogService: From timestamp: $fromTimestamp');

      // Use query to filter by date at native level
      // This helps avoid Parcel errors on very old/corrupt logs
      var entries = await CallLog.query(dateFrom: fromTimestamp);
      print('CallLogService: Fetched ${entries.length} call logs from device');

      // Log details of the most recent call logs for debugging
      if (entries.isNotEmpty) {
        print('=== RECENT DEVICE CALL LOGS (Last 10) ===');
        var count = 0;
        for (final entry in entries.take(10)) {
          count++;
          final timestamp = entry.timestamp != null
              ? DateTime.fromMillisecondsSinceEpoch(entry.timestamp!)
              : null;
          print('$count. Number: ${entry.number ?? "Unknown"}');
          print('   Type: ${entry.callType}');
          print('   Duration: ${entry.duration ?? 0}s');
          print('   Timestamp: ${timestamp?.toString() ?? "Unknown"}');
          if (timestamp != null) {
            print('   Date: ${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}');
          }
        }
        print('=== END RECENT CALL LOGS ===');
      }

      if (phoneNumber != null) {
        final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), ''); // Remove ALL non-digits including +
        print('CallLogService: Filtering for phone number: $phoneNumber (cleaned: $cleanNumber)');

        final filtered = entries.where((entry) {
          if (entry.number == null) return false;
          final entryNumber = entry.number!.replaceAll(RegExp(r'[^0-9]'), ''); // Remove ALL non-digits including +

          // Check if numbers end with the same sequence (last 10 digits) to handle country codes
          if (entryNumber.length >= 10 && cleanNumber.length >= 10) {
            final entryLast10 = entryNumber.substring(entryNumber.length - 10);
            final cleanLast10 = cleanNumber.substring(cleanNumber.length - 10);
            return entryLast10 == cleanLast10;
          }
          return entryNumber == cleanNumber;
        }).toList();

        print('CallLogService: Filtered to ${filtered.length} logs for number: $phoneNumber');
        return filtered;
      } else {
        return entries;
      }
    } catch (e) {
      print('CallLogService: Error fetching call logs - $e');
      return [];
    }
  }

  /// Filters device logs to find ones that haven't been synced yet.
  /// Matches based on approximate timestamp overlapping.
  List<CallLogEntry> getUnsyncedLogs(
    Iterable<CallLogEntry> deviceLogs,
    List<app_model.CallLog> existingLogs,
  ) {
    final unsynced = <CallLogEntry>[];

    print('  === DEDUPLICATION DEBUG ===');
    print('  Device logs to check: ${deviceLogs.length}');
    print('  Existing logs in database: ${existingLogs.length}');
    print('  Existing log timestamps:');
    for (var log in existingLogs) {
      print('    - ${log.createdAt.toLocal()}, duration: ${log.duration}s, type: ${log.callType}');
    }
    print('  === CHECKING EACH DEVICE LOG ===');

    for (final deviceLog in deviceLogs) {
      if (deviceLog.timestamp == null) continue;

      final deviceTime = deviceLog.timestamp!; // Call Start Time
      // deviceLog.duration is in seconds.
      final deviceDuration = deviceLog.duration ?? 0;
      final deviceEndTime = deviceTime + (deviceDuration * 1000);

      print('  → Checking device log: ${deviceLog.number}, time: ${DateTime.fromMillisecondsSinceEpoch(deviceTime)}, duration: ${deviceDuration}s');

      // Check if this log matches any existing log
      bool exists = false;
      for (var existing in existingLogs) {
        final existingCreated = existing.createdAt.millisecondsSinceEpoch;

        // IMPROVED DEDUPLICATION STRATEGY:
        // Compare timestamps with more tolerance for timezone/server delays

        // Case 1: Auto-synced log - timestamps should be very close
        // Allow up to 60 seconds difference to account for server processing time
        final diffRaw = (existingCreated - deviceTime).abs();
        if (diffRaw < 60000) { // Within 60 seconds
          // If timestamps are close, check duration too
          final durationDiff = (existing.duration - deviceDuration).abs();
          if (durationDiff < 5) {
            print('    → Found matching log (timestamp diff: ${diffRaw}ms, duration diff: ${durationDiff}s)');
            print('       Device: ${DateTime.fromMillisecondsSinceEpoch(deviceTime)}');
            print('       Existing: ${existing.createdAt.toLocal()}');
            exists = true;
            break;
          }
        }

        // Case 2: Check if existing log falls within the call time window
        // Server might have adjusted the timestamp, so check if it's within reasonable range
        if (existingCreated >= deviceTime - 300000 && // 5 min before call start
            existingCreated <= deviceEndTime + 300000) { // 5 min after call end
          // Within time window, check duration similarity
          final durationDiff = (existing.duration - deviceDuration).abs();
          if (durationDiff < 10) {
            print('    → Found matching log in time window (duration diff: ${durationDiff}s)');
            print('       Device: ${DateTime.fromMillisecondsSinceEpoch(deviceTime)}');
            print('       Existing: ${existing.createdAt.toLocal()}');
            exists = true;
            break;
          }
        }
      }

      if (!exists) {
        print('    ✓ UNSYNCED - Will be added to database');
        unsynced.add(deviceLog);
      }
    }

    print('  === DEDUPLICATION SUMMARY ===');
    print('  Total device logs checked: ${deviceLogs.length}');
    print('  Already synced: ${deviceLogs.length - unsynced.length}');
    print('  New logs to sync: ${unsynced.length}');

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
